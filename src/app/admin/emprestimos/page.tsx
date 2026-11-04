import Link from "next/link";
import { Suspense, type ReactNode } from "react";
import { redirect } from "next/navigation";
import { PublicLayout } from "../../_components/public-layout";
import { AdminNavigation } from "../_components/admin-navigation";
import { getAdminLoansPageData } from "../../../lib/loans/admin-server";

export const instant = false;

export default function AdminLoansPage() {
  return (
    <Suspense fallback={<AdminLoansLoadingPage />}>
      <AdminLoansData />
    </Suspense>
  );
}

async function AdminLoansData() {
  const result = await getAdminLoansPageData();

  if (result.kind === "unauthenticated") redirect("/admin/entrar");

  if (result.kind === "forbidden") {
    return (
      <AdminLoansLayout
        title="Empréstimos"
        introduction="Registre a saída dos equipamentos do seu banco."
      >
        <div className="remote-state loan-state" role="status" aria-live="polite">
          <p className="body-copy">
            Você não tem permissão para acessar os empréstimos deste banco.
          </p>
          <Link className="secondary-action" href="/admin/entrar">
            Voltar à entrada
          </Link>
        </div>
      </AdminLoansLayout>
    );
  }

  if (result.kind === "error") {
    return (
      <AdminLoansLayout
        title="Empréstimos"
        introduction="Registre a saída dos equipamentos do seu banco."
      >
        <div
          className="remote-state loan-state error-state"
          role="alert"
          aria-live="assertive"
        >
          <p className="body-copy">
            Não foi possível carregar os empréstimos. Tente novamente.
          </p>
          <Link className="secondary-action" href="/admin/emprestimos">
            Tentar novamente
          </Link>
        </div>
      </AdminLoansLayout>
    );
  }

  return (
    <AdminLoansLayout
      eyebrow="Painel do banco"
      title={`Empréstimos de ${result.bankName}`}
      introduction="Registre a saída dos equipamentos e acompanhe o que está aguardando retirada."
    >
      <div className="loan-panel">
        <Link className="primary-action" href="/admin/emprestimos/novo">
          Registrar empréstimo
        </Link>

        {result.loans.length === 0 ? (
          <div className="loan-empty">
            <h2>Nenhum empréstimo aguardando retirada</h2>
            <p className="body-copy">
              Quando você registrar um empréstimo, ele aparece aqui até a entrega
              ser confirmada ou o empréstimo ser cancelado.
            </p>
          </div>
        ) : (
          <section aria-labelledby="loan-list-heading">
            <h2 id="loan-list-heading" className="loan-section-heading">
              Aguardando retirada
            </h2>
            <ul className="loan-list">
              {result.loans.map((loan) => (
                <li key={loan.publicCode} className="loan-list-item">
                  <Link
                    className="loan-list-link"
                    href={`/admin/emprestimos/${loan.publicCode}`}
                  >
                    <span className="loan-list-name">{loan.borrowerName}</span>
                    <span className="loan-list-meta">
                      {loan.unitCount === 1
                        ? "1 equipamento"
                        : `${loan.unitCount} equipamentos`}
                      {" · "}
                      {formatDate(loan.createdAt)}
                    </span>
                    <span className="loan-list-code">
                      Código {loan.publicCode}
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        )}
      </div>
    </AdminLoansLayout>
  );
}

function AdminLoansLayout({
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

function AdminLoansLoadingPage() {
  return (
    <AdminLoansLayout
      title="Empréstimos"
      introduction="Aguarde enquanto carregamos os empréstimos do seu banco."
    >
      <div className="remote-state" role="status" aria-live="polite">
        <span className="loading-indicator" aria-hidden="true" />
        <p className="body-copy">Carregando os empréstimos...</p>
      </div>
    </AdminLoansLayout>
  );
}

function formatDate(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return new Intl.DateTimeFormat("pt-BR", { dateStyle: "short" }).format(date);
}
