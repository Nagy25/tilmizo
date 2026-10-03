import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";

import {
  buildAuthenticationTemplatePayload,
  maskPhone,
  parseAllowedRecipients,
  validateOtpRequest,
} from "./lib.ts";
import type { SendSmsHookPayload } from "./lib.ts";

type MetaResponse = {
  error?: {
    code?: number;
    error_subcode?: number;
    fbtrace_id?: string;
  };
  messages?: Array<{ id?: string }>;
};

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    throw new Error(`missing_environment:${name}`);
  }
  return value;
}

function authError(httpCode: number, message: string): Response {
  return Response.json(
    { error: { http_code: httpCode, message } },
    { status: httpCode },
  );
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return authError(405, "Method not allowed");
  }

  let hookSecret: string;
  let accessToken: string;
  let phoneNumberId: string;
  let graphApiVersion: string;
  let templateName: string;
  let templateLanguage: string;
  let allowedRecipients: Set<string>;

  try {
    hookSecret = requiredEnv("SEND_SMS_HOOK_SECRET").replace(
      /^v1,whsec_/,
      "",
    );
    accessToken = requiredEnv("META_WHATSAPP_ACCESS_TOKEN");
    phoneNumberId = requiredEnv("META_WHATSAPP_PHONE_NUMBER_ID");
    graphApiVersion = requiredEnv("META_WHATSAPP_GRAPH_API_VERSION");
    templateName = requiredEnv("META_WHATSAPP_TEMPLATE_NAME");
    templateLanguage = requiredEnv("META_WHATSAPP_TEMPLATE_LANGUAGE");
    allowedRecipients = parseAllowedRecipients(
      requiredEnv("META_WHATSAPP_ALLOWED_RECIPIENTS"),
    );
  } catch (error) {
    console.error("WhatsApp OTP function configuration is incomplete");
    return authError(500, "Authentication delivery is not configured");
  }

  const rawPayload = await request.text();
  let payload: SendSmsHookPayload;

  try {
    const webhook = new Webhook(hookSecret);
    payload = webhook.verify(
      rawPayload,
      Object.fromEntries(request.headers),
    ) as SendSmsHookPayload;
  } catch (error) {
    console.warn("Rejected an invalid Send SMS hook signature");
    return authError(401, "Invalid hook signature");
  }

  let phone: string;
  let otp: string;

  try {
    ({ phone, otp } = validateOtpRequest(payload, allowedRecipients));
  } catch (error) {
    const reason = error instanceof Error ? error.message : "invalid_payload";
    console.warn("Rejected WhatsApp OTP request", { reason });

    if (reason === "recipient_not_allowed") {
      return authError(403, "Phone number is not enabled for development testing");
    }
    return authError(422, "Invalid Egyptian phone authentication request");
  }

  const endpoint =
    `https://graph.facebook.com/${encodeURIComponent(graphApiVersion)}/` +
    `${encodeURIComponent(phoneNumberId)}/messages`;

  let metaResponse: Response;
  try {
    metaResponse = await fetch(endpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(
        buildAuthenticationTemplatePayload(
          phone,
          otp,
          templateName,
          templateLanguage,
        ),
      ),
      signal: AbortSignal.timeout(3_500),
    });
  } catch (error) {
    console.error("Meta WhatsApp request failed before receiving a response", {
      phone: maskPhone(phone),
    });
    return authError(502, "WhatsApp delivery is temporarily unavailable");
  }

  let responseBody: MetaResponse = {};
  try {
    responseBody = (await metaResponse.json()) as MetaResponse;
  } catch (error) {
    // A non-JSON provider response is handled through the HTTP status below.
  }

  if (!metaResponse.ok || !responseBody.messages?.[0]?.id) {
    console.error("Meta rejected a WhatsApp OTP request", {
      phone: maskPhone(phone),
      status: metaResponse.status,
      code: responseBody.error?.code,
      subcode: responseBody.error?.error_subcode,
      traceId: responseBody.error?.fbtrace_id,
    });
    return authError(502, "WhatsApp delivery was rejected");
  }

  console.info("Meta accepted a WhatsApp OTP request", {
    phone: maskPhone(phone),
    messageId: responseBody.messages[0].id,
  });

  return new Response(null, { status: 200 });
});
