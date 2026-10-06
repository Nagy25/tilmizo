import { createClient } from "npm:@supabase/supabase-js@2.117.2";

import { safeErrorReason } from "./resource_validation.ts";

export const resourceBucket = "group-resources";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info, x-cleanup-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function jsonResponse(
  body: unknown,
  status = 200,
  extraHeaders: Record<string, string> = {},
): Response {
  return Response.json(body, {
    status,
    headers: { ...corsHeaders, ...extraHeaders },
  });
}

export function errorResponse(error: unknown, status = 400): Response {
  return jsonResponse({ error: safeErrorReason(error) }, status);
}

export function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`missing_environment:${name}`);
  return value;
}

export function createAdminClient() {
  return createClient(
    requiredEnv("SUPABASE_URL"),
    requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
}

export async function authenticateUser(request: Request) {
  const authorization = request.headers.get("Authorization")?.trim();
  if (!authorization?.toLowerCase().startsWith("bearer ")) {
    throw new Error("authentication_required");
  }

  const accessToken = authorization.slice(7).trim();
  if (!accessToken) throw new Error("authentication_required");

  const admin = createAdminClient();
  const { data, error } = await admin.auth.getUser(accessToken);
  if (error || !data.user) throw new Error("invalid_access_token");

  return { admin, user: data.user };
}

export async function readJson(
  request: Request,
): Promise<Record<string, unknown>> {
  const contentType = request.headers.get("content-type") ?? "";
  if (!contentType.toLowerCase().includes("application/json")) {
    throw new Error("json_body_required");
  }
  const value = await request.json();
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("invalid_json_body");
  }
  return value as Record<string, unknown>;
}

export function rpcData<T>(
  data: T | null,
  error: { message: string } | null,
): T {
  if (error) throw new Error(error.message);
  if (data === null || data === undefined) {
    throw new Error("empty_backend_response");
  }
  return data;
}

export async function removeStoredObject(
  admin: ReturnType<typeof createAdminClient>,
  storagePath: string,
): Promise<void> {
  const { error } = await admin.storage.from(resourceBucket).remove([
    storagePath,
  ]);
  if (error) throw new Error(error.message);
}

export async function readObjectPrefix(
  storagePath: string,
  maxBytes = 4096,
): Promise<Uint8Array> {
  const encodedPath = storagePath.split("/").map(encodeURIComponent).join("/");
  const response = await fetch(
    `${requiredEnv("SUPABASE_URL")}/storage/v1/object/authenticated/` +
      `${resourceBucket}/${encodedPath}`,
    {
      headers: {
        apikey: requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
        Authorization: `Bearer ${requiredEnv("SUPABASE_SERVICE_ROLE_KEY")}`,
        Range: `bytes=0-${maxBytes - 1}`,
      },
    },
  );

  if (!response.ok) {
    throw new Error(`object_prefix_unavailable:${response.status}`);
  }
  if (!response.body) throw new Error("object_prefix_unavailable");

  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let received = 0;
  while (received < maxBytes) {
    const { done, value } = await reader.read();
    if (done) break;
    const remaining = maxBytes - received;
    const chunk = value.length > remaining ? value.slice(0, remaining) : value;
    chunks.push(chunk);
    received += chunk.length;
    if (received >= maxBytes) {
      await reader.cancel();
      break;
    }
  }

  const result = new Uint8Array(received);
  let offset = 0;
  for (const chunk of chunks) {
    result.set(chunk, offset);
    offset += chunk.length;
  }
  return result;
}

export async function inspectStoredObject(
  admin: ReturnType<typeof createAdminClient>,
  storagePath: string,
) {
  const segments = storagePath.split("/");
  const fileName = segments.pop();
  if (!fileName) throw new Error("invalid_storage_path");
  const folder = segments.join("/");

  const { data, error } = await admin.storage.from(resourceBucket).list(
    folder,
    {
      search: fileName,
      limit: 100,
    },
  );
  if (error) throw new Error(error.message);
  const object = data.find((entry) =>
    entry.name === fileName && entry.id !== null
  );
  if (!object) throw new Error("uploaded_object_not_found");

  const metadata = (object.metadata ?? {}) as Record<string, unknown>;
  const size = Number(metadata.size);
  const mimeType = String(
    metadata.mimetype ?? metadata.contentType ?? metadata.content_type ?? "",
  );
  const prefix = await readObjectPrefix(storagePath);

  return { fileName, size, mimeType, prefix };
}
