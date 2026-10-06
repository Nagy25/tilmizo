import {
  authenticateUser,
  corsHeaders,
  errorResponse,
  jsonResponse,
  readJson,
  removeStoredObject,
  rpcData,
} from "../_shared/resource_edge.ts";
import { cleanUuid, safeErrorReason } from "../_shared/resource_validation.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return errorResponse("method_not_allowed", 405);
  }

  try {
    const { admin, user } = await authenticateUser(request);
    const body = await readJson(request);
    const resourceId = cleanUuid(body.resource_id, "resource_id");

    const prepared = await admin.rpc("prepare_resource_deletion", {
      p_teacher_id: user.id,
      p_resource_id: resourceId,
    });
    const result = rpcData(prepared.data, prepared.error) as {
      deleted: boolean;
      job_id?: string | null;
      storage_path?: string | null;
    };

    if (!result.job_id || !result.storage_path) {
      return jsonResponse({ deleted: true, cleanup_pending: false });
    }

    try {
      await removeStoredObject(admin, result.storage_path);
      const completed = await admin.rpc("complete_resource_deletion", {
        p_job_id: result.job_id,
      });
      if (completed.error) throw new Error(completed.error.message);
      return jsonResponse({ deleted: true, cleanup_pending: false });
    } catch (error) {
      await admin.rpc("record_resource_cleanup_failure", {
        p_kind: "deletion",
        p_id: result.job_id,
        p_error: safeErrorReason(error),
      });
      return jsonResponse({ deleted: true, cleanup_pending: true }, 202);
    }
  } catch (error) {
    const status = safeErrorReason(error).includes("token") ||
        safeErrorReason(error).includes("authentication")
      ? 401
      : 422;
    return errorResponse(error, status);
  }
});
