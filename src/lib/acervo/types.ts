export const equipmentSituations = [
  "disponivel",
  "reservado",
  "emprestado",
  "manutencao",
  "doado",
  "baixado",
] as const;

export type EquipmentSituation = (typeof equipmentSituations)[number];

export const equipmentSituationLabels: Record<EquipmentSituation, string> = {
  disponivel: "Disponível no depósito",
  reservado: "Aguardando retirada",
  emprestado: "Emprestado",
  manutencao: "Em manutenção",
  doado: "Doado",
  baixado: "Retirado do acervo",
};

export const equipmentEntryOrigins = [
  "doacao",
  "compra",
  "retorno_conserto",
  "devolucao_outro_banco",
] as const;

export type EquipmentEntryOrigin = (typeof equipmentEntryOrigins)[number];

export const equipmentEntryOriginLabels: Record<EquipmentEntryOrigin, string> = {
  doacao: "Doação",
  compra: "Compra",
  retorno_conserto: "Retorno de conserto",
  devolucao_outro_banco: "Devolução de outro banco",
};

export type EquipmentUnit = {
  id: string;
  typeCode: string;
  typeName: string;
  visibleCode: string | null;
  storageLocationId: string | null;
  storageLocationName: string | null;
  entryOrigin: EquipmentEntryOrigin | null;
  situation: EquipmentSituation;
};

export type EquipmentTypeOption = {
  code: string;
  name: string;
};

export type StorageLocationOption = {
  id: string;
  name: string;
};

export type AdminAcervoData = {
  bankName: string;
  units: EquipmentUnit[];
  types: EquipmentTypeOption[];
  locations: StorageLocationOption[];
};

export type EquipmentMutationState =
  | { kind: "idle" }
  | { kind: "success"; situation: EquipmentSituation }
  | { kind: "invalid"; message: string }
  | { kind: "conflict"; message: string }
  | { kind: "forbidden"; message: string }
  | { kind: "error"; message: string };
