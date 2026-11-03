export const adminContactStatusLabels = {
  new: "Novo pedido",
  answered: "Já atendeu",
  converted_to_loan: "Empréstimo feito",
  no_response: "Não respondeu",
} as const;

export type AdminContactStatus = keyof typeof adminContactStatusLabels;

export type AdminContactOutcome = Exclude<AdminContactStatus, "new">;

export type AdminContact = {
  publicCode: string;
  status: AdminContactStatus;
  overdue48Hours: boolean;
};

export type AdminContactChangeState =
  | { kind: "idle" }
  | { kind: "success"; status: AdminContactOutcome }
  | { kind: "forbidden" }
  | { kind: "conflict" }
  | { kind: "error" };
