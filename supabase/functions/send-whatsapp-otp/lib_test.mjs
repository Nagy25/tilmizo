import assert from "node:assert/strict";
import test from "node:test";

import {
  buildAuthenticationTemplatePayload,
  maskPhone,
  parseAllowedRecipients,
  validateOtpRequest,
} from "./lib.ts";

test("accepts an allowlisted Egyptian mobile and six-digit OTP", () => {
  const result = validateOtpRequest(
    { user: { phone: "+201012345678" }, sms: { otp: "123456" } },
    new Set(["+201012345678"]),
  );
  assert.deepEqual(result, { phone: "+201012345678", otp: "123456" });
});

test("rejects malformed, non-Egyptian, and unapproved requests", () => {
  const allowed = new Set(["+201012345678"]);
  assert.throws(
    () => validateOtpRequest(
      { user: { phone: "+12025550123" }, sms: { otp: "123456" } },
      allowed,
    ),
    /invalid_egyptian_mobile/,
  );
  assert.throws(
    () => validateOtpRequest(
      { user: { phone: "+201012345678" }, sms: { otp: "12345" } },
      allowed,
    ),
    /invalid_otp/,
  );
  assert.throws(
    () => validateOtpRequest(
      { user: { phone: "+201112345678" }, sms: { otp: "123456" } },
      allowed,
    ),
    /recipient_not_allowed/,
  );
});

test("normalizes recipients, masks logs, and builds the Meta template payload", () => {
  assert.deepEqual(
    [...parseAllowedRecipients(" +201012345678, +201112345678 ")],
    ["+201012345678", "+201112345678"],
  );
  assert.equal(maskPhone("+201012345678"), "+201******78");

  const payload = buildAuthenticationTemplatePayload(
    "+201012345678",
    "123456",
    "telmizo_login_code",
    "ar",
  );
  assert.equal(payload.to, "201012345678");
  assert.equal(payload.type, "template");
  assert.deepEqual(payload.template.components[0].parameters[0], {
    type: "text",
    text: "123456",
  });
  assert.deepEqual(payload.template.components[1].parameters[0], {
    type: "text",
    text: "123456",
  });
});
