"use client";

import { useRouter } from "next/navigation";
import { useRef, useState, useTransition } from "react";
import type { LoanDetail, LoanMutationState } from "../../../lib/loans/types";
import {
  cancelLoanDraftAction,
  completeLoanAction,
  generateLoanTermAction,
} from "../emprestimos/actions";

export function AdminLoanDraft({ loan }: { loan: LoanDetail }) {
  const router = useRouter();
  const [termState, setTermState] = useState<LoanMutationState>({ kind: "idle" });
  const [completeState, setCompleteState] = useState<LoanMutationState>({
    kind: "idle",
  });
  const [cancelState, setCancelState] = useState<LoanMutationState>({
    kind: "idle",
  });
  const [confirmingCancel, setConfirmingCancel] = useState(false);
  const [generating, startGenerate] = useTransition();
  const [completing, startComplete] = useTransition();
  const [cancelling, startCancel] = useTransition();
  const busyRef = useRef(false);

  const isDraft = loan.status === "draft";
  const hasTerm = loan.termVersion !== null;
  const error =
    firstMessage(termState) ??
    firstMessage(completeState) ??
    firstMessage(cancelState);

  function generateTerm() {
    if (busyRef.current) return;
    busyRef.current = true;

    const formData = new FormData();
    formData.set("emprestimo", loan.publicCode);

    startGenerate(async () => {
      try {
        const state = await generateLoanTermAction(formData);
        setTermState(state);
        if (state.kind === "success") router.refresh();
      } catch {
        setTermState({
          kind: "error",
          message: "Não foi possível gerar o termo. Tente novamente.",
        });
      } finally {
        busyRef.current = false;
      }
    });
  }

  function completeLoan() {
    if (busyRef.current) return;
    busyRef.current = true;

    const formData = new FormData();
    formData.set("emprestimo", loan.publicCode);

    startComplete(async () => {
      try {
        const state = await completeLoanAction(formData);
        setCompleteState(state);
        if (state.kind === "success") router.refresh();
      } catch {
        setCompleteState({
          kind: "error",
          message: "Não foi possível concluir a entrega. Tente novamente.",
        });
      } finally {
        busyRef.current = false;
      }
    });
  }

  function cancelDraft() {
    if (busyRef.current) return;
    busyRef.current = true;

    const formData = new FormData();
    formData.set("emprestimo", loan.publicCode);

    startCancel(async () => {
      try {
        const state = await cancelLoanDraftAction(formData);
        setCancelState(state);
        if (state.kind === "success") {
          router.push("/admin/emprestimos");
        }
      } catch {
        setCancelState({
          kind: "error",
          message: "Não foi possível cancelar o empréstimo. Tente novamente.",
        });
      } finally {
        busyRef.current = false;
      }
    });
  }

  return (
    <div className="loan-detail">
      <section className="loan-card" aria-labelledby="loan-person-heading">
        <h2 id="loan-person-heading" className="loan-section-heading">
          Pessoa responsável
        </h2>
        <p className="loan-person-name">{loan.borrowerName}</p>
        <p className="body-copy">
          CPF {loan.maskedCpf} · Telefone {loan.maskedPhone}
        </p>
        <p className="body-copy">
          Quem vai usar: {loan.patientName ?? "a própria pessoa"}
        </p>
      </section>

      <section className="loan-card" aria-labelledby="loan-units-heading">
        <h2 id="loan-units-heading" className="loan-section-heading">
          Equipamentos
        </h2>
        <ul className="loan-unit-list">
          {loan.units.map((unit) => (
            <li key={unit.id}>
              <span className="loan-unit-name">{unit.typeName}</span>
              <span className="loan-unit-meta">
                {unit.visibleCode ?? "Sem número"}
                {unit.storageLocationName
                  ? ` · ${unit.storageLocationName}`
                  : ""}
              </span>
            </li>
          ))}
        </ul>
        {loan.conditionNote ? (
          <p className="body-copy">Estado na entrega: {loan.conditionNote}</p>
        ) : null}
      </section>

      <section className="loan-card" aria-labelledby="loan-dates-heading">
        <h2 id="loan-dates-heading" className="loan-section-heading">
          Datas
        </h2>
        <dl className="loan-summary">
          <div>
            <dt>Entrega</dt>
            <dd>{formatDate(loan.deliveryDate)}</dd>
          </div>
          <div>
            <dt>Devolução prevista</dt>
            <dd>
              {loan.dueDate
                ? formatDate(loan.dueDate)
                : "Sem data de devolução"}
            </dd>
          </div>
          {loan.reviewDate ? (
            <div>
              <dt>Revisão</dt>
              <dd>{formatDate(loan.reviewDate)}</dd>
            </div>
          ) : null}
        </dl>
      </section>

      <section className="loan-card" aria-labelledby="loan-term-heading">
        <h2 id="loan-term-heading" className="loan-section-heading">
          Termo
        </h2>
        <p className="body-copy" aria-live="polite">
          {hasTerm
            ? `Termo gerado em ${formatDateTime(loan.termGeneratedAt)} — versão ${loan.termVersion}`
            : "Termo ainda não gerado"}
        </p>

        {hasTerm ? (
          <a
            className="secondary-action"
            href={`/admin/emprestimos/${loan.publicCode}/termo`}
          >
            Baixar termo
          </a>
        ) : null}

        {isDraft ? (
          <button
            className={hasTerm ? "secondary-action" : "primary-action"}
            disabled={generating}
            onClick={generateTerm}
            type="button"
          >
            {generating
              ? "Gerando o termo..."
              : hasTerm
                ? "Gerar nova versão do termo"
                : "Gerar termo"}
          </button>
        ) : null}
      </section>

      {error ? (
        <p className="field-error" role="alert">
          {error}
        </p>
      ) : null}

      {isDraft ? (
        <div className="loan-actions">
          <button
            className="primary-action"
            disabled={!hasTerm || completing}
            onClick={completeLoan}
            type="button"
          >
            {completing ? "Concluindo..." : "Concluir entrega"}
          </button>
          {!hasTerm ? (
            <p className="field-hint">
              Gere o termo antes de concluir a entrega.
            </p>
          ) : null}

          {confirmingCancel ? (
            <div className="loan-confirm" role="group" aria-label="Confirmar desistência">
              <p className="body-copy">
                As peças voltam para o depósito e o empréstimo é cancelado.
              </p>
              <button
                className="secondary-action"
                disabled={cancelling}
                onClick={cancelDraft}
                type="button"
              >
                {cancelling ? "Cancelando..." : "Sim, desistir do empréstimo"}
              </button>
              <button
                className="secondary-action"
                onClick={() => setConfirmingCancel(false)}
                type="button"
              >
                Manter o empréstimo
              </button>
            </div>
          ) : (
            <button
              className="secondary-action"
              onClick={() => setConfirmingCancel(true)}
              type="button"
            >
              Desistir deste empréstimo
            </button>
          )}
        </div>
      ) : (
        <div className="loan-actions">
          <p className="body-copy">
            {loan.status === "active"
              ? `Entrega confirmada em ${formatDateTime(loan.completedAt)}.`
              : "Este empréstimo foi cancelado."}
          </p>
          <a className="secondary-action" href="/admin/emprestimos">
            Voltar para empréstimos
          </a>
        </div>
      )}

      {generating || completing || cancelling ? (
        <p className="form-pending" role="status">
          <span className="loading-indicator" aria-hidden="true" />
          Salvando...
        </p>
      ) : null}
    </div>
  );
}

function firstMessage(state: LoanMutationState): string | null {
  return state.kind === "invalid" ||
    state.kind === "conflict" ||
    state.kind === "forbidden" ||
    state.kind === "error"
    ? state.message
    : null;
}

function formatDate(value: string): string {
  const [year, month, day] = value.split("-");
  if (!year || !month || !day) return value;
  return `${day}/${month}/${year}`;
}

function formatDateTime(value: string | null): string {
  if (value === null) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return new Intl.DateTimeFormat("pt-BR", {
    dateStyle: "short",
    timeStyle: "short",
  }).format(date);
}
