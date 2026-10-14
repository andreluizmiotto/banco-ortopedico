import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { BankAvailability, EquipmentType } from "./availability";

let publicClient: SupabaseClient | undefined;

function getPublicClient() {
  if (publicClient) return publicClient;

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!url || !anonKey) {
    throw new Error("Configuracao publica do acervo indisponivel.");
  }

  publicClient = createClient(url, anonKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  });

  return publicClient;
}

function isEquipmentType(value: unknown): value is EquipmentType {
  if (!value || typeof value !== "object") return false;

  const row = value as Record<string, unknown>;
  return (
    typeof row.code === "string" &&
    typeof row.name === "string" &&
    Number.isInteger(row.display_order)
  );
}

function isBankAvailability(value: unknown): value is BankAvailability {
  if (!value || typeof value !== "object") return false;

  const row = value as Record<string, unknown>;
  return (
    typeof row.bank_name === "string" &&
    Number.isSafeInteger(row.available_quantity) &&
    Number(row.available_quantity) >= 0
  );
}

export async function readEquipmentTypes(): Promise<EquipmentType[]> {
  const { data, error } = await getPublicClient()
    .from("equipment_types")
    .select("code, name, display_order")
    .order("display_order", { ascending: true });

  if (error) throw error;
  if (!data || !data.every(isEquipmentType)) {
    throw new Error("Resposta publica de equipamentos invalida.");
  }

  return data.map(({ code, name, display_order }) => ({
    code,
    name,
    display_order,
  }));
}

export async function readEquipmentType(
  code: string,
): Promise<EquipmentType | null> {
  const { data, error } = await getPublicClient()
    .from("equipment_types")
    .select("code, name, display_order")
    .eq("code", code)
    .maybeSingle();

  if (error) throw error;
  if (data === null) return null;
  if (!isEquipmentType(data)) {
    throw new Error("Resposta publica de equipamentos invalida.");
  }

  return {
    code: data.code,
    name: data.name,
    display_order: data.display_order,
  };
}

export async function readEquipmentAvailability(
  code: string,
): Promise<BankAvailability[]> {
  const { data, error } = await getPublicClient().rpc(
    "equipment_availability",
    { p_equipment_type_code: code },
  );

  if (error) throw error;
  if (!Array.isArray(data) || !data.every(isBankAvailability)) {
    throw new Error("Resposta publica de disponibilidade invalida.");
  }

  return data.map(({ bank_name, available_quantity }) => ({
    bank_name,
    available_quantity,
  }));
}
