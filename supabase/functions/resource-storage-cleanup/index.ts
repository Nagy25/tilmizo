import {
  createAdminClient,
  errorResponse,
  jsonResponse,
  removeStoredObject,
  requiredEnv,
  rpcData,
} from "../_shared/resource_edge.ts";
import { safeErrorReason } from "../_shared/resource_validation.ts";

type CleanupItem = {
  id: string;
  storage_path: string;
};

function secureEqual(left: string, right: string): boolean {
  const encoder = new TextEncoder();
  const leftBytes = encoder.encode(left);
  const rightBytes = encoder.encode(right);
  let difference = leftBytes.length ^ rightBytes.length;
  const length = Math.max(leftBytes.length, rightBytes.length);
  for (let index = 0; index < length; index++) {
    difference |= (leftBytes[index] ?? 0) ^ (rightBytes[index] ?? 0);
  }
  return difference === 0;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return errorResponse("method_not_allowed", 405);
  }

  const suppliedSecret = request.headers.get("x-cleanup-secret") ?? "";
  let expectedSecret: string;
  try {
    expectedSecret = requiredEnv("RESOURCE_CLEANUP_SECRET");
  } catch (error) {
    return errorResponse(error, 500);
  }
  if (!secureEqual(suppliedSecret, expectedSecret)) {
    return errorResponse("invalid_cleanup_secret", 401);
  }

  const admin = createAdminClient();
  try {
    const workResult = await admin.rpc("list_resource_cleanup_work", {
      p_limit: 100,
    });
    const work = rpcData(workResult.data, workResult.error) as {
      reservations: CleanupItem[];
      deletions: CleanupItem[];
    };

    let completed = 0;
    let failed = 0;
    const tasks = [
      ...work.reservations.map((item) => ({ kind: "reservation", item })),
      ...work.deletions.map((item) => ({ kind: "deletion", item })),
    ];

    for (let offset = 0; offset < tasks.length; offset += 10) {
      const batch = tasks.slice(offset, offset + 10);
      await Promise.all(batch.map(async ({ kind, item }) => {
        try {
          await removeStoredObject(admin, item.storage_path);
          const completion = kind === "reservation"
            ? await admin.rpc("complete_resource_reservation_cleanup", {
              p_reservation_id: item.id,
            })
            : await admin.rpc("complete_resource_deletion", {
              p_job_id: item.id,
            });
          if (completion.error) throw new Error(completion.error.message);
          completed += 1;
        } catch (error) {
          failed += 1;
          await admin.rpc("record_resource_cleanup_failure", {
            p_kind: kind,
            p_id: item.id,
            p_error: safeErrorReason(error),
          });
        }
      }));
    }

    return jsonResponse({ inspected: tasks.length, completed, failed });
  } catch (error) {
    return errorResponse(error, 500);
  }
});
