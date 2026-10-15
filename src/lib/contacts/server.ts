import "server-only";
import type {
  ContactActionState,
  ContactMethod,
  ContactMethodResult,
} from "../auth/action-types";
import { createSupabaseServerClient } from "../supabase/server";

export type CommunityContactMethods =
  | { kind: "visitor" }
  | { kind: "error" }
  | { kind: "community"; methods: Record<string, ContactMethodResult> };

const whatsappLinkPattern =
  /^https:\/\/wa\.me\/[1-9][0-9]{7,14}\?text=Ola\.%20Quero%20conversar%20sobre%20um%20emprestimo%20de%20equipamento\.%20Codigo%20do%20contato:%20[A-F0-9]{12}\.$/;
const telephoneLinkPattern = /^tel:\+[1-9][0-9]{7,14}$/;

function isContactMethod(value: unknown): value is ContactMethod {
  return (
    value === "whatsapp" ||
    value === "telephone" ||
    value === "unavailable"
  );
}

export async function readCommunityContactMethods(
  equipmentTypeCode: string,
  bankNames: string[],
): Promise<CommunityContactMethods> {
  try {
    const supabase = await createSupabaseServerClient();
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) return { kind: "visitor" };

    const { data: hasCommunityRole, error: roleError } = await supabase.rpc(
      "has_community_role",
    );

    if (roleError) return { kind: "error" };
    if (hasCommunityRole !== true) return { kind: "visitor" };

    const entries = await Promise.all(
      bankNames.map(async (bankName) => {
        const { data, error } = await supabase.rpc("community_contact_method", {
          p_public_bank_name: bankName,
          p_equipment_type_code: equipmentTypeCode,
        });

        if (error || !isContactMethod(data)) {
          return [bankName, { kind: "error" } satisfies ContactMethodResult] as const;
        }

        return [bankName, { kind: "ready", method: data } satisfies ContactMethodResult] as const;
      }),
    );

    return { kind: "community", methods: Object.fromEntries(entries) };
  } catch {
    return { kind: "error" };
  }
}

function isSafeContactLink(method: ContactMethod, href: unknown): href is string {
  if (typeof href !== "string") return false;

  return method === "whatsapp"
    ? whatsappLinkPattern.test(href)
    : method === "telephone"
      ? telephoneLinkPattern.test(href)
      : false;
}

export async function createCommunityContactLink(
  bankName: string,
  equipmentTypeCode: string,
): Promise<ContactActionState> {
  try {
    const supabase = await createSupabaseServerClient();
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return {
        kind: "error",
        message: "Não foi possível iniciar a conversa. Tente novamente.",
      };
    }

    const { data: hasCommunityRole, error: roleError } = await supabase.rpc(
      "has_community_role",
    );

    if (roleError || hasCommunityRole !== true) {
      return {
        kind: "error",
        message: "A conversa não está disponível para este perfil.",
      };
    }

    const { data, error } = await supabase.rpc("start_community_contact", {
      p_public_bank_name: bankName,
      p_equipment_type_code: equipmentTypeCode,
    });

    if (error || !Array.isArray(data) || data.length !== 1) {
      return {
        kind: "error",
        message: "Não foi possível iniciar a conversa. Tente novamente.",
      };
    }

    const result = data[0] as {
      method?: unknown;
      href?: unknown;
    };

    if (result.method === "unavailable") {
      return {
        kind: "unavailable",
        message: "O contato não está disponível neste momento.",
      };
    }

    if (
      !isContactMethod(result.method) ||
      !isSafeContactLink(result.method, result.href)
    ) {
      return {
        kind: "error",
        message: "Não foi possível iniciar a conversa. Tente novamente.",
      };
    }

    return { kind: "success", href: result.href };
  } catch {
    return {
      kind: "error",
      message: "Não foi possível iniciar a conversa. Tente novamente.",
    };
  }
}
