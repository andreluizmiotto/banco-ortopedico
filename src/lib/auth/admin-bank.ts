import "server-only";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "../supabase/server";

type ServerSupabaseClient = Awaited<ReturnType<typeof createSupabaseServerClient>>;

export type AdminBankContext = {
  entityId: string;
};

export async function getAdminBankContext(
  client?: ServerSupabaseClient,
): Promise<AdminBankContext | null> {
  try {
    const supabase = client ?? (await createSupabaseServerClient());
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) return null;

    const { data: entityId, error: roleError } = await supabase.rpc(
      "current_admin_bank_entity_id",
    );

    if (roleError || typeof entityId !== "string") return null;

    return { entityId };
  } catch {
    // Fail closed without exposing raw Auth or database errors to the caller.
    return null;
  }
}

export async function requireAdminBankContext(): Promise<AdminBankContext> {
  const context = await getAdminBankContext();

  if (!context) redirect("/admin/entrar");

  return context;
}
