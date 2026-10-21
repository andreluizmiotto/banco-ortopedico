"use server";

import { redirect } from "next/navigation";
import type { AdminSignInState } from "../../../lib/auth/action-types";
import { getAdminBankContext } from "../../../lib/auth/admin-bank";
import { createSupabaseServerClient } from "../../../lib/supabase/server";

const signInErrorMessage =
  "Não foi possível entrar. Confira os dados e tente novamente.";

function formText(formData: FormData, key: string): string | null {
  const value = formData.get(key);
  return typeof value === "string" ? value : null;
}

export async function signInAdminAction(
  _previousState: AdminSignInState,
  formData: FormData,
): Promise<AdminSignInState> {
  const email = formText(formData, "email")?.trim();
  const password = formText(formData, "password");

  if (!email || email.length > 320 || !password) {
    return { message: signInErrorMessage };
  }

  try {
    const supabase = await createSupabaseServerClient();
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error || !data.user) return { message: signInErrorMessage };

    const context = await getAdminBankContext(supabase);
    if (!context) return { message: signInErrorMessage };
  } catch {
    // Keep credential, Auth, and network details out of the response and logs.
    return { message: signInErrorMessage };
  }

  redirect("/admin/contatos");
}
