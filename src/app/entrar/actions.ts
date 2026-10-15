"use server";

import { createHmac } from "node:crypto";
import { isIP } from "node:net";
import { headers } from "next/headers";
import { redirect } from "next/navigation";
import {
  isValidNewPassword,
  normalizeAuthPhone,
  normalizeCpf,
  normalizePersonName,
} from "../../lib/auth/identity";
import type {
  CpfValidationState,
  FinishSignupState,
  MessageState,
  SignupState,
} from "../../lib/auth/action-types";
import { getCommunityPrivacyNotice } from "../../lib/auth/privacy-notice";
import { sanitizeReturnTo } from "../../lib/auth/return-to";
import { createSupabaseServerClient } from "../../lib/supabase/server";
import { createSupabaseServiceClient } from "../../lib/supabase/service";

const invalidCpfMessage = "Confira o CPF digitado e tente novamente.";
const signInErrorMessage = "Não foi possível entrar. Confira os dados e tente novamente.";
const signupErrorMessage =
  "Não foi possível criar o cadastro agora. Confira os dados e tente novamente.";
const confirmPhoneErrorMessage =
  "Não foi possível confirmar o telefone. Confira o código e tente novamente.";

function formText(formData: FormData, key: string): string | null {
  const value = formData.get(key);
  return typeof value === "string" ? value : null;
}

function hasErrorCode(error: unknown, code: string): boolean {
  return (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    error.code === code
  );
}

function clientOriginHash(requestHeaders: Headers): string {
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceRoleKey) {
    throw new Error("Configuracao privada do Supabase indisponivel.");
  }

  const forwardedIp = requestHeaders
    .get("x-forwarded-for")
    ?.split(",", 1)[0]
    ?.trim();
  const realIp = requestHeaders.get("x-real-ip")?.trim();
  const origin = [forwardedIp, realIp].find(
    (candidate): candidate is string =>
      Boolean(candidate) && isIP(candidate as string) !== 0,
  );

  return createHmac("sha256", serviceRoleKey)
    .update(origin ?? "unknown")
    .digest("hex");
}

async function recordFailedSignIn(
  serviceClient: ReturnType<typeof createSupabaseServiceClient>,
  originHash: string,
) {
  await serviceClient.rpc("record_community_login_failure", {
    p_origin_hash: originHash,
  });
}

export async function validateCpfAction(
  formData: FormData,
): Promise<CpfValidationState> {
  const cpf = normalizeCpf(formText(formData, "cpf"));

  return cpf
    ? { valid: true, message: null }
    : { valid: false, message: invalidCpfMessage };
}

export async function signInCommunityAction(
  _previousState: MessageState,
  formData: FormData,
): Promise<MessageState> {
  const cpf = normalizeCpf(formText(formData, "cpf"));
  const password = formText(formData, "password");

  if (!cpf) return { message: invalidCpfMessage };
  if (!password) return { message: signInErrorMessage };

  const destination = sanitizeReturnTo(formText(formData, "returnTo"));

  try {
    const requestHeaders = await headers();
    const originHash = clientOriginHash(requestHeaders);
    const serviceClient = createSupabaseServiceClient();
    const { data: isLocked, error: lockError } = await serviceClient.rpc(
      "is_community_login_locked",
      { p_origin_hash: originHash },
    );

    if (lockError || isLocked !== false) {
      return { message: signInErrorMessage };
    }

    const { data: phone, error: lookupError } = await serviceClient.rpc(
      "community_phone_for_cpf",
      { p_cpf: cpf },
    );

    if (lookupError) return { message: signInErrorMessage };

    if (typeof phone !== "string") {
      await recordFailedSignIn(serviceClient, originHash);
      return { message: signInErrorMessage };
    }

    const supabase = await createSupabaseServerClient();
    const { data, error } = await supabase.auth.signInWithPassword({
      phone,
      password,
    });

    if (error || !data.user) {
      if (hasErrorCode(error, "invalid_credentials")) {
        await recordFailedSignIn(serviceClient, originHash);
      }
      return { message: signInErrorMessage };
    }

    const { data: hasCommunityRole, error: roleError } = await supabase.rpc(
      "has_community_role",
    );

    if (roleError || hasCommunityRole !== true) {
      await supabase.auth.signOut();
      return { message: signInErrorMessage };
    }

    const { error: clearError } = await serviceClient.rpc(
      "clear_community_login_failures",
      { p_origin_hash: originHash },
    );

    if (clearError) {
      await supabase.auth.signOut();
      return { message: signInErrorMessage };
    }
  } catch {
    return { message: signInErrorMessage };
  }

  redirect(destination);
}

export async function startCommunitySignupAction(
  _previousState: SignupState,
  formData: FormData,
): Promise<SignupState> {
  const notice = getCommunityPrivacyNotice();
  if (!notice) {
    return {
      kind: "error",
      message: "O cadastro ainda não está disponível. Tente novamente mais tarde.",
    };
  }

  const name = normalizePersonName(formText(formData, "name"));
  const cpf = normalizeCpf(formText(formData, "cpf"));
  const phone = normalizeAuthPhone(formText(formData, "phone"));
  const password = formText(formData, "password");
  const privacyAccepted = formText(formData, "privacyAccepted") === "true";

  if (!name) return { kind: "error", message: "Informe seu nome completo." };
  if (!cpf) return { kind: "error", message: invalidCpfMessage };
  if (!phone) {
    return {
      kind: "error",
      message: "Informe um telefone válido com código do país.",
    };
  }
  if (!isValidNewPassword(password)) {
    return {
      kind: "error",
      message: "A senha precisa ter pelo menos oito caracteres.",
    };
  }
  if (!privacyAccepted) {
    return {
      kind: "error",
      message: "Leia e aceite o aviso de privacidade para continuar.",
    };
  }

  try {
    const supabase = await createSupabaseServerClient();
    const { data, error } = await supabase.auth.signUp({
      phone,
      password,
      options: { channel: "sms" },
    });

    if (error || !data.user?.id || data.session) {
      if (data.session) await supabase.auth.signOut();
      return { kind: "error", message: signupErrorMessage };
    }

    return {
      kind: "otp",
      acceptedVersion: notice.version,
      message: "Se o telefone puder receber o código, ele foi enviado.",
    };
  } catch {
    return { kind: "error", message: signupErrorMessage };
  }
}

export async function finishCommunitySignupAction(
  _previousState: FinishSignupState,
  formData: FormData,
): Promise<FinishSignupState> {
  const notice = getCommunityPrivacyNotice();
  if (!notice) {
    return {
      kind: "error",
      message: "O cadastro ainda não está disponível. Tente novamente mais tarde.",
    };
  }

  const name = normalizePersonName(formText(formData, "name"));
  const cpf = normalizeCpf(formText(formData, "cpf"));
  const phone = normalizeAuthPhone(formText(formData, "phone"));
  const token = formText(formData, "token")?.trim();
  const acceptedVersion = formText(formData, "acceptedVersion");
  const privacyAccepted = formText(formData, "privacyAccepted") === "true";

  if (!name || !cpf || !phone) {
    return { kind: "error", message: confirmPhoneErrorMessage };
  }
  if (!privacyAccepted || acceptedVersion !== notice.version) {
    return {
      kind: "error",
      message: "O aviso mudou. Volte, leia a versão atual e aceite para continuar.",
    };
  }
  if (!token || !/^\d{1,32}$/.test(token)) {
    return { kind: "error", message: confirmPhoneErrorMessage };
  }

  const destination = sanitizeReturnTo(formText(formData, "returnTo"));

  try {
    const supabase = await createSupabaseServerClient();
    const { data: currentUserData } = await supabase.auth.getUser();
    let user = currentUserData.user;

    if (!user || user.phone !== phone || !user.phone_confirmed_at) {
      const { data, error } = await supabase.auth.verifyOtp({
        phone,
        token,
        type: "sms",
      });

      if (error || !data.user || data.user.phone !== phone) {
        return { kind: "error", message: confirmPhoneErrorMessage };
      }

      user = data.user;
    }

    if (!user.phone_confirmed_at) {
      return { kind: "error", message: confirmPhoneErrorMessage };
    }

    const serviceClient = createSupabaseServiceClient();
    const { error: provisionError } = await serviceClient.rpc(
      "complete_community_signup",
      {
        p_auth_user_id: user.id,
        p_cpf: cpf,
        p_name: name,
        p_phone: user.phone,
        p_privacy_notice_version: notice.version,
        p_privacy_accepted: true,
      },
    );

    if (provisionError) {
      return { kind: "error", message: confirmPhoneErrorMessage };
    }

    const { data: hasCommunityRole, error: roleError } = await supabase.rpc(
      "has_community_role",
    );

    if (roleError || hasCommunityRole !== true) {
      return { kind: "error", message: confirmPhoneErrorMessage };
    }
  } catch {
    return { kind: "error", message: confirmPhoneErrorMessage };
  }

  redirect(destination);
}
