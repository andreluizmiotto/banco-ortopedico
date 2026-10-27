# Acervo e unidades físicas — checks

Mutations: 3
Build: `npm run build`; `npx eslint src/app/admin src/lib/acervo`
Plan: `.specs/features/acervo-unidades-fisicas-fr-018-fr-025-fr-029/plan.md`

## Intent

25 critérios em 4 fatias · 4 portas unidirecionais · 0 pendências abertas.

## Checks

### S1 - Consultar o acervo do próprio banco

**C1** - A RPC de acervo devolve o nome público do banco da sessão e somente as unidades da entidade autorizada, uma vez cada (AC 1)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C1 acervo collection returns the canonical bank and only its units, C1 acervo collection isolates all four synthetic entities

**C2** - O painel deriva as contagens das seis situações a partir das unidades e mostra zero quando não há unidade naquela situação (AC 2)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C2 situation counts cover all six values including zero, C2 situation values stay within the canonical enum

**C3** - A coleção é agrupada por tipo e ordenada por identificador crescente, com nulos por último (AC 3)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C3 units are ordered by type then identifier with nulls last

**C4** - Sem unidades, a tela mostra estado vazio com explicação e exatamente um próximo passo para cadastrar a primeira unidade (AC 4)
Proof: walk - entrar com a identidade sintética de uma entidade sem unidades e abrir /admin/acervo

**C5** - Falha de leitura mostra mensagem compreensível e ação para tentar novamente, sem erro bruto do banco (AC 5)
Proof: walk - interromper a leitura local e reabrir /admin/acervo

**C6** - Sem sessão a rota redireciona para `/admin/entrar`; sem vínculo `admin_banco` ativo a tela mostra falta de permissão sem revelar banco, unidade ou contagem (AC 6)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C6 acervo RPCs reject anon, C6 acervo RPCs reject a session without an active admin_banco, C6 acervo RPCs reject an inactive admin_banco, C6 acervo RPCs reject an admin_banco from another entity
Proof: walk - abrir /admin/acervo sem sessão e com a identidade sintética sem vínculo ativo

**C7** - A navegação administrativa oferece `Acervo de equipamentos` para `/admin/acervo`, sem menu escondido (AC 7)
Proof: walk - abrir /admin/contatos com a identidade sintética e acionar Acervo de equipamentos

### S2 - Cadastrar uma unidade física

**C8** - O cadastro grava exatamente uma unidade com `owner_entity_id` igual à entidade da sessão e os valores enviados (AC 8)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C8 create unit derives the owner entity from the session and persists every field

**C9** - Depois do cadastro, a tela mostra confirmação com tipo, situação inicial e um único próximo passo, e o painel reflete a nova contagem (AC 9)
Proof: walk - cadastrar uma unidade sintética em /admin/acervo e conferir confirmação e painel

**C10** - Identificador em branco vira nulo; preenchido é aparado e limitado a 64 caracteres (AC 10)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C10 blank identifier is stored as null, C10 identifier is trimmed and preserves its internal text, C10 identifier longer than 64 characters is rejected

**C11** - Identificador repetido na mesma entidade é rejeitado; o mesmo identificador em outra entidade é aceito (AC 11)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C11 duplicate identifier in the same entity is rejected, C11 the same identifier is accepted in another entity

**C12** - Tipo inexistente ou inativo, ponto inexistente, situação fora das seis ou origem fora das quatro são rejeitados sem unidade nem auditoria (AC 12)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C12 invalid creation inputs are rejected without unit or audit
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C12 all four entry origins are accepted

**C13** - A criação grava, na mesma transação, auditoria `unit_created` com ator, entidade, unidade, situação, ponto, identificador, origem e data/hora (AC 13)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C13 creation writes one unit_created audit with the complete actor and values

### S3 - Editar uma unidade existente

**C14** - A edição altera somente identificador, ponto de guarda e situação, mantendo tipo e proprietário (AC 14)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C14 update changes only visible code, storage location and situation

**C15** - Qualquer uma das seis situações pode ir para qualquer outra, inclusive a partir de `doado` e `baixado`, com uma auditoria `unit_updated` contendo antes e depois (AC 15)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C15 every situation can transition to every other situation with audit
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C15 doado and baixado are no longer terminal for the inventory panel

**C16** - Repetir os mesmos valores mantém a unidade e não cria auditoria adicional; reenvio após sucesso produz o mesmo resultado (AC 16)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C16 repeating the same update creates no extra audit row

**C17** - Unidade de outra entidade ou inexistente recebe a mesma negação genérica, sem linha e sem auditoria (AC 17)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C17 foreign and unknown unit identifiers receive the same generic denial

**C18** - Dois pedidos simultâneos na mesma unidade são serializados; cada alteração efetiva tem exatamente uma auditoria (AC 18)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C18 effective updates are serialized and each leaves one audit
Proof: walk - duas sessões SQL locais simultâneas na mesma unidade sintética; a segunda aguardou o travamento da primeira e ambas deixaram auditoria

**C19** - Depois da edição, a tela mostra a situação resultante e um único próximo passo, e o painel reflete a contagem nova (AC 19)
Proof: walk - alterar a situação de uma unidade sintética em /admin/acervo e conferir confirmação e painel

### S4 - Isolamento, estados e acessibilidade

**C20** - `anon`, sessão sem `admin_banco`, sessão de outra entidade e papel/entidade forjados pelo navegador não leem nem gravam; as roles da Data API não acessam as tabelas diretamente (AC 20)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C20 client and service roles cannot read or write units and audit directly, C20 client and service roles cannot call the acervo RPCs, C20 forged browser role and entity claims do not change the bank scope, C20 another entity cannot update a unit

**C21** - Enquanto criação ou edição aguarda resposta, a tela mostra indicador e texto e impede envio duplicado (AC 21)
Proof: walk - enviar o formulário com resposta local atrasada e tentar acionar duas vezes

**C22** - Falha de validação, conflito, rede ou servidor mostra mensagem compreensível e ação recuperável, sem SQL ou identificador interno (AC 22)
Proof: walk - provocar identificador repetido e interrupção de rede no formulário

**C23** - A tela a 360 px não tem rolagem horizontal; botões ≥56 px e negrito ≥20 px; texto ≥18 px; títulos ≥26 px; foco e informação não dependem só de cor/ícone; uma ação principal; paleta oficial; linguagem cotidiana (AC 23)
Proof: walk - revisar /admin/acervo a 360 px com dados sintéticos

**C24** - O formulário oferece somente tipos ativos, todos os pontos, as seis situações com `Disponível no depósito` pré-selecionada e as quatro origens; identificador e ponto podem ficar vazios (AC 24)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C24 options return active types and every storage location
Proof: walk - abrir o cadastro e conferir as opções e os campos vazios

**C25** - Uma unidade de tipo hoje inativo continua visível e editável em identificador, ponto e situação, sem oferecer troca de tipo (AC 25)
Proof: npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C25 an inactive type remains readable and its unit remains editable

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| `GET /admin/acervo` statuses (3) | `200` C1 · `307` C6 · `200` falta de permissão C6 | - |
| `admin_bank_equipment_units` statuses (3) | `200` C1 · `401` C20 · `403` C20 | - |
| `admin_bank_equipment_options` statuses (3) | `200` C24 · `401` C20 · `403` C20 | - |
| `admin_create_equipment_unit` statuses (4) | `200` C8 · `400` C11/C12 · `401` C20 · `403` C20 | - |
| `admin_update_equipment_unit` statuses (4) | `200` C14 · `400` C17 · `401` C20 · `403` C20 | - |
| situações (6) | `disponivel` C2/C15 · `reservado` C2/C15 · `emprestado` C2/C15 · `manutencao` C2/C15 · `doado` C2/C15 · `baixado` C2/C15 | - |
| origens (4) | `doacao` C12 · `compra` C12 · `retorno_conserto` C12 · `devolucao_outro_banco` C12 | - |
| portas unidirecionais (4) | identificador C11 · origem C8/C12 · auditoria C13/C15 · caminho privado C6/C20 | - |
| telas e estados (6) | carregando C21 · vazio C4 · falha C5/C22 · falta de permissão C6 · sucesso de cadastro C9 · sucesso de edição C19 | - |
| controles da tela (5) | link `Acervo de equipamentos` C7 · enviar cadastro C8 · enviar edição C14 · tentar novamente C5 · próximo passo do vazio C4 | - |
| entradas inválidas de criação (5) | tipo inexistente C12 · tipo inativo C12 · ponto inexistente C12 · situação inválida C12 · origem inválida C12 | - |
| autorizações (4) | `anon` C20 · sem `admin_banco` C20 · `admin_banco` de outra entidade C20 · papel/entidade forjados C20 | - |

## Swept

- validation: C10, C12, C17
- failure modes: C5, C22
- idempotency: C16
- authorization: C6, C20
- concurrency: C18
- data lifecycle: C16, C25
- dependency failure: C5, C22 - a leitura e a gravação dependem do Supabase; a falha recuperável é a mesma da tela
- state transitions: C15
- observability: C13, C15

## Handoff

- **Settled mid-build:** origem obrigatória e um dos quatro valores de FR-018; qualquer situação para qualquer situação, com auditoria; identificador livre, nulo e único por banco; tipo fixo e situação inicial escolhida com `disponivel` pré-selecionada; todos os pontos cadastrados; lista agrupada por tipo sem filtros; rótulo `Acervo de equipamentos`; seis situações sempre visíveis; estoque mínimo fora do recorte; sem paginação por enquanto; auditoria registrada e consultada diretamente no banco pelos desenvolvedores.
- **Dispatched:** none
- **Boundary:** aguardando implementação
- **Abandoned:** none
- **Walked:** caminhada HTTP local em 2026-10-27 com o admin sintético do Rotary Boa Vista: `/admin/acervo` mostrou o banco, as seis contagens iguais a 1, a lista com `BVCR0001` e o formulário com 13 tipos ativos, ponto sintético, seis situações e quatro origens; `/admin/contatos` mostrou o link `Acervo de equipamentos`. Estado vazio confirmado com entidade sintética sem unidades; falta de permissão confirmada com sessão autenticada sem papel; falha de leitura confirmada com o serviço REST parado e ação `Tentar novamente`. A rota sem sessão executa `redirect("/admin/entrar")` no servidor, conforme o código. Concorrência manual: duas sessões SQL locais atualizaram a mesma unidade sintética; a sessão B aguardou o travamento da sessão A, a situação final foi `manutencao` e a auditoria registrou `unit_created`, `disponivel>reservado` e `reservado>manutencao`; os registros temporários foram removidos. A submissão interativa dos formulários e a revisão visual a 360 px ainda dependem da conferência manual do desenvolvedor, conforme `AGENTS.md`; não foi usado Playwright, Cypress ou Puppeteer.
