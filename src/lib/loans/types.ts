export const loanStatuses = ["draft", "active", "cancelled"] as const;

export type LoanStatus = (typeof loanStatuses)[number];

export const loanStatusLabels: Record<LoanStatus, string> = {
  draft: "Aguardando retirada",
  active: "Emprestado",
  cancelled: "Cancelado",
};

export const dueKinds = ["suggested", "custom", "no_due_date"] as const;

export type DueKind = (typeof dueKinds)[number];

export type LoanUnit = {
  id: string;
  typeName: string;
  visibleCode: string | null;
  storageLocationName: string | null;
};

export type LoanSummary = {
  publicCode: string;
  borrowerName: string;
  unitCount: number;
  createdAt: string;
  status: LoanStatus;
};

export type LoanDetail = {
  bankName: string;
  publicCode: string;
  status: LoanStatus;
  borrowerName: string;
  maskedCpf: string;
  maskedPhone: string;
  patientName: string | null;
  conditionNote: string | null;
  deliveryDate: string;
  dueDate: string | null;
  reviewDate: string | null;
  createdAt: string;
  completedAt: string | null;
  termVersion: number | null;
  termGeneratedAt: string | null;
  units: LoanUnit[];
};

export type PersonResult = {
  userId: string;
  fullName: string;
  maskedCpf: string;
  maskedPhone: string;
  openLoanCount: number;
};

export type LoanFormData = {
  bankName: string;
  suggestedDays: number;
  units: LoanUnit[];
};

export type LoanMutationState =
  | { kind: "idle" }
  | { kind: "success"; publicCode?: string; version?: number }
  | { kind: "invalid"; message: string }
  | { kind: "conflict"; message: string }
  | { kind: "forbidden"; message: string }
  | { kind: "error"; message: string };

export type PeopleSearchState =
  | { kind: "idle" }
  | { kind: "ready"; people: PersonResult[]; hasMore: boolean }
  | { kind: "invalid"; message: string }
  | { kind: "forbidden"; message: string }
  | { kind: "error"; message: string };
