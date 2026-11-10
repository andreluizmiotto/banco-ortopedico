# Handoff — próxima etapa: devolução de equipamentos (FR-022)

Prompt pronto para colar numa sessão nova. Ele assume o repositório
`/Users/miotto/Projects/banco-ortopedico`, branch `feature/equipment-loan`.

---

## Prompt

Você vai conduzir a próxima fatia do Banco Ortopédico: **devolução de equipamentos
(FR-022)**, pelo fluxo do skill `tlc-spec-lean` (plano aprovado → checks → build →
Verifier independente → conferência visual humana → portão verde).

### Antes de qualquer coisa, leia

1. `AGENTS.md` — regras invioláveis de UI, acessibilidade, idioma e testes. Elas
   vencem qualquer preferência sua.
2. `.specs/STATE.md` — decisões `AD-001` a `AD-011`.
3. `.specs/features/emprestimo-equipamentos-fr-019-fr-020-fr-021-fr-034-fr-042-fr-031/`
   — `plan.md`, `checks.md`, `verification.md` e `proofs.md` da fatia anterior. É o
   modelo de forma e de rigor a repetir.
4. `docs/produto/requisitos.md` (FR-022 a FR-024, FR-031), `regras-de-negocio.md`
   (§4 situação, §9 documentos, §11 integridade), `criterios-de-aceite.md`
   (AC-010, AC-011, AC-012, AC-017, AC-019, AC-021, AC-022, AC-023 a AC-027),
   `documentos-gerados.md` (§3 bloco de devolução) e
   `docs/ux/acessibilidade-e-fluxos.md` §"Registrar devolução".
5. `.notebook/` — os fluxos já mapeados (admin-auth, acervo, contatos).

### O que já existe e não se refaz

- Autenticação de comunidade e de `bank_admin`, contatos e acervo.
- Empréstimo completo (FR-019/020/021/031/034/042): `catalog.loans`,
  `catalog.loan_lines`, `catalog.loan_documents`, `catalog.loan_event_audit`,
  `catalog.document_models`, role `admin_loan_manager`, bucket privado `loan-terms`,
  RPCs `admin_*` em `public`, telas `/admin/emprestimos`, `/admin/emprestimos/novo`,
  `/admin/emprestimos/[code]`, `/admin/emprestimos/[code]/termo`, PDF determinístico
  com `pdf-lib`.
- Portão da fatia anterior: 57 checks, 62 provas verdes, 3 mutações mortas,
  `verification.md` com veredito PASS. Use isso como régua.

### Escopo proposto (confirme com o usuário antes de planejar)

- Registrar devolução **total ou parcial** de um empréstimo `active`, escolhendo as
  peças que voltaram.
- Registrar, por peça, o estado na devolução e o destino: `available`,
  `under_maintenance` ou `written_off` (AC-011). `donated` é FR-023 e fica fora,
  salvo decisão explícita do usuário.
- Encerrar o empréstimo quando todas as peças voltarem; deixá-lo em situação
  parcial enquanto faltar peça (regras §11).
- Auditoria de cada mudança (FR-031) e isolamento por entidade (AC-017).
- Fora do recorte, salvo o usuário decidir diferente: FR-024 (lembretes,
  tentativas de contato, lista de devoluções previstas/vencidas), FR-023 (termo de
  doação), FR-027 (administração geral), estoque mínimo, painel do Companheiro, QR
  code, assinatura em tela, mensagem automática.

### Perguntas que o plano precisa fechar com o usuário

1. **De onde a devolução começa:** do detalhe do empréstimo
   (`/admin/emprestimos/[code]`) ou do acervo, clicando uma peça `on_loan`? O UX
   descreve as duas portas ("Emprestado" abre empréstimo, "Disponível para
   empréstimo" abre devolução) e elas podem conflitar.
2. **Situação do empréstimo:** hoje `catalog.loan_status` é
   `('draft','active','cancelled')`. A devolução parcial exige um estado próprio
   (regras §11 fala em `parcial`). Decidir se entra `partial` e `returned`, e como
   um empréstimo com peça pendente aparece na lista.
3. **Documento da devolução:** `documentos-gerados.md` prevê um "bloco de
   devolução" no modelo. Esta fatia gera comprovante de devolução (novo
   `document_type` versionado por entidade) ou só registra no sistema? É porta
   unidirecional: se gerar, precisa de modelo por entidade, bucket e hash.
4. **Quem registra:** só o `bank_admin` do banco dono do empréstimo? Devolução de
   peça emprestada por outro banco (FR-018 cita "devolução de outro banco" como
   origem de entrada) entra agora ou fica para depois?
5. **Peça que não volta:** o que acontece com `released_at`, com a linha e com a
   data de revisão quando o empréstimo é encerrado com peça `written_off`.
6. **Devolução x cancelamento:** um empréstimo `active` não pode ser cancelado hoje
   (`admin_cancel_loan_draft` só aceita `draft`). Confirmar que a devolução é o
   único caminho de saída de `active`.
7. **Auditoria:** nomes dos eventos (`loan_returned`, `loan_partially_returned`,
   `loan_closed`?) e o que cada um carrega.

### Regras técnicas que esta base já ensinou

- **Migrations rodam antes de `seed.sql`.** Dado de referência que depende de linha
  semeada (modelo de documento, por exemplo) mora em `seed.sql`, não na migration.
  O contrário já custou o bug corrigido em `ec70639`.
- **Fixtures não podem colidir com o seed:** CPF único em
  `catalog.community_profiles`, UUID único em `auth.users`. E teste não conta linha
  global: escope por `entity_id` da própria fixture (foi o defeito de
  `loan-draft.test.sql`, corrigido em `ec70639`).
- **RLS por papel de feature:** crie `admin_*_manager` `nologin noinherit
  nobypassrls`, dê `inherit` do checker, escreva as RPCs `security definer`
  `set search_path = ''` e `set row_security = on`, e revogue de
  `public, anon, authenticated, service_role` antes de conceder `execute` a
  `authenticated`. Toda tabela nova: `enable` + `force row level security` e
  `revoke all` das roles da Data API.
- **Prova por asserção:** cada check chama
  `bash scripts/loan-proof.sh <arquivo> --only C<id>`; o script exige
  `Result: PASS` do arquivo inteiro e a linha `ok ... - C<id>`. Nada de pipe dentro
  da célula de prova: `validate_verification.py` lê a tabela do `proofs.md` e um
  pipe a quebra.
- **Concorrência:** `dblink` não funciona no pgTAP (papel de teste não é
  superusuário); use um script com duas sessões `psql`, como
  `scripts/loans-concurrency-test.sh --only C23`.
- **Nomenclatura:** banco, código e API em inglês técnico (`public_code`, `status`,
  `available`, `on_loan`); tela em PT-BR cotidiano, sem "login", "dashboard",
  "status" ou "logout".
- **App:** páginas admin usam `export const instant = false` + `Suspense`; o
  redirect acontece durante o streaming, então só rota de arquivo devolve `307`.
  `AuthSessionMissingError` já é mapeado para `unauthenticated` em
  `src/lib/auth/admin-bank.ts`.
- **PDF:** `pdf-lib` com metadados fixos na época (hash determinístico) e
  `sha256` para idempotência; bucket privado, caminho
  `<entity_id>/<loan_id>/<version>.pdf`.
- **Testes automatizados permitidos:** `npm run build` e
  `npx --yes supabase@latest test db`. Nada de Playwright/Cypress/Puppeteer; a
  conferência de tela é humana e vira a linha `**Walked:**` no Handoff.

### Ambiente

- Não há binário `supabase` no PATH: use `npx --yes supabase@latest ...`.
- Stack local: `npx --yes supabase@latest start -x
  logflare,vector,realtime,studio,imgproxy,edge-runtime,supavisor,mailpit,pg_meta`.
- Banco: `npx --yes supabase@latest db reset` (aplica migrations + `seed.sql`).
- Testes: `npx --yes supabase@latest test db` (hoje: 12 arquivos, 349 testes).
- Build: `npm run build`.
- Admin de teste: `admin-rotary-boa-vista@banco-ortopedico.test` /
  `Rotary-Local-Synthetic-2026!`. O seed tem dois empréstimos aguardando retirada
  (`B0A157E00001`, `B0A157E00002`) prontos para gerar termo e concluir.

### Definição de pronto

1. `plan.md` aprovado pelo usuário, com critérios EARS e valores concretos.
2. `checks.md` com cada critério provado por comando ou por `walk`, mais a tabela
   de cobertura e o `Swept`.
3. `npm run build` verde e `supabase test db` verde.
4. Verifier independente (autor ≠ verificador) com `verification.md` e
   `mutations.json`; toda mutação morta e todo achado fechado por commit.
5. Conferência visual do desenvolvedor nas telas, com `**Walked:**` no Handoff.
6. `check_proofs.py --mutations` verde, `validate_verification.py` sem erro.
7. `STATE.md` atualizado com as decisões novas (e as `AD-010`/`AD-011` corrigidas:
   elas ainda falam `codigo` e rotas antigas, hoje é `public_code`).

### Como fechar o portão (a ordem importa)

1. Commite tudo o que não é `.specs/`.
2. Rode `check_proofs.py --mutations <mutations.json>` **depois** do último commit
   de código: ele grava `proofs.md` com o `HEAD` atual e exige árvore limpa fora de
   `.specs/`.
3. Rode `validate_verification.py`.
4. `proofs.md` é artefato gerado: se você commitar depois da corrida, o `HEAD` muda
   e o portão passa a ler um `HEAD` velho. Deixe-o como está depois da última
   corrida, ou aceite recommitar e rodar de novo.
5. `check_proofs.py --mutations` **deixa o banco com a última mutação aplicada**,
   porque cada mutação roda `db reset` com o arquivo mutado e a restauração é do
   arquivo, não do banco. Depois da corrida, rode `db reset` antes de qualquer
   `supabase test db` ou de entregar o ambiente.
6. Se uma corrida for interrompida no meio de uma mutação, o arquivo da migration
   pode ficar mutado. Antes de rodar de novo: `git status`; se aparecer a migration
   suja, `git checkout -- <arquivo>` e `db reset`. Foi assim que uma corrida
   interrompida fez 43 provas falharem em bloco nesta etapa.
