import { requireAdminBankContext } from "../../../lib/auth/admin-bank";

export const instant = false;

export default async function AdminContactsDestination() {
  await requireAdminBankContext();

  // FR-017/AC-007 owns the screen; this task only establishes its protected route.
  return null;
}
