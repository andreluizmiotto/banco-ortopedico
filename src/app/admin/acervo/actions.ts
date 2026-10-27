"use server";

import { revalidatePath } from "next/cache";
import {
  createAdminEquipmentUnit,
  updateAdminEquipmentUnit,
} from "../../../lib/acervo/admin-server";
import type { EquipmentMutationState } from "../../../lib/acervo/types";

function formText(formData: FormData, key: string): string | null {
  const value = formData.get(key);
  return typeof value === "string" ? value : null;
}

export async function createEquipmentUnitAction(
  formData: FormData,
): Promise<EquipmentMutationState> {
  const result = await createAdminEquipmentUnit({
    typeCode: formText(formData, "tipo"),
    visibleCode: formText(formData, "identificador"),
    storageLocationId: formText(formData, "ponto"),
    situation: formText(formData, "situacao"),
    entryOrigin: formText(formData, "origem"),
  });

  if (result.kind === "success") revalidatePath("/admin/acervo");

  return result;
}

export async function updateEquipmentUnitAction(
  formData: FormData,
): Promise<EquipmentMutationState> {
  const result = await updateAdminEquipmentUnit({
    unitId: formText(formData, "unidade"),
    visibleCode: formText(formData, "identificador"),
    storageLocationId: formText(formData, "ponto"),
    situation: formText(formData, "situacao"),
  });

  if (result.kind === "success") revalidatePath("/admin/acervo");

  return result;
}
