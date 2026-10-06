export type UploadedResourceType =
  | "pdf"
  | "image"
  | "file"
  | "uploaded_video";

export type StoredObjectInfo = {
  fileName: string;
  size: number;
  mimeType: string;
  prefix: Uint8Array;
};

const uploadedTypes = new Set<UploadedResourceType>([
  "pdf",
  "image",
  "file",
  "uploaded_video",
]);

export function isUploadedResourceType(
  value: unknown,
): value is UploadedResourceType {
  return typeof value === "string" &&
    uploadedTypes.has(value as UploadedResourceType);
}

export function cleanRequiredString(
  value: unknown,
  field: string,
  maxLength: number,
): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error(`invalid_${field}`);
  }
  const cleaned = value.trim();
  if (cleaned.length > maxLength) {
    throw new Error(`${field}_too_long`);
  }
  return cleaned;
}

export function cleanOptionalString(
  value: unknown,
  field: string,
  maxLength: number,
): string | null {
  if (value === null || value === undefined) return null;
  if (typeof value !== "string") throw new Error(`invalid_${field}`);
  const cleaned = value.trim();
  if (cleaned.length === 0) return null;
  if (cleaned.length > maxLength) throw new Error(`${field}_too_long`);
  return cleaned;
}

export function cleanUuid(value: unknown, field: string): string {
  if (
    typeof value !== "string" ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      .test(value)
  ) {
    throw new Error(`invalid_${field}`);
  }
  return value.toLowerCase();
}

export function cleanOptionalUuid(
  value: unknown,
  field: string,
): string | null {
  if (value === null || value === undefined || value === "") return null;
  return cleanUuid(value, field);
}

export function cleanPositiveInteger(value: unknown, field: string): number {
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value <= 0) {
    throw new Error(`invalid_${field}`);
  }
  return value;
}

function startsWith(bytes: Uint8Array, expected: number[]): boolean {
  return expected.every((value, index) => bytes[index] === value);
}

function ascii(bytes: Uint8Array, start: number, length: number): string {
  return String.fromCharCode(...bytes.slice(start, start + length));
}

export function detectContentType(prefix: Uint8Array): string | null {
  if (ascii(prefix, 0, 5) === "%PDF-") return "application/pdf";
  if (startsWith(prefix, [0xff, 0xd8, 0xff])) return "image/jpeg";
  if (startsWith(prefix, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
    return "image/png";
  }
  if (ascii(prefix, 0, 6) === "GIF87a" || ascii(prefix, 0, 6) === "GIF89a") {
    return "image/gif";
  }
  if (ascii(prefix, 0, 4) === "RIFF" && ascii(prefix, 8, 4) === "WEBP") {
    return "image/webp";
  }

  if (ascii(prefix, 4, 4) === "ftyp") {
    const brand = ascii(prefix, 8, 4).toLowerCase();
    if (["avif", "avis"].includes(brand)) return "image/avif";
    if (["heic", "heix", "hevc", "hevx", "mif1", "msf1"].includes(brand)) {
      return "image/heic";
    }
    return "video/mp4";
  }

  return null;
}

export function validateStoredObject(
  resourceType: UploadedResourceType,
  object: StoredObjectInfo,
): void {
  if (!Number.isSafeInteger(object.size) || object.size <= 0) {
    throw new Error("invalid_stored_size");
  }

  const mimeType = object.mimeType.trim().toLowerCase();
  if (mimeType.length === 0) throw new Error("invalid_stored_mime_type");
  if (resourceType === "file") return;

  const detected = detectContentType(object.prefix);
  if (resourceType === "pdf") {
    if (
      !object.fileName.toLowerCase().endsWith(".pdf") ||
      mimeType !== "application/pdf" ||
      detected !== "application/pdf"
    ) {
      throw new Error("invalid_pdf_content");
    }
    return;
  }

  if (resourceType === "uploaded_video") {
    if (
      !object.fileName.toLowerCase().endsWith(".mp4") ||
      mimeType !== "video/mp4" ||
      detected !== "video/mp4"
    ) {
      throw new Error("invalid_mp4_content");
    }
    return;
  }

  if (!mimeType.startsWith("image/") || !detected?.startsWith("image/")) {
    throw new Error("invalid_image_content");
  }
}

export function safeErrorReason(error: unknown): string {
  if (error instanceof Error) return error.message.slice(0, 1000);
  if (typeof error === "string") return error.slice(0, 1000);
  return "unexpected_error";
}
