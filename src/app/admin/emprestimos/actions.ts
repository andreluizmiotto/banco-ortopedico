"use server";

import { revalidatePath } from "next/cache";
import {
  cancelAdminLoanDraft,
  completeAdminLoan,
  createAdminLoanDraft,
  generateAdminLoanTerm,
  searchAdminPeople,
} from "../../../lib/loans/admin-server";
import type {
  LoanMutationState,
  PeopleSearchState,
} from "../../../lib/loans/types";

function formText(formData: FormData, key: string): string | null {
  const value = formData.get(key);
  return typeof value === "string" ? value : null;
}

export async function searchPeopleAction(
  formData: FormData,
): Promise<PeopleSearchState> {
  return searchAdminPeople(formText(formData, "busca"));
}

export async function createLoanDraftAction(
  formData: FormData,
): Promise<LoanMutationState> {
  const unitIds = formData
    .getAll("equipamentos")
    .filter((value): value is string => typeof value === "string");

  const result = await createAdminLoanDraft({
    borrowerUserId: formText(formData, "pessoa"),
    unitIds,
    patientName: formText(formData, "paciente"),
    conditionNote: formText(formData, "anotacao"),
    dueKind: formText(formData, "prazo"),
    customDays: formText(formData, "dias"),
    reviewDays: formText(formData, "revisao"),
  });

  if (result.kind === "success") revalidatePath("/admin/emprestimos");

  return result;
}

export async function generateLoanTermAction(
  formData: FormData,
): Promise<LoanMutationState> {
  const publicCode = formText(formData, "emprestimo") ?? "";
  const result = await generateAdminLoanTerm(publicCode);

  if (result.kind === "success") {
    revalidatePath(`/admin/emprestimos/${publicCode}`);
  }

  return result;
}

export async function completeLoanAction(
  formData: FormData,
): Promise<LoanMutationState> {
  const publicCode = formText(formData, "emprestimo") ?? "";
  const result = await completeAdminLoan(publicCode);

  if (result.kind === "success") {
    revalidatePath(`/admin/emprestimos/${publicCode}`);
    revalidatePath("/admin/emprestimos");
    revalidatePath("/admin/acervo");
  }

  return result;
}

export async function cancelLoanDraftAction(
  formData: FormData,
): Promise<LoanMutationState> {
  const publicCode = formText(formData, "emprestimo") ?? "";
  const result = await cancelAdminLoanDraft(publicCode);

  if (result.kind === "success") {
    revalidatePath(`/admin/emprestimos/${publicCode}`);
    revalidatePath("/admin/emprestimos");
    revalidatePath("/admin/acervo");
  }

  return result;
}
