import Link from "next/link";
import { Suspense, type ReactNode } from "react";
import { redirect } from "next/navigation";
import { PublicLayout } from "../../_components/public-layout";
import { AdminContactsManager } from "../_components/admin-contacts-manager";
import { AdminNavigation } from "../_components/admin-navigation";
import { getAdminContactsPageData } from "../../../lib/contacts/admin-server";

export const instant = false;

export default function AdminContactsPage({
  searchParams,
}: PageProps<"/admin/contatos">) {
  return (
    <Suspense fallback={<AdminContactsLoadingPage />}>
      <AdminContactsData searchParams={searchParams} />
    </Suspense>
  );
}

async function AdminContactsData({
  searchParams,
}: {
  searchParams: PageProps<"/admin/contatos">["searchParams"];
}) {
  const params = await searchParams;
  const rawCode = params.code;
  const searchCode =
    rawCode === undefined ? null : typeof rawCode === "string" ? rawCode : "";
  const result = await getAdminContactsPageData(searchCode);

  if (result.kind === "unauthenticated") redirect("/admin/entrar");

  if (result.kind === "forbidden") {
    return (
      <AdminContactsLayout
        title="Pedidos de contato"
        introduction="Acompanhe os pedidos de contato destinados ao seu banco."
      >
        <div
          className="remote-state admin-contacts-state"
          role="status"
          aria-live="polite"
        >
          <p className="body-copy">
            Você não tem permissão para acessar os pedidos deste banco.
          </p>
          <Link className="secondary-action" href="/admin/entrar">
            Voltar à entrada
          </Link>
        </div>
      </AdminContactsLayout>
    );
  }

  if (result.kind === "error") {
    return (
      <AdminContactsLayout
        title="Pedidos de contato"
        introduction="Acompanhe os pedidos de contato destinados ao seu banco."
      >
        <div
          className="remote-state admin-contacts-state error-state"
          role="alert"
          aria-live="assertive"
        >
          <p className="body-copy">
            Não foi possível carregar os pedidos. Tente novamente.
          </p>
          <Link className="secondary-action" href={retryHref(searchCode)}>
            Tentar novamente
          </Link>
        </div>
      </AdminContactsLayout>
    );
  }

  return (
    <AdminContactsLayout
      eyebrow="Painel do banco"
      title={`Pedidos de ${result.bankName}`}
      introduction="Pesquise pelo código que veio na mensagem ou acompanhe a situação de cada pedido."
    >
      <AdminContactsManager
        key={result.searchCode ?? "todos-os-pedidos"}
        contacts={result.contacts}
        searchCode={result.searchCode}
      />
    </AdminContactsLayout>
  );
}

function AdminContactsLayout({
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
      headerNavigation={<AdminNavigation current="/admin/contatos" />}
      introduction={introduction}
      title={title}
    >
      {children}
    </PublicLayout>
  );
}

function AdminContactsLoadingPage() {
  return (
    <AdminContactsLayout
      title="Pedidos de contato"
      introduction="Acompanhe os pedidos de contato destinados ao seu banco."
    >
      <div className="remote-state" role="status" aria-live="polite">
        <span className="loading-indicator" aria-hidden="true" />
        <p className="body-copy">Carregando os pedidos...</p>
      </div>
    </AdminContactsLayout>
  );
}

function retryHref(searchCode: string | null): string {
  if (searchCode === null) return "/admin/contatos";
  if (searchCode.length > 12) return "/admin/contatos";
  return `/admin/contatos?code=${encodeURIComponent(searchCode)}`;
}
