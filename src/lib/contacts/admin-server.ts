import "server-only";
import { resolveAdminBankAccess } from "../auth/admin-bank";
import type {
  AdminContact,
  AdminContactDestination,
  AdminContactSituation,
} from "./admin-types";

const contactCodePattern = /^[A-F0-9]{12}$/;

type AdminContactRow = {
  bank_name: unknown;
  codigo: unknown;
  situacao: unknown;
  destaque_48_horas: unknown;
};

export type AdminContactsPageData =
  | { kind: "unauthenticated" }
  | { kind: "forbidden" }
  | { kind: "error" }
  | {
      kind: "ready";
      bankName: string;
      contacts: AdminContact[];
      searchCode: string | null;
    };

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function isContactSituation(value: unknown): value is AdminContactSituation {
  return (
    value === "novo" ||
    value === "atendido" ||
    value === "virou_emprestimo" ||
    value === "sem_retorno"
  );
}

function isContactDestination(value: string): value is AdminContactDestination {
  return (
    value === "atendido" ||
    value === "sem_retorno" ||
    value === "virou_emprestimo"
  );
}

export async function getAdminContactsPageData(
  searchCode: string | null,
): Promise<AdminContactsPageData> {
  const access = await resolveAdminBankAccess();

  if (access.kind !== "authorized") {
    return access.kind === "unauthenticated" || access.kind === "forbidden"
      ? { kind: access.kind }
      : { kind: "error" };
  }

  try {
    const { data, error } = await access.client.rpc("admin_bank_contacts", {
      p_codigo: searchCode,
    });

    if (error || !Array.isArray(data) || data.length === 0) {
      return error ? { kind: "error" } : { kind: "forbidden" };
    }

    let bankName: string | null = null;
    const contacts: AdminContact[] = [];

    for (const value of data) {
      if (!isRecord(value)) return { kind: "error" };

      const row = value as AdminContactRow;
      if (typeof row.bank_name !== "string") return { kind: "error" };
      if (bankName !== null && bankName !== row.bank_name) {
        return { kind: "error" };
      }
      bankName = row.bank_name;

      if (row.codigo === null) continue;
      if (
        typeof row.codigo !== "string" ||
        !contactCodePattern.test(row.codigo) ||
        !isContactSituation(row.situacao) ||
        typeof row.destaque_48_horas !== "boolean"
      ) {
        return { kind: "error" };
      }

      contacts.push({
        codigo: row.codigo,
        situacao: row.situacao,
        destaque48Horas: row.destaque_48_horas,
      });
    }

    if (bankName === null) return { kind: "error" };

    return {
      kind: "ready",
      bankName,
      contacts,
      searchCode: searchCode !== null && searchCode.length <= 12 ? searchCode : "",
    };
  } catch {
    return { kind: "error" };
  }
}

export async function changeAdminContactSituation(
  codigo: string,
  situation: string,
): Promise<
  | { kind: "success"; situation: AdminContactDestination }
  | { kind: "forbidden" }
  | { kind: "conflict" }
  | { kind: "error" }
> {
  if (
    !contactCodePattern.test(codigo) ||
    !isContactDestination(situation)
  ) {
    return { kind: "forbidden" };
  }

  const access = await resolveAdminBankAccess();
  if (access.kind === "forbidden" || access.kind === "unauthenticated") {
    return { kind: "forbidden" };
  }
  if (access.kind !== "authorized") return { kind: "error" };

  try {
    const { data, error } = await access.client.rpc(
      "admin_set_contact_situation",
      {
        p_codigo: codigo,
        p_new_situation: situation,
      },
    );

    if (error) {
      if (error.code === "P0001" || error.code === "42501") {
        return { kind: "forbidden" };
      }
      if (error.code === "P0002") return { kind: "conflict" };
      return { kind: "error" };
    }

    if (data !== situation) return { kind: "error" };

    return { kind: "success", situation };
  } catch {
    return { kind: "error" };
  }
}
