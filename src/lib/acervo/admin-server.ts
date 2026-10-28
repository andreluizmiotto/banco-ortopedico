import "server-only";
import { resolveAdminBankAccess } from "../auth/admin-bank";
import {
  equipmentEntryOrigins,
  equipmentSituations,
  type AdminAcervoData,
  type EquipmentEntryOrigin,
  type EquipmentMutationState,
  type EquipmentSituation,
  type EquipmentTypeOption,
  type EquipmentUnit,
  type StorageLocationOption,
} from "./types";

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

type UnitRow = {
  bank_name: unknown;
  unit_id: unknown;
  equipment_type_code: unknown;
  equipment_type_name: unknown;
  visible_code: unknown;
  storage_location_id: unknown;
  storage_location_name: unknown;
  entry_origin: unknown;
  situacao: unknown;
};

type OptionRow = {
  option_kind: unknown;
  option_code: unknown;
  option_label: unknown;
};

export type AdminAcervoPageData =
  | { kind: "unauthenticated" }
  | { kind: "forbidden" }
  | { kind: "error" }
  | ({ kind: "ready" } & AdminAcervoData);

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

export function isEquipmentSituation(
  value: unknown,
): value is EquipmentSituation {
  return (
    typeof value === "string" &&
    (equipmentSituations as readonly string[]).includes(value)
  );
}

export function isEquipmentEntryOrigin(
  value: unknown,
): value is EquipmentEntryOrigin {
  return (
    typeof value === "string" &&
    (equipmentEntryOrigins as readonly string[]).includes(value)
  );
}

function isNullableString(value: unknown): value is string | null {
  return value === null || typeof value === "string";
}

function isUuid(value: string): boolean {
  return uuidPattern.test(value);
}

export async function getAdminAcervoPageData(): Promise<AdminAcervoPageData> {
  const access = await resolveAdminBankAccess();

  if (access.kind !== "authorized") {
    return access.kind === "unauthenticated" || access.kind === "forbidden"
      ? { kind: access.kind }
      : { kind: "error" };
  }

  try {
    const [unitsResult, optionsResult] = await Promise.all([
      access.client.rpc("admin_bank_equipment_units"),
      access.client.rpc("admin_bank_equipment_options"),
    ]);

    if (unitsResult.error || optionsResult.error) return { kind: "error" };
    if (!Array.isArray(unitsResult.data) || !Array.isArray(optionsResult.data)) {
      return { kind: "error" };
    }

    let bankName: string | null = null;
    const units: EquipmentUnit[] = [];
    const seenUnitIds = new Set<string>();

    for (const value of unitsResult.data) {
      if (!isRecord(value)) return { kind: "error" };
      const row = value as UnitRow;

      if (typeof row.bank_name !== "string") return { kind: "error" };
      if (bankName !== null && bankName !== row.bank_name) {
        return { kind: "error" };
      }
      bankName = row.bank_name;

      if (row.unit_id === null) continue;

      if (
        typeof row.unit_id !== "string" ||
        !isUuid(row.unit_id) ||
        typeof row.equipment_type_code !== "string" ||
        typeof row.equipment_type_name !== "string" ||
        !isNullableString(row.visible_code) ||
        (row.storage_location_id !== null &&
          (typeof row.storage_location_id !== "string" ||
            !isUuid(row.storage_location_id))) ||
        !isNullableString(row.storage_location_name) ||
        (row.entry_origin !== null &&
          !isEquipmentEntryOrigin(row.entry_origin)) ||
        !isEquipmentSituation(row.situacao) ||
        seenUnitIds.has(row.unit_id)
      ) {
        return { kind: "error" };
      }

      seenUnitIds.add(row.unit_id);
      units.push({
        id: row.unit_id,
        typeCode: row.equipment_type_code,
        typeName: row.equipment_type_name,
        visibleCode: row.visible_code,
        storageLocationId: row.storage_location_id,
        storageLocationName: row.storage_location_name,
        entryOrigin: row.entry_origin,
        situation: row.situacao,
      });
    }

    if (bankName === null) return { kind: "error" };

    const types: EquipmentTypeOption[] = [];
    const locations: StorageLocationOption[] = [];
    const seenTypeCodes = new Set<string>();
    const seenLocationIds = new Set<string>();

    for (const value of optionsResult.data) {
      if (!isRecord(value)) return { kind: "error" };
      const row = value as OptionRow;

      if (
        typeof row.option_code !== "string" ||
        typeof row.option_label !== "string"
      ) {
        return { kind: "error" };
      }

      if (row.option_kind === "equipment_type") {
        if (seenTypeCodes.has(row.option_code)) return { kind: "error" };
        seenTypeCodes.add(row.option_code);
        types.push({ code: row.option_code, name: row.option_label });
      } else if (row.option_kind === "storage_location") {
        if (
          !isUuid(row.option_code) ||
          seenLocationIds.has(row.option_code)
        ) {
          return { kind: "error" };
        }
        seenLocationIds.add(row.option_code);
        locations.push({ id: row.option_code, name: row.option_label });
      } else {
        return { kind: "error" };
      }
    }

    return { kind: "ready", bankName, units, types, locations };
  } catch {
    return { kind: "error" };
  }
}

export async function createAdminEquipmentUnit(input: {
  typeCode: string | null;
  visibleCode: string | null;
  storageLocationId: string | null;
  situation: string | null;
  entryOrigin: string | null;
}): Promise<EquipmentMutationState> {
  const typeCode = input.typeCode?.trim() ?? "";
  const visibleCode = input.visibleCode?.trim() || null;
  const storageLocationId = input.storageLocationId?.trim() || null;

  if (
    typeCode === "" ||
    typeCode.length > 32 ||
    !isEquipmentSituation(input.situation) ||
    !isEquipmentEntryOrigin(input.entryOrigin) ||
    (storageLocationId !== null && !isUuid(storageLocationId)) ||
    (visibleCode !== null && visibleCode.length > 64)
  ) {
    return { kind: "invalid", message: invalidUnitMessage };
  }

  const access = await resolveAdminBankAccess();
  if (access.kind === "forbidden" || access.kind === "unauthenticated") {
    return { kind: "forbidden", message: forbiddenMessage };
  }
  if (access.kind !== "authorized") return { kind: "error", message: errorMessage };

  try {
    const { data, error } = await access.client.rpc(
      "admin_create_equipment_unit",
      {
        p_equipment_type_code: typeCode,
        p_visible_code: visibleCode,
        p_storage_location_id: storageLocationId,
        p_situation: input.situation,
        p_entry_origin: input.entryOrigin,
      },
    );

    if (error) return mapMutationError(error.code);
    if (typeof data !== "string" || !isUuid(data)) {
      return { kind: "error", message: errorMessage };
    }

    return { kind: "success", situation: input.situation };
  } catch {
    return { kind: "error", message: errorMessage };
  }
}

export async function updateAdminEquipmentUnit(input: {
  unitId: string | null;
  visibleCode: string | null;
  storageLocationId: string | null;
  situation: string | null;
}): Promise<EquipmentMutationState> {
  const unitId = input.unitId?.trim() ?? "";
  const visibleCode = input.visibleCode?.trim() || null;
  const storageLocationId = input.storageLocationId?.trim() || null;

  if (
    !isUuid(unitId) ||
    !isEquipmentSituation(input.situation) ||
    (storageLocationId !== null && !isUuid(storageLocationId)) ||
    (visibleCode !== null && visibleCode.length > 64)
  ) {
    return { kind: "invalid", message: invalidUnitMessage };
  }

  const access = await resolveAdminBankAccess();
  if (access.kind === "forbidden" || access.kind === "unauthenticated") {
    return { kind: "forbidden", message: forbiddenMessage };
  }
  if (access.kind !== "authorized") return { kind: "error", message: errorMessage };

  try {
    const { data, error } = await access.client.rpc(
      "admin_update_equipment_unit",
      {
        p_unit_id: unitId,
        p_visible_code: visibleCode,
        p_storage_location_id: storageLocationId,
        p_situation: input.situation,
      },
    );

    if (error) return mapMutationError(error.code);
    if (!isEquipmentSituation(data)) {
      return { kind: "error", message: errorMessage };
    }

    return { kind: "success", situation: data };
  } catch {
    return { kind: "error", message: errorMessage };
  }
}

const invalidUnitMessage =
  "Confira os dados da unidade e tente novamente.";
const forbiddenMessage =
  "Você não tem permissão para alterar o acervo deste banco.";
const errorMessage =
  "Não foi possível salvar a unidade. Tente novamente.";

function mapMutationError(code: string | undefined): EquipmentMutationState {
  if (code === "P0003") {
    return {
      kind: "conflict",
      message:
        "Já existe uma unidade com este identificador neste banco. Confira o tombo e tente novamente.",
    };
  }
  if (code === "P0002") {
    return { kind: "invalid", message: invalidUnitMessage };
  }
  if (code === "P0001" || code === "42501") {
    return { kind: "forbidden", message: forbiddenMessage };
  }
  return { kind: "error", message: errorMessage };
}
