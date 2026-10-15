"use client";

import Link from "next/link";
import type { ReactNode } from "react";

type PublicLayoutProps = {
  title: string;
  introduction: string;
  eyebrow?: string;
  backLink?: { href: string; label: string };
  footerNote?: string | null;
  children: ReactNode;
};

export function PublicLayout({
  title,
  introduction,
  eyebrow = "Consulta pública",
  backLink,
  footerNote = "A disponibilidade é atualizada a partir do acervo de cada banco.",
  children,
}: PublicLayoutProps) {
  return (
    <div className="public-page">
      <a className="skip-link" href="#conteudo-principal">
        Ir para o conteúdo
      </a>
      <div className="page-frame">
        <header className="public-header">
          <Link className="brand-link" href="/">
            <span className="brand-mark" aria-hidden="true" />
            <span>Banco Ortopédico</span>
          </Link>
          <p className="brand-note">Acervo comunitário</p>
        </header>
        <main id="conteudo-principal">
          {backLink ? (
            <Link className="back-link" href={backLink.href}>
              {backLink.label}
            </Link>
          ) : null}
          <div className="page-heading">
            <p className="eyebrow">{eyebrow}</p>
            <h1>{title}</h1>
            <p className="body-copy">{introduction}</p>
          </div>
          <div className="page-content">{children}</div>
        </main>
        {footerNote ? (
          <footer className="public-footer">
            <p className="body-copy">{footerNote}</p>
          </footer>
        ) : null}
      </div>
    </div>
  );
}
