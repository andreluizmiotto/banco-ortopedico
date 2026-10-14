"use server";

import type { ContactActionState } from "../../lib/auth/action-types";
import { createCommunityContactLink } from "../../lib/contacts/server";

function formText(formData: FormData, key: string): string | null {
  const value = formData.get(key);
  return typeof value === "string" ? value : null;
}

export async function startCommunityContactAction(
  _previousState: ContactActionState,
  formData: FormData,
): Promise<ContactActionState> {
  const bankName = formText(formData, "bankName")?.trim();
  const equipmentTypeCode = formText(formData, "equipmentTypeCode")?.trim();

  if (
    !bankName ||
    !equipmentTypeCode ||
    !/^[A-Za-z0-9_-]+$/.test(equipmentTypeCode)
  ) {
    return {
      kind: "error",
      message: "Não foi possível iniciar a conversa. Tente novamente.",
    };
  }

  return createCommunityContactLink(bankName, equipmentTypeCode);
}
