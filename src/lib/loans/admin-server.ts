import "server-only";
import { createHash } from "node:crypto";
import { resolveAdminBankAccess } from "../auth/admin-bank";
import { createSupabaseServiceClient } from "../supabase/service";
import { renderLoanTermPdf } from "./term-pdf";
import {
  dueKinds,
  loanStatuses,
  type DueKind,
  type LoanDetail,
  type LoanFormData,
  type LoanMutationState,
  type LoanStatus,
  type LoanSummary,
  type LoanUnit,
  type PeopleSearchState,
  type PersonResult,
} from "./types";

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const publicCodePattern = /^[A-F0-9]{12}$/;
const bucketName = "loan-terms";

type LoanRow = {
  bank_name: unknown;
  public_code: unknown;
  borrower_name: unknown;
  unit_count: unknown;
  created_at: unknown;
  status: unknown;
};

type UnitRow = {
  bank_name: unknown;
  suggested_days: unknown;
  unit_id: unknown;
  equipment_type_code: unknown;
  equipment_type_name: unknown;
  visible_code: unknown;
  storage_location_name: unknown;
};

type PersonRow = {
  user_id: unknown;
  full_name: unknown;
  masked_cpf: unknown;
  masked_phone: unknown;
  open_loan_count: unknown;
  has_more: unknown;
};

type DetailRow = {
  bank_name: unknown;
  public_code: unknown;
  status: unknown;
  borrower_name: unknown;
  masked_cpf: unknown;
  masked_phone: unknown;
  patient_name: unknown;
  condition_note: unknown;
  delivery_date: unknown;
  due_date: unknown;
  review_date: unknown;
  created_at: unknown;
  completed_at: unknown;
  term_version: unknown;
  term_generated_at: unknown;
  units: unknown;
};

type TermRow = {
  bank_name: unknown;
  public_code: unknown;
  borrower_name: unknown;
  borrower_cpf: unknown;
  patient_name: unknown;
  condition_note: unknown;
  delivery_date: unknown;
  due_date: unknown;
  review_date: unknown;
  units: unknown;
  model_version: unknown;
  model_body: unknown;
  model_review_status: unknown;
  next_version: unknown;
  next_storage_path: unknown;
};

export type AdminLoansPageData =
  | { kind: "unauthenticated" }
  | { kind: "forbidden" }
  | { kind: "error" }
  | { kind: "ready"; bankName: string; loans: LoanSummary[] };

export type AdminLoanFormPageData =
  | { kind: "unauthenticated" }
  | { kind: "forbidden" }
  | { kind: "error" }
  | ({ kind: "ready" } & LoanFormData);

export type AdminLoanDetailPageData =
  | { kind: "unauthenticated" }
  | { kind: "forbidden" }
  | { kind: "notFound" }
  | { kind: "error" }
  | { kind: "ready"; loan: LoanDetail };

export type LoanTermFile =
  | { kind: "unauthenticated" }
  | { kind: "notFound" }
  | { kind: "error" }
  | { kind: "ready"; bytes: ArrayBuffer; fileName: string };

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function isNullableString(value: unknown): value is string | null {
  return value === null || typeof value === "string";
}

function isUuid(value: string): boolean {
  return uuidPattern.test(value);
}

function isLoanStatus(value: unknown): value is LoanStatus {
  return (
    typeof value === "string" &&
    (loanStatuses as readonly string[]).includes(value)
  );
}

function isDueKind(value: unknown): value is DueKind {
  return (
    typeof value === "string" && (dueKinds as readonly string[]).includes(value)
  );
}

function parseUnits(value: unknown): LoanUnit[] | null {
  if (!Array.isArray(value)) return null;

  const units: LoanUnit[] = [];
  for (const item of value) {
    if (!isRecord(item)) return null;
    if (
      typeof item.unit_id !== "string" ||
      !isUuid(item.unit_id) ||
      typeof item.type_name !== "string" ||
      !isNullableString(item.visible_code) ||
      !isNullableString(item.storage_location_name)
    ) {
      return null;
    }
    units.push({
      id: item.unit_id,
      typeName: item.type_name,
      visibleCode: item.visible_code,
      storageLocationName: item.storage_location_name,
    });
  }
  return units;
}

export async function getAdminLoansPageData(): Promise<AdminLoansPageData> {
  const access = await resolveAdminBankAccess();

  if (access.kind !== "authorized") {
    return access.kind === "unauthenticated" || access.kind === "forbidden"
      ? { kind: access.kind }
      : { kind: "error" };
  }

  try {
    const { data, error } = await access.client.rpc("admin_bank_loans");
    if (error || !Array.isArray(data)) return { kind: "error" };

    let bankName: string | null = null;
    const loans: LoanSummary[] = [];

    for (const value of data) {
      if (!isRecord(value)) return { kind: "error" };
      const row = value as LoanRow;

      if (
        typeof row.bank_name !== "string" ||
        typeof row.public_code !== "string" ||
        !publicCodePattern.test(row.public_code) ||
        typeof row.borrower_name !== "string" ||
        typeof row.unit_count !== "number" ||
        typeof row.created_at !== "string" ||
        !isLoanStatus(row.status)
      ) {
        return { kind: "error" };
      }

      if (bankName !== null && bankName !== row.bank_name) {
        return { kind: "error" };
      }
      bankName = row.bank_name;

      loans.push({
        publicCode: row.public_code,
        borrowerName: row.borrower_name,
        unitCount: row.unit_count,
        createdAt: row.created_at,
        status: row.status,
      });
    }

    if (bankName === null) return { kind: "error" };

    return { kind: "ready", bankName, loans };
  } catch {
    return { kind: "error" };
  }
}

export async function getAdminLoanFormData(): Promise<AdminLoanFormPageData> {
  const access = await resolveAdminBankAccess();

  if (access.kind !== "authorized") {
    return access.kind === "unauthenticated" || access.kind === "forbidden"
      ? { kind: access.kind }
      : { kind: "error" };
  }

  try {
    const { data, error } = await access.client.rpc("admin_loan_available_units");
    if (error || !Array.isArray(data)) return { kind: "error" };

    let bankName: string | null = null;
    let suggestedDays: number | null = null;
    const units: LoanUnit[] = [];
    const seenUnitIds = new Set<string>();

    for (const value of data) {
      if (!isRecord(value)) return { kind: "error" };
      const row = value as UnitRow;

      if (
        typeof row.bank_name !== "string" ||
        typeof row.suggested_days !== "number" ||
        typeof row.unit_id !== "string" ||
        !isUuid(row.unit_id) ||
        typeof row.equipment_type_name !== "string" ||
        !isNullableString(row.visible_code) ||
        !isNullableString(row.storage_location_name) ||
        seenUnitIds.has(row.unit_id)
      ) {
        return { kind: "error" };
      }

      if (bankName !== null && bankName !== row.bank_name) {
        return { kind: "error" };
      }
      if (suggestedDays !== null && suggestedDays !== row.suggested_days) {
        return { kind: "error" };
      }

      bankName = row.bank_name;
      suggestedDays = row.suggested_days;
      seenUnitIds.add(row.unit_id);
      units.push({
        id: row.unit_id,
        typeName: row.equipment_type_name,
        visibleCode: row.visible_code,
        storageLocationName: row.storage_location_name,
      });
    }

    if (bankName === null || suggestedDays === null) return { kind: "error" };

    return { kind: "ready", bankName, suggestedDays, units };
  } catch {
    return { kind: "error" };
  }
}

export async function searchAdminPeople(
  query: string | null,
): Promise<PeopleSearchState> {
  const text = query?.trim() ?? "";
  const digits = text.replace(/[^0-9]/g, "");
  const digitsOnly = text !== "" && /^[0-9()./ -]+$/.test(text);

  if (text === "" || (digitsOnly ? digits.length !== 11 : text.length < 3)) {
    return { kind: "invalid", message: searchInvalidMessage };
  }

  const access = await resolveAdminBankAccess();
  if (access.kind === "forbidden" || access.kind === "unauthenticated") {
    return { kind: "forbidden", message: forbiddenMessage };
  }
  if (access.kind !== "authorized") {
    return { kind: "error", message: errorMessage };
  }

  try {
    const { data, error } = await access.client.rpc("admin_search_people", {
      p_query: text,
    });

    if (error) return mapSearchError(error.code);
    if (!Array.isArray(data)) return { kind: "error", message: errorMessage };

    const people: PersonResult[] = [];
    let hasMore = false;

    for (const value of data) {
      if (!isRecord(value)) return { kind: "error", message: errorMessage };
      const row = value as PersonRow;

      if (
        typeof row.user_id !== "string" ||
        !isUuid(row.user_id) ||
        typeof row.full_name !== "string" ||
        typeof row.masked_cpf !== "string" ||
        typeof row.masked_phone !== "string" ||
        typeof row.open_loan_count !== "number" ||
        typeof row.has_more !== "boolean"
      ) {
        return { kind: "error", message: errorMessage };
      }

      hasMore = row.has_more;
      people.push({
        userId: row.user_id,
        fullName: row.full_name,
        maskedCpf: row.masked_cpf,
        maskedPhone: row.masked_phone,
        openLoanCount: row.open_loan_count,
      });
    }

    return { kind: "ready", people, hasMore };
  } catch {
    return { kind: "error", message: errorMessage };
  }
}

export async function createAdminLoanDraft(input: {
  borrowerUserId: string | null;
  unitIds: string[];
  patientName: string | null;
  conditionNote: string | null;
  dueKind: string | null;
  customDays: string | null;
  reviewDays: string | null;
}): Promise<LoanMutationState> {
  const borrowerUserId = input.borrowerUserId?.trim() ?? "";
  const patientName = input.patientName?.trim() || null;
  const conditionNote = input.conditionNote?.trim() || null;
  const unitIds = input.unitIds.map((value) => value.trim());

  if (!isUuid(borrowerUserId)) {
    return { kind: "invalid", message: searchInvalidMessage };
  }

  if (
    unitIds.length < 1 ||
    unitIds.length > 50 ||
    unitIds.some((value) => !isUuid(value)) ||
    new Set(unitIds).size !== unitIds.length
  ) {
    return { kind: "invalid", message: unitsInvalidMessage };
  }

  if (!isDueKind(input.dueKind)) {
    return { kind: "invalid", message: termInvalidMessage };
  }

  const customDays = parseDays(input.customDays);
  const reviewDays = parseDays(input.reviewDays);

  if (input.dueKind === "custom" && !isValidDays(customDays)) {
    return { kind: "invalid", message: termInvalidMessage };
  }
  if (input.dueKind === "no_due_date" && !isValidDays(reviewDays)) {
    return { kind: "invalid", message: reviewInvalidMessage };
  }

  if (patientName !== null && (patientName.length < 2 || patientName.length > 120)) {
    return { kind: "invalid", message: patientInvalidMessage };
  }
  if (conditionNote !== null && conditionNote.length > 200) {
    return { kind: "invalid", message: noteInvalidMessage };
  }

  const access = await resolveAdminBankAccess();
  if (access.kind === "forbidden" || access.kind === "unauthenticated") {
    return { kind: "forbidden", message: forbiddenMessage };
  }
  if (access.kind !== "authorized") {
    return { kind: "error", message: errorMessage };
  }

  try {
    const { data, error } = await access.client.rpc("admin_create_loan_draft", {
      p_borrower_user_id: borrowerUserId,
      p_unit_ids: unitIds,
      p_patient_name: patientName,
      p_condition_note: conditionNote,
      p_due_kind: input.dueKind,
      p_custom_days: input.dueKind === "custom" ? customDays : null,
      p_review_days: input.dueKind === "no_due_date" ? reviewDays : null,
    });

    if (error) return mapMutationError(error.code, error.message);
    if (!Array.isArray(data) || data.length !== 1) {
      return { kind: "error", message: errorMessage };
    }

    const row = data[0];
    if (!isRecord(row) || typeof row.public_code !== "string") {
      return { kind: "error", message: errorMessage };
    }
    if (!publicCodePattern.test(row.public_code)) {
      return { kind: "error", message: errorMessage };
    }

    return { kind: "success", publicCode: row.public_code };
  } catch {
    return { kind: "error", message: errorMessage };
  }
}

export async function getAdminLoanDetail(
  publicCode: string,
): Promise<AdminLoanDetailPageData> {
  if (!publicCodePattern.test(publicCode)) return { kind: "notFound" };

  const access = await resolveAdminBankAccess();
  if (access.kind === "unauthenticated") return { kind: "unauthenticated" };
  if (access.kind === "forbidden") return { kind: "forbidden" };
  if (access.kind !== "authorized") return { kind: "error" };

  try {
    const { data, error } = await access.client.rpc("admin_loan_detail", {
      p_public_code: publicCode,
    });

    if (error) {
      return error.code === "P0005" ? { kind: "notFound" } : { kind: "error" };
    }
    if (!Array.isArray(data) || data.length !== 1) return { kind: "notFound" };

    const value = data[0];
    if (!isRecord(value)) return { kind: "error" };
    const row = value as DetailRow;
    const units = parseUnits(row.units);

    if (
      typeof row.bank_name !== "string" ||
      typeof row.public_code !== "string" ||
      !publicCodePattern.test(row.public_code) ||
      !isLoanStatus(row.status) ||
      typeof row.borrower_name !== "string" ||
      typeof row.masked_cpf !== "string" ||
      typeof row.masked_phone !== "string" ||
      !isNullableString(row.patient_name) ||
      !isNullableString(row.condition_note) ||
      typeof row.delivery_date !== "string" ||
      !isNullableString(row.due_date) ||
      !isNullableString(row.review_date) ||
      typeof row.created_at !== "string" ||
      !isNullableString(row.completed_at) ||
      (row.term_version !== null && typeof row.term_version !== "number") ||
      !isNullableString(row.term_generated_at) ||
      units === null
    ) {
      return { kind: "error" };
    }

    return {
      kind: "ready",
      loan: {
        bankName: row.bank_name,
        publicCode: row.public_code,
        status: row.status,
        borrowerName: row.borrower_name,
        maskedCpf: row.masked_cpf,
        maskedPhone: row.masked_phone,
        patientName: row.patient_name,
        conditionNote: row.condition_note,
        deliveryDate: row.delivery_date,
        dueDate: row.due_date,
        reviewDate: row.review_date,
        createdAt: row.created_at,
        completedAt: row.completed_at,
        termVersion: row.term_version,
        termGeneratedAt: row.term_generated_at,
        units,
      },
    };
  } catch {
    return { kind: "error" };
  }
}

export async function generateAdminLoanTerm(
  publicCode: string,
): Promise<LoanMutationState> {
  if (!publicCodePattern.test(publicCode)) {
    return { kind: "invalid", message: notFoundMessage };
  }

  const access = await resolveAdminBankAccess();
  if (access.kind === "forbidden" || access.kind === "unauthenticated") {
    return { kind: "forbidden", message: forbiddenMessage };
  }
  if (access.kind !== "authorized") {
    return { kind: "error", message: errorMessage };
  }

  try {
    const { data, error } = await access.client.rpc("admin_loan_term_data", {
      p_public_code: publicCode,
    });

    if (error) return mapMutationError(error.code, error.message);
    if (!Array.isArray(data) || data.length !== 1) {
      return { kind: "error", message: errorMessage };
    }

    const value = data[0];
    if (!isRecord(value)) return { kind: "error", message: errorMessage };
    const row = value as TermRow;
    const units = parseUnits(row.units);

    if (
      typeof row.bank_name !== "string" ||
      typeof row.public_code !== "string" ||
      typeof row.borrower_name !== "string" ||
      typeof row.borrower_cpf !== "string" ||
      !isNullableString(row.patient_name) ||
      !isNullableString(row.condition_note) ||
      typeof row.delivery_date !== "string" ||
      !isNullableString(row.due_date) ||
      !isNullableString(row.review_date) ||
      typeof row.model_version !== "number" ||
      typeof row.model_body !== "string" ||
      (row.model_review_status !== "pending_legal_review" &&
        row.model_review_status !== "approved") ||
      typeof row.next_storage_path !== "string" ||
      units === null
    ) {
      return { kind: "error", message: errorMessage };
    }

    const bytes = await renderLoanTermPdf({
      modelBody: row.model_body,
      modelVersion: row.model_version,
      reviewStatus: row.model_review_status,
      values: {
        bank_name: row.bank_name,
        public_code: row.public_code,
        borrower_name: row.borrower_name,
        borrower_cpf: formatCpf(row.borrower_cpf),
        patient_name: row.patient_name ?? "O próprio responsável",
        condition_note: row.condition_note ?? "Nenhuma anotação.",
        delivery_date: formatDate(row.delivery_date),
        due_date: row.due_date
          ? formatDate(row.due_date)
          : "Sem data de devolução",
        review_date: row.review_date
          ? formatDate(row.review_date)
          : "Não se aplica",
        equipment_list: units
          .map(
            (unit) =>
              `- ${unit.typeName} — ${
                unit.visibleCode ?? "sem número"
              }${unit.storageLocationName ? ` (${unit.storageLocationName})` : ""}`,
          )
          .join("\n"),
      },
    });

    const contentHash = createHash("sha256").update(bytes).digest("hex");
    const storage = createSupabaseServiceClient().storage.from(bucketName);
    const upload = await storage.upload(row.next_storage_path, bytes, {
      contentType: "application/pdf",
      upsert: true,
    });

    if (upload.error) return { kind: "error", message: errorMessage };

    const recorded = await access.client.rpc("admin_record_loan_term", {
      p_public_code: publicCode,
      p_model_version: row.model_version,
      p_storage_path: row.next_storage_path,
      p_content_hash: contentHash,
    });

    if (recorded.error) {
      return mapMutationError(recorded.error.code, recorded.error.message);
    }
    if (typeof recorded.data !== "number") {
      return { kind: "error", message: errorMessage };
    }

    return { kind: "success", version: recorded.data };
  } catch {
    return { kind: "error", message: errorMessage };
  }
}

export async function getAdminLoanTermFile(
  publicCode: string,
): Promise<LoanTermFile> {
  if (!publicCodePattern.test(publicCode)) return { kind: "notFound" };

  const access = await resolveAdminBankAccess();
  if (access.kind === "unauthenticated") return { kind: "unauthenticated" };
  if (access.kind !== "authorized") return { kind: "notFound" };

  try {
    const { data, error } = await access.client.rpc("admin_loan_term_file", {
      p_public_code: publicCode,
    });

    if (error || typeof data !== "string") return { kind: "notFound" };

    const download = await createSupabaseServiceClient()
      .storage.from(bucketName)
      .download(data);

    if (download.error || !download.data) return { kind: "error" };

    return {
      kind: "ready",
      bytes: await download.data.arrayBuffer(),
      fileName: `termo-${publicCode}.pdf`,
    };
  } catch {
    return { kind: "error" };
  }
}

export async function completeAdminLoan(
  publicCode: string,
): Promise<LoanMutationState> {
  if (!publicCodePattern.test(publicCode)) {
    return { kind: "invalid", message: notFoundMessage };
  }

  const access = await resolveAdminBankAccess();
  if (access.kind === "forbidden" || access.kind === "unauthenticated") {
    return { kind: "forbidden", message: forbiddenMessage };
  }
  if (access.kind !== "authorized") {
    return { kind: "error", message: errorMessage };
  }

  try {
    const { data, error } = await access.client.rpc("admin_complete_loan", {
      p_public_code: publicCode,
    });

    if (error) return mapMutationError(error.code, error.message);
    if (!Array.isArray(data) || data.length !== 1) {
      return { kind: "error", message: errorMessage };
    }

    return { kind: "success" };
  } catch {
    return { kind: "error", message: errorMessage };
  }
}

export async function cancelAdminLoanDraft(
  publicCode: string,
): Promise<LoanMutationState> {
  if (!publicCodePattern.test(publicCode)) {
    return { kind: "invalid", message: notFoundMessage };
  }

  const access = await resolveAdminBankAccess();
  if (access.kind === "forbidden" || access.kind === "unauthenticated") {
    return { kind: "forbidden", message: forbiddenMessage };
  }
  if (access.kind !== "authorized") {
    return { kind: "error", message: errorMessage };
  }

  try {
    const { data, error } = await access.client.rpc("admin_cancel_loan_draft", {
      p_public_code: publicCode,
    });

    if (error) return mapMutationError(error.code, error.message);
    if (data !== "cancelled") return { kind: "error", message: errorMessage };

    return { kind: "success" };
  } catch {
    return { kind: "error", message: errorMessage };
  }
}

function parseDays(value: string | null): number | null {
  if (value === null || value.trim() === "") return null;
  if (!/^[0-9]{1,3}$/.test(value.trim())) return null;
  return Number(value.trim());
}

function isValidDays(value: number | null): value is number {
  return value !== null && value >= 1 && value <= 365;
}

function formatCpf(value: string): string {
  const digits = value.replace(/[^0-9]/g, "");
  if (digits.length !== 11) return value;
  return `${digits.slice(0, 3)}.${digits.slice(3, 6)}.${digits.slice(6, 9)}-${digits.slice(9)}`;
}

function formatDate(value: string): string {
  const [year, month, day] = value.split("-");
  if (!year || !month || !day) return value;
  return `${day}/${month}/${year}`;
}

const searchInvalidMessage =
  "Digite pelo menos 3 letras do nome ou os 11 números do CPF.";
const unitsInvalidMessage = "Escolha pelo menos um equipamento disponível.";
const termInvalidMessage = "Escolha um prazo entre 1 e 365 dias.";
const reviewInvalidMessage =
  "Informe em quanto tempo o banco vai revisar este empréstimo.";
const patientInvalidMessage =
  "Informe o nome de quem vai usar o equipamento, com até 120 letras.";
const noteInvalidMessage = "A anotação pode ter até 200 letras.";
const forbiddenMessage =
  "Você não tem permissão para registrar empréstimos neste banco.";
const notFoundMessage = "Empréstimo não encontrado neste banco.";
const errorMessage = "Não foi possível concluir a operação. Tente novamente.";

function mapSearchError(code: string | undefined): PeopleSearchState {
  if (code === "P0002") {
    return { kind: "invalid", message: searchInvalidMessage };
  }
  if (code === "P0001" || code === "42501") {
    return { kind: "forbidden", message: forbiddenMessage };
  }
  return { kind: "error", message: errorMessage };
}

const safeMessages = [
  "O equipamento ",
  "Este banco ainda não tem um modelo de termo ativo.",
  "Gere o termo antes de concluir a saída.",
  "A situação de um equipamento mudou. Confira o acervo antes de concluir.",
  "Empréstimo já concluído",
  "Este banco não está recebendo novos empréstimos.",
];

function mapMutationError(
  code: string | undefined,
  message: string | undefined,
): LoanMutationState {
  const safe =
    message !== undefined &&
    safeMessages.some((prefix) => message.startsWith(prefix))
      ? message
      : null;

  if (code === "P0002") {
    return { kind: "invalid", message: safe ?? errorMessage };
  }
  if (code === "P0003") {
    return { kind: "conflict", message: safe ?? conflictMessage };
  }
  if (code === "P0005") {
    return { kind: "invalid", message: notFoundMessage };
  }
  if (code === "P0001" || code === "42501") {
    return { kind: "forbidden", message: safe ?? forbiddenMessage };
  }
  return { kind: "error", message: errorMessage };
}

const conflictMessage =
  "Um dos equipamentos escolhidos não está mais disponível. Atualize a lista e escolha outro.";
