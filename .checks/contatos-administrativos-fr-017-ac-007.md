# Gestão administrativa de contatos da Comunidade — FR-017 / AC-007

State: IN PROGRESS — tela e operações implementadas; os checks automatizados passaram. F0, C6, C9 e C10 têm provas locais concluídas; as provas de interface e a revisão manual permanecem pendentes.

Sources:

- `.tasks/contatos-administrativos-fr-017-ac-007.md` — critérios C1–C16, transição única, limites, decisões e pendências.
- `.checks/autenticacao-administrativa.md` e `.checks/autenticacao-administrativa.verified.md` — dependência administrativa; C2/R2 e `/admin/contatos` foram confirmados localmente. O relatório geral continua FAIL; C11 da autenticação segue pendente.
- `.tasks/autenticacao-comunidade-whatsapp-fr-013-fr-015.md`, `.checks/autenticacao-comunidade-whatsapp-fr-013-fr-015.md` e `.checks/autenticacao-comunidade-whatsapp-fr-013-fr-015.verified.md` — código persistido, deduplicação de 30 minutos, link revisável e fronteira; somente C14 anterior foi aprovado.
- `AGENTS.md` — paleta, linguagem, medidas de acessibilidade, RLS nas quatro entidades, dados sintéticos e limites dos checks.
- `docs/produto/requisitos.md`, `docs/produto/criterios-de-aceite.md` e `docs/produto/regras-de-negocio.md` — FR-017, AC-007, situações canônicas, destaque de 48 horas e limites do domínio.
- `docs/ux/acessibilidade-e-fluxos.md` — **fonte vinculante para a interface**: prioridades administrativas, estados remotos, linguagem e medidas visuais.
- `docs/arquitetura/autenticacao-e-autorizacao.md`, `docs/arquitetura/modelo-conceitual.md`, `docs/arquitetura/visao-geral.md` e `docs/privacidade/requisitos-de-dados.md` — identidade confiável, RLS, auditoria mínima, privacidade e retenção ainda não aprovada.
- `.notebook/INDEX.md`, `.notebook/community-auth-contact-flow.md` e `.notebook/admin-auth-flow.md` — fluxo existente de contato, sessão SSR e escopo `admin_banco`.
- `src/lib/contacts/server.ts` e `src/app/actions/contact.ts` — fluxo comunitário existente, que permanece inalterado.
- `src/app/entrar/actions.ts`, `src/proxy.ts`, `src/app/admin/entrar/actions.ts`, `src/lib/auth/admin-bank.ts`, `src/lib/supabase/server.ts` e a árvore `src/app` — padrões de sessão, proteção server-side e rota atual.
- `supabase/migrations/20261014000000_autenticacao_comunidade.sql`, `20261014010000_contatos_comunidade.sql`, `20261014020000_perfil_privado_e_uid_rls.sql`, `20261015000000_autenticacao_administrativa.sql` e `20261013000000_disponibilidade_publica.sql` — schemas, RLS, situação, autorização e contrato público.
- `supabase/config.toml`, `supabase/seed.sql`, `supabase/tests/contatos-comunidade.test.sql`, `supabase/tests/autenticacao-administrativa.test.sql` e `supabase/tests/disponibilidade-publica.test.sql` — schemas expostos, fixtures sintéticas e padrões de prova SQL.
- Documentação local Next.js 16.4.0 — App Router, Server Components/Actions, autenticação, segurança de dados, formulários, redirecionamento, carregamento e compilação.
- Decisão do usuário nesta sessão — o rótulo literal da navegação para `/admin/contatos` é `Contatos recebidos`.

## Out of scope

- Alterar `supabase/seed.sql` nesta sessão: a estratégia foi definida, mas o usuário escolheu limitar as alterações ao arquivo `.checks`.
- Criar autenticação ou cadastro administrativo de produção. A fixture local não equivale a uma sessão administrativa disponível na aplicação.
- Usar dados reais, credenciais reais, CPF, telefone operacional, contatos ou destinatários reais em seeds, testes, logs ou evidências.
- Automatizar verificação visual ou usar Playwright, Cypress ou Puppeteer.
- Resolver retenção, acesso de `admin_geral`, filtros, ordenação, campos adicionais ou confirmação prévia que permanecem em `Unresolved` na task. A rota e o rótulo `Contatos recebidos` foram decididos.
- Alterar o contrato público de `equipment_availability`, a mensagem revisável do WhatsApp ou a deduplicação de 30 minutos.

## Landing

A tela usa a sessão SSR e o resolvedor administrativo já existentes. Leitura e mudança
de situação passam por RPCs autenticadas com RLS no schema privado; o navegador recebe
somente o nome público do banco, o código, a situação e o destaque textual de 48 horas.
`created_at` é usado no servidor para calcular o destaque, mas não é exibido nem enviado
como campo por contato.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Leitura administrativa | `public.admin_bank_contacts(text)` deriva a entidade por `public.current_admin_bank_entity_id()` e retorna apenas dados necessários; `catalog` continua fora dos schemas expostos. | Receber `entity_id` do navegador ou filtrar somente na tela permite acesso direto/cross-entity. |
| Transição e auditoria | `public.admin_set_contact_situation(text, text)` trava a linha `novo`, atualiza somente `situacao` e grava, na mesma transação, uma linha em `catalog.community_contact_situation_audit`, com `contact_id` único e sem PII. | Atualização e auditoria separadas permitem sobrescrita concorrente ou mudança sem trilha. |
| Papel executor privado | `admin_contact_manager` é `NOLOGIN NOBYPASSRLS`; as RPCs usam `search_path` fixo e policies limitadas à entidade derivada da sessão. | Conceder leitura/escrita às roles expostas ou usar service role ampliaria privilégios e contornaria o isolamento. |
| Resolvedor de entidade para o executor | `admin_contact_manager` herda `admin_bank_authorization_checker` (também `NOLOGIN NOBYPASSRLS`) para reutilizar `public.current_admin_bank_entity_id()` e a policy existente de `catalog.user_roles`. | Duplicar a regra de vínculo ativo em outro resolvedor pode divergir da autorização administrativa já entregue. |
| Destaque de 48 horas | `public.admin_bank_contacts(text)` calcula e devolve somente `destaque_48_horas` para contatos ainda `novo`; `created_at` permanece no servidor. | Enviar `created_at` ao navegador exporia um campo por contato que `Unresolved 6` não decidiu e não é necessário para exibir o destaque. |
| Rótulo de navegação | `Contatos recebidos` é a entrada visível para `/admin/contatos`, conforme decisão explícita do usuário em 2026-10-22. | `Acompanhar contatos` e outros rótulos não foram escolhidos pelo usuário. |

- Nenhuma outra porta unidirecional é necessária; filtros, ordenação, campos adicionais, retenção, `admin_geral` e confirmação prévia continuam fora das decisões desta task.

## Fixture sintética local

A estratégia escolhida é uma identidade sintética somente para Supabase local. Antes dos checks que dependem de um administrador, a fixture em `supabase/seed.sql` deve:

- criar um usuário local sintético e um vínculo `catalog.user_roles` ativo com `role = 'admin_banco'`;
- vincular esse papel por `entity_id` a uma entidade sintética que represente o Rotary Boa Vista;
- ser repetível sem criar vínculos duplicados e não conter dados ou credenciais de produção;
- permitir identificar o ator de teste por seu UUID sintético em assertions SQL, sem confiar em `role` ou `entity_id` enviados pelo navegador.

**Situação antes desta implementação:** `supabase/seed.sql` já contém uma identidade e um papel `admin_banco` sintéticos para `SYN-ROTARY-BOA-VISTA`. O usuário confirmou separadamente a sessão da aplicação e o redirecionamento; isso não comprova que a fixture atual esteja carregada no banco usado pelos checks. F0 permanece pendente até sua assertion e revisão do seed serem realmente executadas.

## Checks

### F0 — Identidade administrativa local

**F0** — Após a fixture ser adicionada ao seed local, confirmar que existe um usuário Auth sintético com um único vínculo ativo `admin_banco` e que o `entity_id` aponta para a entidade sintética do Rotary Boa Vista. Confirmar que nenhum CPF, telefone real, nome real ou credencial de produção foi incluído.

Prova: assertion `F0 local synthetic admin fixture is loaded for Rotary Boa Vista` em `supabase/tests/contatos-administrativos.test.sql` passou em `supabase test db` (exit 0; arquivo `.. ok`). Revisão local de `supabase/seed.sql` confirmou identidade, entidade e credencial sintéticas, sem CPF, telefone ou nome real. **PASS — fixture carregada e assertion executada em 2026-10-22.**

### S1 — Localizar e acompanhar contatos do banco correto

**C1 (critério 1)** — Com uma sessão administrativa local disponível, a navegação principal apresenta a tarefa de contatos recebidos sem menu escondido.

Prova: procedimento manual na aplicação com sessão administrativa local. Abrir `/admin/contatos` e conferir que a navegação principal exibe `Contatos recebidos` sem menu escondido. A sessão prévia e o redirecionamento são registrados em `.checks/autenticacao-administrativa.verified.md`; **PENDENTE — a navegação desta tela não foi revisada manualmente.**

**C2 (critério 2)** — Com contatos sintéticos em cada uma das quatro entidades, conferir que a coleção do Rotary Boa Vista mostra somente os registros da entidade autorizada, cada um uma vez, com código e situação atuais. Conferir nome canônico do banco e os quatro rótulos: `Novo`, `Atendido`, `Virou empréstimo` e `Sem retorno`.

Provas: `C2 Rotary Boa Vista collection returns the canonical bank name and each authorized row once` passou em `supabase test db` (arquivo `.. ok`); conferência manual da tela, código e quatro rótulos **PENDENTE**. Nenhum contato real foi criado.

**C3 (critério 3)** — Pesquisar o código completo de um contato sintético e conferir que o resultado contém o mesmo código e a situação daquele registro.

Prova: procedimento manual com código sintético conhecido; o código não deve ser trocado pelo código do equipamento. **PENDENTE — pesquisa manual não executada.**

**C4 (critério 4)** — Conferir um contato sintético `novo` com `created_at` anterior a 48 horas e outro com menos de 48 horas. O primeiro tem destaque textual; o segundo não é destacado por essa regra. Nenhum deles muda de situação automaticamente.

Provas: `C4 synthetic new contacts straddle the 48-hour highlight threshold` passou em `supabase test db` para timestamps sintéticos de 49 h e 47 h; observar o destaque textual na tela **PENDENTE — não revisado manualmente**.

**C5 (critério 5)** — Conferir que uma busca parcial ou por valor que não tenha o formato completo `^[A-F0-9]{12}$` não retorna contato; um código válido sem correspondência também não retorna registro de outra entidade.

Provas: `C5 exact search rejects malformed, missing, and other-entity codes` passou em `supabase test db`; conferir manualmente o estado vazio **PENDENTE**. Não exigir comportamento para filtros não decididos.

**C6 (critério 6)** — Testar acesso com o `admin_banco` sintético da entidade do registro e com identidades sem vínculo ativo para essa entidade, incluindo `anon`, Comunidade sem `admin_banco`, Companheiro sem `admin_banco` e `admin_banco` de outra entidade. Apenas vínculos ativos permitem leitura/alteração no banco correspondente; não há acesso direto às tabelas privadas nem elevação por papel/entidade enviados pelo cliente.

Provas: assertions `C6 restricted contact function owner cannot log in or bypass RLS`, `C6 contact manager can call the session-derived entity resolver`, `C6 contact manager can derive the authenticated actor`, `C6 admin contact collection is isolated across four synthetic entities` (Rotary, SYN-A, SYN-B e SYN-C), `C6 forged browser role and entity claims do not change the bank scope`, `C6 Community without admin_banco receives no administrative contacts`, `C6 Companion without admin_banco receives no administrative contacts`, `C6 inactive admin_banco receives no administrative contacts`, `C6 authenticated user without an active admin_banco receives no contacts`, `C6 anon cannot call the administrative contact collection`, `C6 client roles cannot read private contact or audit rows directly - contacts`, `C6 client roles cannot read private contact or audit rows directly - audit` e `C6 client and service roles cannot select contact or audit rows directly` passaram em `supabase test db` (exit 0). **PASS.** Não afirmar resultado para `admin_geral`; esse papel continua em `Unresolved`.

### S2 — Registrar uma única mudança de situação

**C7 (critério 7)** — Para contato sintético `novo`, marcar cada destino previsto em casos separados: `atendido`, `sem_retorno` e `virou_emprestimo`. Conferir o valor enum persistido e que somente `situacao` muda; código, ator inicial, entidade, tipo, destinatário efetivo, origem e `created_at` permanecem iguais.

Provas: as seis assertions nomeadas para `atendido`, `sem_retorno` e `virou_emprestimo` e `C7 transition back to novo is rejected` em `supabase/tests/contatos-administrativos.test.sql` passaram em `supabase test db`. **PENDENTE — conferir manualmente os rótulos na tela.** Não criar empréstimo como efeito desta mudança.

**C8 (critério 8)** — Em uma transição confirmada, conferir um registro de auditoria com ator, ação, entidade, identificador interno do contato, situação anterior/nova e data/hora. CPF, telefone, nome de pessoa e erro bruto não aparecem na auditoria nem nos logs inspecionados.

Provas: `C8 audit records actor, action, entity, internal contact, previous/new situation and time` e `C8 audit schema contains no PII columns` passaram em `supabase test db`. **PENDENTE — inspeção manual dos logs sintéticos.**

**C9 (critério 9)** — Repetir o mesmo pedido de mudança depois da confirmação. O contato continua no destino já gravado, mantém o mesmo código e não ganha outra transição nem outro registro de auditoria.

Prova: `C9 repeating the same destination leaves one contact transition and one audit row` passou em `supabase test db` (exit 0; arquivo `.. ok`). **PASS.**

**C10 (critério 10)** — Enviar dois pedidos simultâneos com destinos diferentes para o mesmo contato ainda `novo`. No máximo um confirma; a situação final é um dos três destinos e há um único registro de auditoria.

Provas: `C10 first competing destination is confirmed`, `C10 a competing destination cannot overwrite the confirmed situation or add another audit row` e `C10 only one situation and one audit row remain after competing destinations` passaram em `supabase test db`. **PASS — concorrência manual em duas sessões SQL locais, 2026-10-22:** contato `E0E1E2E3E4E5`, entidade `SYN-ROTARY-BOA-VISTA`, iniciador Comunidade sintético `98000000-0000-4000-8000-000000000001`, situação inicial `novo`. A sessão A segurou o lock, esperou 6 segundos e marcou `atendido`; a sessão B, com o mesmo admin sintético, tentou `sem_retorno` durante o lock, aguardou e recebeu `P0002` / `Situação já registrada`. A leitura final mostrou `atendido` e uma auditoria. O contato, a auditoria, o papel e o usuário sintéticos temporários foram removidos. Não foi criado runner.

**C11 (critério 11)** — Depois de uma mudança confirmada, conferir mensagem de sucesso com a situação resultante e exatamente um próximo passo.

Prova: procedimento manual na aplicação; não inferir uma confirmação antes de gravar. **PENDENTE — sucesso e próximo passo ainda não foram revisados visualmente.**

**C12 (critério 12)** — Atrasar uma resposta local de leitura/gravação e conferir indicador e texto de carregamento. Durante a gravação, o envio repetido fica impedido.

Prova: procedimento manual, sem automação de navegador. **PENDENTE — carregamento atrasado e bloqueio de envio duplicado não foram observados.**

**C13 (critério 13)** — Com coleção vazia ou pesquisa sem resultado, conferir estado vazio de sucesso com explicação e exatamente um próximo passo; nenhum registro de outra entidade aparece.

Prova: procedimento manual com fixture sintética isolada para cada caso. **PENDENTE — estados vazios ainda não foram revisados visualmente.**

**C14 (critério 14)** — Simular falha de leitura/gravação ou interrupção de rede. A tela mostra mensagem compreensível e tentativa recuperável; não mostra erro bruto, CPF, telefone ou nome. A nova tentativa continua coberta por C9/C10.

Prova: procedimento manual com falha controlada local e inspeção dos logs sintéticos; sem Playwright ou outro runner de navegador. **PENDENTE — falha recuperável e retry ainda não foram exercitados na tela.**

**C15 (critério 15)** — Com sessão sem vínculo ativo para a entidade, conferir mensagem de falta de permissão sem revelar existência do contato/código.

Provas: `C15 foreign and unknown contact codes receive the same generic denial - foreign code` e `C15 foreign and unknown contact codes receive the same generic denial - unknown code` passaram em `supabase test db`. **PENDENTE — conferir manualmente a mensagem da tela com identidade sem vínculo ativo, sem revelar se o contato existe.**

**C16 (critério 16)** — Revisar visualmente a 360 px: sem rolagem horizontal; botões principais ≥56 px e texto em negrito ≥20 px; texto corrido ≥18 px; títulos ≥26 px; contraste ≥4,5:1; foco visível; significado não depende só de cor/ícone; uma ação principal por tela; paleta oficial e linguagem cotidiana.

Prova: conferência visual manual pelo desenvolvedor. **PENDENTE — a revisão a 360 px não foi executada.** Não criar automação de navegador.

## Automated checks

Executar somente estes comandos depois da implementação:

- [x] `npm run build` — exit 0; compilação, TypeScript e rotas passaram na repetição recomendada pelo Next.js.
- [x] `supabase test db` — exit 0; `Files=6, Tests=207`, incluindo as assertions SQL `F0`, `C2–C10` e `C15`. As provas manuais continuam pendentes onde indicadas nos critérios.

State: PASS — estes dois checks automatizados passaram. A primeira execução do build parou no aviso de vulnerabilidade do Next.js; a repetição passou sem atualizar dependências. Não foram adicionados outros testes ou runners.

## Local test setup

- `npx --yes supabase@latest start` iniciou a stack local a partir do backup existente; não foi executado `db reset` nem `db seed`.
- `npx --yes supabase@latest migration up --local` aplicou as migrations locais deste recorte; nenhuma conexão ou alteração de produção foi usada.
- A prova manual C10 usou um contato e uma identidade sintéticos temporários, conferiu uma transição/auditoria e removeu somente esses registros.

## Go-live gates

- [ ] A sessão sintética e o redirecionamento foram confirmados localmente; isso não habilita identidades administrativas reais nem resolve os gates de produção em `.tasks/autenticacao-administrativa.md` (Unresolved 1–3).
- [ ] Retenção de contatos sem empréstimo segue pendente de aprovação jurídica; a proposta de 12 meses não foi aprovada. A retenção da auditoria também não foi fechada.
- [ ] Os gates da tarefa anterior para SMS, destinatários reais, aviso jurídico, `SUPABASE_SERVICE_ROLE_KEY`/proxy e retorno padrão de `/entrar` permanecem inalterados.
- [ ] Não declarar M-C1–M-C13 nem M-C15 da tarefa anterior como verificados; seu relatório independente registra somente C14 como aprovado.

## Swept

- validation: C5 e C7 — código completo e destinos limitados ao enum.
- failure modes: C13–C15 — vazio, falha recuperável e permissão negada sem revelar contatos de outra entidade.
- idempotency and retry: C9 e C14 — reenvio não duplica transição/auditoria.
- authorization: C6 e C15 — `admin_banco` ativo, vínculo de entidade e negativas diretas por RLS.
- concurrency and ordering: C10 verifica concorrência; ordenação da coleção continua `Unresolved 5` na task.
- data lifecycle: gate jurídico permanece aberto; nenhum prazo de retenção é inferido ou automatizado.
- external-dependency failure: C14 cobre falha local de rede/servidor; nenhum provedor externo é introduzido.
- state transitions: C7, C9 e C10 — somente uma transição de `novo` para um destino previsto.
- observability: C8 verifica auditoria com ator, entidade, contato, antes/depois e data/hora, sem PII em logs.

## Handoff

- Perfil `light` (nenhum perfil TLC declarado); `handoff: on` por padrão. S1 (coleção, leitura e autorização) toca 11 arquivos existentes, 78.103 B ÷ 4 ≈ 19,5k tokens; S2 (transição, auditoria e falhas de gravação) toca 9 arquivos existentes, 58.247 B ÷ 4 ≈ 14,6k. Total aproximado: 34,1k, abaixo do limite de 150k; S1 e S2 ficam numa única batch, sem builder handoff.
- F0 passou pela assertion SQL após a fixture sintética ser encontrada na base local, e o seed foi revisado sem identificar dados reais. A sessão R2 continua sendo uma prova separada, não uma inferência a partir do seed.
- A decisão de rótulo `Contatos recebidos` foi confirmada pelo usuário nesta sessão e registrada em `Landing`/`Decided`; os demais itens `Unresolved` permanecem sem decisão.
- Depois do último commit, o orquestrador despachará um Verifier novo sobre o diff completo desde a base do recorte e todos os checks, inclusive os que exigem prova manual. O autor não verifica o próprio trabalho.
