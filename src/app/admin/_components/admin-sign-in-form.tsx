"use client";

import { useActionState } from "react";
import type { AdminSignInState } from "../../../lib/auth/action-types";
import { signInAdminAction } from "../entrar/actions";

const initialState: AdminSignInState = { message: null };

export function AdminSignInForm() {
  const [state, formAction, pending] = useActionState(
    signInAdminAction,
    initialState,
  );

  return (
    <section className="auth-panel">
      <form className="auth-form" action={formAction} aria-busy={pending}>
        <label className="form-field" htmlFor="admin-email">
          <span>E-mail</span>
          <input
            id="admin-email"
            name="email"
            type="email"
            autoComplete="email"
            autoCapitalize="none"
            spellCheck={false}
            required
            aria-describedby={state.message ? "admin-entry-message" : undefined}
          />
        </label>
        <label className="form-field" htmlFor="admin-password">
          <span>Senha</span>
          <input
            id="admin-password"
            name="password"
            type="password"
            autoComplete="current-password"
            required
            aria-describedby={state.message ? "admin-entry-message" : undefined}
          />
        </label>
        {state.message ? (
          <p
            className="field-error"
            id="admin-entry-message"
            role="alert"
            aria-live="assertive"
          >
            {state.message}
          </p>
        ) : null}
        {pending ? (
          <div className="admin-auth-loading" role="status" aria-live="polite">
            <span className="loading-indicator" aria-hidden="true" />
            <p className="body-copy">Aguarde enquanto conferimos seu acesso.</p>
          </div>
        ) : null}
        <button className="primary-action" type="submit" disabled={pending}>
          {state.message ? "Tentar novamente" : "Entrar"}
        </button>
      </form>
    </section>
  );
}
