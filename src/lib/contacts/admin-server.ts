import "server-only";
import { resolveAdminBankAccess } from "../auth/admin-bank";
import type {
  AdminContact,
  AdminContactOutcome,
  AdminContactStatus,
} from "./admin-types";

const contactCodePattern = /^[A-F0-9]{12}$/;

type AdminContactRow = {
  bank_name: unknown;
  public_code: unknown;
  status: unknown;
  overdue_48h: unknown;
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

function isContactStatus(value: unknown): value is AdminContactStatus {
  return (
    value === "new" ||
    value === "answered" ||
    value === "converted_to_loan" ||
    value === "no_response"
  );
}

function isContactOutcome(value: string): value is AdminContactOutcome {
  return (
    value === "answered" ||
    value === "no_response" ||
    value === "converted_to_loan"
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
      p_public_code: searchCode,
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

      if (row.public_code === null) continue;
      if (
        typeof row.public_code !== "string" ||
        !contactCodePattern.test(row.public_code) ||
        !isContactStatus(row.status) ||
        typeof row.overdue_48h !== "boolean"
      ) {
        return { kind: "error" };
      }

      contacts.push({
        publicCode: row.public_code,
        status: row.status,
        overdue48Hours: row.overdue_48h,
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

export async function changeAdminContactStatus(
  publicCode: string,
  status: string,
): Promise<
  | { kind: "success"; status: AdminContactOutcome }
  | { kind: "forbidden" }
  | { kind: "conflict" }
  | { kind: "error" }
> {
  if (!contactCodePattern.test(publicCode) || !isContactOutcome(status)) {
    return { kind: "forbidden" };
  }

  const access = await resolveAdminBankAccess();
  if (access.kind === "forbidden" || access.kind === "unauthenticated") {
    return { kind: "forbidden" };
  }
  if (access.kind !== "authorized") return { kind: "error" };

  try {
    const { data, error } = await access.client.rpc(
      "admin_set_contact_status",
      {
        p_public_code: publicCode,
        p_new_status: status,
      },
    );

    if (error) {
      if (error.code === "P0001" || error.code === "42501") {
        return { kind: "forbidden" };
      }
      if (error.code === "P0002") return { kind: "conflict" };
      return { kind: "error" };
    }

    if (data !== status) return { kind: "error" };

    return { kind: "success", status };
  } catch {
    return { kind: "error" };
  }
}
