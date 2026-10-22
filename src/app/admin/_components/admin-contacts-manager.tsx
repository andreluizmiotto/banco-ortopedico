"use client";

import Link from "next/link";
import { useRef, useState, useTransition, type FormEvent } from "react";
import {
  adminContactSituationLabels,
  type AdminContact,
  type AdminContactChangeState,
  type AdminContactDestination,
} from "../../../lib/contacts/admin-types";
import { setAdminContactSituationAction } from "../contatos/actions";

type Props = {
  contacts: AdminContact[];
  searchCode: string | null;
};

export function AdminContactsManager({
  contacts,
  searchCode,
}: Props) {
  const isSearching = searchCode !== null;

  return (
    <div className="admin-contacts">
      <form
        action="/admin/contatos"
        className="admin-contact-search"
        method="get"
        role="search"
      >
        <label className="form-field" htmlFor="contact-code-search">
          <span>Código do contato na mensagem</span>
          <input
            autoCapitalize="off"
            autoComplete="off"
            id="contact-code-search"
            inputMode="text"
            maxLength={12}
            name="codigo"
            type="text"
            defaultValue={searchCode ?? ""}
            aria-describedby="contact-code-hint"
          />
          <span className="field-hint" id="contact-code-hint">
            Digite os 12 caracteres como aparecem na mensagem.
          </span>
        </label>
        <button className="primary-action" type="submit">
          Pesquisar
        </button>
      </form>

      <section
        aria-labelledby="admin-contact-list-heading"
        className="admin-contact-results"
        id="lista-de-contatos"
      >
        <h2 className="admin-contact-section-heading" id="admin-contact-list-heading">
          {isSearching ? "Resultado da pesquisa" : "Contatos recebidos"}
        </h2>

        {contacts.length === 0 ? (
          <EmptyContacts searchCode={searchCode} />
        ) : (
          <ul className="admin-contact-list">
            {contacts.map((contact) => (
              <li key={contact.codigo}>
                <AdminContactCard contact={contact} />
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}

function EmptyContacts({ searchCode }: { searchCode: string | null }) {
  return (
    <div className="admin-contact-empty empty-state">
      <h3>{searchCode === null ? "Ainda não há contatos" : "Nenhum contato encontrado"}</h3>
      <p className="body-copy">
        {searchCode === null
          ? "Quando alguém iniciar uma conversa, o código e a situação aparecerão aqui."
          : "Confira o código na mensagem e tente outra pesquisa."}
      </p>
      <Link className="secondary-action" href="/admin/contatos">
        {searchCode === null ? "Atualizar contatos" : "Ver todos os contatos"}
      </Link>
    </div>
  );
}

function AdminContactCard({ contact }: { contact: AdminContact }) {
  const [changeState, setChangeState] = useState<AdminContactChangeState>({
    kind: "idle",
  });
  const [selectedSituation, setSelectedSituation] = useState<
    AdminContactDestination | ""
  >("");
  const [pending, startTransition] = useTransition();
  const isSubmitting = useRef(false);

  function submitSituation(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (isSubmitting.current || !selectedSituation) return;

    isSubmitting.current = true;
    const formData = new FormData(event.currentTarget);

    startTransition(async () => {
      try {
        setChangeState(await setAdminContactSituationAction(formData));
      } catch {
        setChangeState({ kind: "error" });
      } finally {
        isSubmitting.current = false;
      }
    });
  }

  const situation =
    changeState.kind === "success" ? changeState.situation : contact.situacao;
  const fieldId = `contact-situation-${contact.codigo}`;
  const errorId = `contact-situation-error-${contact.codigo}`;

  return (
    <article className="admin-contact-card">
      <header className="admin-contact-card-heading">
        <h3 className="admin-contact-code">{contact.codigo}</h3>
        <p className={`admin-contact-situation situation-${situation}`}>
          Situação: <strong>{adminContactSituationLabels[situation]}</strong>
        </p>
      </header>

      {contact.destaque48Horas && situation === "novo" ? (
        <p className="admin-contact-overdue">
          Sem atendimento há 48 horas ou mais.
        </p>
      ) : null}

      {changeState.kind === "success" ? (
        <div className="admin-contact-confirmation">
          <p className="body-copy" role="status" aria-live="polite">
            Situação registrada como{" "}
            <strong>{adminContactSituationLabels[changeState.situation]}</strong>.
          </p>
          <Link className="secondary-action" href="#lista-de-contatos">
            Continuar acompanhando contatos
          </Link>
        </div>
      ) : changeState.kind === "conflict" ? (
        <div className="admin-contact-denied">
          <p className="body-copy" role="status" aria-live="polite">
            Outra pessoa já registrou uma situação para este contato.
          </p>
          <Link
            className="secondary-action"
            href={`/admin/contatos?codigo=${encodeURIComponent(contact.codigo)}`}
          >
            Atualizar situação
          </Link>
        </div>
      ) : changeState.kind === "forbidden" ? (
        <div className="admin-contact-denied">
          <p className="field-error" role="alert" aria-live="assertive">
            Você não tem permissão para alterar este contato.
          </p>
          <Link className="secondary-action" href="/admin/contatos">
            Voltar aos contatos
          </Link>
        </div>
      ) : situation === "novo" ? (
        <form
          onSubmit={submitSituation}
          aria-busy={pending}
          className="admin-contact-change-form"
        >
          <input type="hidden" name="codigo" value={contact.codigo} />
          <label className="form-field" htmlFor={fieldId}>
            <span>Marcar situação</span>
            <select
              aria-describedby={changeState.kind === "error" ? errorId : undefined}
              aria-invalid={changeState.kind === "error"}
              disabled={pending}
              id={fieldId}
              name="situacao"
              required
              value={selectedSituation}
              onChange={(event) =>
                setSelectedSituation(
                  event.currentTarget.value as AdminContactDestination | "",
                )
              }
            >
              <option value="">Escolha uma situação</option>
              <option value="atendido">Atendido</option>
              <option value="sem_retorno">Sem retorno</option>
              <option value="virou_emprestimo">Virou empréstimo</option>
            </select>
          </label>

          {changeState.kind === "error" ? (
            <p className="field-error" id={errorId} role="alert" aria-live="assertive">
              Não foi possível registrar a situação. Tente novamente.
            </p>
          ) : null}

          {pending ? (
            <div className="admin-contact-pending" role="status" aria-live="polite">
              <span className="loading-indicator" aria-hidden="true" />
              <p className="body-copy">Aguarde enquanto registramos a situação.</p>
            </div>
          ) : null}

          <button
            className="secondary-action"
            disabled={pending || selectedSituation === ""}
            type="submit"
          >
            {pending
              ? "Aguarde..."
              : changeState.kind === "error"
                ? "Tentar novamente"
                : "Registrar situação"}
          </button>
        </form>
      ) : null}
    </article>
  );
}
