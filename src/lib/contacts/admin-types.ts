export const adminContactSituationLabels = {
  novo: "Novo",
  atendido: "Atendido",
  virou_emprestimo: "Virou empréstimo",
  sem_retorno: "Sem retorno",
} as const;

export type AdminContactSituation = keyof typeof adminContactSituationLabels;

export type AdminContactDestination = Exclude<
  AdminContactSituation,
  "novo"
>;

export type AdminContact = {
  codigo: string;
  situacao: AdminContactSituation;
  destaque48Horas: boolean;
};

export type AdminContactChangeState =
  | { kind: "idle" }
  | { kind: "success"; situation: AdminContactDestination }
  | { kind: "forbidden" }
  | { kind: "conflict" }
  | { kind: "error" };
