export const egyptianMobilePattern = /^\+201[0125][0-9]{8}$/;
export const otpPattern = /^[0-9]{6}$/;

export type SendSmsHookPayload = {
  user?: {
    phone?: unknown;
  };
  sms?: {
    otp?: unknown;
  };
};

export type ValidatedOtpRequest = {
  phone: string;
  otp: string;
};

export function parseAllowedRecipients(value: string): Set<string> {
  return new Set(
    value
      .split(",")
      .map((phone) => phone.trim())
      .filter((phone) => phone.length > 0),
  );
}

export function validateOtpRequest(
  payload: SendSmsHookPayload,
  allowedRecipients: Set<string>,
): ValidatedOtpRequest {
  const phone = payload.user?.phone;
  const otp = payload.sms?.otp;

  if (typeof phone !== "string" || !egyptianMobilePattern.test(phone)) {
    throw new Error("invalid_egyptian_mobile");
  }

  if (typeof otp !== "string" || !otpPattern.test(otp)) {
    throw new Error("invalid_otp");
  }

  if (!allowedRecipients.has(phone)) {
    throw new Error("recipient_not_allowed");
  }

  return { phone, otp };
}

export function maskPhone(phone: string): string {
  return `${phone.slice(0, 4)}******${phone.slice(-2)}`;
}

export function buildAuthenticationTemplatePayload(
  phone: string,
  otp: string,
  templateName: string,
  templateLanguage: string,
): Record<string, unknown> {
  return {
    messaging_product: "whatsapp",
    recipient_type: "individual",
    to: phone.slice(1),
    type: "template",
    template: {
      name: templateName,
      language: { code: templateLanguage },
      components: [
        {
          type: "body",
          parameters: [{ type: "text", text: otp }],
        },
        {
          type: "button",
          sub_type: "url",
          index: "0",
          parameters: [{ type: "text", text: otp }],
        },
      ],
    },
  };
}
