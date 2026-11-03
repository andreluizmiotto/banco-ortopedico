export const equipmentStatuses = [
  "available",
  "reserved",
  "on_loan",
  "under_maintenance",
  "donated",
  "written_off",
] as const;

export type EquipmentStatus = (typeof equipmentStatuses)[number];

export const equipmentStatusLabels: Record<EquipmentStatus, string> = {
  available: "Disponível para empréstimo",
  reserved: "Reservado para retirada",
  on_loan: "Emprestado",
  under_maintenance: "Em conserto",
  donated: "Doado",
  written_off: "Fora de uso",
};

export const equipmentEntryOrigins = [
  "donation",
  "purchase",
  "repair_return",
  "return_from_other_bank",
] as const;

export type EquipmentEntryOrigin = (typeof equipmentEntryOrigins)[number];

export const equipmentEntryOriginLabels: Record<EquipmentEntryOrigin, string> = {
  donation: "Doado",
  purchase: "Comprado",
  repair_return: "Voltou do conserto",
  return_from_other_bank: "Veio de outro banco",
};

export type EquipmentUnit = {
  id: string;
  typeCode: string;
  typeName: string;
  visibleCode: string | null;
  storageLocationId: string | null;
  storageLocationName: string | null;
  entryOrigin: EquipmentEntryOrigin | null;
  status: EquipmentStatus;
};

export type EquipmentTypeOption = {
  code: string;
  name: string;
};

export type StorageLocationOption = {
  id: string;
  name: string;
};

export type AdminInventoryData = {
  bankName: string;
  units: EquipmentUnit[];
  types: EquipmentTypeOption[];
  locations: StorageLocationOption[];
};

export type EquipmentMutationState =
  | { kind: "idle" }
  | { kind: "success"; status: EquipmentStatus }
  | { kind: "invalid"; message: string }
  | { kind: "conflict"; message: string }
  | { kind: "forbidden"; message: string }
  | { kind: "error"; message: string };
