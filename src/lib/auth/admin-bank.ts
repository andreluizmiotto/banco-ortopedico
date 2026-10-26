import "server-only";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "../supabase/server";

export type ServerSupabaseClient = Awaited<
  ReturnType<typeof createSupabaseServerClient>
>;

export type AdminBankContext = {
  entityId: string;
};

export type AdminBankAccess =
  | { kind: "unauthenticated" }
  | { kind: "forbidden" }
  | { kind: "unavailable" }
  | {
      kind: "authorized";
      entityId: string;
      client: ServerSupabaseClient;
    };

export async function resolveAdminBankAccess(
  client?: ServerSupabaseClient,
): Promise<AdminBankAccess> {
  try {
    const supabase = client ?? (await createSupabaseServerClient());
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError) return { kind: "unavailable" };
    if (!user) return { kind: "unauthenticated" };

    const { data: entityId, error: roleError } = await supabase.rpc(
      "current_admin_bank_entity_id",
    );

    if (roleError) return { kind: "unavailable" };
    if (typeof entityId !== "string") return { kind: "forbidden" };

    return { kind: "authorized", entityId, client: supabase };
  } catch {
    return { kind: "unavailable" };
  }
}

export async function getAdminBankContext(
  client?: ServerSupabaseClient,
): Promise<AdminBankContext | null> {
  const access = await resolveAdminBankAccess(client);
  return access.kind === "authorized" ? { entityId: access.entityId } : null;
}

export async function requireAdminBankContext(): Promise<AdminBankContext> {
  const context = await getAdminBankContext();

  if (!context) redirect("/admin/entrar");

  return context;
}
