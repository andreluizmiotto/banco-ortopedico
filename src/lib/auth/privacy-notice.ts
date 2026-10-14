import "server-only";

export type CommunityPrivacyNotice = {
  version: string;
  text: string;
};

const localSyntheticNotice: CommunityPrivacyNotice = {
  version: "local-synthetic-v1",
  text: "Este aviso e sintetico e serve somente para testes locais. Nao use dados reais. O aviso definitivo precisa ser aprovado antes de qualquer cadastro real.",
};

export function getCommunityPrivacyNotice(): CommunityPrivacyNotice | null {
  if (process.env.NODE_ENV !== "production") return localSyntheticNotice;

  if (process.env.COMMUNITY_PRIVACY_NOTICE_APPROVED !== "true") return null;

  const version = process.env.COMMUNITY_PRIVACY_NOTICE_VERSION?.trim();
  const text = process.env.COMMUNITY_PRIVACY_NOTICE_TEXT?.trim();

  if (!version || !text) return null;

  return { version, text };
}
