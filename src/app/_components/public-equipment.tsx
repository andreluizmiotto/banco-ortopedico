"use client";

import Link from "next/link";
import {
  useEffect,
  useState,
  type Dispatch,
  type ReactNode,
  type SetStateAction,
} from "react";
import {
  orderAvailability,
  type BankAvailability,
  type EquipmentType,
} from "../../lib/availability";
import {
  readEquipmentAvailability,
  readEquipmentType,
  readEquipmentTypes,
} from "../../lib/public-supabase";

type RemoteState<T> =
  | { kind: "loading" }
  | { kind: "error" }
  | { kind: "ready"; value: T };

type CatalogEntry = {
  equipment: EquipmentType;
  availableQuantity: number;
};

function PublicPage({
  title,
  introduction,
  backLink,
  children,
}: {
  title: string;
  introduction: string;
  backLink?: { href: string; label: string };
  children: ReactNode;
}) {
  return (
    <div className="public-page">
      <a className="skip-link" href="#conteudo-principal">
        Ir para o conteúdo
      </a>
      <div className="page-frame">
        <header className="public-header">
          <Link className="brand-link" href="/">
            <span className="brand-mark" aria-hidden="true" />
            <span>Banco Ortopédico</span>
          </Link>
          <p className="brand-note">Acervo comunitário</p>
        </header>
        <main id="conteudo-principal">
          {backLink ? (
            <Link className="back-link" href={backLink.href}>
              {backLink.label}
            </Link>
          ) : null}
          <div className="page-heading">
            <p className="eyebrow">Consulta pública</p>
            <h1>{title}</h1>
            <p className="body-copy">{introduction}</p>
          </div>
          <div className="page-content">{children}</div>
        </main>
        <footer className="public-footer">
          <p className="body-copy">
            A disponibilidade é atualizada a partir do acervo de cada banco.
          </p>
        </footer>
      </div>
    </div>
  );
}

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
    <PublicPage
      title="Disponibilidade por banco"
      introduction="Consulte os equipamentos dos bancos comunitários."
    >
      <LoadingMessage />
    </PublicPage>
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
    <PublicPage
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
    </PublicPage>
  );
}

function BankCard({ bank }: { bank: BankAvailability }) {
  return (
    <article className="bank-card">
      <div className="bank-card-heading">
        <h2 className="bank-name">{bank.bank_name}</h2>
        <span
          className="availability-count"
          aria-label={`Quantidade disponível: ${bank.available_quantity}`}
        >
          {bank.available_quantity}
        </span>
      </div>
      {bank.available_quantity > 0 ? (
        <p className="availability-label">Disponível no depósito</p>
      ) : (
        <p className="availability-empty">Todos emprestados no momento</p>
      )}
      <Link className="primary-action" href="/entrar">
        Entrar para conversar
      </Link>
    </article>
  );
}

export function EquipmentDetail({ code }: { code: string }) {
  const [state, setState] = useState<
    RemoteState<{ equipment: EquipmentType; banks: BankAvailability[] } | null>
  >({ kind: "loading" });
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let current = true;

    async function loadDetail() {
      try {
        const equipment = await readEquipmentType(code);
        if (!equipment) {
          if (current) setState({ kind: "ready", value: null });
          return;
        }

        const availability = await readEquipmentAvailability(equipment.code);
        if (current) {
          setState({
            kind: "ready",
            value: {
              equipment,
              banks: orderAvailability(availability),
            },
          });
        }
      } catch {
        if (current) setState({ kind: "error" });
      }
    }

    void loadDetail();
    return () => {
      current = false;
    };
  }, [attempt, code]);

  const title =
    state.kind === "ready" && state.value
      ? state.value.equipment.name
      : "Disponibilidade por banco";

  return (
    <PublicPage
      title={title}
      introduction="Veja a quantidade disponível em cada banco mantenedor."
      backLink={{ href: "/", label: "Voltar para os equipamentos" }}
    >
      {state.kind === "loading" ? (
        <LoadingMessage />
      ) : state.kind === "error" ? (
        <ErrorMessage onRetry={() => retryRemote(setState, setAttempt)} />
      ) : state.value === null ? (
        <p className="empty-state body-copy">
          Equipamento não encontrado. Volte para a lista de equipamentos.
        </p>
      ) : state.value.banks.length === 0 ? (
        <p className="empty-state body-copy">
          Nenhum banco cadastrou este tipo de equipamento.
        </p>
      ) : (
        <ul className="bank-list">
          {state.value.banks.map((bank) => (
            <li key={bank.bank_name}>
              <BankCard bank={bank} />
            </li>
          ))}
        </ul>
      )}
    </PublicPage>
  );
}
