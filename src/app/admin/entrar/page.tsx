import { Suspense } from "react";
import { redirect } from "next/navigation";
import { PublicLayout } from "../../_components/public-layout";
import { AdminSignInForm } from "../_components/admin-sign-in-form";
import { getAdminBankContext } from "../../../lib/auth/admin-bank";

export default function AdminEnterPage() {
  return (
    <Suspense fallback={<AdminEnterLoading />}>
      <ResolvedAdminEnterPage />
    </Suspense>
  );
}

async function ResolvedAdminEnterPage() {
  const context = await getAdminBankContext();
  if (context) redirect("/admin/contatos");

  return (
    <PublicLayout
      title="Entrar no painel do banco"
      eyebrow="Acesso administrativo"
      introduction="Use o e-mail e a senha da conta administrativa do seu banco."
      footerNote={null}
    >
      <AdminSignInForm />
    </PublicLayout>
  );
}

function AdminEnterLoading() {
  return (
    <PublicLayout
      title="Entrar no painel do banco"
      eyebrow="Acesso administrativo"
      introduction="Aguarde enquanto verificamos o acesso."
      footerNote={null}
    >
      <div className="remote-state" role="status" aria-live="polite">
        <span className="loading-indicator" aria-hidden="true" />
        <p className="body-copy">Aguarde...</p>
      </div>
    </PublicLayout>
  );
}
