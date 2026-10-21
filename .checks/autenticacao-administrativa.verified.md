# Acesso e sessão administrativa — `admin_banco`: verificação
**Veredito atual**: FAIL — 5/12 checks comprovados (C2, C6, C7, C9 e C10); 7 permanecem pendentes ou incompletos.
**Perfil**: `light` — padrão porque `AGENTS.md` não declara outro perfil.
**Intervalo do diff**: `d9790d7398651b01e3360ea27863f5c5ccc7015c..51bbdb10270bd06fb7a5508e374cd301e457c5eb`
**HEAD verificada**: `51bbdb10270bd06fb7a5508e374cd301e457c5eb` (esperada; confirmada)
**Round**: 3 — scoped; o diff completo foi lido e C1–C12 foram contabilizados. C6, C7, C9 e C10 foram revalidados.
**Verifier**: subagente independente, distinto do autor e dos verificadores das rodadas 1 e 2.

O FAIL permanece porque R1, R3–R5, R8 e R12 são provas manuais não executadas e a fixture atualizada do seed ainda não foi recarregada. R2 foi confirmado depois pelo usuário: a entrada administrativa redirecionou com sucesso para `/admin/contatos`. Esta rodada não executou `db reset`, não carregou o seed e não substituiu as demais provas por build, CSS ou SQL.

## Acompanhamento manual informado pelo usuário — 2026-10-21

- C2 / R2: **PASS** — o usuário confirmou que entrou com a conta administrativa local e foi redirecionado para `/admin/contatos`.
- Escopo: comprova o fluxo manual de entrada e redirecionamento. A rota `/admin/contatos` ainda retorna `null`; não comprova conteúdo ou revisão visual da tela.

## Fontes e escopo da rodada 3

- Revisei o diff integral solicitado, `.checks/autenticacao-administrativa.md`, este relatório anterior, `README.md`, `supabase/seed.sql`, actions/helpers administrativos e da Comunidade, Proxy, componentes, estilos, migrations e testes SQL.
- Abri as fontes da checklist: `.tasks/autenticacao-administrativa.md`, `.tasks/contatos-administrativos-fr-017-ac-007.md`, `.checks/contatos-administrativos-fr-017-ac-007.md`, `AGENTS.md`, os documentos de arquitetura/UX/produto/privacidade, configuração e migrations Supabase, testes SQL, documentação local Next.js 16.4.0, instruções locais Supabase e fontes instaladas `GoTrueClient.ts`/`types.ts`. Também consultei as fontes GoTrue vinculantes citadas abaixo.
- Perfil `light`: a comparação formal da checklist com fontes visuais é etapa `ui` e não foi executada; a fonte UX não contém desenho específico desta tela. Não há seção `Coverage` nem `Test policy` na checklist (N/A); fault injection não integra este perfil (N/A).
- A fronteira de FR-017/AC-007 continua preservada: `src/app/admin/contatos/page.tsx:5-9` chama `requireAdminBankContext()` e retorna `null`; o diff não implementa coleção, operações ou tela de contatos. Os arquivos locais `.tasks/autenticacao-administrativa.md`, `.tasks/contatos-administrativos-fr-017-ac-007.md` e `.checks/contatos-administrativos-fr-017-ac-007.md` estavam modificados antes desta rodada e não foram alterados.

## Provas reexecutadas na HEAD

| Comando | Resultado observado |
|---|---|
| `npm run build` | Exit 0; Next.js 16.4.0 compilou, concluiu TypeScript e gerou rotas. `/admin/contatos` foi classificada dinâmica e `/admin/entrar` parcialmente pré-renderizada. |
| `npx --yes supabase@latest test db` | Exit 0; 5 arquivos `.. ok`, `Files=5, Tests=161`. `autenticacao-administrativa.test.sql .. ok`. O runner não imprime cada rótulo pgTAP individualmente; os rótulos/expressões abaixo foram localizados no arquivo executado. |

## Checks C1–C12 — rodada 3

| Check | Resultado e prova | Assertion/evidência localizada (expressão exata) |
|---|---|---|
| C1 | **PENDENTE** — R1, revisão manual de `/admin/entrar` e `/entrar`, não executada. | Indício estático, não prova de tela: `src/app/admin/_components/admin-sign-in-form.tsx:19,32` — `<span>E-mail</span>` e `<span>Senha</span>`; `:58-60` — `<button className="primary-action" type="submit" disabled={pending}>` e `{state.message ? "Tentar novamente" : "Entrar"}`. `src/app/entrar/page.tsx:41-53` mantém `title="Entrar ou criar cadastro"`, `eyebrow="Acesso da Comunidade"` e `<AuthFlow returnTo={returnTo} privacyNotice={privacyNotice} />`; nenhuma mudança desse arquivo está no diff. R1 continua necessário para conferir apresentação e comportamento reais. |
| C2 | **PASS — R2 confirmado manualmente pelo usuário em 2026-10-21.** | O usuário confirmou que a entrada administrativa local teve sucesso e redirecionou para `/admin/contatos`. Isso comprova a sessão e o destino observados; a rota ainda retorna `null`, portanto não comprova conteúdo visual. O escopo autorizado da entidade também é coberto por C6/C9. |
| C3 | **PENDENTE** — R3, casos de credencial/papel e inspeção manual da resposta/logs, não executada. | `src/app/admin/entrar/actions.ts:8-9`: `const signInErrorMessage = "Não foi possível entrar. Confira os dados e tente novamente."`; `:34-40`: falhas de Auth, contexto e exceção retornam `{ message: signInErrorMessage }`. O código estático não prova o conteúdo dos logs/resposta em execução; R3 permanece necessário. |
| C4 | **PENDENTE** — R4, observação manual com Auth atrasado, não executada. | `src/app/admin/_components/admin-sign-in-form.tsx:10-13`: `const [state, formAction, pending] = useActionState(...)`; `:52-56` renderiza `role="status"`, indicador e `Aguarde enquanto conferimos seu acesso.`; `:58-60` usa `disabled={pending}`. A demora e a prevenção efetiva de envio duplicado não foram observadas em R4. |
| C5 | **PENDENTE** — R5, falha controlada de Auth/rede seguida de nova tentativa, não executada. | `src/app/admin/entrar/actions.ts:36-40`: reconsulta `getAdminBankContext(supabase)` e, em falha/contexto ausente, retorna a mensagem comum; `src/app/admin/_components/admin-sign-in-form.tsx:58-60` mostra `"Tentar novamente"` quando `state.message`. Isso não substitui a falha/repetição observada em R5. |
| C6 | **PASS — verificado em `51bbdb1`**. `npm run build` e `npx --yes supabase@latest test db` passaram; arquivo administrativo terminou `ok`. | `src/lib/auth/admin-bank.ts:19-27` chama `auth.getUser()` antes da RPC sem argumentos; `src/app/admin/entrar/actions.ts:36-37` e `src/app/admin/contatos/page.tsx:5-6` revalidam nas superfícies administrativas. Migration `20261015000000_autenticacao_administrativa.sql:35-40` deriva de `catalog.current_auth_uid()` e exige `having count(*) = 1`. Assertion: `supabase/tests/autenticacao-administrativa.test.sql:149-153` — `public.current_admin_bank_entity_id()` esperado como `'92000000-0000-4000-8000-000000000001'::uuid`, rótulo `C6 resolver derives entity A from the authenticated uid`; `:81-85` espera argumentos `''`. |
| C7 | **PASS — verificado em `51bbdb1`**. `npx --yes supabase@latest test db` passou. | `supabase/migrations/20261015000000_autenticacao_administrativa.sql:1-3`: `where role = 'admin_banco' and is_active`; teste `:19-30` exige `idx.indisunique` e predicado; `:133-143` espera contagem `1`. Em `:174-185`, a assertion espera `'23505', null, 'C7 second active admin_banco entity is rejected'` ao inserir a segunda associação. O formulário não contém seletor (`src/app/admin/_components/admin-sign-in-form.tsx:18-60`). |
| C8 | **PENDENTE — subprova SQL PASS; R8 não executada**. | `supabase/tests/autenticacao-administrativa.test.sql:259-263`: `is(public.current_admin_bank_entity_id(), null::uuid, 'C8 revoked admin_banco has no resolved entity on the next database request')`. `src/lib/auth/admin-bank.ts:39` usa `redirect("/admin/entrar")`; `src/app/admin/contatos/page.tsx:5-9` protege e retorna `null`. A resposta HTTP e a ausência de conteúdo protegido após revogação não foram observadas em R8; C8 não é PASS integral. |
| C9 | **PASS — verificado em `51bbdb1`**. `npx --yes supabase@latest test db` passou. | `supabase/tests/autenticacao-administrativa.test.sql:124-132` testa quatro entidades (esperado `4`); `:161-165` espera a entidade A no teste `C9 resolver ignores browser role and entity claims`; `:196-200` — `is(public.current_admin_bank_entity_id(), null::uuid, 'C9 Community without admin_banco resolves no entity')`; a mesma assertion espera `null::uuid` para Companheiro, `admin_geral` sem `admin_banco`, vínculo inativo e usuário sem papel em `:201-224`. Negações diretas incluem `throws_ok($$select * from catalog.user_roles$$, '42501', null, 'C9 authenticated browser cannot read role rows directly')` em `:166-171` e `throws_ok($$select public.current_admin_bank_entity_id()$$, '42501', null, 'C9 anon cannot call the admin entity resolver')` em `:230-235`; `:70-75` confere ausência de `SELECT` direto para `anon`, `authenticated` e `service_role`. |
| C10 | **PASS — verificado em `51bbdb1`**. Revisão de configuração/migration e `npx --yes supabase@latest test db` passaram. | `supabase/config.toml:13`: `schemas = ["public", "graphql_public"]` (sem `catalog`); `supabase/migrations/20261013000000_disponibilidade_publica.sql:78-80` declara `returns table (bank_name text, available_quantity integer)`; assertion `supabase/tests/autenticacao-administrativa.test.sql:244-248` espera exatamente `TABLE(bank_name text, available_quantity integer)`. |
| C11 | **PENDENTE — seed corrigido revisado estaticamente; fixture não recarregada nem confirmada.** | `supabase/seed.sql:52` insere `'00000000-0000-0000-0000-000000000000'`; `:67-77` faz `on conflict (id) do update`, incluindo `instance_id = excluded.instance_id` em `:69`; o vínculo sintético e seu upsert estão em `:79-93`. O teste `supabase/tests/autenticacao-administrativa.test.sql:5-9` só afirma que `to_regprocedure('extensions.crypt(text,text)') is not null and to_regprocedure('extensions.gen_salt(text,integer)') is not null`; não executa nem verifica o seed. O README documenta reset local em `:43-50` e repetir o passo após a correção em `:70-72`. C11 fica pendente até o usuário recarregar e confirmar a fixture. |
| C12 | **PENDENTE** — R12, revisão visual manual a 360 px, não executada; nenhuma automação de navegador foi usada. | Apenas valores estáticos: `src/app/globals.css:133-137` (`font-size: 18px`); `:224-239` (`min-height: 56px`, `font-size: 20px`, `font-weight: 700`); `:121-130` título; `:249-255,397-400` foco. Esses trechos não provam contraste, ausência de rolagem/composição a 360 px nem as demais condições visuais de C12. |

## Diagnóstico GoTrue e seed (C11)

O diagnóstico de `instance_id` é sustentado pela fonte GoTrue vinculante. O cliente Supabase instalado envia e-mail/senha a `/token?grant_type=password` (`node_modules/@supabase/auth-js/src/GoTrueClient.ts:1243-1250`). No GoTrue consultado, o fluxo por e-mail chama `FindUserByEmailAndAudience` (`[internal/api/token.go:97](https://github.com/supabase/auth/blob/master/internal/api/token.go#L97)`), cuja busca usa exatamente `instance_id = ? and LOWER(email) = ? and aud = ? and is_sso_user = false` com `uuid.Nil` (`[internal/models/user.go:699-701](https://github.com/supabase/auth/blob/master/internal/models/user.go#L699-L701)`). A definição base consultada declara `instance_id uuid NULL` sem default (`[migrations/00_init_auth_schema.up.sql:4](https://github.com/supabase/auth/blob/master/migrations/00_init_auth_schema.up.sql#L4)`); portanto, omitir a coluna deixa `NULL`, que não satisfaz o filtro pelo UUID zero. O seed atual insere o UUID zero e o `ON CONFLICT (id)` corrige também uma linha existente com `instance_id` nulo por meio de `instance_id = excluded.instance_id`. A conclusão é estática: sem recarregar a fixture, não se prova que o acesso local funciona; C11 permanece PENDENTE, conforme o limite desta rodada.

## Swept, nível e amostragem — perfil `light`

| Dimensão | Verificação desta rodada |
|---|---|
| validation | A action lê e valida e-mail/senha em `src/app/admin/entrar/actions.ts:20-24`; C2/R2 foi confirmado pelo usuário; R1 e R3 permanecem sem prova manual. O índice único parcial de C7 foi revalidado. |
| failure modes | Action/helper falham de forma fechada e devolvem mensagem genérica (`src/app/admin/entrar/actions.ts:34-40`; `src/lib/auth/admin-bank.ts:21-32`). R5 e a resposta HTTP de R8 não foram observados. |
| idempotency and retry | Nova tentativa volta a autenticar e consultar o vínculo (`src/app/admin/entrar/actions.ts:27-37`); entidade, usuário e papel do seed usam `ON CONFLICT` (`supabase/seed.sql:30-34,67-93`). Fixture sem execução. |
| authorization | `auth.getUser()` e RPC sem argumentos em `src/lib/auth/admin-bank.ts:19-27`; função deriva de `auth.uid()` e vínculo ativo na migration `20261015000000_autenticacao_administrativa.sql:35-40`; negativas C9 passaram. |
| concurrency and ordering | C7 revalidado: índice parcial único e rejeição da segunda associação ativa com `23505` (`migration:1-3`; `supabase/tests/autenticacao-administrativa.test.sql:174-185`). Nenhuma operação de contatos foi acrescentada. |
| data lifecycle | SQL C8 confirma resolução `null` após desativação (`supabase/tests/autenticacao-administrativa.test.sql:250-263`); R8 ainda não comprova a resposta da rota. |
| external-dependency failure | O `catch` retorna a mensagem comum (`src/app/admin/entrar/actions.ts:38-40`); R5 não executou a falha controlada. |
| state transitions | Código estático cobre entrada, negação e proteção; R2 foi observado com sucesso pelo usuário; R1, R3–R5 e R8 continuam sem observação manual. Não há transição de situação de contato ou criação de empréstimo neste diff. |
| observability | A action não retorna erro bruto (`src/app/admin/entrar/actions.ts:34-40`); inspeção manual de resposta/logs em R3/R5 continua pendente. Gate de auditoria operacional permanece aberto. |

Não há gap de amostragem novo nas quatro aprovações automatizadas: C6/C7 têm assertions no nível da RPC/constraint; C9 cobre as quatro entidades sintéticas e os papéis negativos listados; C10 compara a assinatura pública. C2/R2 foi observado manualmente. C8 tem gap de nível entre RPC e resposta HTTP. C11 tem gap de nível entre disponibilidade de `pgcrypto` e execução/entrada local da fixture. R1, R3–R5, R8 e R12 continuam pendentes no nível especificado.

## Gates de go-live — permanecem abertos

- [ ] Provisionar a identidade Auth de produção e definir/entregar a senha inicial por processo confiável.
- [ ] Aprovar auditoria de inserções, desativações e remoções diretas de papéis em produção.
- [ ] Definir recuperação de senha para contas administrativas.

## `Unresolved` — cinco itens permanecem abertos

- [ ] Duração e renovação da sessão administrativa.
- [ ] Texto literal da mensagem de erro.
- [ ] Comportamento de `/admin/entrar` com sessão administrativa já válida.
- [ ] Localização da ação `Sair`.
- [ ] Permanência da sessão Auth válida quando não há papel ativo.

## Limites e preservação

- R1, R3–R5, R8 e R12 não foram executados manualmente. R2 foi confirmado pelo usuário. A fixture corrigida não foi carregada; não rodei seed nem `db reset`.
- Os únicos comandos de validação executados nesta rodada foram `npm run build` e `npx --yes supabase@latest test db`. Não rodei `supabase start`, migration up, dev, curl, lint, outros testes, automação visual/navegador, deploy ou comando de produção; nenhum dado de produção foi inserido.
- `.tasks/contatos-administrativos-fr-017-ac-007.md` e `.checks/contatos-administrativos-fr-017-ac-007.md` não foram alterados; seus estados locais preexistentes foram preservados. Não declaro M-C1–M-C13 ou M-C15 verificados; C14 continua sendo a única aprovação anterior.

---

# Histórico da rodada 2 — relatório anterior preservado

**Veredito**: FAIL — 4/12 checks comprovados integralmente; 8 permanecem pendentes ou incompletos.
**Perfil**: `light` — padrão porque `AGENTS.md` não declara outro perfil.
**Intervalo do diff**: `d9790d7398651b01e3360ea27863f5c5ccc7015c..dc71e6d6e2ea4ef5bc4e1e0ffffab4c0769e1d83`
**HEAD verificada**: `dc71e6d6e2ea4ef5bc4e1e0ffffab4c0769e1d83`
**Round**: 2 — full; revisão integral solicitada para o intervalo e C1–C12.
**Verifier**: subagente independente, distinto do autor e do Verifier round 1.

O FAIL permanece porque R1–R5, R8 e R12 não foram executados e a fixture do seed não foi carregada. C6, C7, C9 e C10 foram revalidados nesta rodada; somente esses quatro checks estão PASS. Build, SQL estático e CSS não substituem as provas manuais nem a execução do seed.

## Perfil e fontes (revisadas em `dc71e6d`)

- `AGENTS.md:29-35` restringe validações a `npm run build` e `supabase test db`, proíbe automação de navegador e exige revisão visual manual. A comparação formal com fonte visual vinculante é etapa `ui`, não executada em `light`; não há desenho específico para esta tela. A checklist não contém `Coverage` nem `Test policy`; ambos são N/A. Fault injection não integra o perfil `light`.
- Foram lidos `.tasks/autenticacao-administrativa.md`, `.checks/autenticacao-administrativa.md` e `AGENTS.md`, além de `.tasks/contatos-administrativos-fr-017-ac-007.md` e `.checks/contatos-administrativos-fr-017-ac-007.md` no estado atual. A dependência e a fronteira da task de contatos continuam separadas.
- Fontes de arquitetura, UX, produto e privacidade abertas: `docs/arquitetura/autenticacao-e-autorizacao.md:28-64`, `docs/arquitetura/modelo-conceitual.md:109-129`, `docs/arquitetura/visao-geral.md:19-25`, `docs/ux/acessibilidade-e-fluxos.md:5-26,83-92`, `docs/produto/requisitos.md:120-127,149-158` e `docs/privacidade/requisitos-de-dados.md:64-76`. Não encontrei contradição com os critérios e a fronteira decidida.
- Foram lidos os fluxos existentes `src/app/entrar/actions.ts`, `src/app/entrar/page.tsx`, `src/app/_components/auth-flow.tsx`, `src/app/_components/public-layout.tsx`, `src/lib/supabase/server.ts`, `src/lib/supabase/service.ts`, `src/proxy.ts` e `src/app/globals.css`, além de toda a implementação administrativa do diff.
- Os documentos locais Next.js 16.4.0 foram abertos nos caminhos exatos da checklist: `node_modules/next/dist/docs/01-app/01-getting-started/03-layouts-and-pages.md`, `node_modules/next/dist/docs/01-app/01-getting-started/05-server-and-client-components.md`, `node_modules/next/dist/docs/01-app/01-getting-started/07-mutating-data.md`, `node_modules/next/dist/docs/01-app/01-getting-started/16-proxy.md`, `node_modules/next/dist/docs/01-app/02-guides/authentication.md`, `node_modules/next/dist/docs/01-app/02-guides/server-actions.md`, `node_modules/next/dist/docs/01-app/02-guides/forms.md`, `node_modules/next/dist/docs/01-app/02-guides/data-security.md`, `node_modules/next/dist/docs/01-app/02-guides/redirecting.md`, `node_modules/next/dist/docs/01-app/02-guides/authentication-with-cache-components.md`, `node_modules/next/dist/docs/01-app/02-guides/building.md`, `node_modules/next/dist/docs/01-app/02-guides/instant-navigation.md` e `node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/02-route-segment-config/instant.md`; também `node_modules/next/AGENTS.md`.
- Foram lidos `node_modules/@supabase/supabase-js/AGENTS.md`, `node_modules/@supabase/auth-js/AGENTS.md`, `node_modules/@supabase/auth-js/src/GoTrueClient.ts:1104-1116,1236-1289,3223-3281` e `node_modules/@supabase/auth-js/src/lib/types.ts:691-699`. Também foram lidos `supabase/config.toml`, `supabase/seed.sql`, as migrations `20261014000000_autenticacao_comunidade.sql`, `20261014010000_contatos_comunidade.sql`, `20261014020000_perfil_privado_e_uid_rls.sql`, `20261013000000_disponibilidade_publica.sql` e `20261015000000_autenticacao_administrativa.sql`, e os testes SQL citados pela checklist e executados pelo runner.

## Comandos reexecutados na HEAD

| Comando | Resultado observado |
|---|---|
| `npm run build` | Exit 0. Next.js 16.4.0: `Compiled successfully`, TypeScript e geração de rotas concluídos; `/admin/contatos` saiu como dinâmica e `/admin/entrar` como parcialmente pré-renderizada. |
| `npx --yes supabase@latest test db` | Exit 0: `autenticacao-administrativa.test.sql`, `autenticacao-comunidade.test.sql`, `catalogo-publico.test.sql`, `contatos-comunidade.test.sql` e `disponibilidade-publica.test.sql` terminaram `ok`; `Files=5, Tests=161. Result: PASS`. |

O runner registra resultado por arquivo, não imprime cada rótulo pgTAP individualmente. Os nomes e expressões das assertions pertinentes foram localizados no arquivo SQL e o arquivo administrativo terminou `ok` nesta execução. Build comprova compilação/rotas, não comportamento visual ou os fluxos manuais.

## Checks (revalidados em `dc71e6d`)

| Check | Resultado | Proof executado | Evidência localizada |
|---|---|---|---|
| C1 | **PENDENTE — carry-forward de R1, confirmado em `dc71e6d`** | R1 — revisão manual de `/admin/entrar` e `/entrar`: não executada. | `src/app/admin/_components/admin-sign-in-form.tsx:18-40` contém os labels `E-mail` e `Senha`; `:58-60` renderiza o único botão do formulário como `Entrar` ou `Tentar novamente`. `src/app/entrar/page.tsx:40-54` continua apresentando `Acesso da Comunidade` e `AuthFlow`. Isso é leitura estática, não substitui R1 nem a conferência manual das duas telas. |
| C2 | **PENDENTE — carry-forward de R2, confirmado em `dc71e6d`** | R2 — entrada manual local com a identidade do seed: não executada; seed não rodado. | `src/app/admin/entrar/actions.ts:20-24` lê apenas `email` e `password`; `:29-37` chama `signInWithPassword` e valida `getAdminBankContext`; `:43` usa `redirect("/admin/contatos")`. Não há leitura de `entity_id`; falta observar sessão e URL final na entrada local R2. |
| C3 | **PENDENTE — carry-forward de R3, confirmado em `dc71e6d`** | R3 — casos manuais de credencial/papel ausente ou inativo e inspeção da resposta/logs: não executada. | `src/app/admin/entrar/actions.ts:8-9` define a mensagem única e `:34-40` retorna a mesma constante para erro de Auth, contexto ausente e exceção; `src/lib/auth/admin-bank.ts:21-32` falha fechado sem devolver erro bruto. A inspeção manual exigida por R3 segue pendente. |
| C4 | **PENDENTE — carry-forward de R4, confirmado em `dc71e6d`** | R4 — resposta Auth local atrasada observada manualmente: não executada. | `src/app/admin/_components/admin-sign-in-form.tsx:10-13` obtém `pending`; `:52-56` renderiza `role="status"`, indicador e texto; `:58-60` desabilita o botão enquanto `pending`. Isso não observa atraso nem envio duplicado; R4 continua pendente. |
| C5 | **PENDENTE — carry-forward de R5, confirmado em `dc71e6d`** | R5 — falha local controlada de Auth/rede seguida de nova tentativa: não executada. | `src/app/admin/entrar/actions.ts:27-40` converte falha em mensagem genérica e `:29-37` tenta Auth e verifica novamente o vínculo; `src/app/admin/_components/admin-sign-in-form.tsx:58-60` oferece `Tentar novamente`. A falha/rede e a repetição não foram observadas em R5. |
| C6 | **PASS — verificado em `dc71e6d`** | `npm run build` exit 0 e `npx --yes supabase@latest test db` exit 0; `autenticacao-administrativa.test.sql .. ok`. | `src/lib/auth/admin-bank.ts:16-27` chama `auth.getUser()` antes de `rpc("current_admin_bank_entity_id")` sem argumentos; `src/app/admin/entrar/actions.ts:29-37` e `src/app/admin/contatos/page.tsx:5-9` repetem a autorização nas superfícies administrativas. `supabase/migrations/20261015000000_autenticacao_administrativa.sql:35-40` deriva por `catalog.current_auth_uid()` e `having count(*) = 1`; `supabase/migrations/20261014020000_perfil_privado_e_uid_rls.sql:28-36` define o helper como `select auth.uid()`. As assertions `supabase/tests/autenticacao-administrativa.test.sql:76-85` esperam retorno `uuid` e argumentos `''`; `:149-164` espera a entidade A para o uid autenticado mesmo após claims forjados. |
| C7 | **PASS — verificado em `dc71e6d`** | `npx --yes supabase@latest test db` exit 0; arquivo administrativo `ok`. | `supabase/migrations/20261015000000_autenticacao_administrativa.sql:1-3` cria índice único parcial por `user_id` para `role = 'admin_banco' AND is_active`; `supabase/tests/autenticacao-administrativa.test.sql:19-29` exige `idx.indisunique` e predicado ativo; `:174-184` espera SQLSTATE `23505` ao inserir a segunda associação. `src/app/admin/_components/admin-sign-in-form.tsx:18-40,58-60` não apresenta seletor, e `src/app/admin/contatos/page.tsx:5-10` permanece vazia e protegida. |
| C8 | **PENDENTE — subprova SQL PASS; R8 carried from R1** | `npx --yes supabase@latest test db` exit 0; R8 — navegação manual após revogação: não executada. | `supabase/tests/autenticacao-administrativa.test.sql:250-263` desativa o vínculo e afirma `public.current_admin_bank_entity_id() = null::uuid` na chamada seguinte. `src/lib/auth/admin-bank.ts:36-40` redireciona sem contexto e `src/app/admin/contatos/page.tsx:5-9` só retorna `null` depois da autorização. A resposta HTTP/ausência de conteúdo protegido não foi observada em R8; C8 não é PASS integral. |
| C9 | **PASS — verificado em `dc71e6d`** | `npx --yes supabase@latest test db` exit 0; arquivo administrativo `ok`. | `supabase/tests/autenticacao-administrativa.test.sql:124-132` afirma `count(*) = 4`; `:149-164` espera a entidade A mesmo com role/entity claims forjados; `:190-193` espera a entidade B vinculada ao outro uid; `:196-224` espera `null::uuid` para Comunidade, Companheiro, `admin_geral` sem `admin_banco`, papel inativo e usuário sem papel. `:166-170` espera `throws_ok(..., '42501', ...)` para leitura autenticada direta; `:230-240` espera `42501` para chamada do resolvedor e leitura direta por `anon`. `:70-75` também afirma ausência de SELECT direto para `anon`, `authenticated` e `service_role`. |
| C10 | **PASS — verificado em `dc71e6d`** | Revisão de configuração/migration e `npx --yes supabase@latest test db` exit 0; arquivo administrativo `ok`. | `supabase/config.toml:11-15` define `schemas = ["public", "graphql_public"]`, sem `catalog`; `supabase/tests/autenticacao-administrativa.test.sql:244-248` espera exatamente `TABLE(bank_name text, available_quantity integer)`; `supabase/migrations/20261013000000_disponibilidade_publica.sql:78-80` declara essa assinatura. |
| C11 | **PENDENTE — revisão estática em `dc71e6d`; fixture não executada** | O teste de banco passou, mas nenhum seed ou `db reset` foi executado. | `supabase/seed.sql:23-34` define `SYN-ROTARY-BOA-VISTA` e upsert da entidade; `:36-73` define identidade/credencial sintéticas locais, hash `extensions.crypt(..., extensions.gen_salt('bf'))` e upsert Auth; `:75-89` insere o vínculo ativo e usa upsert. A assertion `supabase/tests/autenticacao-administrativa.test.sql:5-9` só testa se `extensions.crypt` e `extensions.gen_salt` existem; não executa o seed nem prova a fixture carregada. C11 permanece pendente. |
| C12 | **PENDENTE — carry-forward de R12, confirmado em `dc71e6d`** | R12 — revisão visual manual de `/admin/entrar` a 360 px: não executada; nenhuma automação de navegador foi usada. | Estático: labels em `src/app/admin/_components/admin-sign-in-form.tsx:18-40`; texto corrido `18px` em `src/app/globals.css:133-138`; botão `min-height: 56px`, `font-size: 20px`, `font-weight: 700` em `:224-239`; foco visível em `:249-255,372-400`; título `h1` em `:121-131`. Esses valores não provam contraste, rolagem, composição ou comportamento real a 360 px; R12 continua pendente. |

## Revisão das linhas `Swept` (perfil light)

| Dimensão | Resultado da releitura independente (verificado em `dc71e6d`) |
|---|---|
| validation | `src/app/admin/entrar/actions.ts:11-24` aceita texto, remove espaços do e-mail, limita-o a 320 caracteres e exige senha; o Auth verifica credenciais. O índice parcial de C7 existe. R1–R3 continuam sem prova manual. |
| failure modes | A ação e o helper retornam falha genérica/fechada (`src/app/admin/entrar/actions.ts:34-40`; `src/lib/auth/admin-bank.ts:21-32`). A revogação SQL de C8 passa, mas R8 não prova a navegação HTTP; R5 também não foi executado. |
| idempotency and retry | Nova submissão chama Auth e o resolvedor novamente (`src/app/admin/entrar/actions.ts:27-37`); entidade, identidade e papel do seed usam `ON CONFLICT` (`supabase/seed.sql:30-34,64-73,84-89`). A fixture continua sem execução. |
| authorization | `getUser()` e a RPC sem argumentos estão em `src/lib/auth/admin-bank.ts:16-27`; a migration deriva de `auth.uid()` e vínculo ativo (`supabase/migrations/20261015000000_autenticacao_administrativa.sql:35-40`). As negações/claims adulterados de C9 passaram. A experiência completa de C2 aguarda R2. |
| concurrency and ordering | O índice parcial de C7 bloqueia segunda associação ativa e a tentativa no banco falha com `23505` (`supabase/migrations/20261015000000_autenticacao_administrativa.sql:1-3`; `supabase/tests/autenticacao-administrativa.test.sql:174-184`). Nenhuma mutação de contato foi adicionada ao diff. |
| data lifecycle | Desativar o papel remove o resultado da RPC (`supabase/tests/autenticacao-administrativa.test.sql:250-263`); R8 ainda não observa a resposta HTTP. Exclusão da conta Auth, retenção e auditoria operacional continuam fora/em aberto. |
| external-dependency failure | Exceções de Auth/rede são convertidas à mensagem genérica (`src/app/admin/entrar/actions.ts:27-40`); a tentativa controlada R5 não foi realizada. |
| state transitions | O código cobre entrada, negação e proteção da rota (`src/app/admin/entrar/actions.ts:27-43`; `src/app/admin/contatos/page.tsx:5-10`). R1–R5/R8 não foram observados manualmente; o diff não adiciona transição de situação de contato ou criação de empréstimo. |
| observability | A nova ação não registra credenciais/erro bruto e devolve mensagem genérica (`src/app/admin/entrar/actions.ts:8-9,34-40`). R3/R5 não inspecionaram logs; auditoria operacional de alterações de papéis permanece gate aberto. |

## Histórico da rodada 1 — preservado (carried from `636ae446faf3e1292ae9b6efa518ed6e9af2bbd3`)

R1 cobriu `d9790d7398651b01e3360ea27863f5c5ccc7015c..636ae44`, terminou em `636ae446faf3e1292ae9b6efa518ed6e9af2bbd3` e registrou FAIL com 4/12 checks integrais PASS: C6, C7, C9 e C10. Registrou `npm run build` exit 0 e `npx --yes supabase@latest test db` exit 0 (`Files=5, Tests=161`). O resumo histórico abaixo preserva os resultados/evidências R1; a tabela atual acima contém a revalidação completa em `dc71e6d`.

| Check | Resultado/evidência registrada em R1 |
|---|---|
| C1 | PENDENTE — R1 manual não executado; labels `E-mail`/`Senha` e botão em `src/app/admin/_components/admin-sign-in-form.tsx:18-39,58-60`; fluxo Comunidade em `src/app/entrar/page.tsx:40-54`. |
| C2 | PENDENTE — R2 manual não executado e seed não rodado; action lê `email`/`password`, verifica Auth/papel e redireciona para destino literal em `src/app/admin/entrar/actions.ts:20-43`. |
| C3 | PENDENTE — R3 manual de resposta/logs não executado; mensagem comum em `src/app/admin/entrar/actions.ts:8-9,34-40` e helper fail-closed em `src/lib/auth/admin-bank.ts:21-32`. |
| C4 | PENDENTE — R4 manual com Auth atrasado não executado; estado, indicador, texto e botão desabilitado em `src/app/admin/_components/admin-sign-in-form.tsx:10-13,52-60`. |
| C5 | PENDENTE — R5 manual de falha/repetição não executado; catch genérico e revalidação em `src/app/admin/entrar/actions.ts:27-40`, botão de repetição em `src/app/admin/_components/admin-sign-in-form.tsx:58-60`. |
| C6 | PASS — R1 citou `auth.getUser()`/RPC em `src/lib/auth/admin-bank.ts:16-29`, assinatura sem argumentos em `supabase/tests/autenticacao-administrativa.test.sql:81-85`, retorno derivado de uid em `:149-164`, e a validação da rota/action em `src/app/admin/contatos/page.tsx:5-9` e `src/app/admin/entrar/actions.ts:27-37`. Revalidado independentemente acima. |
| C7 | PASS — R1 citou o índice parcial em `supabase/migrations/20261015000000_autenticacao_administrativa.sql:1-3` e a assertion de segunda associação com SQLSTATE `23505` em `supabase/tests/autenticacao-administrativa.test.sql:174-184`; a ausência de seletor foi revisada no form/destino. Revalidado independentemente acima. |
| C8 | PENDENTE — R1 registrou subprova SQL PASS (`supabase/tests/autenticacao-administrativa.test.sql:250-262`), mas R8 manual não executado. |
| C9 | PASS — R1 citou quatro entidades em `supabase/tests/autenticacao-administrativa.test.sql:124-131`, claims adulterados em `:149-170`, entidade B em `:190-193`, negações em `:195-240` e privilégio de leitura em `:70-75`. Revalidado independentemente acima. |
| C10 | PASS — R1 revisou `supabase/config.toml:11-15`, `supabase/migrations/20261013000000_disponibilidade_publica.sql:78-80` e assertion de retorno em `supabase/tests/autenticacao-administrativa.test.sql:244-248`. Revalidado independentemente acima. |
| C11 | PENDENTE — R1 revisou estaticamente a entidade e os upserts em `supabase/seed.sql:23-34,36-73,75-89`; `supabase/tests/autenticacao-administrativa.test.sql:5-9` só testa a presença de `crypt`/`gen_salt`. Seed e `db reset` não foram executados. |
| C12 | PENDENTE — R12 manual não executado; R1 registrou apenas os estilos declarados em `src/app/globals.css:133-138,224-239,372-400`, sem tratá-los como prova visual. |

R1 anotou que os caminhos locais da documentação Next.js não abriam; a checklist atualizou esses caminhos e todos foram abertos nesta rodada. A stack local e a migration administrativa já aplicada foram pré-condições informadas/autorizadas; nesta revisão não rodei `supabase start` nem migration up.

## Test policy, Coverage e faults (verificado em `dc71e6d`)

- `Coverage`: N/A — a checklist não declara conjuntos/linhas de Coverage.
- `Test policy`: N/A — a checklist não contém essa seção.
- Fault injection: N/A no perfil `light`; nenhuma mutação foi feita.

## Nível e amostragem (verificado em `dc71e6d`)

- C6, C7, C9 e C10 têm assertions de banco executadas no `supabase test db`, no nível das regras/RPCs verificadas. C9 afirma quatro entidades sintéticas e cobre os papéis negativos listados; C7 combina a assertion de rejeição da segunda linha com o índice único que impõe a regra ao conjunto inteiro.
- C8 não pode herdar PASS da assertion SQL: ela prova somente que a RPC devolve `null` após revogação, não a resposta HTTP nem a ausência de conteúdo protegido na rota. Por isso R8 continua necessário.
- C11 também tem diferença de nível: a assertion disponível só verifica a presença de `crypt`/`gen_salt`; nem ela nem a revisão estática prova que a fixture do seed foi carregada. O seed não foi executado.
- R1–R5 e R12 permanecem no nível manual especificado; build, CSS e testes SQL não os substituem. Não identifiquei lacuna de amostragem adicional nos checks automatizados PASS.

## Gates de go-live — continuam abertos (carried from `dc71e6d`)

- [ ] Criar/provisionar a identidade Auth de produção e entregar/definir a senha inicial por processo confiável.
- [ ] Aprovar auditoria de inserções, desativações e remoções diretas de papéis em produção.
- [ ] Definir recuperação de senha para contas administrativas.

## `Unresolved` — cinco itens continuam abertos (carried from `dc71e6d`)

- [ ] Duração e renovação da sessão administrativa.
- [ ] Texto literal da mensagem de erro.
- [ ] Comportamento de `/admin/entrar` com sessão administrativa já válida.
- [ ] Localização da ação `Sair`.
- [ ] Permanência da sessão Auth válida quando não há papel ativo.

## Limites e preservação

- R1–R5, R8 e R12 continuam sem execução manual; não foram substituídos por build, CSS ou SQL. C11 continua PENDENTE até prova de execução da fixture; não rodei seed nem `db reset`.
- Os únicos comandos de validação executados nesta rodada foram `npm run build` e `npx --yes supabase@latest test db`. Não rodei `supabase start`, migration up, dev, curl, lint, outro teste, automação visual/navegador, deploy ou comando de produção; nenhum dado de produção foi inserido.
- O diff mantém `/admin/contatos` como rota vazia e protegida (`src/app/admin/contatos/page.tsx:5-10`); não acrescenta tela/coleção/operações de contatos, acesso de `admin_geral`, retenção, rótulo literal, filtros/ordenação/densidade, campos extras ou confirmação prévia. Não reabre WhatsApp/deduplicação nem cria empréstimo por mudança de situação.
- `.tasks/contatos-administrativos-fr-017-ac-007.md` e `.checks/contatos-administrativos-fr-017-ac-007.md` foram lidos e não alterados nesta rodada; os estados locais preexistentes foram preservados. Não declaro M-C1–M-C13 nem M-C15 da task anterior verificados; C14 continua sendo a única aprovação anterior, sem reavaliação ou ampliação.
