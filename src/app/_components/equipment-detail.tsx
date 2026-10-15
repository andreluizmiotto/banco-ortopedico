import Link from "next/link";
import type { BankAvailability, EquipmentType } from "../../lib/availability";
import { orderAvailability } from "../../lib/availability";
import { readEquipmentAvailability, readEquipmentType } from "../../lib/public-supabase";
import { readCommunityContactMethods } from "../../lib/contacts/server";
import { CommunityContactAction, RefreshButton } from "./community-contact-action";
import { PublicLayout } from "./public-layout";

function BankCard({
  bank,
  equipmentTypeCode,
  contactMethod,
}: {
  bank: BankAvailability;
  equipmentTypeCode: string;
  contactMethod?:
    | { kind: "ready"; method: "whatsapp" | "telephone" | "unavailable" }
    | { kind: "error" };
}) {
  return (
    <article className="bank-card">
      <div className="bank-card-heading">
        <h2 className="bank-name">{bank.bank_name}</h2>
        <span
          className="availability-count"
          aria-label={`Quantidade disponível: ${bank.available_quantity}`}
        >
          {bank.available_quantity}
        </span>
      </div>
      {bank.available_quantity > 0 ? (
        <p className="availability-label">Disponível no depósito</p>
      ) : (
        <p className="availability-empty">Todos emprestados no momento</p>
      )}
      {contactMethod === undefined ? (
        <Link className="primary-action" href="/entrar">
          Entrar para conversar
        </Link>
      ) : contactMethod.kind === "error" ? (
        <div className="contact-action-state" role="alert">
          <p className="body-copy">
            Não foi possível carregar a opção de contato. Tente novamente.
          </p>
          <RefreshButton />
        </div>
      ) : contactMethod.method === "unavailable" ? (
        <p className="contact-unavailable body-copy">
          O contato não está disponível neste momento.
        </p>
      ) : (
        <CommunityContactAction
          bankName={bank.bank_name}
          equipmentTypeCode={equipmentTypeCode}
          method={contactMethod.method}
        />
      )}
    </article>
  );
}

export async function EquipmentDetail({ code }: { code: string }) {
  let equipment: EquipmentType | null;
  let banks: BankAvailability[];

  try {
    equipment = await readEquipmentType(code);
    if (!equipment) {
      return (
        <PublicLayout
          title="Disponibilidade por banco"
          introduction="Veja a quantidade disponível em cada banco mantenedor."
          backLink={{ href: "/", label: "Voltar para os equipamentos" }}
        >
          <p className="empty-state body-copy">
            Equipamento não encontrado. Volte para a lista de equipamentos.
          </p>
        </PublicLayout>
      );
    }

    banks = orderAvailability(await readEquipmentAvailability(equipment.code));
  } catch {
    return (
      <PublicLayout
        title="Disponibilidade por banco"
        introduction="Veja a quantidade disponível em cada banco mantenedor."
        backLink={{ href: "/", label: "Voltar para os equipamentos" }}
      >
        <div className="remote-state error-state" role="alert">
          <p className="body-copy">
            Não foi possível carregar a disponibilidade. Tente novamente.
          </p>
          <RefreshButton />
        </div>
      </PublicLayout>
    );
  }

  const contactAccess = await readCommunityContactMethods(
    equipment.code,
    banks.map((bank) => bank.bank_name),
  );

  return (
    <PublicLayout
      title={equipment.name}
      introduction="Veja a quantidade disponível em cada banco mantenedor."
      backLink={{ href: "/", label: "Voltar para os equipamentos" }}
    >
      {banks.length === 0 ? (
        <p className="empty-state body-copy">
          Nenhum banco cadastrou este tipo de equipamento.
        </p>
      ) : (
        <ul className="bank-list">
          {banks.map((bank) => (
            <li key={bank.bank_name}>
              <BankCard
                bank={bank}
                equipmentTypeCode={equipment.code}
                contactMethod={
                  contactAccess.kind === "community"
                    ? contactAccess.methods[bank.bank_name] ?? { kind: "error" }
                    : contactAccess.kind === "error"
                      ? { kind: "error" }
                      : undefined
                }
              />
            </li>
          ))}
        </ul>
      )}
    </PublicLayout>
  );
}
