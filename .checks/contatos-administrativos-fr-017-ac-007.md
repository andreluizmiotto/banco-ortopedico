# Gestão administrativa de contatos da Comunidade — FR-017 / AC-007

State: PLANNED — a funcionalidade não foi implementada e nenhum check foi executado.

Sources:

- `.tasks/contatos-administrativos-fr-017-ac-007.md` — critérios C1–C16, transição única, superfícies, decisões e pendências.
- `AGENTS.md` — dados sintéticos, isolamento RLS, verificação visual manual e comandos automatizados permitidos.
- `supabase/seed.sql` — fixtures locais atuais; ainda não contém usuário `admin_banco` nem entidade sintética identificada como Rotary Boa Vista.
- `supabase/config.toml` — configuração de Supabase local e OTP sintético local; não é configuração de produção.
- `supabase/migrations/20261014000000_autenticacao_comunidade.sql` — enum/papéis e vínculo de `admin_banco` à entidade.
- `supabase/migrations/20261014010000_contatos_comunidade.sql` e `supabase/migrations/20261014020000_perfil_privado_e_uid_rls.sql` — situação, registros de contato, RLS e operações privadas já existentes.
- `supabase/tests/contatos-comunidade.test.sql` — padrão atual de assertions RLS com entidades, usuários e dados sintéticos transacionais.
- `.checks/autenticacao-comunidade-whatsapp-fr-013-fr-015.verified.md` — somente C14 foi aprovado; M-C1–M-C13 e M-C15 continuam sem verificação manual.

## Out of scope

- Implementar a tela, ações, RPCs, políticas, migrations ou novos testes nesta sessão.
- Alterar `supabase/seed.sql` nesta sessão: a estratégia foi definida, mas o usuário escolheu limitar as alterações ao arquivo `.checks`.
- Criar autenticação ou cadastro administrativo de produção. A fixture local não equivale a uma sessão administrativa disponível na aplicação.
- Usar dados reais, credenciais reais, CPF, telefone operacional, contatos ou destinatários reais em seeds, testes, logs ou evidências.
- Automatizar verificação visual ou usar Playwright, Cypress ou Puppeteer.
- Resolver retenção, acesso de `admin_geral`, rota, filtros, ordenação, campos adicionais ou confirmação prévia que permanecem em `Unresolved` na task.
- Alterar o contrato público de `equipment_availability`, a mensagem revisável do WhatsApp ou a deduplicação de 30 minutos.

## Fixture sintética local

A estratégia escolhida é uma identidade sintética somente para Supabase local. Antes dos checks que dependem de um administrador, a fixture futura em `supabase/seed.sql` deve:

- criar um usuário local sintético e um vínculo `catalog.user_roles` ativo com `role = 'admin_banco'`;
- vincular esse papel por `entity_id` a uma entidade sintética que represente o Rotary Boa Vista;
- ser repetível sem criar vínculos duplicados e não conter dados ou credenciais de produção;
- permitir identificar o ator de teste por seu UUID sintético em assertions SQL, sem confiar em `role` ou `entity_id` enviados pelo navegador.

**Situação nesta sessão:** a fixture não foi adicionada. O `seed.sql` atual contém as entidades sintéticas `SYN-A`, `SYN-B` e `SYN-C`, sem usuário Auth ou papel administrativo. Portanto, F0 continua pendente. A fixture futura servirá para validação local; não fecha por si só o bloqueio da task sobre entrada/sessão administrativa na aplicação.

## Checks

### F0 — Identidade administrativa local

**F0** — Após a fixture ser adicionada ao seed local, confirmar que existe um usuário Auth sintético com um único vínculo ativo `admin_banco` e que o `entity_id` aponta para a entidade sintética do Rotary Boa Vista. Confirmar que nenhum CPF, telefone real, nome real ou credencial de produção foi incluído.

Prova: assertion SQL dentro de `supabase test db` para o vínculo e revisão local do seed; manter a fixture somente local/sintética. **Pendente — seed não foi alterado nesta sessão.**

### S1 — Localizar e acompanhar contatos do banco correto

**C1 (critério 1)** — Com uma sessão administrativa local disponível, a navegação principal apresenta a tarefa de contatos recebidos sem menu escondido.

Prova: procedimento manual na aplicação, após existir a dependência de sessão administrativa. Não testar nem inventar uma rota fixa nesta checklist.

**C2 (critério 2)** — Com contatos sintéticos em cada uma das quatro entidades, conferir que a coleção do Rotary Boa Vista mostra somente os registros da entidade autorizada, cada um uma vez, com código e situação atuais. Conferir nome canônico do banco e os quatro rótulos: `Novo`, `Atendido`, `Virou empréstimo` e `Sem retorno`.

Prova: consulta SQL/RLS com dados sintéticos e conferência manual da tela. Nenhum contato real deve ser criado.

**C3 (critério 3)** — Pesquisar o código completo de um contato sintético e conferir que o resultado contém o mesmo código e a situação daquele registro.

Prova: procedimento manual com código sintético conhecido; o código não deve ser trocado pelo código do equipamento.

**C4 (critério 4)** — Conferir um contato sintético `novo` com `created_at` anterior a 48 horas e outro com menos de 48 horas. O primeiro tem destaque textual; o segundo não é destacado por essa regra. Nenhum deles muda de situação automaticamente.

Prova: preparar timestamps apenas em dados locais sintéticos e observar a tela manualmente.

**C5 (critério 5)** — Conferir que uma busca parcial ou por valor que não tenha o formato completo `^[A-F0-9]{12}$` não retorna contato; um código válido sem correspondência também não retorna registro de outra entidade.

Prova: assertion SQL/RPC em `supabase test db` e conferência manual do estado vazio. Não exigir comportamento para filtros não decididos.

**C6 (critério 6)** — Testar acesso com o `admin_banco` sintético da entidade do registro e com identidades sem vínculo ativo para essa entidade, incluindo `anon`, Comunidade sem `admin_banco`, Companheiro sem `admin_banco` e `admin_banco` de outra entidade. Apenas vínculos ativos permitem leitura/alteração no banco correspondente; não há acesso direto às tabelas privadas nem elevação por papel/entidade enviados pelo cliente.

Prova automatizada: assertions SQL negativas e positivas em `supabase test db`, usando as quatro entidades sintéticas e rollback. Não afirmar resultado para `admin_geral`; esse papel continua em `Unresolved`.

### S2 — Registrar uma única mudança de situação

**C7 (critério 7)** — Para contato sintético `novo`, marcar cada destino previsto em casos separados: `atendido`, `sem_retorno` e `virou_emprestimo`. Conferir o valor enum persistido e que somente `situacao` muda; código, ator inicial, entidade, tipo, destinatário efetivo, origem e `created_at` permanecem iguais.

Prova automatizada: assertions SQL em `supabase test db`; conferir também o rótulo correspondente na tela manualmente. Não criar empréstimo como efeito desta mudança.

**C8 (critério 8)** — Em uma transição confirmada, conferir um registro de auditoria com ator, ação, entidade, identificador interno do contato, situação anterior/nova e data/hora. CPF, telefone, nome de pessoa e erro bruto não aparecem na auditoria nem nos logs inspecionados.

Prova automatizada: assertions SQL em `supabase test db`; inspeção manual de logs somente com dados sintéticos.

**C9 (critério 9)** — Repetir o mesmo pedido de mudança depois da confirmação. O contato continua no destino já gravado, mantém o mesmo código e não ganha outra transição nem outro registro de auditoria.

Prova automatizada: duas chamadas SQL/RPC no teste de banco e assertion de um único contato/evento.

**C10 (critério 10)** — Enviar dois pedidos simultâneos com destinos diferentes para o mesmo contato ainda `novo`. No máximo um confirma; a situação final é um dos três destinos e há um único registro de auditoria.

Prova: teste de concorrência no banco local. Se não couber em uma assertion determinística do `supabase test db`, verificar manualmente com duas sessões SQL locais; não criar outro runner ou automação de navegador.

**C11 (critério 11)** — Depois de uma mudança confirmada, conferir mensagem de sucesso com a situação resultante e exatamente um próximo passo.

Prova: procedimento manual na aplicação; não inferir uma confirmação antes de gravar.

**C12 (critério 12)** — Atrasar uma resposta local de leitura/gravação e conferir indicador e texto de carregamento. Durante a gravação, o envio repetido fica impedido.

Prova: procedimento manual, sem automação de navegador.

**C13 (critério 13)** — Com coleção vazia ou pesquisa sem resultado, conferir estado vazio de sucesso com explicação e exatamente um próximo passo; nenhum registro de outra entidade aparece.

Prova: procedimento manual com fixture sintética isolada para cada caso.

**C14 (critério 14)** — Simular falha de leitura/gravação ou interrupção de rede. A tela mostra mensagem compreensível e tentativa recuperável; não mostra erro bruto, CPF, telefone ou nome. A nova tentativa continua coberta por C9/C10.

Prova: procedimento manual com falha controlada local e inspeção dos logs sintéticos; sem Playwright ou outro runner de navegador.

**C15 (critério 15)** — Com sessão sem vínculo ativo para a entidade, conferir mensagem de falta de permissão sem revelar existência do contato/código.

Prova automatizada: negação SQL/RLS em `supabase test db`; prova manual da tela quando houver sessão administrativa local.

**C16 (critério 16)** — Revisar visualmente a 360 px: sem rolagem horizontal; botões principais ≥56 px e texto em negrito ≥20 px; texto corrido ≥18 px; títulos ≥26 px; contraste ≥4,5:1; foco visível; significado não depende só de cor/ícone; uma ação principal por tela; paleta oficial e linguagem cotidiana.

Prova: conferência visual manual pelo desenvolvedor. Não criar automação de navegador.

## Automated checks

Executar somente estes comandos depois da implementação:

- [ ] `npm run build` — build/compilação TypeScript.
- [ ] `supabase test db` — assertions SQL de RLS e comportamento de banco com dados sintéticos.

State: NOT RUN. Nenhum build ou teste foi executado nesta sessão. Não adicionar outros comandos, scripts ou runners automatizados.

## Go-live gates

- [ ] Uma fixture local de `admin_banco` não comprova autenticação administrativa de produção; o acesso/sessão da aplicação continua dependente da tarefa prévia registrada em `Unresolved 1` da task.
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

- Esta checklist não implementa a fixture nem a funcionalidade. `supabase/seed.sql` deve receber a fixture local em uma alteração posterior antes de os checks locais que dependem dela serem marcados como concluídos.
- A fixture local apoia desenvolvimento/teste sintético; não substitui sessão administrativa, login, navegação ou provisionamento de produção.
- Manter todos os resultados como pendentes até existir implementação e prova registrada.
