import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import { base64Url, equalSecret, fcmFailure } from "./lib.ts";

type Delivery = {
  id: string;
  token: string;
  title: string;
  body: string;
  event_type: string;
  target_id: string | null;
  attempts: number;
};

type ServiceAccount = {
  client_email: string;
  private_key: string;
  project_id: string;
};

async function googleAccessToken(account: ServiceAccount): Promise<string> {
  const pem = account.private_key.replace(
    /-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g,
    "",
  );
  const keyBytes = Uint8Array.from(atob(pem), (char) => char.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const now = Math.floor(Date.now() / 1000);
  const encoder = new TextEncoder();
  const header = base64Url(
    encoder.encode(JSON.stringify({ alg: "RS256", typ: "JWT" })),
  );
  const claims = base64Url(encoder.encode(JSON.stringify({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })));
  const unsigned = `${header}.${claims}`;
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      key,
      encoder.encode(unsigned),
    ),
  );
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${base64Url(signature)}`,
    }),
  });
  if (!response.ok) throw new Error("google_oauth_unavailable");
  const value = await response.json();
  if (typeof value.access_token !== "string") {
    throw new Error("google_oauth_invalid_response");
  }
  return value.access_token;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return Response.json({ error: "method_not_allowed" }, { status: 405 });
  }
  const expected = Deno.env.get("RESOURCE_CLEANUP_SECRET") ?? "";
  if (
    !expected ||
    !equalSecret(request.headers.get("x-dispatch-secret") ?? "", expected)
  ) {
    return Response.json({ error: "unauthorized" }, { status: 401 });
  }

  const rawCredential = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!rawCredential) return Response.json({ configured: false, inspected: 0 });

  try {
    const account = JSON.parse(rawCredential) as ServiceAccount;
    if (!account.client_email || !account.private_key || !account.project_id) {
      throw new Error("invalid_fcm_credentials");
    }
    const accessToken = await googleAccessToken(account);
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const claimed = await admin.rpc("phase6_claim_deliveries", {
      p_limit: 100,
    });
    if (claimed.error) throw claimed.error;
    const deliveries = (claimed.data ?? []) as Delivery[];
    let sent = 0;
    let failed = 0;

    for (const delivery of deliveries) {
      let result: "sent" | "retry" | "invalid" | "failed" = "retry";
      let reason: string | null = null;
      try {
        const response = await fetch(
          `https://fcm.googleapis.com/v1/projects/${
            encodeURIComponent(account.project_id)
          }/messages:send`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              message: {
                token: delivery.token,
                notification: { title: delivery.title, body: delivery.body },
                data: {
                  event_type: delivery.event_type,
                  target_id: delivery.target_id ?? "",
                },
              },
            }),
          },
        );
        if (response.ok) result = "sent";
        else {
          const payload = await response.json().catch(() => null);
          result = fcmFailure(response.status, payload);
          reason = `fcm_http_${response.status}`;
        }
      } catch {
        reason = "fcm_network_error";
      }
      const finished = await admin.rpc("phase6_finish_delivery", {
        p_id: delivery.id,
        p_result: result,
        p_error: reason,
      });
      if (finished.error) throw finished.error;
      if (result === "sent") sent++;
      else failed++;
    }
    return Response.json({ inspected: deliveries.length, sent, failed });
  } catch {
    return Response.json({ error: "dispatch_failed" }, { status: 500 });
  }
});
