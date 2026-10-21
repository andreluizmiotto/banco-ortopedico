"use client";

import {
  useLayoutEffect,
  useRef,
  useState,
  useTransition,
  type ChangeEvent,
  type FormEvent,
  type KeyboardEvent,
} from "react";
import type { CommunityPrivacyNotice } from "../../lib/auth/privacy-notice";
import {
  finishCommunitySignupAction,
  signInCommunityAction,
  startCommunitySignupAction,
  validateCpfAction,
} from "../entrar/actions";

type Step =
  | "choice"
  | "sign-in-cpf"
  | "sign-in-password"
  | "signup"
  | "otp";

type Props = {
  returnTo: string;
  privacyNotice: CommunityPrivacyNotice | null;
};

type AuthMessage = {
  kind: "error" | "status";
  text: string;
};

function maskPhone(phone: string) {
  const digits = phone.replace(/\D/g, "");
  return `•••• ${digits.slice(-4)}`;
}

function formatCpfInput(value: string): string {
  const digits = value.replace(/\D/g, "").slice(0, 11);

  if (digits.length <= 3) return digits;
  if (digits.length <= 6) return `${digits.slice(0, 3)}.${digits.slice(3)}`;
  if (digits.length <= 9) {
    return `${digits.slice(0, 3)}.${digits.slice(3, 6)}.${digits.slice(6)}`;
  }

  return `${digits.slice(0, 3)}.${digits.slice(3, 6)}.${digits.slice(6, 9)}-${digits.slice(9)}`;
}

function formatPhoneInput(value: string): string {
  const digits = value.replace(/\D/g, "").slice(0, 15);
  if (!digits) return value.startsWith("+") ? "+" : "";

  if (!digits.startsWith("55")) {
    return value.trimStart().startsWith("+") ? `+${digits}` : digits;
  }

  const nationalDigits = digits.slice(2, 13);
  if (nationalDigits.length === 0) return "+55";
  if (nationalDigits.length < 2) return `+55 (${nationalDigits}`;

  const areaCode = nationalDigits.slice(0, 2);
  const subscriber = nationalDigits.slice(2);
  if (!subscriber) return `+55 (${areaCode})`;

  const isMobile = subscriber.startsWith("9") || subscriber.length > 8;
  const prefixLength = isMobile ? 5 : 4;
  const subscriberPrefix = subscriber.slice(0, prefixLength);
  const subscriberSuffix = subscriber.slice(prefixLength, isMobile ? 9 : 8);

  return `+55 (${areaCode}) ${subscriberPrefix}${subscriberSuffix ? `-${subscriberSuffix}` : ""}`;
}

function countDigitsBeforeCursor(value: string, cursor: number): number {
  return value.slice(0, cursor).replace(/\D/g, "").length;
}

function cursorAfterDigits(value: string, digitCount: number): number {
  if (digitCount === 0) return value.startsWith("+") ? 1 : 0;

  let digitsSeen = 0;
  for (let index = 0; index < value.length; index += 1) {
    if (!/\d/.test(value.charAt(index))) continue;

    digitsSeen += 1;
    if (digitsSeen === digitCount) {
      let cursor = index + 1;
      while (cursor < value.length && !/\d/.test(value.charAt(cursor))) {
        cursor += 1;
      }
      return cursor;
    }
  }

  return value.length;
}

function handleMaskDeletion(
  event: KeyboardEvent<HTMLInputElement>,
  format: (value: string) => string,
  setValue: (value: string) => void,
  caretPosition: { current: number | null },
) {
  if (
    (event.key !== "Backspace" && event.key !== "Delete") ||
    event.metaKey ||
    event.ctrlKey ||
    event.altKey
  ) {
    return;
  }

  const input = event.currentTarget;
  const cursor = input.selectionStart;
  if (cursor === null || input.selectionEnd !== cursor) return;

  const direction = event.key === "Backspace" ? -1 : 1;
  let digitIndex = event.key === "Backspace" ? cursor - 1 : cursor;
  if (digitIndex < 0 || digitIndex >= input.value.length) return;
  if (/[\d+]/.test(input.value.charAt(digitIndex))) return;

  while (
    digitIndex >= 0 &&
    digitIndex < input.value.length &&
    !/\d/.test(input.value.charAt(digitIndex))
  ) {
    digitIndex += direction;
  }
  if (digitIndex < 0 || digitIndex >= input.value.length) return;

  event.preventDefault();
  const inputValue =
    input.value.slice(0, digitIndex) + input.value.slice(digitIndex + 1);
  const formattedValue = format(inputValue);
  caretPosition.current = cursorAfterDigits(
    formattedValue,
    countDigitsBeforeCursor(input.value, digitIndex),
  );
  setValue(formattedValue);
}

function SubmitPendingMessage() {
  return (
    <p className="form-pending body-copy" role="status" aria-live="polite">
      Aguarde enquanto conferimos as informações...
    </p>
  );
}

function FormMessage({
  message,
  id,
}: {
  message: AuthMessage;
  id: string;
}) {
  return (
    <p
      id={id}
      className={message.kind === "error" ? "field-error" : "form-pending body-copy"}
      role={message.kind === "error" ? "alert" : "status"}
      aria-live={message.kind === "error" ? "assertive" : "polite"}
    >
      {message.text}
    </p>
  );
}

export function AuthFlow({ returnTo, privacyNotice }: Props) {
  const [step, setStep] = useState<Step>("choice");
  const [mode, setMode] = useState<"enter" | "signup">("enter");
  const [cpf, setCpf] = useState("");
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [token, setToken] = useState("");
  const [passwordVisible, setPasswordVisible] = useState(false);
  const [privacyAccepted, setPrivacyAccepted] = useState(false);
  const [acceptedVersion, setAcceptedVersion] = useState("");
  const [message, setMessage] = useState<AuthMessage | null>(null);
  const [pending, startTransition] = useTransition();
  const cpfInputRef = useRef<HTMLInputElement>(null);
  const phoneInputRef = useRef<HTMLInputElement>(null);
  const cpfCaretPosition = useRef<number | null>(null);
  const phoneCaretPosition = useRef<number | null>(null);

  useLayoutEffect(() => {
    const input = cpfInputRef.current;
    const caretPosition = cpfCaretPosition.current;
    if (input && caretPosition !== null && document.activeElement === input) {
      input.setSelectionRange(caretPosition, caretPosition);
    }
    cpfCaretPosition.current = null;
  }, [cpf]);

  useLayoutEffect(() => {
    const input = phoneInputRef.current;
    const caretPosition = phoneCaretPosition.current;
    if (input && caretPosition !== null && document.activeElement === input) {
      input.setSelectionRange(caretPosition, caretPosition);
    }
    phoneCaretPosition.current = null;
  }, [phone]);

  function handleCpfChange(event: ChangeEvent<HTMLInputElement>) {
    const inputValue = event.currentTarget.value;
    const cursor = event.currentTarget.selectionStart ?? inputValue.length;
    const formattedValue = formatCpfInput(inputValue);

    cpfCaretPosition.current =
      formattedValue === inputValue
        ? null
        : cursorAfterDigits(
            formattedValue,
            countDigitsBeforeCursor(inputValue, cursor),
          );
    setCpf(formattedValue);
  }

  function handlePhoneChange(event: ChangeEvent<HTMLInputElement>) {
    const inputValue = event.currentTarget.value;
    const cursor = event.currentTarget.selectionStart ?? inputValue.length;
    const formattedValue = formatPhoneInput(inputValue);

    phoneCaretPosition.current =
      formattedValue === inputValue
        ? null
        : cursorAfterDigits(
            formattedValue,
            countDigitsBeforeCursor(inputValue, cursor),
          );
    setPhone(formattedValue);
  }

  function handleCpfKeyDown(event: KeyboardEvent<HTMLInputElement>) {
    handleMaskDeletion(event, formatCpfInput, setCpf, cpfCaretPosition);
  }

  function handlePhoneKeyDown(event: KeyboardEvent<HTMLInputElement>) {
    handleMaskDeletion(event, formatPhoneInput, setPhone, phoneCaretPosition);
  }

  function goBack(nextStep: Step) {
    setMessage(null);
    setStep(nextStep);
  }

  function continueFromChoice(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setMessage(null);

    if (mode === "signup" && !privacyNotice) {
      setMessage({
        kind: "error",
        text: "O cadastro ainda não está disponível. Tente novamente mais tarde.",
      });
      return;
    }

    setStep(mode === "enter" ? "sign-in-cpf" : "signup");
  }

  function continueWithCpf(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setMessage(null);
    const formData = new FormData(event.currentTarget);

    startTransition(async () => {
      try {
        const result = await validateCpfAction(formData);
        if (result.valid) {
          setStep("sign-in-password");
        } else {
          setMessage(
            result.message ? { kind: "error", text: result.message } : null,
          );
        }
      } catch {
        setMessage({
          kind: "error",
          text: "Não foi possível conferir o CPF. Tente novamente.",
        });
      }
    });
  }

  function submitSignIn(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setMessage(null);
    const formData = new FormData(event.currentTarget);
    formData.set("cpf", cpf);
    formData.set("returnTo", returnTo);

    startTransition(async () => {
      try {
        const result = await signInCommunityAction({ message: null }, formData);
        setMessage(
          result.message ? { kind: "error", text: result.message } : null,
        );
        setPassword("");
      } catch {
        setMessage({
          kind: "error",
          text: "Não foi possível entrar agora. Tente novamente.",
        });
      }
    });
  }

  function submitSignup(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setMessage(null);
    const formData = new FormData(event.currentTarget);

    startTransition(async () => {
      try {
        const result = await startCommunitySignupAction(
          { kind: "idle", message: null },
          formData,
        );

        setMessage(
          result.message
            ? {
                kind: result.kind === "otp" ? "status" : "error",
                text: result.message,
              }
            : null,
        );
        if (result.kind === "otp" && result.acceptedVersion) {
          setAcceptedVersion(result.acceptedVersion);
          setPassword("");
          setStep("otp");
        }
      } catch {
        setMessage({
          kind: "error",
          text: "Não foi possível criar o cadastro agora. Tente novamente.",
        });
      }
    });
  }

  function submitOtp(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setMessage(null);
    const formData = new FormData(event.currentTarget);
    formData.set("name", name);
    formData.set("cpf", cpf);
    formData.set("phone", phone);
    formData.set("token", token);
    formData.set("acceptedVersion", acceptedVersion);
    formData.set("privacyAccepted", privacyAccepted ? "true" : "false");
    formData.set("returnTo", returnTo);

    startTransition(async () => {
      try {
        const result = await finishCommunitySignupAction(
          { kind: "idle", message: null },
          formData,
        );
        setMessage(
          result.message ? { kind: "error", text: result.message } : null,
        );
      } catch {
        setMessage({
          kind: "error",
          text: "Não foi possível confirmar o telefone. Tente novamente.",
        });
      }
    });
  }

  return (
    <section className="auth-panel" aria-live="polite">
      {step === "choice" ? (
        <form className="auth-form" onSubmit={continueFromChoice}>
          <div className="auth-step-heading">
            <p className="step-indicator">Escolha uma opção</p>
            <h2>Você já tem cadastro?</h2>
          </div>
          <fieldset
            className="choice-list"
            aria-describedby={message ? "auth-choice-message" : undefined}
          >
            <legend className="body-copy">Como deseja continuar?</legend>
            <label className="choice-option" htmlFor="auth-mode-enter">
              <input
                id="auth-mode-enter"
                name="auth-mode"
                type="radio"
                value="enter"
                checked={mode === "enter"}
                onChange={() => setMode("enter")}
              />
              <span>Já tenho cadastro</span>
            </label>
            <label
              className={`choice-option${privacyNotice ? "" : " choice-disabled"}`}
              htmlFor="auth-mode-signup"
            >
              <input
                id="auth-mode-signup"
                name="auth-mode"
                type="radio"
                value="signup"
                checked={mode === "signup"}
                disabled={!privacyNotice}
                onChange={() => setMode("signup")}
              />
              <span>Quero criar cadastro</span>
            </label>
          </fieldset>
          {!privacyNotice ? (
            <p className="body-copy">
              O cadastro ainda não está disponível. Tente novamente mais tarde.
            </p>
          ) : null}
          {message ? (
            <FormMessage message={message} id="auth-choice-message" />
          ) : null}
          <button className="primary-action" type="submit" disabled={pending}>
            Continuar
          </button>
        </form>
      ) : null}

      {step === "sign-in-cpf" ? (
        <form className="auth-form" onSubmit={continueWithCpf}>
          <div className="auth-step-heading">
            <p className="step-indicator">Etapa 1 de 2</p>
            <h2>Informe seu CPF</h2>
          </div>
          <label className="form-field" htmlFor="signin-cpf">
            <span>CPF</span>
            <input
              id="signin-cpf"
              name="cpf"
              type="text"
              inputMode="numeric"
              autoComplete="off"
              maxLength={14}
              placeholder="000.000.000-00"
              aria-describedby={
                message
                  ? "signin-cpf-message signin-cpf-hint"
                  : "signin-cpf-hint"
              }
              aria-invalid={message?.kind === "error"}
              ref={cpfInputRef}
              value={cpf}
              onKeyDown={handleCpfKeyDown}
              onChange={handleCpfChange}
              required
            />
            <span className="field-hint" id="signin-cpf-hint">
              Digite os 11 números. Os pontos e o hífen são inseridos automaticamente.
            </span>
          </label>
          {message ? (
            <FormMessage message={message} id="signin-cpf-message" />
          ) : null}
          {pending ? <SubmitPendingMessage /> : null}
          <button className="primary-action" type="submit" disabled={pending}>
            Continuar
          </button>
          <button
            className="secondary-action"
            type="button"
            onClick={() => goBack("choice")}
            disabled={pending}
          >
            Voltar
          </button>
        </form>
      ) : null}

      {step === "sign-in-password" ? (
        <form className="auth-form" onSubmit={submitSignIn}>
          <div className="auth-step-heading">
            <p className="step-indicator">Etapa 2 de 2</p>
            <h2>Digite sua senha</h2>
          </div>
          <input type="hidden" name="cpf" value={cpf} />
          <input type="hidden" name="returnTo" value={returnTo} />
          <label className="form-field" htmlFor="signin-password">
            <span>Senha</span>
            <input
              id="signin-password"
              name="password"
              type={passwordVisible ? "text" : "password"}
              autoComplete="current-password"
              aria-describedby={message ? "signin-password-message" : undefined}
              aria-invalid={message?.kind === "error"}
              value={password}
              onChange={(event) => setPassword(event.currentTarget.value)}
              required
            />
          </label>
          <button
            className="secondary-action"
            type="button"
            aria-pressed={passwordVisible}
            onClick={() => setPasswordVisible((visible) => !visible)}
          >
            {passwordVisible ? "Ocultar senha" : "Mostrar senha"}
          </button>
          {message ? (
            <FormMessage message={message} id="signin-password-message" />
          ) : null}
          {pending ? <SubmitPendingMessage /> : null}
          <button className="primary-action" type="submit" disabled={pending}>
            Entrar
          </button>
          <button
            className="secondary-action"
            type="button"
            onClick={() => goBack("sign-in-cpf")}
            disabled={pending}
          >
            Voltar
          </button>
        </form>
      ) : null}

      {step === "signup" && privacyNotice ? (
        <form className="auth-form" onSubmit={submitSignup}>
          <div className="auth-step-heading">
            <p className="step-indicator">Etapa 1 de 2</p>
            <h2>Crie seu cadastro</h2>
          </div>
          <label className="form-field" htmlFor="signup-name">
            <span>Nome completo</span>
            <input
              id="signup-name"
              name="name"
              type="text"
              autoComplete="name"
              aria-describedby={message ? "signup-message" : undefined}
              aria-invalid={message?.kind === "error"}
              value={name}
              onChange={(event) => setName(event.currentTarget.value)}
              required
            />
          </label>
          <label className="form-field" htmlFor="signup-cpf">
            <span>CPF</span>
            <input
              id="signup-cpf"
              name="cpf"
              type="text"
              inputMode="numeric"
              autoComplete="off"
              maxLength={14}
              placeholder="000.000.000-00"
              aria-describedby={
                message
                  ? "signup-message signup-cpf-hint"
                  : "signup-cpf-hint"
              }
              aria-invalid={message?.kind === "error"}
              ref={cpfInputRef}
              value={cpf}
              onKeyDown={handleCpfKeyDown}
              onChange={handleCpfChange}
              required
            />
            <span className="field-hint" id="signup-cpf-hint">
              Digite os 11 números. Os pontos e o hífen são inseridos automaticamente.
            </span>
          </label>
          <label className="form-field" htmlFor="signup-phone">
            <span>Telefone com código do país</span>
            <input
              id="signup-phone"
              name="phone"
              type="tel"
              inputMode="tel"
              autoComplete="tel"
              maxLength={32}
              aria-describedby={
                message
                  ? "signup-message signup-phone-hint"
                  : "signup-phone-hint"
              }
              aria-invalid={message?.kind === "error"}
              ref={phoneInputRef}
              value={phone}
              onKeyDown={handlePhoneKeyDown}
              onChange={handlePhoneChange}
              required
            />
            <span className="field-hint" id="signup-phone-hint">
              Digite 55, o DDD e o número. O +, os parênteses e o hífen são inseridos automaticamente.
            </span>
          </label>
          <label className="form-field" htmlFor="signup-password">
            <span>Crie uma senha com pelo menos oito caracteres</span>
            <input
              id="signup-password"
              name="password"
              type={passwordVisible ? "text" : "password"}
              autoComplete="new-password"
              minLength={8}
              aria-describedby={message ? "signup-message" : undefined}
              aria-invalid={message?.kind === "error"}
              value={password}
              onChange={(event) => setPassword(event.currentTarget.value)}
              required
            />
          </label>
          <button
            className="secondary-action"
            type="button"
            aria-pressed={passwordVisible}
            onClick={() => setPasswordVisible((visible) => !visible)}
          >
            {passwordVisible ? "Ocultar senha" : "Mostrar senha"}
          </button>
          <section className="privacy-notice" aria-labelledby="privacy-notice-heading">
            <h3 id="privacy-notice-heading">Aviso de privacidade</h3>
            <p className="body-copy">{privacyNotice.text}</p>
            <p className="notice-version">Versão: {privacyNotice.version}</p>
          </section>
          <label className="consent-option" htmlFor="privacy-accepted">
            <input
              id="privacy-accepted"
              name="privacyAccepted"
              type="checkbox"
              value="true"
              checked={privacyAccepted}
              aria-describedby={message ? "signup-message" : undefined}
              aria-invalid={message?.kind === "error"}
              onChange={(event) => setPrivacyAccepted(event.currentTarget.checked)}
              required
            />
            <span>Li e aceito o aviso de privacidade.</span>
          </label>
          {message ? (
            <FormMessage message={message} id="signup-message" />
          ) : null}
          {pending ? <SubmitPendingMessage /> : null}
          <button className="primary-action" type="submit" disabled={pending}>
            Enviar código
          </button>
          <button
            className="secondary-action"
            type="button"
            onClick={() => goBack("choice")}
            disabled={pending}
          >
            Voltar
          </button>
        </form>
      ) : null}

      {step === "otp" ? (
        <form className="auth-form" onSubmit={submitOtp}>
          <div className="auth-step-heading">
            <p className="step-indicator">Etapa 2 de 2</p>
            <h2>Confirme seu telefone</h2>
            <p className="body-copy">
              Digite o código enviado para o telefone terminado em {maskPhone(phone)}.
            </p>
          </div>
          <input type="hidden" name="name" value={name} />
          <input type="hidden" name="cpf" value={cpf} />
          <input type="hidden" name="phone" value={phone} />
          <input type="hidden" name="acceptedVersion" value={acceptedVersion} />
          <input
            type="hidden"
            name="privacyAccepted"
            value={privacyAccepted ? "true" : "false"}
          />
          <input type="hidden" name="returnTo" value={returnTo} />
          <label className="form-field" htmlFor="signup-token">
            <span>Código de confirmação</span>
            <input
              id="signup-token"
              name="token"
              type="text"
              inputMode="numeric"
              autoComplete="one-time-code"
              maxLength={32}
              pattern="[0-9]{1,32}"
              aria-describedby={message ? "otp-message" : undefined}
              aria-invalid={message?.kind === "error"}
              value={token}
              onChange={(event) => setToken(event.currentTarget.value)}
              required
            />
          </label>
          {message ? (
            <FormMessage message={message} id="otp-message" />
          ) : null}
          {pending ? <SubmitPendingMessage /> : null}
          <button className="primary-action" type="submit" disabled={pending}>
            Confirmar telefone
          </button>
          <button
            className="secondary-action"
            type="button"
            onClick={() => goBack("signup")}
            disabled={pending}
          >
            Voltar
          </button>
        </form>
      ) : null}
    </section>
  );
}
