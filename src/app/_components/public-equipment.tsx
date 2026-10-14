"use client";

import Link from "next/link";
import {
  useEffect,
  useState,
  type Dispatch,
  type SetStateAction,
} from "react";
import type { EquipmentType } from "../../lib/availability";
import {
  readEquipmentAvailability,
  readEquipmentTypes,
} from "../../lib/public-supabase";
import { PublicLayout } from "./public-layout";

type RemoteState<T> =
  | { kind: "loading" }
  | { kind: "error" }
  | { kind: "ready"; value: T };

type CatalogEntry = {
  equipment: EquipmentType;
  availableQuantity: number;
};

function LoadingMessage() {
  return (
    <div className="remote-state" role="status" aria-live="polite">
      <span
        className="loading-indicator"
        data-loading-indicator
        aria-hidden="true"
      />
      <p className="body-copy">Carregando a disponibilidade...</p>
    </div>
  );
}

function ErrorMessage({ onRetry }: { onRetry: () => void }) {
  return (
    <div className="remote-state error-state" role="alert">
      <p className="body-copy">
        Não foi possível carregar a disponibilidade. Tente novamente.
      </p>
      <button className="primary-action" type="button" onClick={onRetry}>
        Tentar novamente
      </button>
    </div>
  );
}

function retryRemote<T>(
  setState: Dispatch<SetStateAction<RemoteState<T>>>,
  setAttempt: Dispatch<SetStateAction<number>>,
) {
  setState({ kind: "loading" });
  setAttempt((attempt) => attempt + 1);
}

export function PublicAvailabilityLoading() {
  return (
    <PublicLayout
      title="Disponibilidade por banco"
      introduction="Consulte os equipamentos dos bancos comunitários."
    >
      <LoadingMessage />
    </PublicLayout>
  );
}

export function EquipmentCatalog() {
  const [state, setState] = useState<RemoteState<CatalogEntry[]>>({
    kind: "loading",
  });
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let current = true;

    async function loadCatalog() {
      try {
        const equipmentTypes = await readEquipmentTypes();
        const entries = await Promise.all(
          equipmentTypes.map(async (equipment) => {
            const availability = await readEquipmentAvailability(equipment.code);
            return {
              equipment,
              availableQuantity: availability.reduce(
                (total, bank) => total + bank.available_quantity,
                0,
              ),
            };
          }),
        );

        if (current) setState({ kind: "ready", value: entries });
      } catch {
        if (current) setState({ kind: "error" });
      }
    }

    void loadCatalog();
    return () => {
      current = false;
    };
  }, [attempt]);

  return (
    <PublicLayout
      title="Equipamentos ortopédicos"
      introduction="Encontre um equipamento e consulte a disponibilidade nos bancos comunitários."
    >
      {state.kind === "loading" ? (
        <LoadingMessage />
      ) : state.kind === "error" ? (
        <ErrorMessage onRetry={() => retryRemote(setState, setAttempt)} />
      ) : state.value.length === 0 ? (
        <p className="empty-state body-copy">
          Ainda não há equipamentos para consultar.
        </p>
      ) : (
        <ul className="equipment-list">
          {state.value.map(({ equipment, availableQuantity }) => (
            <li key={equipment.code}>
              <article className="equipment-entry">
                <h2 className="equipment-name">{equipment.name}</h2>
                <div className="equipment-availability">
                  {availableQuantity > 0 ? (
                    <>
                      <p className="availability-label">
                        Disponível no depósito
                      </p>
                      <p
                        className="availability-count"
                        aria-label={`Quantidade disponível: ${availableQuantity}`}
                      >
                        {availableQuantity} equipamento
                        {availableQuantity === 1 ? "" : "s"}
                      </p>
                    </>
                  ) : (
                    <p className="availability-empty">
                      Todos emprestados no momento
                    </p>
                  )}
                </div>
                <Link
                  className="primary-action"
                  href={`/equipamentos/${encodeURIComponent(equipment.code)}`}
                >
                  Ver disponibilidade
                </Link>
              </article>
            </li>
          ))}
        </ul>
      )}
    </PublicLayout>
  );
}
