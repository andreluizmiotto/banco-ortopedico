"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useRef, useState, useTransition, type FormEvent } from "react";
import {
  equipmentEntryOriginLabels,
  equipmentEntryOrigins,
  equipmentSituationLabels,
  equipmentSituations,
  type AdminAcervoData,
  type EquipmentMutationState,
  type EquipmentSituation,
  type EquipmentUnit,
} from "../../../lib/acervo/types";
import {
  createEquipmentUnitAction,
  updateEquipmentUnitAction,
} from "../acervo/actions";

type UnitGroup = {
  typeCode: string;
  typeName: string;
  units: EquipmentUnit[];
};

export function AdminAcervoManager({
  bankName,
  units,
  types,
  locations,
}: AdminAcervoData) {
  const groups = groupUnitsByType(units);
  const counts = countSituations(units);
  const [createState, setCreateState] = useState<EquipmentMutationState>({
    kind: "idle",
  });
  const [createdTypeName, setCreatedTypeName] = useState<string | null>(null);
  const [createPending, startCreate] = useTransition();
  const createSubmitting = useRef(false);
  const router = useRouter();
  const createError =
    createState.kind === "invalid" ||
    createState.kind === "conflict" ||
    createState.kind === "forbidden" ||
    createState.kind === "error"
      ? createState.message
      : null;

  function submitCreate(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (createSubmitting.current) return;

    createSubmitting.current = true;
    const form = event.currentTarget;
    const formData = new FormData(form);
    const typeCode = formData.get("tipo");
    const typeName =
      typeof typeCode === "string"
        ? types.find((type) => type.code === typeCode)?.name ?? null
        : null;

    startCreate(async () => {
      try {
        const state = await createEquipmentUnitAction(formData);
        setCreateState(state);
        if (state.kind === "success") {
          setCreatedTypeName(typeName);
          form.reset();
          router.refresh();
        }
      } catch {
        setCreateState({
          kind: "error",
          message: "Não foi possível cadastrar o equipamento. Tente novamente.",
        });
      } finally {
        createSubmitting.current = false;
      }
    });
  }

  function resetCreate() {
    setCreatedTypeName(null);
    setCreateState({ kind: "idle" });
  }

  return (
    <div className="admin-acervo">
      <section aria-labelledby="acervo-resumo" className="acervo-summary">
        <h2 id="acervo-resumo">Resumo do acervo de {bankName}</h2>
        <ul className="acervo-summary-list">
          {equipmentSituations.map((situation) => (
            <li key={situation}>
              <span className="acervo-summary-label">
                {equipmentSituationLabels[situation]}
              </span>
              <strong className="acervo-summary-value">
                {counts[situation]}
              </strong>
            </li>
          ))}
        </ul>
      </section>

      <section aria-labelledby="acervo-cadastro" className="acervo-card">
        <h2 id="acervo-cadastro">Cadastrar equipamento</h2>

        {createState.kind === "success" ? (
          <div
            aria-live="polite"
            className="acervo-confirmation"
            role="status"
          >
            <p className="body-copy">
              {createdTypeName === null
                ? "Equipamento cadastrado como "
                : `Equipamento ${createdTypeName} cadastrado como `}
              <strong>{equipmentSituationLabels[createState.situation]}</strong>.
            </p>
            <button
              className="secondary-action"
              onClick={resetCreate}
              type="button"
            >
              Cadastrar outro equipamento
            </button>
          </div>
        ) : (
          <form
            aria-busy={createPending}
            className="acervo-form"
            onSubmit={submitCreate}
          >
            <label className="form-field" htmlFor="acervo-tipo">
              <span>Tipo de equipamento</span>
              <select
                defaultValue=""
                disabled={createPending}
                id="acervo-tipo"
                name="tipo"
                required
              >
                <option value="">Escolha o tipo</option>
                {types.map((type) => (
                  <option key={type.code} value={type.code}>
                    {type.name}
                  </option>
                ))}
              </select>
            </label>

            <label className="form-field" htmlFor="acervo-identificador">
              <span>Identificador, tombo ou patrimônio</span>
              <input
                autoCapitalize="off"
                autoComplete="off"
                disabled={createPending}
                id="acervo-identificador"
                maxLength={64}
                name="identificador"
                type="text"
                aria-describedby="acervo-identificador-dica"
              />
              <span className="field-hint" id="acervo-identificador-dica">
                Pode ficar vazio ou ser preenchido depois, na conferência.
              </span>
            </label>

            <label className="form-field" htmlFor="acervo-ponto">
              <span>Ponto de guarda</span>
              <select
                defaultValue=""
                disabled={createPending}
                id="acervo-ponto"
                name="ponto"
              >
                <option value="">Sem ponto de guarda</option>
                {locations.map((location) => (
                  <option key={location.id} value={location.id}>
                    {location.name}
                  </option>
                ))}
              </select>
            </label>

            <label className="form-field" htmlFor="acervo-situacao">
              <span>Situação</span>
              <select
                defaultValue="disponivel"
                disabled={createPending}
                id="acervo-situacao"
                name="situacao"
                required
              >
                {equipmentSituations.map((situation) => (
                  <option key={situation} value={situation}>
                    {equipmentSituationLabels[situation]}
                  </option>
                ))}
              </select>
            </label>

            <label className="form-field" htmlFor="acervo-origem">
              <span>Como o equipamento entrou</span>
              <select
                defaultValue=""
                disabled={createPending}
                id="acervo-origem"
                name="origem"
                required
              >
                <option value="">Escolha a origem</option>
                {equipmentEntryOrigins.map((origin) => (
                  <option key={origin} value={origin}>
                    {equipmentEntryOriginLabels[origin]}
                  </option>
                ))}
              </select>
            </label>

            {createError === null ? null : (
              <p
                className="field-error"
                role="alert"
                aria-live="assertive"
              >
                {createError}
              </p>
            )}

            {createPending ? (
              <div
                className="acervo-pending"
                role="status"
                aria-live="polite"
              >
                <span className="loading-indicator" aria-hidden="true" />
                <p className="body-copy">Aguarde enquanto cadastramos.</p>
              </div>
            ) : null}

            <button
              className="primary-action"
              disabled={createPending}
              type="submit"
            >
              {createPending
                ? "Aguarde..."
                : createState.kind === "error" ||
                    createState.kind === "invalid" ||
                    createState.kind === "conflict"
                  ? "Tentar novamente"
                  : "Cadastrar equipamento"}
            </button>
          </form>
        )}
      </section>

      <section aria-labelledby="acervo-lista" id="lista-de-equipamentos">
        <h2 className="acervo-section-heading" id="acervo-lista">
          Equipamentos do acervo
        </h2>

        {units.length === 0 ? (
          <div className="acervo-empty empty-state">
            <h3>Ainda não há equipamentos cadastrados</h3>
            <p className="body-copy">
              Cadastre o primeiro equipamento para acompanhar o acervo e a
              situação de cada peça.
            </p>
            <Link className="secondary-action" href="#acervo-cadastro">
              Cadastrar o primeiro equipamento
            </Link>
          </div>
        ) : (
          <div className="acervo-groups">
            {groups.map((group) => (
              <section
                aria-labelledby={`acervo-grupo-${group.typeCode}`}
                className="acervo-group"
                key={group.typeCode}
              >
                <h3
                  className="acervo-group-heading"
                  id={`acervo-grupo-${group.typeCode}`}
                >
                  {group.typeName}
                </h3>
                <ul className="acervo-unit-list">
                  {group.units.map((unit) => (
                    <li key={unit.id}>
                      <AdminAcervoUnitCard
                        locations={locations}
                        unit={unit}
                      />
                    </li>
                  ))}
                </ul>
              </section>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

function AdminAcervoUnitCard({
  unit,
  locations,
}: {
  unit: EquipmentUnit;
  locations: AdminAcervoData["locations"];
}) {
  const [editing, setEditing] = useState(false);
  const [state, setState] = useState<EquipmentMutationState>({ kind: "idle" });
  const [pending, startUpdate] = useTransition();
  const submitting = useRef(false);
  const router = useRouter();
  const fieldId = `unidade-${unit.id}`;
  const errorId = `${fieldId}-erro`;

  function submitUpdate(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (submitting.current) return;

    submitting.current = true;
    const formData = new FormData(event.currentTarget);

    startUpdate(async () => {
      try {
        const result = await updateEquipmentUnitAction(formData);
        setState(result);
        if (result.kind === "success") router.refresh();
      } catch {
        setState({
          kind: "error",
          message: "Não foi possível salvar o equipamento. Tente novamente.",
        });
      } finally {
        submitting.current = false;
      }
    });
  }

  const situation =
    state.kind === "success" ? state.situation : unit.situation;

  return (
    <article className="acervo-unit-card">
      <header className="acervo-unit-heading">
        <h4 className="acervo-unit-code">
          {unit.visibleCode ?? "Sem identificador"}
        </h4>
        <p className="acervo-unit-situation">
          Situação: <strong>{equipmentSituationLabels[situation]}</strong>
        </p>
      </header>

      <dl className="acervo-unit-details">
        <div>
          <dt>Ponto de guarda</dt>
          <dd>{unit.storageLocationName ?? "Sem ponto de guarda"}</dd>
        </div>
        <div>
          <dt>Como entrou</dt>
          <dd>
            {unit.entryOrigin === null
              ? "Origem não registrada"
              : equipmentEntryOriginLabels[unit.entryOrigin]}
          </dd>
        </div>
      </dl>

      {state.kind === "success" ? (
        <div aria-live="polite" className="acervo-confirmation" role="status">
          <p className="body-copy">
            Situação atualizada para{" "}
            <strong>{equipmentSituationLabels[state.situation]}</strong>.
          </p>
          <Link
            className="secondary-action"
            href="#lista-de-equipamentos"
            onClick={() => {
              setEditing(false);
              setState({ kind: "idle" });
            }}
          >
            Continuar no acervo
          </Link>
        </div>
      ) : editing ? (
        <form
          aria-busy={pending}
          className="acervo-form acervo-edit-form"
          onSubmit={submitUpdate}
        >
          <input name="unidade" type="hidden" value={unit.id} />

          <label className="form-field" htmlFor={`${fieldId}-identificador`}>
            <span>Identificador, tombo ou patrimônio</span>
            <input
              autoCapitalize="off"
              autoComplete="off"
              defaultValue={unit.visibleCode ?? ""}
              disabled={pending}
              id={`${fieldId}-identificador`}
              maxLength={64}
              name="identificador"
              type="text"
            />
          </label>

          <label className="form-field" htmlFor={`${fieldId}-ponto`}>
            <span>Ponto de guarda</span>
            <select
              defaultValue={unit.storageLocationId ?? ""}
              disabled={pending}
              id={`${fieldId}-ponto`}
              name="ponto"
            >
              <option value="">Sem ponto de guarda</option>
              {locations.map((location) => (
                <option key={location.id} value={location.id}>
                  {location.name}
                </option>
              ))}
            </select>
          </label>

          <label className="form-field" htmlFor={`${fieldId}-situacao`}>
            <span>Situação</span>
            <select
              defaultValue={unit.situation}
              disabled={pending}
              id={`${fieldId}-situacao`}
              name="situacao"
              required
            >
              {equipmentSituations.map((option) => (
                <option key={option} value={option}>
                  {equipmentSituationLabels[option]}
                </option>
              ))}
            </select>
          </label>

          {state.kind === "idle" ? null : (
            <p
              className="field-error"
              id={errorId}
              role="alert"
              aria-live="assertive"
            >
              {state.message}
            </p>
          )}

          {pending ? (
            <div className="acervo-pending" role="status" aria-live="polite">
              <span className="loading-indicator" aria-hidden="true" />
              <p className="body-copy">Aguarde enquanto salvamos.</p>
            </div>
          ) : null}

          <div className="acervo-edit-actions">
            <button
              className="secondary-action"
              disabled={pending}
              type="submit"
            >
              {pending ? "Aguarde..." : "Salvar alterações"}
            </button>
            <button
              className="acervo-close-action"
              disabled={pending}
              onClick={() => {
                setEditing(false);
                setState({ kind: "idle" });
              }}
              type="button"
            >
              Fechar edição
            </button>
          </div>
        </form>
      ) : (
        <button
          className="secondary-action"
          onClick={() => {
            setEditing(true);
            setState({ kind: "idle" });
          }}
          type="button"
        >
          Editar equipamento
        </button>
      )}
    </article>
  );
}

function groupUnitsByType(units: EquipmentUnit[]): UnitGroup[] {
  const groups: UnitGroup[] = [];
  const index = new Map<string, UnitGroup>();

  for (const unit of units) {
    let group = index.get(unit.typeCode);
    if (!group) {
      group = { typeCode: unit.typeCode, typeName: unit.typeName, units: [] };
      index.set(unit.typeCode, group);
      groups.push(group);
    }
    group.units.push(unit);
  }

  return groups;
}

function countSituations(
  units: EquipmentUnit[],
): Record<EquipmentSituation, number> {
  const counts = Object.fromEntries(
    equipmentSituations.map((situation) => [situation, 0]),
  ) as Record<EquipmentSituation, number>;

  for (const unit of units) counts[unit.situation] += 1;

  return counts;
}
