"use server";

import { revalidatePath } from "next/cache";
import {
  createAdminEquipmentUnit,
  updateAdminEquipmentUnit,
} from "../../../lib/inventory/admin-server";
import type { EquipmentMutationState } from "../../../lib/inventory/types";

function formText(formData: FormData, key: string): string | null {
  const value = formData.get(key);
  return typeof value === "string" ? value : null;
}

export async function createEquipmentUnitAction(
  formData: FormData,
): Promise<EquipmentMutationState> {
  const result = await createAdminEquipmentUnit({
    typeCode: formText(formData, "type"),
    visibleCode: formText(formData, "visibleCode"),
    storageLocationId: formText(formData, "location"),
    status: formText(formData, "status"),
    entryOrigin: formText(formData, "entryOrigin"),
  });

  if (result.kind === "success") revalidatePath("/admin/acervo");

  return result;
}

export async function updateEquipmentUnitAction(
  formData: FormData,
): Promise<EquipmentMutationState> {
  const result = await updateAdminEquipmentUnit({
    unitId: formText(formData, "unitId"),
    visibleCode: formText(formData, "visibleCode"),
    storageLocationId: formText(formData, "location"),
    status: formText(formData, "status"),
  });

  if (result.kind === "success") revalidatePath("/admin/acervo");

  return result;
}
