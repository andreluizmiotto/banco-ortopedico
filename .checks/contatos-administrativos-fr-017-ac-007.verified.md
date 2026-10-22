# Gestão administrativa de contatos — verificação independente

**Veredito da rodada 2: FAIL — 4/17 checks integralmente PASS; 7/17 têm subprovas SQL aprovadas, mas a parte manual continua pendente; 6/17 aguardam prova manual.**
**Perfil:** `light`.
**Diff range:** `1871c5dedfb53d9b5817d4f38e331169f40592e7..c2a5ae5f34aaae133c666b960199294c85806740`.
**HEAD:** `c2a5ae5f34aaae133c666b960199294c85806740` (confirmada).
**Round:** 2 — full.
**Verifier:** subagente independente, novo nesta rodada; autor da implementação ≠ verifier.

O FAIL permanece pelas provas manuais de interface/logs e pela revisão visual a 360 px que não foram executadas. F0, C6, C9 e C10 estão integralmente provados. A lacuna da rodada 1 em C6 foi fechada: o arquivo SQL agora executa negações de mutação para cada identidade negativa nomeada, inclusive admin de outra entidade, Companion, admin inativo e usuário autenticado sem admin_banco. C4 agora cobre 49 h, exatamente 48 h e 47 h; sua assertion de limite exato passou. C10 foi repetido manualmente em duas sessões SQL locais. Nenhuma prova visual foi inferida de markup, CSS ou build.

## Escopo e fontes da rodada 2

- Li integralmente `AGENTS.md`, `.tasks/contatos-administrativos-fr-017-ac-007.md`, `.checks/contatos-administrativos-fr-017-ac-007.md` e o relatório da rodada 1 preservado abaixo.
- Li a tarefa, checklist e verificação da autenticação administrativa. Para a dependência de sessão de C2, confirmei somente a prova manual registrada: `.checks/autenticacao-administrativa.verified.md:13-14` registra que o usuário entrou e chegou a `/admin/contatos`; `.checks/autenticacao-administrativa.md:67-70` identifica esse resultado como R2. Isso é evidência anterior de sessão/URL, não uma inferência do seed; também não comprova a tela de contatos.
- Li a tarefa, checklist e verificação independentes de WhatsApp/Comunidade. O relatório anterior aprovou somente C14 (`.checks/autenticacao-comunidade-whatsapp-fr-013-fr-015.verified.md:3,53-64`). **Não declaro M-C1–M-C13 nem M-C15 dessa tarefa verificados.**
- Li as fontes de produto `docs/produto/requisitos.md`, `docs/produto/criterios-de-aceite.md` e `docs/produto/regras-de-negocio.md`; UX `docs/ux/acessibilidade-e-fluxos.md`; arquitetura `docs/arquitetura/autenticacao-e-autorizacao.md`, `docs/arquitetura/modelo-conceitual.md` e `docs/arquitetura/visao-geral.md`; privacidade `docs/privacidade/requisitos-de-dados.md`; `.notebook/INDEX.md` e as três notas de fluxo administrativo/Comunidade.
- Li integralmente o diff completo (`22 arquivos; 2.169 inserções, 71 remoções`): `.checks/autenticacao-administrativa.md`, `.checks/contatos-administrativos-fr-017-ac-007.md`, `.notebook/INDEX.md`, `.notebook/admin-auth-flow.md`, `.notebook/admin-contact-management-flow.md`, `.tasks/contatos-administrativos-fr-017-ac-007.md`, `README.md`, `src/app/_components/public-layout.tsx`, `src/app/admin/_components/admin-contacts-manager.tsx`, `src/app/admin/contatos/actions.ts`, `src/app/admin/contatos/page.tsx`, `src/app/globals.css`, `src/lib/auth/admin-bank.ts`, `src/lib/contacts/admin-server.ts`, `src/lib/contacts/admin-types.ts`, as seis migrations `20261022000000`–`20261027000000` de contatos administrativos e `supabase/tests/contatos-administrativos.test.sql`.
- Li a árvore atual do aplicativo e os arquivos citados da autenticação, sessão SSR, Proxy e fluxo de contato da Comunidade. Li `supabase/config.toml`, o seed completo, todas as 12 migrations e os seis arquivos SQL de teste atuais (incluindo os testes executados pelo comando permitido).
- Li `node_modules/next/AGENTS.md` e a documentação instalada do Next.js 16.4.0: App Router layouts/pages, Server/Client Components, Mutating Data, Proxy, Authentication, Authentication with Cache Components, Server Actions, Forms, Data Security, Redirecting, Building, Instant Navigation e as referências de arquivo `page.md`, `loading.md`, `proxy.md` e `02-route-segment-config/instant.md`.

## Fontes vinculantes

| Fonte | Leitura | Resultado desta rodada |
|---|---|---|
| `docs/ux/acessibilidade-e-fluxos.md` | Completa; fonte vinculante | Os requisitos textuais da checklist cobrem os temas aplicáveis de navegação, estados remotos, linguagem e acessibilidade. O perfil `light` não executa a comparação formal da etapa `ui`; não enumerei composição de tela nem fiz inspeção visual. Não certifico arranjo, contraste, medidas ou comportamento a partir de CSS/markup. |
| `AGENTS.md` | Completa | Os únicos checks automatizados permitidos são `npm run build` e `supabase test db`; revisão visual manual e 360 px não são automatizadas. |
| Task/checklist FR-017/AC-007 | Completas | F0 e C1–C16 foram julgados separadamente abaixo. Itens `Unresolved` (incluindo acesso de `admin_geral` e retenção) não foram decididos. |

Não há seção `Coverage` nem `Test policy` na checklist. Fault injection e comparação formal da interface pertencem a perfis superiores (`standard`/`ui`), não executados em `light`; nenhum fault foi injetado.

## Comandos permitidos executados na HEAD

| Comando | Resultado observado |
|---|---|
| `npm run build` — primeira execução | **Exit 1.** Next.js 16.4.0 compilou, concluiu TypeScript e gerou a tabela de rotas, depois parou com `SecurityFatalError` e o lembrete de vulnerabilidade conhecida, recomendando repetir o mesmo comando. |
| `npm run build` — repetição idêntica | **Exit 0.** Compilação, TypeScript, prerenderização/rotas concluídos. O lembrete de vulnerabilidade foi exibido novamente, mas o build continuou. Nenhum upgrade de segurança foi executado. |
| `npx --yes supabase@latest test db` | **Exit 0 — `Files=6, Tests=212`, `All tests successful`, `Result: PASS`.** Os seis arquivos terminaram `ok`, incluindo `contatos-administrativos.test.sql`. O runner informa por arquivo, não imprime cada rótulo pgTAP; as assertions abaixo foram localizadas no arquivo executado. |

O stack e as migrations locais já estavam em execução/aplicadas. Não rodei `supabase start`, reset, seed, migration up, produção, outro runner, automação de navegador, deploy ou push. A prova C10 abaixo foi SQL manual em duas sessões, não um runner.

## Checks F0 e C1–C16

### F0 — PASS

`npx --yes supabase@latest test db` terminou com exit 0; `contatos-administrativos.test.sql` terminou `ok`, e o plano desse arquivo declara 51 assertions (`:3`). A assertion nomeada realmente está no arquivo executado (`supabase/tests/contatos-administrativos.test.sql:5-28`): `exists (select 1 from auth.users as auth_user join catalog.user_roles as user_role on user_role.user_id = auth_user.id and user_role.role = 'admin_banco' and user_role.is_active join catalog.entities as entity on entity.id = user_role.entity_id where auth_user.id = '90000000-0000-4000-8000-000000000001' and auth_user.instance_id = '00000000-0000-0000-0000-000000000000' and auth_user.email = 'admin-rotary-boa-vista@banco-ortopedico.test' and entity.code = 'SYN-ROTARY-BOA-VISTA') and (select count(*) = 1 from catalog.user_roles where user_id = '90000000-0000-4000-8000-000000000001' and role = 'admin_banco' and is_active)`, label `F0 local synthetic admin fixture is loaded for Rotary Boa Vista`. O resultado `ok` do arquivo, com `Tests=212`, confirma a assertion no run atual.

Revisei o seed completo (`supabase/seed.sql:1-146`): entidades `SYN-*` e Rotary Boa Vista explicitamente sintético (`:23-34`), Auth de desenvolvimento local com UUID de instância zero e e-mail `.test` (`:36-89`), papel local/upsert (`:91-105`) e inventário sintético (`:112-146`). Não há CPF, telefone, nome de pessoa ou credencial de produção. A revisão do seed não foi usada como prova de sessão nem de carga; F0 foi satisfeito pela assertion executada.

### C1 — PENDENTE (manual)

O checklist exige abrir `/admin/contatos` e confirmar visualmente que a navegação principal expõe `Contatos recebidos` sem menu escondido (`.checks/contatos-administrativos-fr-017-ac-007.md:71-73`). Não fiz essa inspeção. O markup estático `<Link aria-current="page" href="/admin/contatos">Contatos recebidos</Link>` existe em `src/app/admin/contatos/page.tsx:124-126`, mas **não é prova de apresentação nem de composição**. `rg -n 'C1 |C11 |C12 |C13 |C14 |C16 ' supabase/tests/contatos-administrativos.test.sql` não encontrou assertion de tela; permanece pendente.

### C2 — SUBPROVA SQL PASS; UI PENDENTE

O SQL passou no comando de banco. `supabase/tests/contatos-administrativos.test.sql:260-273` executa `results_eq($$ select bank_name, codigo, situacao from public.admin_bank_contacts(null) where codigo is not null order by codigo $$, $$ values ('Rotary Boa Vista (sintético)'::text, 'A1B2C3D4E5F6'::text, 'novo'::text), ('Rotary Boa Vista (sintético)'::text, 'A7B8C9D0E1F2'::text, 'novo'::text) $$, 'C2 Rotary Boa Vista collection returns the canonical bank name and each authorized row once; C6 admin contact collection is isolated across four synthetic entities - C6 admin Rotary sees only its synthetic contacts')`. O conjunto esperado fixa nome canônico, código, situação e ausência de duplicata para a coleção Rotary. Os casos positivos de escopo nas outras entidades estão em C6 (`:406-464`). Conferência manual da tela, dos quatro rótulos `Novo`, `Atendido`, `Virou empréstimo`, `Sem retorno` e da sessão não foi repetida nesta tela (`checklist:75-77`). A dependência de sessão foi confirmada somente pelo R2 registrado na tarefa anterior (`.checks/autenticacao-administrativa.verified.md:13-14`; `.checks/autenticacao-administrativa.md:67-70`), não pelo seed; isso não valida a UI de contatos.

### C3 — SUBPROVA SQL PASS; UI PENDENTE

`supabase/tests/contatos-administrativos.test.sql:275-285` executa `results_eq($$ select bank_name, codigo, situacao from public.admin_bank_contacts('A1B2C3D4E5F6') where codigo is not null $$, $$ values ('Rotary Boa Vista (sintético)'::text, 'A1B2C3D4E5F6'::text, 'novo'::text) $$, 'C3 exact message code search returns the same code and current situation')`; o teste SQL passou. A pesquisa manual na tela pelo código completo não foi executada (`checklist:79-81`), então C3 não é PASS integral.

### C4 — SUBPROVA SQL PASS, INCLUINDO O LIMITE EXATO; UI PENDENTE

`supabase/tests/contatos-administrativos.test.sql:287-303` exige `(exists (... codigo = 'A1B2C3D4E5F6' and situacao = 'novo' and destaque_48_horas) and exists (... codigo = 'A7B8C9D0E1F2' and situacao = 'novo' and not destaque_48_horas))`; as fixtures em `:218-219` são 49 h e 47 h. A assertion nova `:305-318` fixa `created_at = transaction_timestamp() - interval '48 hours'` e executa `is((select destaque_48_horas from public.admin_bank_contacts('A7B8C9D0E1F2') where codigo = 'A7B8C9D0E1F2' and situacao = 'novo'), true, 'C4 exact 48-hour boundary is highlighted and situation stays novo')`. As três assertions passaram. A função final usa o limite inclusivo `contact.created_at <= transaction_timestamp() - interval '48 hours'` (`20261027000000_admin_contact_highlight_boundary.sql:30-34`). A observação do destaque textual na tela não foi feita (`checklist:83-85`); permanece pendente.

### C5 — SUBPROVA SQL PASS; UI PENDENTE

`supabase/tests/contatos-administrativos.test.sql:320-342` executa uma assertion `ok` cujo predicado exige `count(*)::integer = 0` para `admin_bank_contacts('A1B2')`, `('a1b2c3d4e5f6')`, `('FFFFFFFFFFFF')` e o código estrangeiro `('B1C2D3E4F5A6')`; label `C5 exact search rejects malformed, missing, and other-entity codes`. Ela passou. A observação manual do estado vazio para a pesquisa inválida/sem correspondência permanece pendente (`checklist:87-89`).

### C6 — PASS PARA A MATRIZ DE IDENTIDADES EXPLICITAMENTE EXIGIDA

O arquivo executado (`supabase/tests/contatos-administrativos.test.sql:3`, 51 assertions) agora contém os casos de mutação negativa que faltavam em R1. Para o admin de outra entidade, `:426-431` espera `throws_ok($$select public.admin_set_contact_situation('A1B2C3D4E5F6', 'atendido')$$, 'P0001', 'Contato indisponível', 'C6 admin_banco from another entity cannot change a Rotary contact')`. Para Comunidade sem admin, Companion sem admin, admin_banco inativo e usuário autenticado sem admin_banco, as mesmas chamadas `throws_ok(..., 'P0001', 'Contato indisponível', ...)` estão em `:481-486`, `:502-507`, `:523-528` e `:544-549`, respectivamente. `anon` recebe negação `42501` ao tentar alterar em `:391-396`. **Todos esses testes de mutação foram executados no arquivo que terminou `ok`.**

As quatro entidades sintéticas e os papéis negativos estão montados em `:147-188`; as coleções autorizadas de Rotary/A/B/C estão em `:260-273,406-464`. Os claims forjados têm assertion de coleção em `:344-366` (`is((select count(*)::integer from public.admin_bank_contacts('B1C2D3E4F5A6') where codigo is not null), 0, 'C6 forged browser role and entity claims do not change the bank scope')`). O acesso direto às tabelas contatos/auditoria é negado em `:91-110,368-379`. A assertion de claims é de leitura; não a descrevo como uma chamada de mutação. As negações de mutação para todas as identidades expressamente nomeadas, inclusive a lacuna da rodada 1, estão cobertas. Não declaro resultado para uma identidade `admin_geral` real; continua `Unresolved`.

### C7 — SUBPROVA SQL PASS; RÓTULOS DA TELA PENDENTES

Os três destinos são assertions executadas: `is(public.admin_set_contact_situation('A1B2C3D4E5F6', 'atendido'), 'atendido', ...)` (`:556-560`), `is(public.admin_set_contact_situation('B1C2D3E4F5A6', 'sem_retorno'), 'sem_retorno', ...)` (`:603-607`) e `is(public.admin_set_contact_situation('C1D2E3F4A5B6', 'virou_emprestimo'), 'virou_emprestimo', ...)` (`:635-639`). Para cada destino, a assertion `exists(...)` compara situação nova e igualdade com `contact_snapshot` para `codigo`, `user_id`, `entity_id`, tipo, destinatário, papel do destinatário, origem e `created_at` (`:562-579`, `:609-626`, `:641-658`); retorno a `novo` é rejeitado com `throws_ok(..., 'P0001', 'Contato indisponível', ...)` em `:588-593`. SQL passou. A conferência visual dos rótulos não foi feita (`checklist:97-99`).

### C8 — SUBPROVAS SQL PASS; INSPEÇÃO DE LOGS PENDENTE

`supabase/tests/contatos-administrativos.test.sql:660-675` exige uma auditoria com `actor_user_id`, `action`, `entity_id`, `contact_id`, situação anterior/nova e `created_at is not null`. `:676-695` compara `array_agg(attribute.attname::text order by attribute.attnum)` com exatamente `['id','actor_user_id','action','entity_id','contact_id','previous_situation','new_situation','created_at']::text[]`; `:697-704` espera três eventos para três transições. Essas assertions passaram. Não inspecionei manualmente logs sintéticos; as assertions de schema não provam o conteúdo de logs de aplicação, conforme exige o checklist (`:101-103`). C8 permanece parcial.

### C9 — PASS

As duas chamadas à RPC, primeira e retry no mesmo destino, estão em `supabase/tests/contatos-administrativos.test.sql:713-722`: `is(public.admin_set_contact_situation('D1E2F3A4B5C6', 'sem_retorno'), 'sem_retorno', ...)` em ambas. A assertion final `:724-738` exige `(select count(*)::integer = 1 from catalog.community_contact_situation_audit where contact_id = '96000000-0000-4000-8000-000000000005') and exists (select 1 from catalog.community_contacts where id = '96000000-0000-4000-8000-000000000005' and codigo = 'D1E2F3A4B5C6' and situacao = 'sem_retorno')`, label `C9 repeating the same destination leaves one contact transition and one audit row`. O arquivo passou.

### C10 — PASS; ASSERTIONS SEQUENCIAIS MAIS CONCORRÊNCIA MANUAL REAL

As assertions SQL `:747-771` são sequenciais, não bastam sozinhas: a primeira `is(... 'atendido' ...)`, depois `throws_ok(... 'P0002', 'Situação já registrada', ...)` para `sem_retorno`, e a assertion final espera uma linha de auditoria e `situacao = 'atendido'`.

Repeti o procedimento manual autorizado com duas sessões `psql` separadas dentro do container local já ativo `supabase_db_banco-ortopedico`. Criei somente um Auth user sintético Comunidade (`98000000-0000-4000-8000-000000000017`), seu papel e um contato `novo` (`97000000-0000-4000-8000-000000000017`, código `C10F017007AA`) na entidade `SYN-ROTARY-BOA-VISTA`; o ator das duas RPCs foi o admin sintético já presente no seed. O preflight confirmou `novo` e zero auditorias.

- Sessão A: `BEGIN`; `SET LOCAL ROLE authenticated`; `request.jwt.claim.sub = '90000000-0000-4000-8000-000000000001'`; `SELECT public.admin_set_contact_situation('C10F017007AA', 'atendido')` retornou `atendido`; `SELECT pg_sleep(45)` manteve a transação e o lock abertos; depois `COMMIT`.
- Sessão B, iniciada em outra conexão enquanto A mantinha a transação: mesma identidade administrativa, `SELECT public.admin_set_contact_situation('C10F017007AA', 'sem_retorno')`. Após A confirmar, B recebeu **`ERROR: P0002: Situação já registrada`** e fez `ROLLBACK`.
- Leitura final: `C10F017007AA | atendido | final_situation_allowed=t | audit_rows=1`. A guarda/lock `FOR UPDATE` está em `20261022000000_contatos_administrativos.sql:160-177`; a atualização e inserção de auditoria ocorrem na mesma função/transação (`:179-206`).
- Removi somente a auditoria, contato, vínculo e Auth user temporários identificados acima; cada `DELETE` retornou `DELETE 1`. A consulta final confirmou `initiator_removed=t`, `role_removed=t`, `contact_removed=t`, `audit_removed=t`. Nenhum runner foi criado. Uma tentativa preliminar de sessão única foi desfeita e não foi contada como concorrência; a prova acima começou de novo com situação `novo` e zero auditorias.

### C11 — PENDENTE (manual)

O procedimento exige observar sucesso após gravação, situação resultante e um único próximo passo (`checklist:113-115`); não executei a tela. O markup estático de sucesso é `src/app/admin/_components/admin-contacts-manager.tsx:143-151`, não prova de interação. A busca `rg -n 'C1 |C11 |C12 |C13 |C14 |C16 ' supabase/tests/contatos-administrativos.test.sql` não encontrou assertions para esse requisito manual.

### C12 — PENDENTE (manual)

Não atrasei leitura/gravação nem observei o bloqueio de repetição (`checklist:117-119`). O estado `pending`, o texto e `disabled={pending || selectedSituation === ""}` estão estaticamente em `src/app/admin/_components/admin-contacts-manager.tsx:210-227`; isso não demonstra a resposta atrasada ou o bloqueio real. A busca de assertions manuais citada em C11 não retornou correspondência.

### C13 — PENDENTE (manual)

Não inspecionei os dois estados vazios em execução (`checklist:121-123`). `EmptyContacts` contém textos/um link estáticos em `src/app/admin/_components/admin-contacts-manager.tsx:79-92`; isso não prova resultado remoto, composição ou próximo passo visível. Nenhuma assertion SQL de C13 foi localizada.

### C14 — PENDENTE (manual)

Não provoquei falha de leitura/gravação/rede, não percorri retry e não inspecionei logs (`checklist:125-127`). O estado genérico aparece estaticamente em `src/app/admin/contatos/page.tsx:55-73` e `src/app/admin/_components/admin-contacts-manager.tsx:204-227`, mas código/build não provam recuperação em execução. Nenhuma assertion SQL de C14 foi localizada.

### C15 — SUBPROVA SQL PASS; MENSAGEM DA TELA PENDENTE

`supabase/tests/contatos-administrativos.test.sql:781-792` executa `throws_ok($$select public.admin_set_contact_situation('B1C2D3E4F5A6', 'atendido')$$, 'P0001', 'Contato indisponível', 'C15 foreign and unknown contact codes receive the same generic denial - foreign code')` e a mesma assertion/SQLSTATE/mensagem para `'FFFFFFFFFFFF'` com label `... - unknown code`. O arquivo passou e as duas negações SQL são idênticas. Não conferi manualmente que a tela apresenta mensagem sem revelar a existência do código/contato (`checklist:129-131`).

### C16 — PENDENTE (revisão visual manual)

Não realizei revisão em viewport de 360 px, inspeção de contraste/foco, medição de controles ou avaliação visual de ação principal/linguagem/paleta (`checklist:133-135`). Nenhuma automação de navegador foi usada; CSS, markup e build não foram tratados como prova. A busca de assertions manuais citada em C11 não retornou correspondência.

## Revisão das linhas `Swept` e limites

| Dimensão | Resultado desta rodada |
|---|---|
| validation (C5, C7) | Formato `^[A-F0-9]{12}$` e destinos limitados aparecem em `src/lib/contacts/admin-server.ts:9,122-126` e `20261022000000_contatos_administrativos.sql:151-158`; C5/C7 SQL passou. A tela C5 e rótulos C7 permanecem pendentes. |
| failure modes (C13–C15) | Estados de vazio/erro/sem permissão estão nos componentes/página; C15 SQL passou. C13 e C14 não foram exercitados manualmente, e C15 ainda precisa da observação da mensagem. |
| idempotency and retry (C9, C14) | A RPC retorna a situação já confirmada em `20261022000000_contatos_administrativos.sql:171-173`; C9 passou. Retry após falha de rede em C14 não foi observado. |
| authorization (C6, C15) | Resolvedor por sessão em `20261022000000_contatos_administrativos.sql:141-148`; C6 inclui todas as negações de mutação das identidades explicitamente listadas e C15 nega código estrangeiro/desconhecido. Não há afirmação sobre `admin_geral`. |
| concurrency and ordering (C10) | `FOR UPDATE` e transição única em `20261022000000_contatos_administrativos.sql:160-177`; sessão A/B confirmou conflito e uma auditoria. Ordenação/densidade continuam `Unresolved 5`. |
| data lifecycle | Retenção continua dependente de aprovação jurídica; não há exclusão automática adicionada. |
| external-dependency failure (C14) | Nenhum provedor externo novo; mapeamento de falha é genérico no servidor, mas a falha/retry manual continua pendente. |
| state transitions (C7, C9, C10) | RPC limita transição a partir de `novo` (`20261022000000_contatos_administrativos.sql:171-204`); assertions C7/C9 e concorrência C10 passaram como descrito. |
| observability (C8) | Auditoria atômica em `20261022000000_contatos_administrativos.sql:189-204`; assertion de conteúdo/schema passou. Inspeção manual de logs permanece pendente. |

O conjunto antigo de WhatsApp não foi reavaliado nem ampliado: somente C14 permanece como aprovação anterior; M-C1–M-C13 e M-C15 não são declarados verificados. Retenção, `admin_geral` e gates de produção continuam sem decisão. A sessão R2 local é uma prova anterior separada da assertion F0; a fixture local não habilita acesso de produção.

## Preservação

- A íntegra do relatório da rodada 1 foi preservada abaixo, sem apagar ou substituir suas evidências/histórico.
- O stack local permaneceu ativo; não rodei reset, seed, migration ou serviço de produção. A limpeza C10 confirmou a remoção somente das quatro linhas sintéticas temporárias criadas para essa prova.
- Não alterei implementação, task, checklist, seed ou migrations; não fiz commit. A única alteração desta rodada é este relatório.

---

## Histórico: relatório da rodada 1 preservado integralmente

# Gestão administrativa de contatos — verificação independente

**Veredito: FAIL — 3/17 checks integralmente PASS; C6 não está integralmente provado; 13 checks permanecem total ou parcialmente pendentes de provas manuais.**
**Perfil:** `light` — declarado no Handoff da checklist; `AGENTS.md` não declara perfil.
**Diff range:** `1871c5dedfb53d9b5817d4f38e331169f40592e7..a350f70bed9e2b8d45943fe879667ab676dbc264`
**HEAD:** `a350f70bed9e2b8d45943fe879667ab676dbc264` (confirmada)
**Round:** `1 — full`
**Verifier:** subagente independente, novo para esta verificação; autor ≠ verifier.

O veredito é FAIL porque C1–C5, C7–C8 e C11–C16 incluem observações manuais que não realizei, e o conjunto de assertions de C6 não cobre todas as mutações negativas que o critério afirma. O build passou na repetição; os testes SQL passaram. C10 também passou pela reprodução manual independente em duas sessões SQL descrita abaixo.

## Escopo lido

Li integralmente `AGENTS.md`, `.tasks/contatos-administrativos-fr-017-ac-007.md`, `.checks/contatos-administrativos-fr-017-ac-007.md` e o diff completo solicitado (21 arquivos; 2.071 inserções e 71 remoções). Os arquivos do diff foram:

- `.checks/autenticacao-administrativa.md`, `.checks/contatos-administrativos-fr-017-ac-007.md`, `.notebook/INDEX.md`, `.notebook/admin-auth-flow.md`, `.notebook/admin-contact-management-flow.md`, `.tasks/contatos-administrativos-fr-017-ac-007.md`, `README.md`;
- `src/app/_components/public-layout.tsx`, `src/app/admin/_components/admin-contacts-manager.tsx`, `src/app/admin/contatos/actions.ts`, `src/app/admin/contatos/page.tsx`, `src/app/globals.css`, `src/lib/auth/admin-bank.ts`, `src/lib/contacts/admin-server.ts`, `src/lib/contacts/admin-types.ts`;
- `supabase/migrations/20261022000000_contatos_administrativos.sql`, `20261023000000_contatos_admin_resolver_privileges.sql`, `20261024000000_admin_contact_resolver_grant.sql`, `20261025000000_admin_contact_manager_checker_membership.sql`, `20261026000000_admin_contact_highlight_dto.sql` e `supabase/tests/contatos-administrativos.test.sql`.

Também li as fontes relevantes indicadas pela task/checklist: `.tasks/autenticacao-administrativa.md`, `.checks/autenticacao-administrativa.md` e seu relatório independente; `.tasks/autenticacao-comunidade-whatsapp-fr-013-fr-015.md`, sua checklist e seu relatório independente; `.notebook/INDEX.md` e os três fluxos; `docs/produto/requisitos.md`, `docs/produto/criterios-de-aceite.md`, `docs/produto/regras-de-negocio.md`; `docs/ux/acessibilidade-e-fluxos.md`; os três documentos de arquitetura e `docs/privacidade/requisitos-de-dados.md`; o `src/app` completo; os fluxos existentes de autenticação/contato, sessão SSR e Proxy; `supabase/seed.sql`, `supabase/config.toml`, as migrations anteriores citadas e os testes SQL citados/executados.

Abri a fonte vinculante `docs/ux/acessibilidade-e-fluxos.md` integralmente. Ela fixa as regras gerais de interface (`:5-26`), as prioridades administrativas (`:59-62`) e os estados remotos (`:83-92`). A comparação formal fonte-a-tela e a enumeração de composição pertencem ao perfil `ui`, não ao perfil `light`; não as declaro concluídas. Nenhuma prova visual foi inferida da implementação ou do CSS.

Consultei a documentação local instalada do Next.js 16.4.0: `node_modules/next/AGENTS.md`; `dist/docs/01-app/01-getting-started/{03-layouts-and-pages,05-server-and-client-components,07-mutating-data,16-proxy}.md`; `dist/docs/01-app/02-guides/{authentication,authentication-with-cache-components,server-actions,forms,data-security,redirecting,building,instant-navigation}.md`; e `dist/docs/01-app/03-api-reference/03-file-conventions/02-route-segment-config/instant.md`. A rota usa `export const instant = false` e uma fronteira `Suspense`; as convenções de `searchParams`, Server Actions, autorização no servidor e `instant` conferem com a documentação instalada. O build é a prova de compilação, não de comportamento ou visual.

## Fonte de interface

| Fonte vinculante | Leitura | Resultado desta rodada |
|---|---|---|
| `docs/ux/acessibilidade-e-fluxos.md` | Completa | Fonte lida. O perfil `light` não executa a comparação formal de telas. C1, C11–C16 e as partes visuais de C2–C5/C7–C8/C15 continuam sem prova manual; não há conclusão visual positiva ou negativa nesta rodada. |

## Comandos automatizados executados na HEAD

| Comando | Resultado observado |
|---|---|
| `npm run build` — primeira execução | **Exit 1.** Next.js 16.4.0 compilou, concluiu TypeScript e imprimiu a tabela de rotas; em seguida parou com `SecurityFatalError`: versão afetada por vulnerabilidade conhecida e instrução para repetir o comando. |
| `npm run build` — repetição idêntica | **Exit 0.** Compilação, TypeScript e geração de rotas concluídos. O processo continuou após emitir o aviso de vulnerabilidade do Next.js. A recomendação de upgrade permanece aberta; nenhum upgrade foi executado nesta verificação. |
| `npx --yes supabase@latest test db` | **Exit 0 — `Files=6, Tests=207`, `All tests successful`, `Result: PASS`.** `contatos-administrativos.test.sql ..... ok`; os seis arquivos terminaram `ok`. O runner não imprime cada rótulo pgTAP individualmente, portanto cada assertion abaixo foi localizada no arquivo efetivamente executado. |

O stack local já estava em execução. Não rodei `db reset`, `db seed`, migrations, outros runners, automação de navegador, deploy ou serviços de produção. Os testes SQL usam suas transações/rollback. A prova C10 foi SQL manual em sessões locais, não um runner.

## Checks F0 e C1–C16

| Check | Claim | Prova executada / resultado | Assertion localizada — expressão exata, ou prova manual pendente |
|---|---|---|---|
| **F0** | Fixture administrativa local sintética carregada | `npx --yes supabase@latest test db` — exit 0; o arquivo que contém a assertion terminou `ok`. **PASS.** Revisão independente do seed também concluída. | `supabase/tests/contatos-administrativos.test.sql:5-28`: `exists (select 1 from auth.users as auth_user join catalog.user_roles as user_role on user_role.user_id = auth_user.id and user_role.role = 'admin_banco' and user_role.is_active join catalog.entities as entity on entity.id = user_role.entity_id where auth_user.id = '90000000-0000-4000-8000-000000000001' and auth_user.instance_id = '00000000-0000-0000-0000-000000000000' and auth_user.email = 'admin-rotary-boa-vista@banco-ortopedico.test' and entity.code = 'SYN-ROTARY-BOA-VISTA') and (select count(*) = 1 from catalog.user_roles where user_id = '90000000-0000-4000-8000-000000000001' and role = 'admin_banco' and is_active)`; rótulo exato: `'F0 local synthetic admin fixture is loaded for Rotary Boa Vista'`. O `select ok(...)` passou porque o arquivo executado terminou `ok`. Revisei `supabase/seed.sql` completo: `:23-34` identifica entidades `SYN-*` e `Rotary Boa Vista (sintético)`; `:36-89` identifica a conta/credencial como local e sintética; não há CPF, telefone, nome de pessoa nem credencial de produção no seed. O restante contém tipos genéricos e fixtures sintéticas. F0 não foi inferido do seed ou do R2 anterior. |
| **C1** | Navegação administrativa visível, sem menu escondido | Procedimento manual da checklist **não executado**; sem prova visual. | Sem assertion automatizada: `.checks/contatos-administrativos-fr-017-ac-007.md:71-73` exige abrir `/admin/contatos` e conferir literalmente `Contatos recebidos` sem menu escondido. Há markup em `src/app/admin/contatos/page.tsx:116-129` (`<nav aria-label="Tarefas prioritárias do banco" ...>` e `<Link aria-current="page" href="/admin/contatos">Contatos recebidos</Link>`), mas isso não é prova de apresentação. **PENDENTE.** |
| **C2** | Coleção da entidade autorizada, sem duplicatas, nome/código/situação canônicos | Supabase SQL — exit 0; assertion passou. Conferência manual de tela, código e rótulos **não executada**. | `supabase/tests/contatos-administrativos.test.sql:260-273`: `results_eq($$ select bank_name, codigo, situacao from public.admin_bank_contacts(null) where codigo is not null order by codigo $$, $$ values ('Rotary Boa Vista (sintético)'::text, 'A1B2C3D4E5F6'::text, 'novo'::text), ('Rotary Boa Vista (sintético)'::text, 'A7B8C9D0E1F2'::text, 'novo'::text) $$, 'C2 Rotary Boa Vista collection returns the canonical bank name and each authorized row once; C6 admin contact collection is isolated across four synthetic entities - C6 admin Rotary sees only its synthetic contacts')`. **PENDENTE — subprova SQL PASS; UI pendente.** |
| **C3** | Busca exata mostra o mesmo código e situação | Supabase SQL — exit 0; assertion do RPC passou. Pesquisa manual da tela **não executada**. | `supabase/tests/contatos-administrativos.test.sql:275-285`: `results_eq($$ select bank_name, codigo, situacao from public.admin_bank_contacts('A1B2C3D4E5F6') where codigo is not null $$, $$ values ('Rotary Boa Vista (sintético)'::text, 'A1B2C3D4E5F6'::text, 'novo'::text) $$, 'C3 exact message code search returns the same code and current situation')`. A assertion SQL não substitui a busca manual exigida em `.checks/...md:79-81`. **PENDENTE — subprova SQL PASS; UI pendente.** |
| **C4** | Destaque textual após 48 h, sem mudança automática de situação | Supabase SQL — exit 0; assertion passou para 49 h e 47 h. Destaque observado na tela **não**. | `supabase/tests/contatos-administrativos.test.sql:287-303`: `exists (select 1 from public.admin_bank_contacts(null) where codigo = 'A1B2C3D4E5F6' and situacao = 'novo' and destaque_48_horas) and exists (select 1 from public.admin_bank_contacts(null) where codigo = 'A7B8C9D0E1F2' and situacao = 'novo' and not destaque_48_horas)`. As fixtures estão em `:218-219` (49 h/47 h); o limite exato de 48 h não foi amostrado. **PENDENTE — subprova SQL PASS, lacuna de amostragem no limite e observação manual pendente.** |
| **C5** | Pesquisa parcial/malformada, inexistente ou de outra entidade não retorna contato | Supabase SQL — exit 0; assertion passou. Estado vazio da tela **não revisado**. | `supabase/tests/contatos-administrativos.test.sql:305-327`: `(select count(*)::integer = 0 from public.admin_bank_contacts('A1B2') where codigo is not null) and (select count(*)::integer = 0 from public.admin_bank_contacts('a1b2c3d4e5f6') where codigo is not null) and (select count(*)::integer = 0 from public.admin_bank_contacts('FFFFFFFFFFFF') where codigo is not null) and (select count(*)::integer = 0 from public.admin_bank_contacts('B1C2D3E4F5A6') where codigo is not null)`; rótulo exato: `'C5 exact search rejects malformed, missing, and other-entity codes'`. **PENDENTE — subprova SQL PASS; UI pendente.** |
| **C6** | Autorização por sessão/entidade, negativas, RLS e ausência de elevação por claims do cliente | Supabase SQL — exit 0; o arquivo inteiro passou. **PARCIAL — não PASS integral.** | Claim forjado (`:344-352`): `is((select count(*)::integer from public.admin_bank_contacts('B1C2D3E4F5A6') where codigo is not null), 0, 'C6 forged browser role and entity claims do not change the bank scope')`. Leitura Companion (`:472-479`): `is((select count(*)::integer from public.admin_bank_contacts(null) where codigo is not null), 0, 'C6 Companion without admin_banco receives no administrative contacts')`; as linhas `:487-509` testam leitura vazia para vínculo inativo/ausente. Escrita negativa Community (`:460-464`): `throws_ok($$select public.admin_set_contact_situation('A1B2C3D4E5F6', 'atendido')$$, 'P0001', 'Contato indisponível', 'C6 Community without admin_banco cannot change a contact')`; anon recebe `42501` em `:377-380`. **Gap:** não há chamada/assertion de `admin_set_contact_situation` para Companheiro, `admin_banco` inativo ou usuário sem papel ativo; para esses atores o teste afirma somente a coleção vazia. Assim, a parte “somente vínculo ativo permite leitura/alteração” não tem cobertura explícita de mutação para todos os tipos de identidade nomeados. O código da função tem a guarda compartilhada em `supabase/migrations/20261022000000_contatos_administrativos.sql:147-149`, mas código não substitui a assertion ausente. Não atribuo qualquer resultado a `admin_geral`. |
| **C7** | Uma única transição para cada destino; apenas `situacao` muda | Supabase SQL — exit 0; assertions de destino, preservação e bloqueio do retorno passaram. Conferência manual dos rótulos **não executada**. | `supabase/tests/contatos-administrativos.test.sql:517-520`: `is(public.admin_set_contact_situation('A1B2C3D4E5F6', 'atendido'), 'atendido', 'C7 atendido changes the situation from novo')`; `:564-568`: `is(public.admin_set_contact_situation('B1C2D3E4F5A6', 'sem_retorno'), 'sem_retorno', 'C7 sem_retorno changes the situation from novo')`; `:596-600`: `is(public.admin_set_contact_situation('C1D2E3F4A5B6', 'virou_emprestimo'), 'virou_emprestimo', 'C7 virou_emprestimo changes the situation from novo')`. Exemplo da assertion de preservação (`:523-540`): `exists (select 1 from catalog.community_contacts as contact join contact_snapshot as snapshot on snapshot.id = contact.id where contact.codigo = 'A1B2C3D4E5F6' and contact.situacao = 'atendido' and contact.codigo = snapshot.codigo and contact.user_id = snapshot.user_id and contact.entity_id = snapshot.entity_id and contact.equipment_type_code = snapshot.equipment_type_code and contact.recipient_user_id = snapshot.recipient_user_id and contact.recipient_role = snapshot.recipient_role and contact.origem = snapshot.origem and contact.created_at = snapshot.created_at)`. `:549-554` exige SQLSTATE `P0001` para retorno a `novo`. **PENDENTE — subprova SQL PASS; rótulos da tela pendentes.** |
| **C8** | Auditoria contém ator/ação/entidade/contato/antes/depois/data; sem PII em auditoria ou logs | Supabase SQL — exit 0; assertions de auditoria/schema passaram. Inspeção manual de logs **não executada**. | `supabase/tests/contatos-administrativos.test.sql:621-635`: `exists (select 1 from catalog.community_contact_situation_audit as audit where audit.actor_user_id = '94000000-0000-4000-8000-000000000002' and audit.action = 'contact_situation_changed' and audit.entity_id = (select id from catalog.entities where code = 'SYN-A') and audit.contact_id = '96000000-0000-4000-8000-000000000003' and audit.previous_situation = 'novo' and audit.new_situation = 'sem_retorno' and audit.created_at is not null)`; `:637-656` compara `array_agg(attribute.attname::text order by attribute.attnum)` com `array['id', 'actor_user_id', 'action', 'entity_id', 'contact_id', 'previous_situation', 'new_situation', 'created_at']::text[]`. Isso não prova o conteúdo de logs de aplicação. **PENDENTE — subprovas SQL PASS; logs pendentes.** |
| **C9** | Repetir o mesmo destino preserva uma transição e uma auditoria | Supabase SQL — exit 0; assertion passou. **PASS.** | `supabase/tests/contatos-administrativos.test.sql:685-699`: `(select count(*)::integer = 1 from catalog.community_contact_situation_audit as audit where audit.contact_id = '96000000-0000-4000-8000-000000000005') and exists (select 1 from catalog.community_contacts as contact where contact.id = '96000000-0000-4000-8000-000000000005' and contact.codigo = 'D1E2F3A4B5C6' and contact.situacao = 'sem_retorno')`; rótulo exato: `'C9 repeating the same destination leaves one contact transition and one audit row'`. |
| **C10** | Pedidos concorrentes de destinos diferentes produzem no máximo uma transição/auditoria | Supabase SQL — exit 0; três assertions **sequenciais** em `:708-733`, não prova de concorrência. Prova manual independente em duas sessões locais — **PASS**. | SQL sequencial: `is(public.admin_set_contact_situation('A7B8C9D0E1F2', 'atendido'), 'atendido', 'C10 first competing destination is confirmed')`; depois `throws_ok($$select public.admin_set_contact_situation('A7B8C9D0E1F2', 'sem_retorno')$$, 'P0002', 'Situação já registrada', 'C10 a competing destination cannot overwrite the confirmed situation or add another audit row')`; a verificação final exige `count(*)::integer = 1` e situação `atendido` (`:720-732`). **Prova independente:** na sessão A, a RPC para `8BC26A8FA1C7` retornou `atendido` e manteve a transação/lock aberta; a sessão B iniciou `sem_retorno` em outra conexão local enquanto A mantinha a transação. Após A confirmar, B recebeu `ERROR: P0002: Situação já registrada`; leitura final antes da limpeza: `8BC26A8FA1C7 | atendido | 1` (uma auditoria). Os seis deletes exatos (auditoria, contato, dois vínculos e dois usuários sintéticos) retornaram `DELETE 1`. Duas tentativas anteriores que retornaram `P0001: Contato indisponível` não foram contadas como prova; seus dados sintéticos também foram removidos (`DELETE 1` em cada linha). Nenhum arquivo/runner foi criado. |
| **C11** | Confirmação de sucesso nomeia situação e oferece um único próximo passo | Procedimento manual da tela **não executado**; sem assertion automatizada. | `.checks/contatos-administrativos-fr-017-ac-007.md:113-115` exige observar sucesso depois da gravação. O código tem renderização estática (`src/app/admin/_components/admin-contacts-manager.tsx:143-151`), mas não foi usada como prova da interação. Busca por rótulos C11/C12/C13/C14/C16 em `supabase/tests/contatos-administrativos.test.sql` não encontrou assertions. **PENDENTE.** |
| **C12** | Carregamento observável e envio duplicado impedido | Procedimento manual com resposta atrasada **não executado**; sem assertion automatizada. | `.checks/contatos-administrativos-fr-017-ac-007.md:117-119` exige observação em execução. O componente contém `disabled={pending || selectedSituation === ""}` (`src/app/admin/_components/admin-contacts-manager.tsx:217-220`), mas isso não demonstra atraso nem prevenção real de duplicidade. **PENDENTE.** |
| **C13** | Coleção/pesquisa vazia explica o resultado e oferece um próximo passo | Procedimento manual **não executado**; sem assertion automatizada. | `.checks/contatos-administrativos-fr-017-ac-007.md:121-123` exige observação com fixtures isoladas. `EmptyContacts` em `src/app/admin/_components/admin-contacts-manager.tsx:79-91` é somente markup; não o trato como prova de estado ou composição. **PENDENTE.** |
| **C14** | Falha de leitura/gravação/rede é recuperável e não vaza erro bruto/PII | Falha controlada e inspeção manual de logs **não executadas**; sem assertion automatizada. | `.checks/contatos-administrativos-fr-017-ac-007.md:125-127` exige falha local controlada, retry e inspeção de logs. `src/lib/contacts/admin-server.ts:135-157` mapeia falhas para `{ kind: "error" }`, mas o source não prova o comportamento em execução. **PENDENTE.** |
| **C15** | Negação genérica para código estrangeiro/desconhecido, sem revelar existência | Supabase SQL — exit 0; assertions RPC passaram. Mensagem na tela **não conferida manualmente**. | `supabase/tests/contatos-administrativos.test.sql:742-752`: `throws_ok($$select public.admin_set_contact_situation('B1C2D3E4F5A6', 'atendido')$$, 'P0001', 'Contato indisponível', 'C15 foreign and unknown contact codes receive the same generic denial - foreign code')` e `throws_ok($$select public.admin_set_contact_situation('FFFFFFFFFFFF', 'atendido')$$, 'P0001', 'Contato indisponível', 'C15 foreign and unknown contact codes receive the same generic denial - unknown code')`. **PENDENTE — subprova SQL PASS; tela pendente.** |
| **C16** | Verificação visual manual a 360 px e requisitos de acessibilidade | Nenhuma inspeção visual realizada; automação de navegador proibida; sem assertion automatizada. | `.checks/contatos-administrativos-fr-017-ac-007.md:133-135` define a prova manual completa. **PENDENTE.** CSS/build não foram usados como prova de medidas, contraste, foco, composição, viewport ou comportamento. |

## Níveis, amostragem e dimensões `Swept` (perfil `light`)

- A checklist não contém `Coverage` nem `Test policy`; ambos são N/A. Fault injection não faz parte de `light` e nenhum fault foi injetado.
- C6 é um gap de amostragem/prova: as leituras negativas abrangem Companheiro, vínculo inativo e usuário sem vínculo; as assertions de escrita negativa abrangem anon e Community, mas não os três atores autenticados restantes. A assertion que o teste tem sobre a função de escrita não prova esses casos sem a chamada correspondente.
- C4 cobre 49 h e 47 h, mas não o instante exato de 48 h; além disso, a observação textual na tela permanece pendente.
- C8 prova a linha e o schema da auditoria, mas não inspeciona logs de aplicação; a própria checklist marca essa prova manual como pendente.
- C10 não herda prova de concorrência das chamadas sequenciais no arquivo SQL; a lacuna foi preenchida pela sessão A/B independente. A ordem/densidade da coleção permanece `Unresolved 5`, sem requisito inferido.
- validation — formato/código e enum de destinos aparecem em `src/lib/contacts/admin-server.ts:9,122-126` e `supabase/migrations/20261022000000_contatos_administrativos.sql:151-158`; C5/C7 SQL passou. A tela C5 continua pendente.
- failure modes — `admin-server.ts:61-68,108-110,135-157` converte falhas em estados fechados/genéricos; C14 não foi exercitado manualmente, portanto a recuperação real permanece pendente.
- idempotency and retry — a função SQL retorna a situação quando `v_previous_situation = v_target_situation` (`20261022000000_contatos_administrativos.sql:171-173`); a assertion C9 passou. Retry após falha de rede continua pendente em C14.
- authorization — resolução por sessão e RPC estão em `src/lib/auth/admin-bank.ts:23-46` e o banco filtra por `public.current_admin_bank_entity_id()` (`20261022000000_contatos_administrativos.sql:103-126`); C6 tem o gap de mutação acima e não declara resultado de `admin_geral`.
- concurrency and ordering — o mutation RPC usa `FOR UPDATE` (`20261022000000_contatos_administrativos.sql:160-166`); a sessão A/B confirmou o conflito. Nenhuma ordenação visual foi decidida; continua `Unresolved 5`.
- data lifecycle — retenção continua sem decisão jurídica; não há retenção/exclusão adicionada. A proposta de 12 meses para contatos e a proposta inicial de dois anos para auditoria não foram aprovadas.
- external-dependency failure — nenhuma dependência externa nova foi introduzida; o erro local da operação cai no estado genérico em `admin-server.ts:135-157`. C14 manual permanece pendente.
- state transitions — a função limita destino e estado anterior em `20261022000000_contatos_administrativos.sql:151-177`; C7, C9 e C10 passaram conforme as provas descritas.
- observability — a inserção de auditoria atômica está em `20261022000000_contatos_administrativos.sql:189-206`; C8 schema/audit passou; inspeção manual dos logs permanece pendente.

## Gates e escopo preservado

- A conta/Auth sintética e o redirecionamento local da tarefa administrativa anterior não habilitam identidades de produção. Os três gates dessa tarefa — identidade/provisionamento de produção, auditoria de alterações diretas de papéis e recuperação de senha — continuam abertos.
- Retenção de contatos sem empréstimo continua sujeita a aprovação jurídica; retenção da auditoria também permanece aberta. Nenhum prazo foi escolhido ou automatizado.
- `admin_geral` permanece `Unresolved`; esta verificação não amplia nem declara acesso global. Filtros, ordenação/densidade, campos adicionais e confirmação prévia também permanecem sem decisão.
- Os gates herdados de SMS, destinatários reais, aviso jurídico, `SUPABASE_SERVICE_ROLE_KEY`/proxy confiável e retorno padrão de `/entrar` não foram alterados.
- O relatório anterior de WhatsApp foi lido: somente o C14 daquele recorte foi aprovado. **Não declaro M-C1–M-C13 nem M-C15 da feature WhatsApp verificados.**
- Não alterei aplicação, migrations, testes, task ou critérios; não fiz commit, push, upgrade ou deploy. O stack local permaneceu em execução. A única alteração de arquivo nesta rodada é este relatório.
- Provas manuais pendentes continuam sendo provas de interface/execução; não foram substituídas por CSS, build, markup, assertions de nível inferior ou automação de navegador.

## Gate final

**FAIL.** F0, C9 e C10 estão integralmente provados. C6 tem assertions SQL aprovadas, mas cobertura incompleta da negação de mutação para todas as identidades explicitadas. C1–C5, C7–C8 e C11–C16 continuam pendentes na parcela manual especificada. O build passou somente na repetição após a recomendação de segurança; o aviso de vulnerabilidade do Next.js 16.4.0 permanece sem upgrade nesta rodada.
