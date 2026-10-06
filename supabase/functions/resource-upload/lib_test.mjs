import assert from "node:assert/strict";
import test from "node:test";

import {
  cleanOptionalString,
  cleanPositiveInteger,
  cleanRequiredString,
  detectContentType,
  validateStoredObject,
} from "../_shared/resource_validation.ts";

function bytes(...values) {
  return new Uint8Array(values);
}

function textBytes(value) {
  return new TextEncoder().encode(value);
}

test("normalizes resource request fields", () => {
  assert.equal(
    cleanRequiredString("  Lesson notes  ", "title", 200),
    "Lesson notes",
  );
  assert.equal(cleanOptionalString("   ", "description", 5000), null);
  assert.equal(cleanPositiveInteger(1024, "file_size"), 1024);
  assert.throws(
    () => cleanPositiveInteger(1.5, "file_size"),
    /invalid_file_size/,
  );
});

test("detects PDF and common image signatures", () => {
  assert.equal(detectContentType(textBytes("%PDF-1.7")), "application/pdf");
  assert.equal(detectContentType(bytes(0xff, 0xd8, 0xff, 0xe0)), "image/jpeg");
  assert.equal(
    detectContentType(bytes(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)),
    "image/png",
  );
});

test("requires matching PDF content, extension, and MIME", () => {
  const valid = {
    fileName: "lesson.pdf",
    size: 200,
    mimeType: "application/pdf",
    prefix: textBytes("%PDF-1.7"),
  };
  assert.doesNotThrow(() => validateStoredObject("pdf", valid));
  assert.throws(
    () =>
      validateStoredObject("pdf", { ...valid, prefix: textBytes("not pdf") }),
    /invalid_pdf_content/,
  );
});

test("accepts an MP4 ftyp box and rejects a renamed payload", () => {
  const mp4Prefix = bytes(
    0,
    0,
    0,
    24,
    0x66,
    0x74,
    0x79,
    0x70,
    0x69,
    0x73,
    0x6f,
    0x6d,
  );
  const valid = {
    fileName: "class.mp4",
    size: 4096,
    mimeType: "video/mp4",
    prefix: mp4Prefix,
  };
  assert.doesNotThrow(() => validateStoredObject("uploaded_video", valid));
  assert.throws(
    () =>
      validateStoredObject("uploaded_video", {
        ...valid,
        fileName: "class.bin",
      }),
    /invalid_mp4_content/,
  );
});

test("generic files require metadata but do not require a known signature", () => {
  assert.doesNotThrow(() =>
    validateStoredObject("file", {
      fileName: "archive.bin",
      size: 20,
      mimeType: "application/octet-stream",
      prefix: textBytes("anything"),
    })
  );
});
