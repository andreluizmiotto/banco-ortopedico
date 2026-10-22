# Gestão administrativa de contatos da Comunidade — FR-017 / AC-007

State: PLANNED — a funcionalidade não foi implementada e nenhum check foi executado.

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

- Implementar a tela, ações, RPCs, políticas, migrations ou novos testes nesta sessão.
- Alterar `supabase/seed.sql` nesta sessão: a estratégia foi definida, mas o usuário escolheu limitar as alterações ao arquivo `.checks`.
- Criar autenticação ou cadastro administrativo de produção. A fixture local não equivale a uma sessão administrativa disponível na aplicação.
- Usar dados reais, credenciais reais, CPF, telefone operacional, contatos ou destinatários reais em seeds, testes, logs ou evidências.
- Automatizar verificação visual ou usar Playwright, Cypress ou Puppeteer.
- Resolver retenção, acesso de `admin_geral`, filtros, ordenação, campos adicionais ou confirmação prévia que permanecem em `Unresolved` na task. A rota e o rótulo `Contatos recebidos` foram decididos.
- Alterar o contrato público de `equipment_availability`, a mensagem revisável do WhatsApp ou a deduplicação de 30 minutos.

## Landing

A tela usa a sessão SSR e o resolvedor administrativo já existentes. Leitura e mudança
de situação passam por RPCs autenticadas com RLS no schema privado; o navegador recebe
somente nome público do banco, código, situação e data do contato.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Leitura administrativa | `public.admin_bank_contacts(text)` deriva a entidade por `public.current_admin_bank_entity_id()` e retorna apenas dados necessários; `catalog` continua fora dos schemas expostos. | Receber `entity_id` do navegador ou filtrar somente na tela permite acesso direto/cross-entity. |
| Transição e auditoria | `public.admin_set_contact_situation(text, text)` trava a linha `novo`, atualiza somente `situacao` e grava, na mesma transação, uma linha em `catalog.community_contact_situation_audit`, com `contact_id` único e sem PII. | Atualização e auditoria separadas permitem sobrescrita concorrente ou mudança sem trilha. |
| Papel executor privado | `admin_contact_manager` é `NOLOGIN NOBYPASSRLS`; as RPCs usam `search_path` fixo e policies limitadas à entidade derivada da sessão. | Conceder leitura/escrita às roles expostas ou usar service role ampliaria privilégios e contornaria o isolamento. |
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

Prova: assertion `F0 local synthetic admin fixture is loaded for Rotary Boa Vista` em `supabase/tests/contatos-administrativos.test.sql`, executada por `supabase test db`, mais revisão local do seed para confirmar que todos os dados e credenciais são sintéticos. **Pendente até a assertion passar; a existência do fixture no arquivo não é prova de que foi carregado.**

### S1 — Localizar e acompanhar contatos do banco correto

**C1 (critério 1)** — Com uma sessão administrativa local disponível, a navegação principal apresenta a tarefa de contatos recebidos sem menu escondido.

Prova: procedimento manual na aplicação com sessão administrativa local. Abrir `/admin/contatos` e conferir que a navegação principal exibe `Contatos recebidos` sem menu escondido. A sessão prévia e o redirecionamento são registrados em `.checks/autenticacao-administrativa.verified.md`; esta prova ainda precisa conferir a navegação desta tela.

**C2 (critério 2)** — Com contatos sintéticos em cada uma das quatro entidades, conferir que a coleção do Rotary Boa Vista mostra somente os registros da entidade autorizada, cada um uma vez, com código e situação atuais. Conferir nome canônico do banco e os quatro rótulos: `Novo`, `Atendido`, `Virou empréstimo` e `Sem retorno`.

Provas: `C2 admin contact collection returns the canonical bank name and each authorized row once` em `supabase/tests/contatos-administrativos.test.sql` via `supabase test db`; conferência manual da tela, código e quatro rótulos. Nenhum contato real deve ser criado.

**C3 (critério 3)** — Pesquisar o código completo de um contato sintético e conferir que o resultado contém o mesmo código e a situação daquele registro.

Prova: procedimento manual com código sintético conhecido; o código não deve ser trocado pelo código do equipamento.

**C4 (critério 4)** — Conferir um contato sintético `novo` com `created_at` anterior a 48 horas e outro com menos de 48 horas. O primeiro tem destaque textual; o segundo não é destacado por essa regra. Nenhum deles muda de situação automaticamente.

Prova: preparar timestamps apenas em dados locais sintéticos e observar a tela manualmente.

**C5 (critério 5)** — Conferir que uma busca parcial ou por valor que não tenha o formato completo `^[A-F0-9]{12}$` não retorna contato; um código válido sem correspondência também não retorna registro de outra entidade.

Provas: `C5 exact search rejects malformed and foreign codes` em `supabase/tests/contatos-administrativos.test.sql` via `supabase test db`; conferência manual do estado vazio. Não exigir comportamento para filtros não decididos.

**C6 (critério 6)** — Testar acesso com o `admin_banco` sintético da entidade do registro e com identidades sem vínculo ativo para essa entidade, incluindo `anon`, Comunidade sem `admin_banco`, Companheiro sem `admin_banco` e `admin_banco` de outra entidade. Apenas vínculos ativos permitem leitura/alteração no banco correspondente; não há acesso direto às tabelas privadas nem elevação por papel/entidade enviados pelo cliente.

Provas: `C6 admin contact collection is isolated across four synthetic entities` e `C6 client roles cannot read private contact or audit rows` em `supabase/tests/contatos-administrativos.test.sql`, executadas por `supabase test db`; conferir também que claims forjados não mudam o escopo. Não afirmar resultado para `admin_geral`; esse papel continua em `Unresolved`.

### S2 — Registrar uma única mudança de situação

**C7 (critério 7)** — Para contato sintético `novo`, marcar cada destino previsto em casos separados: `atendido`, `sem_retorno` e `virou_emprestimo`. Conferir o valor enum persistido e que somente `situacao` muda; código, ator inicial, entidade, tipo, destinatário efetivo, origem e `created_at` permanecem iguais.

Provas: `C7 each allowed destination changes only situation` em `supabase/tests/contatos-administrativos.test.sql` via `supabase test db`; conferir rótulo na tela manualmente. Não criar empréstimo como efeito desta mudança.

**C8 (critério 8)** — Em uma transição confirmada, conferir um registro de auditoria com ator, ação, entidade, identificador interno do contato, situação anterior/nova e data/hora. CPF, telefone, nome de pessoa e erro bruto não aparecem na auditoria nem nos logs inspecionados.

Provas: `C8 audit records actor, action, entity, internal contact, previous/new situation and time without PII` em `supabase/tests/contatos-administrativos.test.sql` via `supabase test db`; inspeção manual dos logs sintéticos.

**C9 (critério 9)** — Repetir o mesmo pedido de mudança depois da confirmação. O contato continua no destino já gravado, mantém o mesmo código e não ganha outra transição nem outro registro de auditoria.

Prova: `C9 repeating the same destination leaves one contact transition and one audit row` em `supabase/tests/contatos-administrativos.test.sql` via `supabase test db`.

**C10 (critério 10)** — Enviar dois pedidos simultâneos com destinos diferentes para o mesmo contato ainda `novo`. No máximo um confirma; a situação final é um dos três destinos e há um único registro de auditoria.

Provas: `C10 a competing destination cannot overwrite the confirmed situation or add another audit row` em `supabase/tests/contatos-administrativos.test.sql` via `supabase test db`, mais duas sessões SQL locais simultâneas com destinos diferentes. Se a concorrência manual não for executada, C10 permanece pendente; não criar outro runner ou automação de navegador.

**C11 (critério 11)** — Depois de uma mudança confirmada, conferir mensagem de sucesso com a situação resultante e exatamente um próximo passo.

Prova: procedimento manual na aplicação; não inferir uma confirmação antes de gravar.

**C12 (critério 12)** — Atrasar uma resposta local de leitura/gravação e conferir indicador e texto de carregamento. Durante a gravação, o envio repetido fica impedido.

Prova: procedimento manual, sem automação de navegador.

**C13 (critério 13)** — Com coleção vazia ou pesquisa sem resultado, conferir estado vazio de sucesso com explicação e exatamente um próximo passo; nenhum registro de outra entidade aparece.

Prova: procedimento manual com fixture sintética isolada para cada caso.

**C14 (critério 14)** — Simular falha de leitura/gravação ou interrupção de rede. A tela mostra mensagem compreensível e tentativa recuperável; não mostra erro bruto, CPF, telefone ou nome. A nova tentativa continua coberta por C9/C10.

Prova: procedimento manual com falha controlada local e inspeção dos logs sintéticos; sem Playwright ou outro runner de navegador.

**C15 (critério 15)** — Com sessão sem vínculo ativo para a entidade, conferir mensagem de falta de permissão sem revelar existência do contato/código.

Provas: `C15 foreign and unknown contact codes receive the same generic denial` em `supabase/tests/contatos-administrativos.test.sql` via `supabase test db`; prova manual da tela com identidade sem vínculo ativo, sem revelar se o contato existe.

**C16 (critério 16)** — Revisar visualmente a 360 px: sem rolagem horizontal; botões principais ≥56 px e texto em negrito ≥20 px; texto corrido ≥18 px; títulos ≥26 px; contraste ≥4,5:1; foco visível; significado não depende só de cor/ícone; uma ação principal por tela; paleta oficial e linguagem cotidiana.

Prova: conferência visual manual pelo desenvolvedor. Não criar automação de navegador.

## Automated checks

Executar somente estes comandos depois da implementação:

- [ ] `npm run build` — build/compilação TypeScript.
- [ ] `supabase test db` — assertions SQL de RLS e comportamento de banco com dados sintéticos.

State: NOT RUN. Nenhum build ou teste foi executado nesta sessão. Não adicionar outros comandos, scripts ou runners automatizados.

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
- A fixture sintética existe em `supabase/seed.sql`, mas F0 permanece pendente até a assertion SQL passar e o seed ser revisado; não inferir que o arquivo foi carregado a partir da sessão R2.
- A decisão de rótulo `Contatos recebidos` foi confirmada pelo usuário nesta sessão e registrada em `Landing`/`Decided`; os demais itens `Unresolved` permanecem sem decisão.
- Depois do último commit, o orquestrador despachará um Verifier novo sobre o diff completo desde a base do recorte e todos os checks, inclusive os que exigem prova manual. O autor não verifica o próprio trabalho.
