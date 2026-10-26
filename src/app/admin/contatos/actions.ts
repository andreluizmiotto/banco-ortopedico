"use server";

import { changeAdminContactSituation } from "../../../lib/contacts/admin-server";
import type { AdminContactChangeState } from "../../../lib/contacts/admin-types";

function formText(formData: FormData, key: string): string | null {
  const value = formData.get(key);
  return typeof value === "string" ? value : null;
}

export async function setAdminContactSituationAction(
  formData: FormData,
): Promise<AdminContactChangeState> {
  const codigo = formText(formData, "codigo");
  const situation = formText(formData, "situacao");

  if (!codigo || !situation) return { kind: "forbidden" };

  return changeAdminContactSituation(codigo, situation);
}
