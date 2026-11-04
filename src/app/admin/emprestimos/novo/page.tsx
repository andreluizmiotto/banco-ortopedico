import Link from "next/link";
import { Suspense, type ReactNode } from "react";
import { redirect } from "next/navigation";
import { PublicLayout } from "../../../_components/public-layout";
import { AdminLoanWizard } from "../../_components/admin-loan-wizard";
import { AdminNavigation } from "../../_components/admin-navigation";
import { getAdminLoanFormData } from "../../../../lib/loans/admin-server";

export const instant = false;

export default function AdminNewLoanPage() {
  return (
    <Suspense fallback={<AdminNewLoanLoadingPage />}>
      <AdminNewLoanData />
    </Suspense>
  );
}

async function AdminNewLoanData() {
  const result = await getAdminLoanFormData();

  if (result.kind === "unauthenticated") redirect("/admin/entrar");

  if (result.kind === "forbidden") {
    return (
      <AdminNewLoanLayout
        title="Registrar empréstimo"
        introduction="Registre a saída dos equipamentos do seu banco."
      >
        <div className="remote-state loan-state" role="status" aria-live="polite">
          <p className="body-copy">
            Você não tem permissão para registrar empréstimos neste banco.
          </p>
          <Link className="secondary-action" href="/admin/entrar">
            Voltar à entrada
          </Link>
        </div>
      </AdminNewLoanLayout>
    );
  }

  if (result.kind === "error") {
    return (
      <AdminNewLoanLayout
        title="Registrar empréstimo"
        introduction="Registre a saída dos equipamentos do seu banco."
      >
        <div
          className="remote-state loan-state error-state"
          role="alert"
          aria-live="assertive"
        >
          <p className="body-copy">
            Não foi possível carregar os equipamentos. Tente novamente.
          </p>
          <Link className="secondary-action" href="/admin/emprestimos/novo">
            Tentar novamente
          </Link>
        </div>
      </AdminNewLoanLayout>
    );
  }

  return (
    <AdminNewLoanLayout
      eyebrow="Painel do banco"
      title={`Novo empréstimo — ${result.bankName}`}
      introduction="Localize a pessoa, escolha os equipamentos e confira o prazo antes de salvar."
    >
      <AdminLoanWizard
        bankName={result.bankName}
        suggestedDays={result.suggestedDays}
        units={result.units}
      />
    </AdminNewLoanLayout>
  );
}

function AdminNewLoanLayout({
  title,
  introduction,
  eyebrow,
  children,
}: {
  title: string;
  introduction: string;
  eyebrow?: string;
  children: ReactNode;
}) {
  return (
    <PublicLayout
      backLink={{ href: "/admin/emprestimos", label: "Voltar para empréstimos" }}
      eyebrow={eyebrow ?? "Gestão do banco"}
      footerNote={null}
      headerNavigation={<AdminNavigation current="/admin/emprestimos" />}
      introduction={introduction}
      title={title}
    >
      {children}
    </PublicLayout>
  );
}

function AdminNewLoanLoadingPage() {
  return (
    <AdminNewLoanLayout
      title="Registrar empréstimo"
      introduction="Aguarde enquanto carregamos os equipamentos disponíveis."
    >
      <div className="remote-state" role="status" aria-live="polite">
        <span className="loading-indicator" aria-hidden="true" />
        <p className="body-copy">Carregando os equipamentos...</p>
      </div>
    </AdminNewLoanLayout>
  );
}
