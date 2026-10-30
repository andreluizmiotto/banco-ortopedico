# Housekeeping de Nomenclatura — Proposta para Aprovação

**Data:** 2026-10-28
**Status:** aguardando aprovação (nenhum arquivo de código, migration ou `seed.sql` foi alterado)
**Escopo inspecionado:** 12 migrations + `supabase/seed.sql`, 7 testes SQL, `src/app/**`, `src/lib/**`, `docs/produto/**`, `docs/ux/**`, `docs/arquitetura/**`, `AGENTS.md`, `.specs/STATE.md`, os dois `plan.md` em `.specs/features/`.

## Achado principal

A camada de dados já é ~80% inglesa (`equipment_units`, `equipment_types`, `community_contacts`, `user_roles`, `equipment_unit_change_audit`). O débito está concentrado em **1 tabela**, **3 colunas**, **5 enums**, **~20 valores de enum** e **alguns parâmetros de RPC**. O maior volume de trabalho não é o banco: são os **rótulos de tela** e os **testes SQL** (34 ocorrências de `situacao`, 18 de `pontos_atendimento`).

**Achado colateral, fora do escopo:** a raiz do repositório tem ~150 diretórios vazios espúrios (`64/`, `a/`, `accepted/`, `nullC10/`, `rejects/`…), provavelmente resíduo de um comando malformado. Sugestão: `git clean` revisado em tarefa separada.

---

## 1. Tabela de Migração de Banco (PT-BR → EN)

### 1.1 Tabelas

| Atual | Proposto | Evidência |
|---|---|---|
| `catalog.pontos_atendimento` | `catalog.storage_locations` | `20261013000000_disponibilidade_publica.sql:20` |

> `storage_locations` alinha com a coluna já existente `storage_location_id` e com os nomes de policy já em inglês ("Admin equipment manager reads storage locations"). Alternativa: `service_locations` (mais fiel a "ponto de atendimento", menos coerente com a coluna).

### 1.2 Colunas

| Tabela | Atual | Proposto |
|---|---|---|
| `equipment_units` | `situacao` | `status` |
| `community_contacts` | `situacao` | `status` |
| `community_contacts` | `codigo` | `public_code` |
| `community_contacts` | `origem` | `source` |
| `equipment_unit_change_audit` | `previous_situation` / `new_situation` | `previous_status` / `new_status` |
| `community_contact_situation_audit` (nome da tabela) | — | `community_contact_status_audit` |
| RPC `admin_bank_equipment_units` (saída) | `situacao` | `status` |
| RPC `admin_bank_contacts` (saída) | `codigo`, `situacao`, `destaque_48_horas` | `public_code`, `status`, `overdue_48h` |

### 1.3 Tipos (enums) e valores

| Tipo atual | Tipo proposto | Valor atual | Valor proposto |
|---|---|---|---|
| `equipment_situation` | `equipment_status` | `disponivel` | `available` |
| | | `reservado` | `reserved` |
| | | `emprestado` | `on_loan` |
| | | `manutencao` | `under_maintenance` |
| | | `doado` | `donated` |
| | | `baixado` | `written_off` |
| `contact_situation` | `contact_status` | `novo` | `new` |
| | | `atendido` | `answered` |
| | | `virou_emprestimo` | `converted_to_loan` |
| | | `sem_retorno` | `no_response` |
| `equipment_entry_origin` | mantém | `doacao` | `donation` |
| | | `compra` | `purchase` |
| | | `retorno_conserto` | `repair_return` |
| | | `devolucao_outro_banco` | `return_from_other_bank` |
| `user_role` | mantém | `comunidade` | `community` |
| | | `companheiro` | `rotarian` |
| | | `responsavel` | `responsible` |
| | | `substituto` | `substitute` |
| | | `admin_banco` | `bank_admin` |
| | | `admin_geral` | `general_admin` |

`recipient_role` (check subset de `user_role` em `contact_destinations`) passa a usar `('responsible','substitute')`.

### 1.4 Funções, parâmetros e índices

| Atual | Proposto |
|---|---|
| `admin_bank_contacts(p_codigo text)` | `p_public_code` |
| `admin_create_equipment_unit(..., p_situation text, ...)` | mantém (já inglês) |
| `admin_update_equipment_unit(..., p_situation text)` | mantém |
| `equipment_units_owner_type_situation_idx` | `equipment_units_owner_type_status_idx` |
| `community_contacts_owner_entity_type_created_idx` | mantém |

### 1.5 Identificadores que permanecem em português (recomendação)

| Item | Por que manter |
|---|---|
| `equipment_types.code` (`CR`, `CM`, `AN`…) e `name` ("Cadeira de rodas") | São dados de catálogo impressos na etiqueta física e no termo; `visible_code` deriva deles (`BVCR0001`). Traduzir quebraria etiquetas já planejadas. |
| `entities.code` / `public_name` | Nome próprio do clube. |
| `community_profiles.cpf` | Acrônimo de domínio brasileiro (como `cnpj`). |
| Slugs de rota (`/admin/acervo`, `/admin/emprestimos`, `/equipamentos`) | URL visível ao usuário; acompanha a regra "UI em PT-BR". |
| Nomes de arquivos de migration antigos | Só renomear se a estratégia for reescrever (ver §6). |

### 1.6 Plano de empréstimos — identificadores previstos

| No `plan.md` | Proposto |
|---|---|
| `catalog.loans.codigo` | `public_code` |
| `catalog.loan_situation` (`rascunho`/`ativo`/`cancelado`) | `loan_status` (`draft`/`active`/`cancelled`) |
| `document_type` = `termo_emprestimo` | `loan_term` |
| `review_status` = `pendente_revisao_juridica`/`aprovado` | `pending_legal_review`/`approved` |
| `admin_*_loan*(p_codigo text)` | `p_public_code` |
| `loan_event_audit.previous_situation`/`new_situation` | `previous_status`/`new_status` |

---

## 2. Validação de Linguagem da UI (Termos Naturais em PT-BR)

Legenda: **[REC]** = recomendação. Marcar a escolha por número (ex.: `2.1=b`).

### 2.1 Local onde o equipamento está guardado (`storage_location_id`)

| | Opção |
|---|---|
| a **[REC]** | "Onde está guardado" (campo e `<dt>`); vazio: "Não sabemos onde está" |
| b | "Local do equipamento"; vazio: "Sem local definido" |
| c | "Depósito do banco"; vazio: "Sem depósito" |
| d | Outro |

> Hoje: "Ponto de guarda" (7 ocorrências em `admin-acervo-manager.tsx`) e "ponto de atendimento" (`regras-de-negocio.md` §8). Os dois são jargão interno.

### 2.2 Identificador da peça (`visible_code`)

| | Opção |
|---|---|
| a **[REC]** | "Número do equipamento" + dica "Pode ser o número da etiqueta ou do tombo. Se não tiver, deixe em branco." |
| b | "Etiqueta do equipamento" |
| c | Manter "Identificador, tombo ou patrimônio" |
| d | Outro |

> Hoje: três sinônimos empilhados no mesmo rótulo. "Tombamento/tombo" é vocabulário de patrimônio público — os voluntários podem não reconhecer.

### 2.3 Nome da área de gestão (`/admin/acervo`)

| | Opção |
|---|---|
| a **[REC]** | "Equipamentos do banco" (nav + título + aba) |
| b | "Estoque do banco" |
| c | Manter "Acervo de equipamentos" / "Acervo" |
| d | Outro |

> "Acervo" aparece em nav, título, resumo, vazio e mensagens de erro. `docs/ux/acessibilidade-e-fluxos.md` §2 já manda evitar termos internos; "acervo" não está na lista proibida, mas é o mais burocrático dos rótulos atuais.

### 2.4 "Resumo do acervo de {banco}" (painel de contagens)

| | Opção |
|---|---|
| a **[REC]** | "Como estão os equipamentos" |
| b | "Resumo dos equipamentos" |
| c | Manter "Resumo do acervo de {banco}" |
| d | Outro |

### 2.5 Rótulos das seis situações (tela do banco)

| Valor atual | Atual na tela | Proposta **[REC]** | Alternativas |
|---|---|---|---|
| `disponivel` | Disponível no depósito | **Disponível para empréstimo** | "Pronto para emprestar" / manter |
| `reservado` | Aguardando retirada | **Separado para retirada** | "Reservado" / "Aguardando a pessoa buscar" |
| `emprestado` | Emprestado | **Emprestado** (manter) | "Com a pessoa" |
| `manutencao` | Em manutenção | **Em conserto** | "Em manutenção" / manter |
| `doado` | Doado | **Doado** (manter) | "Doado para alguém" |
| `baixado` | Retirado do acervo | **Fora de uso** | "Perdido ou descartado" / "Baixado" |

> "Retirado do acervo" para `baixado` é ambíguo: lê-se como "saiu do estoque e voltou ao acervo". É o rótulo mais arriscado da tela.

### 2.6 Rótulos na consulta pública (comunidade)

| Atual | Proposta **[REC]** | Alternativas |
|---|---|---|
| "Disponível no depósito" | **Tem para emprestar** | "Disponível agora" / "Disponível para empréstimo" |
| "Todos emprestados no momento" | **Nenhum disponível agora** | "Todos estão emprestados" / manter |
| "Quantidade disponível: {n}" / "{n} equipamentos" | **"{n} para emprestar"** | "{n} disponíveis" / "Temos {n}" |
| "Disponibilidade por banco" | **Onde tem equipamento** | "Onde encontrar" / manter |
| "banco mantenedor" | **banco responsável** | "banco que atende" / "clube responsável" |
| "Ver disponibilidade" | **Ver onde tem** | "Ver os bancos" / manter |

> Sobre "Soma de Disponibilidade": o termo não aparece literalmente na UI; o equivalente é a soma silenciosa feita em `public-equipment.tsx:89-93` e exibida como "{n} equipamentos". A correção não é de nome técnico, é deixar claro que o número é um total entre bancos ("{n} para emprestar no total") — ou remover o total da lista e mostrar só no detalhe.

### 2.7 Origem de entrada

| Atual | Proposta **[REC]** | Alternativas |
|---|---|---|
| "Como o equipamento entrou" / "Como entrou" | **De onde veio o equipamento** | "Como o equipamento chegou" / manter |
| "Origem não registrada" | **Não sabemos de onde veio** | "Sem informação de origem" |
| "Doação" / "Compra" | **Doado / Comprado** | manter substantivos |
| "Retorno de conserto" | **Voltou do conserto** | "Conserto" / "Voltou de reparo" |
| "Devolução de outro banco" | **Veio de outro banco** | "Devolvido por outro banco" |

### 2.8 Contatos

| Atual | Proposta **[REC]** | Alternativas |
|---|---|---|
| Nav "Contatos recebidos" | **Pedidos de contato** | "Pessoas que chamaram" / "Mensagens recebidas" |
| "Código do contato na mensagem" | **Código que veio na mensagem** | "Código do atendimento" |
| `novo` → "Novo" | **Novo pedido** | "Aguardando resposta" / "Novo" |
| `atendido` → "Atendido" | **Já atendeu** | "Atendido" |
| `sem_retorno` → "Sem retorno" | **Não respondeu** | "Não deu retorno" / "Desistiu" |
| `virou_emprestimo` → "Virou empréstimo" | **Empréstimo feito** | "A pessoa levou o equipamento" |

### 2.9 Jargão que vaza hoje (correções obrigatórias, não dependem de escolha)

| Onde | Texto atual | Correção |
|---|---|---|
| `admin-server.ts` (acervo) | "Confira os **dados da unidade**" | "Confira os dados do **equipamento**" |
| `admin-server.ts` (acervo) | "Já existe uma **unidade** com este identificador" | "Já existe um **equipamento** com este número neste banco" |
| `admin-server.ts` (acervo) | "Não foi possível salvar a **unidade**" | "... o equipamento" |
| `admin-acervo-manager.tsx` | "Cadastrar equipamento" ✅ | manter |

> `docs/ux/acessibilidade-e-fluxos.md` §2 já proíbe "unidade" na interface; a UI atual viola a própria regra em 3 mensagens.

### 2.10 Termos do fluxo de empréstimo (validar junto com §4)

| Conceito | Proposta **[REC]** | Alternativas |
|---|---|---|
| `draft` (empréstimo não concluído) | **Aguardando retirada** | "Em preparo" / "Empréstimo em aberto" |
| "Concluir saída" | **Entregar equipamento** | "Confirmar empréstimo" / "Concluir entrega" |
| "Desistir deste empréstimo" | **Cancelar este empréstimo** | "Voltar atrás" / manter |
| "Gerar termo" / "Baixar termo" | **Gerar termo de empréstimo** / **Baixar o termo** | manter |
| `patient_name` (paciente) | **Quem vai usar o equipamento** | "Paciente" / "Nome de quem vai usar" |
| "responsável" | **Quem vai retirar** | "Responsável" |
| "situação do termo" | **Termo pendente / Termo gerado** | "Situação do termo" |

---

## 3. Proposta de Fixtures Verossímeis (`seed.sql`)

Princípios: (i) nomes de clube reais do produto (`regras-de-negocio.md` §1) — não são dados pessoais; (ii) e-mails sempre em `.test` (RFC 2606), logo impossíveis de existir; (iii) nenhum CPF/telefone real; (iv) os 4 clubes deixam de ser "A/B/C/Compartilhado" e ganham identidade própria.

| De | Para |
|---|---|
| `SYN-A` / "Entidade Sintética A" | `ROTARY-BOA-VISTA` / "Banco Ortopédico Rotary Boa Vista" |
| `SYN-B` / "Entidade Sintética B" | `ROTARY-TRES-VENDAS` / "Banco Ortopédico Três Vendas" |
| `SYN-C` / "Entidade Sintética C" | `ROTARY-CASA-AMIZADE` / "Casa da Amizade — Banco Ortopédico" |
| `SYN-ROTARY-BOA-VISTA` / "Rotary Boa Vista (sintético)" | `ROTARY-ERECHIM` / "Banco Ortopédico Rotary Erechim" |
| `SYN-SHARED` / "Ponto Sintetico Compartilhado" | `SEDE-BOA-VISTA` / "Sede do Rotary Boa Vista" |
| — | `SEDE-TRES-VENDAS` / "Salão comunitário de Três Vendas" |
| — | `SEDE-CASA-AMIZADE` / "Casa da Amizade" |
| — | `APOIO-ERECHIM` / "Ponto de apoio — Erechim" (banco itinerante de `regras-de-negocio.md` §8) |
| `admin-rotary-boa-vista@banco-ortopedico.test` | `admin.boavista@rotary.test` |
| `admin_banco` vinculado a `SYN-ROTARY-BOA-VISTA` | vinculado a `ROTARY-BOA-VISTA` |
| `visible_code` nulo nas unidades 1–11 | `BVCR0001`…`BVCR0008`, `TVCR0001`, `TVCR0002`, `CACR0001` (padrão de `regras-de-negocio.md` §3) |
| Comentários `-- Synthetic development fixtures only` | `-- Dados fictícios de desenvolvimento. Nomes de clubes reais; nenhuma pessoa, CPF ou telefone real.` |

Pontos de atenção na execução:

- O `values` (`'00000000-…-0001','CR','SYN-A','disponivel'`) precisa apontar para o ponto do próprio clube (`storage_location_id` por entidade, em vez do join fixo em `SYN-SHARED`).
- `README.md` (seção "Acesso administrativo local") cita o e-mail e a senha atuais — muda junto.
- A senha `Rotary-Local-Synthetic-2026!` pode ficar (já documentada) ou virar `Boavista@2026` — decisão pendente.

---

## 4. Mapeamento de Impacto no Plano de Empréstimos

Arquivo: `.specs/features/emprestimo-equipamentos-fr-019-fr-020-fr-021-fr-034-fr-042-fr-031/plan.md` (360 linhas, aprovado em 2026-10-28).

### 4.1 Identificadores técnicos citados que precisam mudar

| Linha(s) | Hoje | Depois |
|---|---|---|
| 46, 50, 51, 179-185 | `admin_*` com `p_codigo text` | `p_public_code text` |
| 193 | coluna `codigo text not null unique default upper(substr(replace(gen_random_uuid()...` | renomear para `public_code` (default não muda) |
| 193 | `create type catalog.loan_situation as enum ('rascunho','ativo','cancelado')` | `catalog.loan_status` = `('draft','active','cancelled')` |
| 193 | `situation catalog.loan_situation not null default 'rascunho'` | `status catalog.loan_status not null default 'draft'` |
| 192 | `document_type` enum `('termo_emprestimo')` | `('loan_term')` |
| 192 | `review_status in ('pendente_revisao_juridica','aprovado')` | `('pending_legal_review','approved')` |
| 195 | `previous_situation`/`new_situation` em `loan_event_audit` | `previous_status`/`new_status` |
| 124, 127, 193, 220-221, 276 | `situacao`, `disponivel`, `reservado`, `emprestado` | `status`, `available`, `reserved`, `on_loan` |
| 156 | "identificador e **ponto de guarda**" (saída da RPC) | "número e **onde está guardado**" (ou o rótulo escolhido em §2.1) |

### 4.2 Rótulos de tela que o plano fixa e precisam ser reescritos

| Linha | Texto aprovado hoje | Ajuste |
|---|---|---|
| 45, 52 | Empréstimo `rascunho` | "Empréstimo aguardando retirada" (nunca "rascunho" na tela) |
| 54, 275, 282 | "Aguardando retirada" no acervo | validar contra §2.5 ("Separado para retirada") |
| 259 | "A situação de um equipamento mudou. Confira o acervo antes de concluir." | "... Confira os equipamentos antes de continuar." |
| 221 | estado vazio abrindo `/admin/acervo` | se o nav mudar (§2.3), o nome citado muda junto |
| 279, 281 | exige termos cotidianos `empréstimo, equipamento, situação, prazo, revisão, salvar` | acrescentar que "rascunho", "acervo", "unidade" e "ponto de guarda" não podem aparecer |
| 293, 315 | `virou_emprestimo` | `converted_to_loan`; na tela, o rótulo de §2.8 |
| 320 | "12 caracteres hexadecimais ... código público" | mantém-se; só a coluna vira `public_code` |

### 4.3 Diagramas e fontes

- Mermaid ER (linhas 129-140): `Entidade`, `Emprestimo`, `LinhaEmprestimo`, `ModeloDocumento`, `ArquivoTermo`, `AuditoriaEmprestimo`, `UnidadeFisica` → nomes de tabela em inglês (`entities`, `loans`, `loan_lines`, `document_models`, `loan_documents`, `loan_event_audit`, `equipment_units`). Vale o mesmo para o `plan.md` do acervo (linhas 90-95).
- Linhas 343-359 (`Sources`): os caminhos de migration listados continuam válidos na estratégia aditiva; mudam na reescrita.
- Critérios 21, 39, 41, 49, 50 citam `reservado`/`emprestado` literalmente — reescrita obrigatória.

### 4.4 O que **não** precisa mudar

Rotas (`/admin/emprestimos`), nomes de função pública (`admin_create_loan_draft`, `admin_complete_loan`, …), bucket `loan-terms`, eventos de auditoria (`loan_draft_created` etc.) — todos já em inglês. O esforço real é: **6 identificadores de schema + 3 enums + ~15 literais de critério + 4 rótulos de tela**.

---

## 5. Minuta de Adição ao `AGENTS.md`

Inserir como nova seção após "Architecture & Security" (+5 linhas, sem tocar no resto):

```markdown
## Naming Rules
- Banco, código e API em inglês técnico: `storage_locations`, `status`, `available`, `public_code`. Nunca `pontos_atendimento`, `situacao`, `codigo` em identificadores novos.
- Texto na tela em PT-BR natural e cotidiano; identificador técnico nunca vaza para a UI. Rótulos canônicos ficam em `docs/produto/regras-de-negocio.md` §4.
- `seed.sql` usa nomes verossímeis de clube, ponto e e-mail em `.test`. Proibido "Sintético A", "Ponto AQ 1", e-mail em domínio real.
```

---

## 6. Estratégia de execução proposta

Como **não há projeto Supabase remoto configurado** (`supabase/config.toml` só tem `project_id` local, sem `project-ref`) e o produto não está publicado, duas rotas:

| | Rota A — reescrever as migrations (recomendada) | Rota B — migration aditiva de rename |
|---|---|---|
| Como | Editar os 12 arquivos originais + `db reset` | `20261029000000_rename_domain_identifiers.sql` com `RENAME TABLE/COLUMN/VALUE` |
| Vantagem | Zero dívida de nomenclatura; migrations legíveis; nenhum `RENAME` morto | Histórico preservado; seguro se alguém já tiver banco aplicado |
| Risco | Exige `db reset` em todas as máquinas | `ALTER TYPE ... RENAME VALUE` não reescreve literais em `CHECK` e em predicates de RLS → todos precisam ser recriados; corpos de funções plpgsql não são atualizados por `RENAME TABLE` → todas as RPCs precisam de `CREATE OR REPLACE` |
| Esforço | Médio, tudo de uma vez | Alto e mais fácil de errar silenciosamente |

Fases sugeridas (independente da rota):

1. **Núcleo de dados** — migrations + `seed.sql`, e `npx supabase db reset && npx supabase test db`.
2. **Código** — `src/lib/acervo/types.ts` (`EquipmentSituation` → `EquipmentStatus`, `equipmentSituationLabels` → `equipmentStatusLabels`), `admin-server.ts`, `contacts/admin-types.ts`, `contacts/admin-server.ts`, `admin-acervo-manager.tsx`, `admin-contacts-manager.tsx`, `actions.ts`, atributos `name=` dos formulários (`tipo`→`type`, `ponto`→`location`, `identificador`→`visibleCode`, `situacao`→`status`, `origem`→`entryOrigin`), query `?codigo=` → `?code=`.
3. **Rótulos de UI** — só depois da validação da §2; mexe em `src/` + `docs/produto/regras-de-negocio.md` §4/§6/§8/§10 + `docs/ux/acessibilidade-e-fluxos.md` §2/§3 + `docs/arquitetura/modelo-conceitual.md` §3.
4. **Testes e evidências** — 7 arquivos em `supabase/tests/` (34 refs a `situacao`, 18 a `pontos_atendimento`), `.checks/*.md`, `.tasks/*.md`, `.notebook/*.md`.
5. **Planos** — `plan.md` de empréstimos (§4) e de acervo; `AGENTS.md` (§5).
6. **Validação** — `npm run build` + `supabase test db` (conforme `AGENTS.md`); verificação visual manual a 360 px.

---

## 7. Decisões pendentes

| # | Decisão | Recomendação |
|---|---|---|
| D1 | Tabela `pontos_atendimento` → `storage_locations`? | Sim |
| D2 | Coluna `situacao` → `status` (e tipo `equipment_situation` → `equipment_status`)? | Sim |
| D3 | `user_role.companheiro` → `rotarian`? | Sim |
| D4 | Manter `equipment_types.code`/`name` em PT (etiquetas físicas)? | Sim, manter |
| D5 | **Rota A (reescrever migrations) ou Rota B (rename aditivo)?** | Rota A |
| D6 | Termo do local: §2.1 a/b/c/d | a — "Onde está guardado" |
| D7 | Termo do identificador: §2.2 a/b/c/d | a — "Número do equipamento" |
| D8 | Nome da área: §2.3 a/b/c/d | a — "Equipamentos do banco" |
| D9 | Painel: §2.4 a/b/c/d | a — "Como estão os equipamentos" |
| D10 | Rótulos das 6 situações: aceitar a coluna [REC] da §2.5 ou ajustar linha a linha? | Aceitar |
| D11 | Rótulos públicos: aceitar §2.6 [REC]? Principalmente `baixado` → "Fora de uso" | Aceitar |
| D12 | Origem: §2.7 a/b/c | [REC] |
| D13 | Contatos: §2.8 [REC]? (`sem_retorno` → "Não respondeu") | Aceitar |
| D14 | Termos do empréstimo: §2.10 [REC]? (`draft` → "Aguardando retirada", "Concluir saída" → "Entregar equipamento", "Desistir" → "Cancelar") | Aceitar |
| D15 | Fixtures §3: usar os 4 clubes reais (`Boa Vista`, `Três Vendas`, `Casa da Amizade`, `Erechim`) ou manter siglas neutras? | Usar os 4 clubes |
| D16 | Senha da fixture: manter `Rotary-Local-Synthetic-2026!` ou trocar? | Manter |
| D17 | Texto do `AGENTS.md` §5: aprovar como está? | Aprovar |
| D18 | Atualizar também `docs/ux`, `docs/arquitetura` e `.checks/.tasks/.notebook` nesta mesma entrega, ou só código+DB agora e docs depois? | Mesma entrega, em commits separados |

Sem as respostas acima, nenhuma migration, `seed.sql` ou `plan.md` será alterado.

---

## 8. Execução (2026-10-28)

Proposta aprovada com D1–D18, com dois ajustes do usuário:

- `reserved` na tela do banco: **Reservado para retirada** (não "Separado").
- Ação de conclusão do empréstimo: **Confirmar entrega** (não "Entregar equipamento").

Rota escolhida: **A** — migrations reescritas, sem migration de rename, banco local recriado.

### Entregue

| Camada | O que mudou |
|---|---|
| Migrations | `storage_locations`, `equipment_status`, `contact_status`, `status`, `public_code`, `source`, `public_code`, `p_public_code`, `overdue_48h`; valores de enum em inglês; nomes de arquivo em inglês |
| Seeds | 4 clubes reais, 4 pontos, `admin.boavista@rotary.test`, códigos `BVCR0001` etc., comentários em inglês |
| Testes SQL | 7 arquivos renomeados e reescritos; `public-availability` e `community-contacts` passaram a criar suas próprias fixtures em vez de depender do seed |
| Código | `src/lib/inventory/`, `AdminInventoryManager`, `EquipmentStatus`, `AdminContactStatus`, `publicCode`, nomes de campo `type/visibleCode/location/status/entryOrigin/unitId`, query `?code=` |
| UI | "Equipamentos do banco", "Onde está guardado", "Número do equipamento", "Pedidos de contato", rótulos das 6 situações e dos 4 desfechos de contato, textos públicos ("Tem para emprestar", "Nenhum disponível agora") |
| CSS | `.acervo-*` → `.inventory-*`, `.situation-*` → `.status-*` |
| Docs | regras de negócio §4/§6/§10, requisitos FR-002/003/025/028/029, critérios AC-001/011/012, UX §2/§3, modelo conceitual, `.specs/STATE.md`, `.notebook/`, `README.md` |
| Planos | acervo (nomes de código, rótulos, diagramas de estado) e empréstimos (§4 do relatório: `loan_status`, `public_code`, `loan_term`, `pending_legal_review`, `draft/active/cancelled`, `[code]`, "Confirmar entrega") |
| `AGENTS.md` | seção **Naming Rules** (3 linhas) |

### Verificação

- `npm run build` — sucesso.
- `npx supabase db reset --local` — 13 migrations + seed aplicados.
- `npx supabase test db` — **7 arquivos, 265 testes, PASS**.

### Fora do escopo desta execução

- `.checks/` e `.tasks/` foram restaurados ao estado do Git: são evidências datadas de execuções anteriores e citam identificadores antigos de propósito.
- Desenhos `.excalidraw` não foram editados (binário/JSON de desenho).
- Nomes de entidade nos diagramas ER conceituais permanecem em PT-BR; o próprio documento declara que não é o esquema físico.
- Rotas visíveis (`/admin/acervo`, `/equipamentos`) continuam em português, por serem URLs de interface.
