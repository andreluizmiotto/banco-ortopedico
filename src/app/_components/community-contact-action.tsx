"use client";

import { useEffect, useRef, useState, useTransition, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import type {
  ContactActionState,
  ContactMethod,
} from "../../lib/auth/action-types";
import { startCommunityContactAction } from "../actions/contact";

const initialState: ContactActionState = { kind: "idle" };

export function RefreshButton({ label = "Tentar novamente" }: { label?: string }) {
  const router = useRouter();

  return (
    <button
      className="secondary-action"
      type="button"
      onClick={() => router.refresh()}
    >
      {label}
    </button>
  );
}

export function CommunityContactAction({
  bankName,
  equipmentTypeCode,
  method,
}: {
  bankName: string;
  equipmentTypeCode: string;
  method: ContactMethod;
}) {
  const [state, setState] = useState<ContactActionState>(initialState);
  const [pending, startTransition] = useTransition();
  const hasNavigated = useRef(false);

  useEffect(() => {
    if (state.kind === "success" && !hasNavigated.current) {
      hasNavigated.current = true;
      window.location.assign(state.href);
    }
  }, [state]);

  function submitContact(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (pending) return;

    const formData = new FormData(event.currentTarget);
    startTransition(async () => {
      try {
        const result = await startCommunityContactAction(state, formData);
        setState(result);
      } catch {
        setState({
          kind: "error",
          message: "Não foi possível iniciar a conversa. Tente novamente.",
        });
      }
    });
  }

  if (state.kind === "unavailable") {
    return (
      <div className="contact-action-state" role="status">
        <p className="body-copy">{state.message}</p>
        <RefreshButton />
      </div>
    );
  }

  const label = method === "whatsapp" ? "Conversar no WhatsApp" : "Ligar";

  return (
    <form className="contact-action-form" onSubmit={submitContact}>
      <input type="hidden" name="bankName" value={bankName} />
      <input
        type="hidden"
        name="equipmentTypeCode"
        value={equipmentTypeCode}
      />
      {state.kind === "error" ? (
        <p className="field-error" role="alert">
          {state.message}
        </p>
      ) : null}
      {pending ? (
        <p className="contact-pending body-copy" role="status" aria-live="polite">
          Preparando o contato...
        </p>
      ) : null}
      <button className="primary-action" type="submit" disabled={pending}>
        {pending
          ? "Aguarde..."
          : state.kind === "error"
            ? "Tentar novamente"
            : label}
      </button>
    </form>
  );
}
