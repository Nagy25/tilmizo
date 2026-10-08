export function equalSecret(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let difference = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    difference |= (x[i] ?? 0) ^ (y[i] ?? 0);
  }
  return difference === 0;
}

export function base64Url(bytes: Uint8Array): string {
  let text = "";
  for (const byte of bytes) text += String.fromCharCode(byte);
  return btoa(text).replaceAll("+", "-").replaceAll("/", "_").replace(
    /=+$/,
    "",
  );
}

export function fcmFailure(
  status: number,
  payload: unknown,
): "retry" | "invalid" | "failed" {
  if (status === 429 || status >= 500) return "retry";
  const detail = JSON.stringify(payload);
  if (detail.includes("UNREGISTERED")) return "invalid";
  return "failed";
}
