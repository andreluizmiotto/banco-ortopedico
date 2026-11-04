"use client";

import { useRouter } from "next/navigation";
import { useRef, useState, useTransition, type FormEvent } from "react";
import type {
  LoanFormData,
  LoanMutationState,
  LoanUnit,
  PeopleSearchState,
  PersonResult,
} from "../../../lib/loans/types";
import {
  createLoanDraftAction,
  searchPeopleAction,
} from "../emprestimos/actions";

type Step = 1 | 2 | 3 | 4;

type UnitGroup = {
  typeName: string;
  units: LoanUnit[];
};

export function AdminLoanWizard({
  bankName,
  suggestedDays,
  units,
}: LoanFormData) {
  const router = useRouter();
  const [step, setStep] = useState<Step>(1);
  const [searchState, setSearchState] = useState<PeopleSearchState>({
    kind: "idle",
  });
  const [searching, startSearch] = useTransition();
  const [person, setPerson] = useState<PersonResult | null>(null);
  const [selectedUnits, setSelectedUnits] = useState<string[]>([]);
  const [patientMode, setPatientMode] = useState<"self" | "other">("self");
  const [patientName, setPatientName] = useState("");
  const [dueKind, setDueKind] = useState<"suggested" | "custom" | "no_due_date">(
    "suggested",
  );
  const [customDays, setCustomDays] = useState(String(suggestedDays));
  const [reviewDays, setReviewDays] = useState("90");
  const [note, setNote] = useState("");
  const [submitState, setSubmitState] = useState<LoanMutationState>({
    kind: "idle",
  });
  const [submitting, startSubmit] = useTransition();
  const submittingRef = useRef(false);

  const groups = groupUnits(units);
  const searchError =
    searchState.kind === "invalid" ||
    searchState.kind === "forbidden" ||
    searchState.kind === "error"
      ? searchState.message
      : null;
  const submitError =
    submitState.kind === "invalid" ||
    submitState.kind === "conflict" ||
    submitState.kind === "forbidden" ||
    submitState.kind === "error"
      ? submitState.message
      : null;

  function submitSearch(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (searching) return;

    const formData = new FormData(event.currentTarget);
    startSearch(async () => {
      try {
        setSearchState(await searchPeopleAction(formData));
      } catch {
        setSearchState({
          kind: "error",
          message: "Não foi possível buscar agora. Tente novamente.",
        });
      }
    });
  }

  function toggleUnit(unitId: string) {
    setSelectedUnits((current) =>
      current.includes(unitId)
        ? current.filter((value) => value !== unitId)
        : [...current, unitId],
    );
  }

  function submitDraft() {
    if (submittingRef.current || person === null) return;

    submittingRef.current = true;
    const formData = new FormData();
    formData.set("pessoa", person.userId);
    for (const unitId of selectedUnits) formData.append("equipamentos", unitId);
    formData.set("paciente", patientMode === "other" ? patientName : "");
    formData.set("anotacao", note);
    formData.set("prazo", dueKind);
    formData.set("dias", dueKind === "custom" ? customDays : "");
    formData.set("revisao", dueKind === "no_due_date" ? reviewDays : "");

    startSubmit(async () => {
      try {
        const state = await createLoanDraftAction(formData);
        setSubmitState(state);
        if (state.kind === "success" && state.publicCode) {
          router.push(`/admin/emprestimos/${state.publicCode}`);
        }
      } catch {
        setSubmitState({
          kind: "error",
          message: "Não foi possível salvar o empréstimo. Tente novamente.",
        });
      } finally {
        submittingRef.current = false;
      }
    });
  }

  return (
    <div className="loan-wizard">
      <p className="step-indicator" aria-live="polite">
        Passo {step} de 4
      </p>

      {step === 1 ? (
        <section aria-labelledby="loan-step-person">
          <h2 id="loan-step-person" className="loan-step-heading">
            Quem vai levar o equipamento?
          </h2>
          <p className="body-copy">
            Busque pelo nome ou pelo CPF de quem já tem cadastro na comunidade.
          </p>

          <form className="loan-search-form" onSubmit={submitSearch}>
            <div className="form-field">
              <label htmlFor="busca">Nome ou CPF</label>
              <input
                autoComplete="off"
                id="busca"
                name="busca"
                placeholder="Ex.: Maria Oliveira ou 000.000.000-00"
                type="search"
              />
              <p className="field-hint">
                Digite pelo menos 3 letras do nome ou os 11 números do CPF.
              </p>
            </div>
            <button className="secondary-action" disabled={searching} type="submit">
              {searching ? "Buscando..." : "Buscar pessoa"}
            </button>
          </form>

          {searchError ? (
            <p className="field-error" role="alert">
              {searchError}
            </p>
          ) : null}

          {searchState.kind === "ready" ? (
            searchState.people.length === 0 ? (
              <div className="loan-empty" role="status">
                <h3>Não encontramos ninguém com esse nome ou CPF.</h3>
                <p className="body-copy">
                  Confira a escrita e tente outra busca.
                </p>
              </div>
            ) : (
              <div className="loan-results">
                <h3 className="loan-section-heading">
                  {searchState.people.length === 1
                    ? "1 pessoa encontrada"
                    : `${searchState.people.length} pessoas encontradas`}
                </h3>
                <ul className="loan-result-list">
                  {searchState.people.map((result) => (
                    <li key={result.userId} className="loan-result">
                      <div>
                        <p className="loan-result-name">{result.fullName}</p>
                        <p className="loan-result-meta">
                          CPF {result.maskedCpf} · Telefone {result.maskedPhone}
                        </p>
                        <p className="loan-result-meta">
                          {result.openLoanCount === 0
                            ? "Nenhum empréstimo em aberto neste banco"
                            : result.openLoanCount === 1
                              ? "1 empréstimo em aberto neste banco"
                              : `${result.openLoanCount} empréstimos em aberto neste banco`}
                        </p>
                      </div>
                      <button
                        className="secondary-action"
                        onClick={() => {
                          setPerson(result);
                          setStep(2);
                        }}
                        type="button"
                      >
                        Escolher
                      </button>
                    </li>
                  ))}
                </ul>
                {searchState.hasMore ? (
                  <p className="field-hint">
                    Refine a busca para ver outras pessoas.
                  </p>
                ) : null}
              </div>
            )
          ) : null}
        </section>
      ) : null}

      {step === 2 ? (
        <section aria-labelledby="loan-step-units">
          <h2 id="loan-step-units" className="loan-step-heading">
            Quais equipamentos vão sair?
          </h2>
          <p className="body-copy">
            Só aparecem os equipamentos disponíveis no depósito de {bankName}.
          </p>

          {groups.length === 0 ? (
            <div className="loan-empty" role="status">
              <h3>Nenhum equipamento disponível agora</h3>
              <p className="body-copy">
                Confira o acervo do banco e volte quando houver equipamento
                disponível.
              </p>
              <a className="secondary-action" href="/admin/acervo">
                Abrir equipamentos do banco
              </a>
            </div>
          ) : (
            <div className="loan-unit-groups">
              {groups.map((group) => (
                <fieldset key={group.typeName} className="loan-unit-group">
                  <legend>{group.typeName}</legend>
                  {group.units.map((unit) => (
                    <label key={unit.id} className="loan-unit-option">
                      <input
                        checked={selectedUnits.includes(unit.id)}
                        onChange={() => toggleUnit(unit.id)}
                        type="checkbox"
                      />
                      <span>
                        {unit.visibleCode ?? "Sem número"}
                        {unit.storageLocationName
                          ? ` · ${unit.storageLocationName}`
                          : ""}
                      </span>
                    </label>
                  ))}
                </fieldset>
              ))}
            </div>
          )}

          <div className="loan-step-actions">
            <button
              className="secondary-action"
              onClick={() => setStep(1)}
              type="button"
            >
              Voltar
            </button>
            <button
              className="primary-action"
              disabled={selectedUnits.length === 0}
              onClick={() => setStep(3)}
              type="button"
            >
              Continuar
            </button>
          </div>
        </section>
      ) : null}

      {step === 3 ? (
        <section aria-labelledby="loan-step-term">
          <h2 id="loan-step-term" className="loan-step-heading">
            Prazo e pessoa que vai usar
          </h2>

          <fieldset className="loan-choice-group">
            <legend>Quem vai usar o equipamento?</legend>
            <label className="choice-option">
              <input
                checked={patientMode === "self"}
                name="paciente-escolha"
                onChange={() => setPatientMode("self")}
                type="radio"
              />
              <span>A própria pessoa</span>
            </label>
            <label className="choice-option">
              <input
                checked={patientMode === "other"}
                name="paciente-escolha"
                onChange={() => setPatientMode("other")}
                type="radio"
              />
              <span>Outra pessoa</span>
            </label>
          </fieldset>

          {patientMode === "other" ? (
            <div className="form-field">
              <label htmlFor="paciente">Nome de quem vai usar</label>
              <input
                id="paciente"
                maxLength={120}
                onChange={(event) => setPatientName(event.target.value)}
                type="text"
                value={patientName}
              />
              <p className="field-hint">
                Guardamos somente o nome, sem diagnóstico ou motivo de saúde.
              </p>
            </div>
          ) : null}

          <fieldset className="loan-choice-group">
            <legend>Prazo do empréstimo</legend>
            <label className="choice-option">
              <input
                checked={dueKind === "suggested"}
                name="prazo-escolha"
                onChange={() => setDueKind("suggested")}
                type="radio"
              />
              <span>Prazo sugerido ({suggestedDays} dias)</span>
            </label>
            <label className="choice-option">
              <input
                checked={dueKind === "custom"}
                name="prazo-escolha"
                onChange={() => setDueKind("custom")}
                type="radio"
              />
              <span>Outra data</span>
            </label>
            <label className="choice-option">
              <input
                checked={dueKind === "no_due_date"}
                name="prazo-escolha"
                onChange={() => setDueKind("no_due_date")}
                type="radio"
              />
              <span>Sem data de devolução</span>
            </label>
          </fieldset>

          {dueKind === "custom" ? (
            <div className="form-field">
              <label htmlFor="dias">Quantos dias de empréstimo?</label>
              <input
                id="dias"
                inputMode="numeric"
                max={365}
                min={1}
                onChange={(event) => setCustomDays(event.target.value)}
                type="number"
                value={customDays}
              />
              <p className="field-hint">De 1 a 365 dias.</p>
            </div>
          ) : null}

          {dueKind === "no_due_date" ? (
            <div className="form-field">
              <label htmlFor="revisao">Em quantos dias o banco vai revisar?</label>
              <input
                id="revisao"
                inputMode="numeric"
                max={365}
                min={1}
                onChange={(event) => setReviewDays(event.target.value)}
                type="number"
                value={reviewDays}
              />
              <p className="field-hint">
                A revisão gera um lembrete, não uma cobrança automática.
              </p>
            </div>
          ) : null}

          <div className="form-field">
            <label htmlFor="anotacao">
              Como o equipamento está sendo entregue?
            </label>
            <textarea
              id="anotacao"
              maxLength={200}
              onChange={(event) => setNote(event.target.value)}
              rows={3}
              value={note}
            />
            <p className="field-hint">
              Opcional, até 200 letras. Ex.: bom estado, com marcas de uso.
            </p>
          </div>

          <div className="loan-step-actions">
            <button
              className="secondary-action"
              onClick={() => setStep(2)}
              type="button"
            >
              Voltar
            </button>
            <button
              className="primary-action"
              onClick={() => setStep(4)}
              type="button"
            >
              Continuar
            </button>
          </div>
        </section>
      ) : null}

      {step === 4 ? (
        <section aria-labelledby="loan-step-review">
          <h2 id="loan-step-review" className="loan-step-heading">
            Confira antes de salvar
          </h2>

          <dl className="loan-summary">
            <div>
              <dt>Pessoa</dt>
              <dd>
                {person?.fullName} · CPF {person?.maskedCpf}
              </dd>
            </div>
            <div>
              <dt>Quem vai usar</dt>
              <dd>
                {patientMode === "other" && patientName.trim() !== ""
                  ? patientName.trim()
                  : "A própria pessoa"}
              </dd>
            </div>
            <div>
              <dt>Equipamentos</dt>
              <dd>
                {selectedUnits.length === 1
                  ? "1 equipamento"
                  : `${selectedUnits.length} equipamentos`}
              </dd>
            </div>
            <div>
              <dt>Prazo</dt>
              <dd>
                {dueKind === "suggested"
                  ? `${suggestedDays} dias`
                  : dueKind === "custom"
                    ? `${customDays} dias`
                    : `Sem data de devolução, revisão em ${reviewDays} dias`}
              </dd>
            </div>
          </dl>

          {submitError ? (
            <p className="field-error" role="alert">
              {submitError}
            </p>
          ) : null}

          <div className="loan-step-actions">
            <button
              className="secondary-action"
              disabled={submitting}
              onClick={() => setStep(3)}
              type="button"
            >
              Voltar
            </button>
            <button
              className="primary-action"
              disabled={submitting}
              onClick={submitDraft}
              type="button"
            >
              {submitting ? "Salvando..." : "Salvar empréstimo"}
            </button>
          </div>

          {submitting ? (
            <p className="form-pending" role="status">
              <span className="loading-indicator" aria-hidden="true" />
              Salvando o empréstimo...
            </p>
          ) : null}
        </section>
      ) : null}
    </div>
  );
}

function groupUnits(units: LoanUnit[]): UnitGroup[] {
  const groups: UnitGroup[] = [];

  for (const unit of units) {
    const group = groups.find((item) => item.typeName === unit.typeName);
    if (group) {
      group.units.push(unit);
    } else {
      groups.push({ typeName: unit.typeName, units: [unit] });
    }
  }

  return groups;
}
