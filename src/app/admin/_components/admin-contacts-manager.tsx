"use client";

import Link from "next/link";
import { useRef, useState, useTransition, type FormEvent } from "react";
import {
  adminContactStatusLabels,
  type AdminContact,
  type AdminContactChangeState,
  type AdminContactOutcome,
} from "../../../lib/contacts/admin-types";
import { setAdminContactStatusAction } from "../contatos/actions";

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
          <span>Código que veio na mensagem</span>
          <input
            autoCapitalize="off"
            autoComplete="off"
            id="contact-code-search"
            inputMode="text"
            maxLength={12}
            name="code"
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
        id="contact-list"
      >
        <h2 className="admin-contact-section-heading" id="admin-contact-list-heading">
          {isSearching ? "Resultado da pesquisa" : "Pedidos de contato"}
        </h2>

        {contacts.length === 0 ? (
          <EmptyContacts searchCode={searchCode} />
        ) : (
          <ul className="admin-contact-list">
            {contacts.map((contact) => (
              <li key={contact.publicCode}>
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
      <h3>{searchCode === null ? "Ainda não há pedidos" : "Nenhum pedido encontrado"}</h3>
      <p className="body-copy">
        {searchCode === null
          ? "Quando alguém pedir contato, o código e a situação aparecerão aqui."
          : "Confira o código na mensagem e tente outra pesquisa."}
      </p>
      <Link className="secondary-action" href="/admin/contatos">
        {searchCode === null ? "Atualizar pedidos" : "Ver todos os pedidos"}
      </Link>
    </div>
  );
}

function AdminContactCard({ contact }: { contact: AdminContact }) {
  const [changeState, setChangeState] = useState<AdminContactChangeState>({
    kind: "idle",
  });
  const [selectedStatus, setSelectedStatus] = useState<
    AdminContactOutcome | ""
  >("");
  const [pending, startTransition] = useTransition();
  const isSubmitting = useRef(false);

  function submitStatus(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (isSubmitting.current || !selectedStatus) return;

    isSubmitting.current = true;
    const formData = new FormData(event.currentTarget);

    startTransition(async () => {
      try {
        setChangeState(await setAdminContactStatusAction(formData));
      } catch {
        setChangeState({ kind: "error" });
      } finally {
        isSubmitting.current = false;
      }
    });
  }

  const status =
    changeState.kind === "success" ? changeState.status : contact.status;
  const fieldId = `contact-status-${contact.publicCode}`;
  const errorId = `contact-status-error-${contact.publicCode}`;

  return (
    <article className="admin-contact-card">
      <header className="admin-contact-card-heading">
        <h3 className="admin-contact-code">{contact.publicCode}</h3>
        <p className={`admin-contact-status status-${status}`}>
          Situação: <strong>{adminContactStatusLabels[status]}</strong>
        </p>
      </header>

      {contact.overdue48Hours && status === "new" ? (
        <p className="admin-contact-overdue">
          Sem atendimento há 48 horas ou mais.
        </p>
      ) : null}

      {changeState.kind === "success" ? (
        <div className="admin-contact-confirmation">
          <p className="body-copy" role="status" aria-live="polite">
            Situação registrada como{" "}
            <strong>{adminContactStatusLabels[changeState.status]}</strong>.
          </p>
          <Link className="secondary-action" href="#contact-list">
            Continuar acompanhando pedidos
          </Link>
        </div>
      ) : changeState.kind === "conflict" ? (
        <div className="admin-contact-denied">
          <p className="body-copy" role="status" aria-live="polite">
            Outra pessoa já registrou uma situação para este pedido.
          </p>
          <Link
            className="secondary-action"
            href={`/admin/contatos?code=${encodeURIComponent(contact.publicCode)}`}
          >
            Atualizar situação
          </Link>
        </div>
      ) : changeState.kind === "forbidden" ? (
        <div className="admin-contact-denied">
          <p className="field-error" role="alert" aria-live="assertive">
            Você não tem permissão para alterar este pedido.
          </p>
          <Link className="secondary-action" href="/admin/contatos">
            Voltar aos pedidos
          </Link>
        </div>
      ) : status === "new" ? (
        <form
          onSubmit={submitStatus}
          aria-busy={pending}
          className="admin-contact-change-form"
        >
          <input type="hidden" name="publicCode" value={contact.publicCode} />
          <label className="form-field" htmlFor={fieldId}>
            <span>Marcar situação</span>
            <select
              aria-describedby={changeState.kind === "error" ? errorId : undefined}
              aria-invalid={changeState.kind === "error"}
              disabled={pending}
              id={fieldId}
              name="status"
              required
              value={selectedStatus}
              onChange={(event) =>
                setSelectedStatus(
                  event.currentTarget.value as AdminContactOutcome | "",
                )
              }
            >
              <option value="">Escolha uma situação</option>
              <option value="answered">Já atendeu</option>
              <option value="no_response">Não respondeu</option>
              <option value="converted_to_loan">Empréstimo feito</option>
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
            disabled={pending || selectedStatus === ""}
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
