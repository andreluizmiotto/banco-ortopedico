export type CpfValidationState = {
  valid: boolean;
  message: string | null;
};

export type MessageState = {
  message: string | null;
};

export type AdminSignInState = {
  message: string | null;
};

export type SignupState = {
  kind: "idle" | "error" | "otp";
  message: string | null;
  acceptedVersion?: string;
};

export type FinishSignupState = {
  kind: "idle" | "error";
  message: string | null;
};

export type ContactMethod = "whatsapp" | "telephone" | "unavailable";

export type ContactMethodResult =
  | { kind: "ready"; method: ContactMethod }
  | { kind: "error" };

export type ContactActionState =
  | { kind: "idle" }
  | { kind: "error"; message: string }
  | { kind: "unavailable"; message: string }
  | { kind: "success"; href: string };
