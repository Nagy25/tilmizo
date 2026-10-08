import { base64Url, equalSecret, fcmFailure } from "./lib.ts";

Deno.test("dispatch secret comparison", () => {
  if (!equalSecret("same", "same")) throw new Error("Matching secret rejected");
  if (equalSecret("same", "different")) {
    throw new Error("Wrong secret accepted");
  }
  if (equalSecret("", "secret")) throw new Error("Empty secret accepted");
});

Deno.test("base64url encodes without padding", () => {
  if (base64Url(new TextEncoder().encode("test")) !== "dGVzdA") {
    throw new Error("Incorrect base64url output");
  }
});

Deno.test("FCM errors classify retries and invalid tokens", () => {
  if (fcmFailure(429, null) !== "retry" || fcmFailure(503, null) !== "retry") {
    throw new Error("Transient error was not retried");
  }
  if (fcmFailure(404, { error: "UNREGISTERED" }) !== "invalid") {
    throw new Error("Unregistered token was not retired");
  }
  if (fcmFailure(400, { error: "INVALID_ARGUMENT" }) !== "failed") {
    throw new Error("Payload error should not retire token");
  }
});
