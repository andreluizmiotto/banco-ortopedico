import Link from "next/link";
import { Suspense, type ReactNode } from "react";
import { redirect } from "next/navigation";
import { PublicLayout } from "../../_components/public-layout";
import { AdminAcervoManager } from "../_components/admin-acervo-manager";
import { AdminNavigation } from "../_components/admin-navigation";
import { getAdminAcervoPageData } from "../../../lib/acervo/admin-server";

export const instant = false;

export default function AdminAcervoPage() {
  return (
    <Suspense fallback={<AdminAcervoLoadingPage />}>
      <AdminAcervoData />
    </Suspense>
  );
}

async function AdminAcervoData() {
  const result = await getAdminAcervoPageData();

  if (result.kind === "unauthenticated") redirect("/admin/entrar");

  if (result.kind === "forbidden") {
    return (
      <AdminAcervoLayout
        title="Acervo de equipamentos"
        introduction="Acompanhe os equipamentos do seu banco."
      >
        <div
          className="remote-state admin-acervo-state"
          role="status"
          aria-live="polite"
        >
          <p className="body-copy">
            Você não tem permissão para acessar o acervo deste banco.
          </p>
          <Link className="secondary-action" href="/admin/entrar">
            Voltar à entrada
          </Link>
        </div>
      </AdminAcervoLayout>
    );
  }

  if (result.kind === "error") {
    return (
      <AdminAcervoLayout
        title="Acervo de equipamentos"
        introduction="Acompanhe os equipamentos do seu banco."
      >
        <div
          className="remote-state admin-acervo-state error-state"
          role="alert"
          aria-live="assertive"
        >
          <p className="body-copy">
            Não foi possível carregar o acervo. Tente novamente.
          </p>
          <Link className="secondary-action" href="/admin/acervo">
            Tentar novamente
          </Link>
        </div>
      </AdminAcervoLayout>
    );
  }

  return (
    <AdminAcervoLayout
      eyebrow="Painel do banco"
      title={`Acervo de ${result.bankName}`}
      introduction="Confira a situação de cada equipamento e corrija o que a conferência encontrar."
    >
      <AdminAcervoManager
        bankName={result.bankName}
        locations={result.locations}
        types={result.types}
        units={result.units}
      />
    </AdminAcervoLayout>
  );
}

function AdminAcervoLayout({
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
      headerNavigation={<AdminNavigation current="/admin/acervo" />}
      introduction={introduction}
      title={title}
    >
      {children}
    </PublicLayout>
  );
}

function AdminAcervoLoadingPage() {
  return (
    <AdminAcervoLayout
      title="Acervo de equipamentos"
      introduction="Aguarde enquanto carregamos o acervo do seu banco."
    >
      <div className="remote-state" role="status" aria-live="polite">
        <span className="loading-indicator" aria-hidden="true" />
        <p className="body-copy">Carregando o acervo...</p>
      </div>
    </AdminAcervoLayout>
  );
}
