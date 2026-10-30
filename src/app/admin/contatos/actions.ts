"use server";

import { changeAdminContactStatus } from "../../../lib/contacts/admin-server";
import type { AdminContactChangeState } from "../../../lib/contacts/admin-types";

function formText(formData: FormData, key: string): string | null {
  const value = formData.get(key);
  return typeof value === "string" ? value : null;
}

export async function setAdminContactStatusAction(
  formData: FormData,
): Promise<AdminContactChangeState> {
  const publicCode = formText(formData, "publicCode");
  const status = formText(formData, "status");

  if (!publicCode || !status) return { kind: "forbidden" };

  return changeAdminContactStatus(publicCode, status);
}
