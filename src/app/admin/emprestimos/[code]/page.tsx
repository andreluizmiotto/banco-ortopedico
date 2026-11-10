import Link from "next/link";
import { Suspense, type ReactNode } from "react";
import { redirect } from "next/navigation";
import { PublicLayout } from "../../../_components/public-layout";
import { AdminLoanDraft } from "../../_components/admin-loan-draft";
import { AdminNavigation } from "../../_components/admin-navigation";
import { getAdminLoanDetail } from "../../../../lib/loans/admin-server";

export const instant = false;

type PageParameters = {
  params: Promise<{ code: string }>;
};

export default function AdminLoanPage({ params }: PageParameters) {
  return (
    <Suspense fallback={<AdminLoanLoadingPage />}>
      <AdminLoanData params={params} />
    </Suspense>
  );
}

async function AdminLoanData({ params }: PageParameters) {
  const { code } = await params;
  const result = await getAdminLoanDetail(code);

  if (result.kind === "unauthenticated") redirect("/admin/entrar");

  if (result.kind === "forbidden") {
    return (
      <AdminLoanLayout
        title="Empréstimo"
        introduction="Acompanhe o empréstimo do seu banco."
      >
        <div className="remote-state loan-state" role="status" aria-live="polite">
          <p className="body-copy">
            Você não tem permissão para acessar os empréstimos deste banco.
          </p>
          <Link className="secondary-action" href="/admin/entrar">
            Voltar à entrada
          </Link>
        </div>
      </AdminLoanLayout>
    );
  }

  if (result.kind === "notFound") {
    return (
      <AdminLoanLayout
        title="Empréstimo"
        introduction="Acompanhe o empréstimo do seu banco."
      >
        <div className="remote-state loan-state" role="status" aria-live="polite">
          <p className="body-copy">Empréstimo não encontrado neste banco.</p>
          <Link className="secondary-action" href="/admin/emprestimos">
            Voltar para empréstimos
          </Link>
        </div>
      </AdminLoanLayout>
    );
  }

  if (result.kind === "error") {
    return (
      <AdminLoanLayout
        title="Empréstimo"
        introduction="Acompanhe o empréstimo do seu banco."
      >
        <div
          className="remote-state loan-state error-state"
          role="alert"
          aria-live="assertive"
        >
          <p className="body-copy">
            Não foi possível carregar o empréstimo. Tente novamente.
          </p>
          <Link
            className="secondary-action"
            href={`/admin/emprestimos/${code}`}
          >
            Tentar novamente
          </Link>
        </div>
      </AdminLoanLayout>
    );
  }

  return (
    <AdminLoanLayout
      backLink={{ href: "/admin/emprestimos", label: "Voltar para empréstimos" }}
      eyebrow="Painel do banco"
      title={`Empréstimo ${result.loan.publicCode}`}
      introduction={
        result.loan.status === "draft"
          ? "Confira os dados, gere o termo e conclua a entrega."
          : "Confira os dados registrados neste empréstimo."
      }
    >
      <AdminLoanDraft loan={result.loan} />
    </AdminLoanLayout>
  );
}

function AdminLoanLayout({
  title,
  introduction,
  eyebrow,
  backLink,
  children,
}: {
  title: string;
  introduction: string;
  eyebrow?: string;
  backLink?: { href: string; label: string };
  children: ReactNode;
}) {
  return (
    <PublicLayout
      backLink={backLink}
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

function AdminLoanLoadingPage() {
  return (
    <AdminLoanLayout
      title="Empréstimo"
      introduction="Aguarde enquanto carregamos o empréstimo."
    >
      <div className="remote-state" role="status" aria-live="polite">
        <span className="loading-indicator" aria-hidden="true" />
        <p className="body-copy">Carregando o empréstimo...</p>
      </div>
    </AdminLoanLayout>
  );
}
