# Acesso e sessão administrativa — `admin_banco`

State: PLANNED — nenhum check foi executado. Manter cada check pendente até executar e registrar todas as provas listadas.

## Sources

- `.tasks/autenticacao-administrativa.md` — critérios C1–C12, decisões, limites e `Unresolved` 1–8.
- Conversa desta sessão — Supabase Auth por e-mail/senha, separação de `/entrar`, destino fixo `/admin/contatos`, fixture local sintética e proibição de alterações em produção.
- `.tasks/contatos-administrativos-fr-017-ac-007.md` — dependência, acesso restrito a `admin_banco` e decisões da task de contatos que permanecem abertas.
- `.checks/contatos-administrativos-fr-017-ac-007.md` — fixture local, validação manual e fronteira de escopo; não transferir nem declarar checks de contatos verificados.
- `AGENTS.md` — termos em português, paleta, acessibilidade manual e comandos permitidos.
- `docs/arquitetura/autenticacao-e-autorizacao.md` — Auth, papel ativo, escopo de entidade e RLS.
- `docs/arquitetura/modelo-conceitual.md` — relação entre identidade, papel e entidade.
- `docs/arquitetura/visao-geral.md` — navegador não confiável, servidor e RLS como barreira final.
- `docs/ux/acessibilidade-e-fluxos.md` — fonte vinculante dos requisitos gerais da interface, seções 1–2; não há desenho específico para esta tela.
- `docs/produto/requisitos.md` — FR-026/027/030/031 e NFR-003/005/007.
- `docs/privacidade/requisitos-de-dados.md` — minimização, logs, credenciais, auditoria e dados sintéticos.
- `src/app/entrar/actions.ts`, `src/app/entrar/page.tsx`, `src/app/_components/auth-flow.tsx` e `src/app/_components/public-layout.tsx` — fluxo da Comunidade e referência visual existente; a lógica de autenticação não será compartilhada.
- `src/lib/supabase/server.ts`, `src/lib/supabase/service.ts` e `src/proxy.ts` — sessão SSR, fronteira server-only e atualização de sessão.
- `src/app/globals.css` — estilos reutilizáveis e tokens visuais existentes.
- `supabase/migrations/20261014000000_autenticacao_comunidade.sql` — `catalog.user_roles`, papéis e autorização atual.
- `supabase/migrations/20261014010000_contatos_comunidade.sql` e `20261014020000_perfil_privado_e_uid_rls.sql` — RLS, vínculo, `catalog.current_auth_uid()` e RPCs atuais.
- `supabase/migrations/20261013000000_disponibilidade_publica.sql` — assinatura pública existente de `equipment_availability`.
- `supabase/seed.sql` e `supabase/config.toml` — convenção das fixtures e schemas expostos.
- `supabase/tests/autenticacao-comunidade.test.sql`, `supabase/tests/contatos-comunidade.test.sql` e `supabase/tests/disponibilidade-publica.test.sql` — padrões SQL, isolamento entre entidades e contrato público.
- `node_modules/next/AGENTS.md` e documentação local Next.js 16.4.0 (`01-getting-started/03-layouts-and-pages.md`, `05-server-and-client-components.md`, `07-mutating-data.md`, `16-proxy.md`; `02-guides/authentication.md`, `server-actions.md`, `forms.md`, `data-security.md`, `redirecting.md`) — App Router, Server Actions, autorização, Proxy e redirecionamento.
- `node_modules/@supabase/supabase-js/AGENTS.md`, `node_modules/@supabase/auth-js/AGENTS.md` e `node_modules/@supabase/auth-js/src/GoTrueClient.ts` / `src/lib/types.ts` — assinaturas instaladas de `signInWithPassword` e `getUser`.

## Out of scope

- Conteúdo, coleção, navegação, filtros, ordenação, densidade e operações de `/admin/contatos`; essa entrega pertence a FR-017/AC-007.
- Acesso de `admin_geral`, rótulo literal da navegação, retenção, campos adicionais ou confirmação prévia.
- Cadastro, convite ou gestão de papéis administrativos; criar a identidade Auth de produção; recuperar senha; MFA; inserir papéis em produção; deploy.
- Alterar `/entrar`, o fluxo CPF/senha da Comunidade, `equipment_availability` ou a exposição de `catalog`.
- Reabrir o link revisável de WhatsApp, a deduplicação de 30 minutos ou criar empréstimo como efeito de mudança de situação.
- Declarar M-C1–M-C13 ou M-C15 da tarefa anterior verificados. Somente C14 foi aprovado anteriormente.
- Playwright, Cypress, Puppeteer, outros runners ou automação visual.

## Landing

A entrada administrativa reutiliza o cliente SSR e o invólucro visual existentes, sem reutilizar a autenticação da Comunidade. A autorização será centralizada em um helper server-only e em uma RPC sem parâmetros que deriva o vínculo de `auth.uid()`; o Proxy apenas atualizará a sessão, sem substituir as verificações no servidor/banco. `/admin/contatos` será uma rota protegida vazia, sem UI ou dados de contatos.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Regra monobanco em `catalog.user_roles` | Índice único parcial em `user_id` para `role = 'admin_banco' AND is_active` | Apenas validar na tela ou usar trigger sem unicidade transacional; ambos permitem corrida/duplicidade. Não corrigir vínculos existentes automaticamente. |
| Resolvedor de autorização no banco | `public.current_admin_bank_entity_id()` sem argumentos; retorna somente o UUID da entidade do `auth.uid()` quando há exatamente um vínculo ativo; owner `admin_bank_authorization_checker` `NOLOGIN NOBYPASSRLS` e RLS | Aceitar `user_id`, papel ou entidade do navegador, ou devolver linhas de `catalog.user_roles`; viola a origem confiável e expõe mais dados. |
| Destino da entrada | `/admin/contatos`; página Server Component chama `requireAdminBankContext()` em cada requisição e retorna `null` sem renderizar conteúdo | Não criar rota e terminar em 404, ou implementar agora uma tela/coleção de contatos fora da task. |
| Atualização SSR das rotas administrativas | Acrescentar `/admin/:path*` ao matcher existente; o Proxy continua apenas chamando `auth.getUser()` para atualizar cookies | Deixar novas páginas fora do fluxo existente de atualização de cookie, ou deslocar autorização de papel para o Proxy. |
| Fixture local | Entidade `SYN-ROTARY-BOA-VISTA`, identidade Auth com e-mail `.test`, senha sintética local armazenada somente como hash e exatamente um vínculo ativo; inserts idempotentes | Dados reais, credenciais de produção ou criação automática de papel pela tela. |

- O layout e a tipografia da entrada seguem os componentes/tokens existentes; não há dependência nova nem alteração de contrato público.

## Checks

### S1 — Entrar com uma conta administrativa previamente provisionada · 5 critérios

**C1 (critério 1) — PENDENTE** — `/admin/entrar` apresenta campos rotulados `E-mail` e `Senha`, uma ação `Entrar` e nenhuma opção de criar cadastro. `/entrar` permanece exclusivo da Comunidade e inalterado.

Prova: **R1 — revisão manual de `/admin/entrar` e `/entrar`**. Conferir os dois rótulos, a ação, a ausência de cadastro administrativo e o fluxo de Comunidade preservado. Ainda não executada.

**C2 (critério 2) — PENDENTE** — Conta Auth sintética com credenciais válidas e um vínculo ativo único é aceita e encaminhada para `/admin/contatos`; nenhum destino vem de `entity_id` enviado pelo navegador.

Prova: **R2 — entrada manual local com a identidade sintética do seed**. Conferir sessão Auth e URL final `/admin/contatos`; não enviar nem alterar `entity_id`. Ainda não executada.

**C3 (critério 3) — PENDENTE** — Credenciais inválidas e ausência/inatividade de `admin_banco` são negadas pela mesma mensagem genérica; resposta e logs não revelam existência da conta, e-mail, senha, erro bruto ou dados privados.

Prova: **R3 — casos manuais locais de credencial inválida e papel ausente/inativo, com inspeção da resposta e logs sintéticos**. Ainda não executada.

**C4 (critério 4) — PENDENTE** — Enquanto Auth aguarda, aparece indicador com texto de carregamento e `Entrar` fica desabilitado.

Prova: **R4 — observação manual da tela durante uma resposta Auth local atrasada**. Conferir texto, indicador, botão desabilitado e ausência de envio duplicado. Ainda não executada.

**C5 (critério 5) — PENDENTE** — Falha de Auth/rede mostra mensagem compreensível e permite nova tentativa, sem erro bruto; toda tentativa volta a verificar o vínculo ativo.

Prova: **R5 — falha local controlada de Auth/rede seguida de nova tentativa**. Conferir mensagem genérica, ação de repetir e nova consulta de autorização. Ainda não executada.

### S2 — Revalidar a autorização administrativa em cada requisição · 7 critérios

**C6 (critério 6) — PENDENTE** — Cada superfície protegida valida a identidade da sessão com Supabase Auth e deriva papel/entidade da RPC baseada em `auth.uid()`; nenhum valor de papel/entidade do cliente concede acesso.

Provas: `npm run build` e revisão do Verifier em `getAdminBankContext()`, `requireAdminBankContext()`, `/admin/contatos` e `current_admin_bank_entity_id()`; `supabase test db` — assertion `C6 resolver derives identity from auth.uid and accepts no caller identity`. Ainda não executadas.

**C7 (critério 7) — PENDENTE** — Segunda associação ativa `admin_banco` do mesmo usuário a outra entidade é rejeitada pelo banco; não há seletor de entidade.

Prova: `supabase test db` — assertion `C7 second active admin_banco entity is rejected`. Ainda não executada.

**C8 (critério 8) — PENDENTE** — Após desativar/remover o vínculo, a próxima requisição protegida é negada e não retorna informação protegida.

Provas: `supabase test db` — assertion `C8 revoked admin_banco has no resolved entity on the next database request`; **R8 — navegação manual local para a rota protegida após desativar o vínculo**, conferindo redirecionamento e ausência de dados. Ainda não executadas.

**C9 (critério 9) — PENDENTE** — Com quatro entidades sintéticas, o resolvedor retorna somente a entidade do vínculo ativo de `auth.uid()` e ignora papel/entidade informados pelo navegador. `anon`, Comunidade, Companheiro, `admin_geral` sem `admin_banco`, vínculo inativo e leitura direta de `catalog.user_roles` não recebem autorização.

Prova: `supabase test db` — assertions `C9 resolver ignores browser role and entity claims`, `C9 anon and identities without active admin_banco resolve no entity` e `C9 client roles cannot read catalog.user_roles directly`. Ainda não executada.

**C10 (critério 10) — PENDENTE** — `catalog` permanece fora dos schemas expostos pela Data API e `equipment_availability` continua retornando somente `bank_name` e `available_quantity`.

Provas: revisão do Verifier de `supabase/config.toml` (schemas expostos) e `supabase test db` — assertion `C10 equipment_availability public result remains bank_name and available_quantity`. Ainda não executadas.

**C11 (critério 11) — PENDENTE** — `supabase/seed.sql` cria, de forma repetível, identidade Auth sintética local com exatamente um `admin_banco` ativo para a entidade sintética Rotary Boa Vista, sem dados ou credenciais reais.

Provas: `supabase test db` — assertion `C11 seeded synthetic admin has exactly one active Rotary Boa Vista entity`; revisão do Verifier de `supabase/seed.sql` para email `.test`, hash local e cláusulas `ON CONFLICT`. Ainda não executadas. A fixture não habilita acesso administrativo de produção.

**C12 (critério 12) — PENDENTE** — Revisão visual manual a 360 px confirma: sem rolagem horizontal; botões principais ≥56 px e texto em negrito ≥20 px; texto corrido ≥18 px; títulos ≥26 px; contraste ≥4,5:1; foco/informação não dependem apenas de cor/ícone; uma ação principal; rótulos acessíveis; linguagem e paleta de `AGENTS.md`.

Prova: **R12 — conferência visual manual de `/admin/entrar` a 360 px**. Não automatizar. Ainda não executada.

## Automated checks

Executar somente:

- [ ] `npm run build` — compila Next.js e TypeScript.
- [ ] `supabase test db` — executa as assertions SQL de autorização e RLS.

State: NOT RUN. Não executar outros comandos de validação nem adicionar runners.

## Go-live gates

- [ ] Criar/provisionar a identidade Auth de produção e entregar/definir a senha inicial por processo confiável.
- [ ] Aprovar auditoria de inserções, desativações e remoções diretas de papéis em produção.
- [ ] Definir recuperação de senha para contas administrativas.

## Open decisions — permanecem abertas

- [ ] Duração e renovação da sessão administrativa; não alterar a configuração Supabase existente.
- [ ] Texto literal de erro; usar apenas como padrão provisório a mensagem genérica de `src/app/entrar/actions.ts`.
- [ ] Comportamento de `/admin/entrar` com sessão administrativa já válida; usar provisoriamente o destino `/admin/contatos`.
- [ ] Localização da ação `Sair`; não criar nem posicionar navegação de saída nesta task.
- [ ] Permanência da sessão Auth válida sem papel ativo; negar acesso administrativo sem encerrar a sessão, como padrão provisório.

## Preservação da task anterior

M-C1–M-C13 e M-C15 continuam sem verificação manual; o único item aprovado anteriormente é C14. Esta checklist não altera nem conclui checks da task FR-017/AC-007.

## Swept

- validation: C1–C3 e C7 — campos e entradas verificadas no servidor; vínculo ativo único imposto no banco.
- failure modes: C3, C5 e C8 — negação genérica, falha remota recuperável e revogação na próxima requisição.
- idempotency and retry: C5 e C11 — nova tentativa revalida autorização; seed local usa inserts repetíveis.
- authorization: C2, C6–C9 — `getUser()`, `auth.uid()`, vínculo ativo único e negativas SQL; nenhum papel/entidade do navegador.
- concurrency and ordering: C7 — índice único parcial aplica a regra também a inserções concorrentes; nenhuma mutação de domínio de contatos nesta task.
- data lifecycle: C8 — desativação/remove acesso; exclusão da conta Auth, retenção e auditoria operacional continuam fora/em aberto.
- external-dependency failure: C5 — falha de Auth/rede tem mensagem genérica e tentativa recuperável.
- state transitions: C2–C5 e C8 — visitante, autorizado, negado e revogado; não há transições de situação de contatos.
- observability: C3 e C5 — sem e-mail, senha ou erro bruto na resposta/log da aplicação; auditoria de alterações diretas de papel permanece gate aberto.

## Handoff

- Perfil `light` e `handoff: on` são os padrões, pois `AGENTS.md` não declara outro perfil. S1: 43.361 bytes de fontes existentes ÷ 4 ≈ 10,9k tokens; S2: 100.636 bytes ÷ 4 ≈ 25,2k; total ≈36,1k, abaixo de 150k. S1 e S2 cabem em uma única batch; não haverá builder handoff. O Verifier independente será despachado pelo orquestrador somente após o último commit do recurso e revisará o diff completo.
