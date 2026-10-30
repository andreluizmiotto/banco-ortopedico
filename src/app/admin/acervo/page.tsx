import Link from "next/link";
import { Suspense, type ReactNode } from "react";
import { redirect } from "next/navigation";
import { PublicLayout } from "../../_components/public-layout";
import { AdminInventoryManager } from "../_components/admin-inventory-manager";
import { AdminNavigation } from "../_components/admin-navigation";
import { getAdminInventoryPageData } from "../../../lib/inventory/admin-server";

export const instant = false;

export default function AdminInventoryPage() {
  return (
    <Suspense fallback={<AdminInventoryLoadingPage />}>
      <AdminInventoryData />
    </Suspense>
  );
}

async function AdminInventoryData() {
  const result = await getAdminInventoryPageData();

  if (result.kind === "unauthenticated") redirect("/admin/entrar");

  if (result.kind === "forbidden") {
    return (
      <AdminInventoryLayout
        title="Equipamentos do banco"
        introduction="Acompanhe os equipamentos do seu banco."
      >
        <div
          className="remote-state admin-inventory-state"
          role="status"
          aria-live="polite"
        >
          <p className="body-copy">
            Você não tem permissão para acessar os equipamentos deste banco.
          </p>
          <Link className="secondary-action" href="/admin/entrar">
            Voltar à entrada
          </Link>
        </div>
      </AdminInventoryLayout>
    );
  }

  if (result.kind === "error") {
    return (
      <AdminInventoryLayout
        title="Equipamentos do banco"
        introduction="Acompanhe os equipamentos do seu banco."
      >
        <div
          className="remote-state admin-inventory-state error-state"
          role="alert"
          aria-live="assertive"
        >
          <p className="body-copy">
            Não foi possível carregar os equipamentos. Tente novamente.
          </p>
          <Link className="secondary-action" href="/admin/acervo">
            Tentar novamente
          </Link>
        </div>
      </AdminInventoryLayout>
    );
  }

  return (
    <AdminInventoryLayout
      eyebrow="Painel do banco"
      title={`Equipamentos de ${result.bankName}`}
      introduction="Confira a situação de cada equipamento e corrija o que a conferência encontrar."
    >
      <AdminInventoryManager
        bankName={result.bankName}
        locations={result.locations}
        types={result.types}
        units={result.units}
      />
    </AdminInventoryLayout>
  );
}

function AdminInventoryLayout({
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

function AdminInventoryLoadingPage() {
  return (
    <AdminInventoryLayout
      title="Equipamentos do banco"
      introduction="Aguarde enquanto carregamos os equipamentos do seu banco."
    >
      <div className="remote-state" role="status" aria-live="polite">
        <span className="loading-indicator" aria-hidden="true" />
        <p className="body-copy">Carregando os equipamentos...</p>
      </div>
    </AdminInventoryLayout>
  );
}
