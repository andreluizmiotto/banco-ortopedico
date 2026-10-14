import { Suspense } from "react";
import { headers } from "next/headers";
import { AuthFlow } from "../_components/auth-flow";
import { PublicLayout } from "../_components/public-layout";
import { getCommunityPrivacyNotice } from "../../lib/auth/privacy-notice";
import { sanitizeReturnTo } from "../../lib/auth/return-to";

export default function EnterPage() {
  return (
    <Suspense fallback={<EnterLoading />}>
      <ResolvedEnterPage />
    </Suspense>
  );
}

async function ResolvedEnterPage() {
  const requestHeaders = await headers();
  const referer = requestHeaders.get("referer");
  const requestHost = (
    requestHeaders.get("x-forwarded-host") ?? requestHeaders.get("host") ?? ""
  )
    .split(",", 1)[0]
    .trim();

  let returnTo = "/";
  if (referer && requestHost) {
    try {
      const refererUrl = new URL(referer);
      if (refererUrl.host.toLowerCase() === requestHost.toLowerCase()) {
        returnTo = sanitizeReturnTo(refererUrl.pathname);
      }
    } catch {
      returnTo = "/";
    }
  }

  const privacyNotice = getCommunityPrivacyNotice();

  return (
    <PublicLayout
      title="Entrar ou criar cadastro"
      eyebrow="Acesso da Comunidade"
      introduction="Entre para conversar com um banco ou crie seu cadastro da Comunidade."
      backLink={{
        href: returnTo,
        label:
          returnTo === "/"
            ? "Voltar para os equipamentos"
            : "Voltar para o equipamento",
      }}
      footerNote={null}
    >
      <AuthFlow returnTo={returnTo} privacyNotice={privacyNotice} />
    </PublicLayout>
  );
}

function EnterLoading() {
  return (
    <PublicLayout
      title="Entrar ou criar cadastro"
      eyebrow="Acesso da Comunidade"
      introduction="Carregando as opções para entrar ou criar cadastro."
      footerNote={null}
    >
      <div className="remote-state" role="status" aria-live="polite">
        <span className="loading-indicator" aria-hidden="true" />
        <p className="body-copy">Aguarde...</p>
      </div>
    </PublicLayout>
  );
}
