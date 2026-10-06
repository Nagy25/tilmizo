import {
  authenticateUser,
  corsHeaders,
  errorResponse,
  inspectStoredObject,
  jsonResponse,
  readJson,
  removeStoredObject,
  resourceBucket,
  rpcData,
} from "../_shared/resource_edge.ts";
import {
  cleanOptionalString,
  cleanOptionalUuid,
  cleanPositiveInteger,
  cleanRequiredString,
  cleanUuid,
  isUploadedResourceType,
  safeErrorReason,
  validateStoredObject,
} from "../_shared/resource_validation.ts";

type Reservation = {
  id: string;
  resource_type: string;
  storage_path: string;
  status: string;
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return errorResponse("method_not_allowed", 405);
  }

  let admin;
  let teacherId: string;
  try {
    const authenticated = await authenticateUser(request);
    admin = authenticated.admin;
    teacherId = authenticated.user.id;
  } catch (error) {
    return errorResponse(error, 401);
  }

  let body: Record<string, unknown>;
  try {
    body = await readJson(request);
  } catch (error) {
    return errorResponse(error, 400);
  }

  const action = body.action;
  if (action === "reserve") {
    let reservationId: string | null = null;
    try {
      const resourceType = body.type;
      if (!isUploadedResourceType(resourceType)) {
        throw new Error("invalid_resource_type");
      }

      const { data, error } = await admin.rpc("reserve_resource_upload", {
        p_teacher_id: teacherId,
        p_group_id: cleanUuid(body.group_id, "group_id"),
        p_title: cleanRequiredString(body.title, "title", 200),
        p_resource_type: resourceType,
        p_file_name: cleanRequiredString(body.file_name, "file_name", 255),
        p_declared_size: cleanPositiveInteger(body.file_size, "file_size"),
        p_declared_mime_type: cleanRequiredString(
          body.mime_type,
          "mime_type",
          255,
        ).toLowerCase(),
        p_description: cleanOptionalString(
          body.description,
          "description",
          5000,
        ),
        p_session_id: cleanOptionalUuid(body.session_id, "session_id"),
      });
      const reservation = rpcData(data, error) as Record<string, unknown>;
      reservationId = String(reservation.reservation_id);
      const storagePath = String(reservation.storage_path);

      const signed = await admin.storage.from(resourceBucket)
        .createSignedUploadUrl(storagePath, { upsert: false });
      if (signed.error || !signed.data?.token) {
        throw new Error(
          signed.error?.message ?? "signed_upload_creation_failed",
        );
      }

      return jsonResponse({
        ...reservation,
        signed_upload_token: signed.data.token,
        signed_upload_url: signed.data.signedUrl,
        use_resumable_upload:
          Number(reservation.declared_size) > 6 * 1024 * 1024,
      }, 201);
    } catch (error) {
      if (reservationId) {
        await admin.rpc("cancel_resource_upload", {
          p_teacher_id: teacherId,
          p_reservation_id: reservationId,
          p_reason: safeErrorReason(error),
          p_release_immediately: true,
        });
      }
      return errorResponse(error, 422);
    }
  }

  if (action === "finalize") {
    let reservationId: string;
    try {
      reservationId = cleanUuid(body.reservation_id, "reservation_id");
    } catch (error) {
      return errorResponse(error, 400);
    }

    try {
      const lookup = await admin.rpc("get_resource_upload_reservation", {
        p_teacher_id: teacherId,
        p_reservation_id: reservationId,
      });
      const reservation = rpcData(lookup.data, lookup.error) as Reservation;
      if (!isUploadedResourceType(reservation.resource_type)) {
        throw new Error("invalid_reserved_resource_type");
      }

      const object = await inspectStoredObject(admin, reservation.storage_path);
      validateStoredObject(reservation.resource_type, object);

      const finalized = await admin.rpc("finalize_resource_upload", {
        p_teacher_id: teacherId,
        p_reservation_id: reservationId,
        p_actual_size: object.size,
        p_actual_mime_type: object.mimeType.toLowerCase(),
      });
      return jsonResponse({
        resource: rpcData(finalized.data, finalized.error),
      });
    } catch (error) {
      const lookup = await admin.rpc("get_resource_upload_reservation", {
        p_teacher_id: teacherId,
        p_reservation_id: reservationId,
      });
      const reservation = lookup.data as Reservation | null;
      if (reservation?.storage_path && reservation.status !== "finalized") {
        try {
          await removeStoredObject(admin, reservation.storage_path);
        } catch (_) {
          // The scheduled cleanup worker will retry after the token expires.
        }
        await admin.rpc("cancel_resource_upload", {
          p_teacher_id: teacherId,
          p_reservation_id: reservationId,
          p_reason: safeErrorReason(error),
          p_release_immediately: false,
        });
      }
      return errorResponse(error, 422);
    }
  }

  if (action === "cancel") {
    try {
      const reservationId = cleanUuid(body.reservation_id, "reservation_id");
      const lookup = await admin.rpc("get_resource_upload_reservation", {
        p_teacher_id: teacherId,
        p_reservation_id: reservationId,
      });
      const reservation = rpcData(lookup.data, lookup.error) as Reservation;
      if (reservation.status === "finalized") {
        throw new Error("finalized_upload_cannot_be_cancelled");
      }

      try {
        await removeStoredObject(admin, reservation.storage_path);
      } catch (_) {
        // Final cleanup is deliberately deferred until the upload token expires.
      }
      const cancelled = await admin.rpc("cancel_resource_upload", {
        p_teacher_id: teacherId,
        p_reservation_id: reservationId,
        p_reason: "cancelled_by_teacher",
        p_release_immediately: false,
      });
      return jsonResponse(rpcData(cancelled.data, cancelled.error));
    } catch (error) {
      return errorResponse(error, 422);
    }
  }

  return errorResponse("invalid_action", 400);
});
