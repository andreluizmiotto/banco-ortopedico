"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useRef, useState, useTransition, type FormEvent } from "react";
import {
  equipmentEntryOriginLabels,
  equipmentEntryOrigins,
  equipmentStatuses,
  equipmentStatusLabels,
  type AdminInventoryData,
  type EquipmentMutationState,
  type EquipmentStatus,
  type EquipmentUnit,
} from "../../../lib/inventory/types";
import {
  createEquipmentUnitAction,
  updateEquipmentUnitAction,
} from "../acervo/actions";

type UnitGroup = {
  typeCode: string;
  typeName: string;
  units: EquipmentUnit[];
};

export function AdminInventoryManager({
  bankName,
  units,
  types,
  locations,
}: AdminInventoryData) {
  const groups = groupUnitsByType(units);
  const counts = countStatuses(units);
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
    const typeCode = formData.get("type");
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
    <div className="admin-inventory">
      <section aria-labelledby="inventory-summary" className="inventory-summary">
        <h2 id="inventory-summary">
          Como estão os equipamentos de {bankName}
        </h2>
        <ul className="inventory-summary-list">
          {equipmentStatuses.map((status) => (
            <li key={status}>
              <span className="inventory-summary-label">
                {equipmentStatusLabels[status]}
              </span>
              <strong className="inventory-summary-value">
                {counts[status]}
              </strong>
            </li>
          ))}
        </ul>
      </section>

      <section aria-labelledby="inventory-form" className="inventory-card">
        <h2 id="inventory-form">Cadastrar equipamento</h2>

        {createState.kind === "success" ? (
          <div
            aria-live="polite"
            className="inventory-confirmation"
            role="status"
          >
            <p className="body-copy">
              {createdTypeName === null
                ? "Equipamento cadastrado como "
                : `Equipamento ${createdTypeName} cadastrado como `}
              <strong>{equipmentStatusLabels[createState.status]}</strong>.
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
            className="inventory-form"
            onSubmit={submitCreate}
          >
            <label className="form-field" htmlFor="equipment-type">
              <span>Tipo de equipamento</span>
              <select
                defaultValue=""
                disabled={createPending}
                id="equipment-type"
                name="type"
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

            <label className="form-field" htmlFor="equipment-number">
              <span>Número do equipamento</span>
              <input
                autoCapitalize="off"
                autoComplete="off"
                disabled={createPending}
                id="equipment-number"
                maxLength={64}
                name="visibleCode"
                type="text"
                aria-describedby="equipment-number-hint"
              />
              <span className="field-hint" id="equipment-number-hint">
                Pode ser o número da etiqueta ou do tombo. Se não tiver, deixe
                em branco.
              </span>
            </label>

            <label className="form-field" htmlFor="equipment-location">
              <span>Onde está guardado</span>
              <select
                defaultValue=""
                disabled={createPending}
                id="equipment-location"
                name="location"
              >
                <option value="">Não sabemos onde está</option>
                {locations.map((location) => (
                  <option key={location.id} value={location.id}>
                    {location.name}
                  </option>
                ))}
              </select>
            </label>

            <label className="form-field" htmlFor="equipment-status">
              <span>Situação</span>
              <select
                defaultValue="available"
                disabled={createPending}
                id="equipment-status"
                name="status"
                required
              >
                {equipmentStatuses.map((status) => (
                  <option key={status} value={status}>
                    {equipmentStatusLabels[status]}
                  </option>
                ))}
              </select>
            </label>

            <label className="form-field" htmlFor="equipment-origin">
              <span>De onde veio o equipamento</span>
              <select
                defaultValue=""
                disabled={createPending}
                id="equipment-origin"
                name="entryOrigin"
                required
              >
                <option value="">Escolha de onde veio</option>
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
                className="inventory-pending"
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

      <section aria-labelledby="inventory-list" id="inventory-list">
        <h2 className="inventory-section-heading" id="inventory-list">
          Equipamentos do banco
        </h2>

        {units.length === 0 ? (
          <div className="inventory-empty empty-state">
            <h3>Ainda não há equipamentos cadastrados</h3>
            <p className="body-copy">
              Cadastre o primeiro equipamento para acompanhar o que o banco tem
              e a situação de cada peça.
            </p>
            <Link className="secondary-action" href="#inventory-form">
              Cadastrar o primeiro equipamento
            </Link>
          </div>
        ) : (
          <div className="inventory-groups">
            {groups.map((group) => (
              <section
                aria-labelledby={`inventory-group-${group.typeCode}`}
                className="inventory-group"
                key={group.typeCode}
              >
                <h3
                  className="inventory-group-heading"
                  id={`inventory-group-${group.typeCode}`}
                >
                  {group.typeName}
                </h3>
                <ul className="inventory-unit-list">
                  {group.units.map((unit) => (
                    <li key={unit.id}>
                      <AdminInventoryUnitCard
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

function AdminInventoryUnitCard({
  unit,
  locations,
}: {
  unit: EquipmentUnit;
  locations: AdminInventoryData["locations"];
}) {
  const [editing, setEditing] = useState(false);
  const [state, setState] = useState<EquipmentMutationState>({ kind: "idle" });
  const [pending, startUpdate] = useTransition();
  const submitting = useRef(false);
  const router = useRouter();
  const fieldId = `unit-${unit.id}`;
  const errorId = `${fieldId}-error`;

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

  const status = state.kind === "success" ? state.status : unit.status;

  return (
    <article className="inventory-unit-card">
      <header className="inventory-unit-heading">
        <h4 className="inventory-unit-code">
          {unit.visibleCode ?? "Sem número"}
        </h4>
        <p className="inventory-unit-status">
          Situação: <strong>{equipmentStatusLabels[status]}</strong>
        </p>
      </header>

      <dl className="inventory-unit-details">
        <div>
          <dt>Onde está guardado</dt>
          <dd>{unit.storageLocationName ?? "Não sabemos onde está"}</dd>
        </div>
        <div>
          <dt>De onde veio</dt>
          <dd>
            {unit.entryOrigin === null
              ? "Não sabemos de onde veio"
              : equipmentEntryOriginLabels[unit.entryOrigin]}
          </dd>
        </div>
      </dl>

      {state.kind === "success" ? (
        <div aria-live="polite" className="inventory-confirmation" role="status">
          <p className="body-copy">
            Situação atualizada para{" "}
            <strong>{equipmentStatusLabels[state.status]}</strong>.
          </p>
          <Link
            className="secondary-action"
            href="#inventory-list"
            onClick={() => {
              setEditing(false);
              setState({ kind: "idle" });
            }}
          >
            Continuar nos equipamentos
          </Link>
        </div>
      ) : editing ? (
        <form
          aria-busy={pending}
          className="inventory-form inventory-edit-form"
          onSubmit={submitUpdate}
        >
          <input name="unitId" type="hidden" value={unit.id} />

          <label className="form-field" htmlFor={`${fieldId}-number`}>
            <span>Número do equipamento</span>
            <input
              autoCapitalize="off"
              autoComplete="off"
              defaultValue={unit.visibleCode ?? ""}
              disabled={pending}
              id={`${fieldId}-number`}
              maxLength={64}
              name="visibleCode"
              type="text"
            />
          </label>

          <label className="form-field" htmlFor={`${fieldId}-location`}>
            <span>Onde está guardado</span>
            <select
              defaultValue={unit.storageLocationId ?? ""}
              disabled={pending}
              id={`${fieldId}-location`}
              name="location"
            >
              <option value="">Não sabemos onde está</option>
              {locations.map((location) => (
                <option key={location.id} value={location.id}>
                  {location.name}
                </option>
              ))}
            </select>
          </label>

          <label className="form-field" htmlFor={`${fieldId}-status`}>
            <span>Situação</span>
            <select
              defaultValue={unit.status}
              disabled={pending}
              id={`${fieldId}-status`}
              name="status"
              required
            >
              {equipmentStatuses.map((option) => (
                <option key={option} value={option}>
                  {equipmentStatusLabels[option]}
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
            <div className="inventory-pending" role="status" aria-live="polite">
              <span className="loading-indicator" aria-hidden="true" />
              <p className="body-copy">Aguarde enquanto salvamos.</p>
            </div>
          ) : null}

          <div className="inventory-edit-actions">
            <button
              className="secondary-action"
              disabled={pending}
              type="submit"
            >
              {pending ? "Aguarde..." : "Salvar alterações"}
            </button>
            <button
              className="inventory-close-action"
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

function countStatuses(
  units: EquipmentUnit[],
): Record<EquipmentStatus, number> {
  const counts = Object.fromEntries(
    equipmentStatuses.map((status) => [status, 0]),
  ) as Record<EquipmentStatus, number>;

  for (const unit of units) counts[unit.status] += 1;

  return counts;
}
