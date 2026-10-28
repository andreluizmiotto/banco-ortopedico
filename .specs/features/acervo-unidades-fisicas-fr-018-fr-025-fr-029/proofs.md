# acervo-unidades-fisicas-fr-018-fr-025-fr-029 proofs

**HEAD**: dbdd14f
**Tree**: dirty - docs/arquitetura/autenticacao-e-autorizacao.md, docs/arquitetura/decisoes/0001-nextjs-supabase.md, docs/arquitetura/visao-geral.md, docs/produto/regras-de-negocio.md, docs/produto/requisitos.md
**Result**: 32 pass, 0 fail; mutations 3 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `bash scripts/acervo-test-db.sh # C1 acervo collection returns the canonical bank and only its units, C1 acervo` | count unknown | - | pass |
| C2 | `bash scripts/acervo-test-db.sh # C2 situation counts cover all six values including zero, C2 situation values ` | count unknown | - | pass |
| C3 | `bash scripts/acervo-test-db.sh # C3 units are ordered by type then identifier with nulls last` | count unknown | - | pass |
| C4 | `walk - entrar com a identidade sintética de uma entidade sem unidades e abrir /admin/acervo` | - | - | pass (Walked) |
| C5 | `walk - interromper a leitura local e reabrir /admin/acervo` | - | - | pass (Walked) |
| C6 | `bash scripts/acervo-test-db.sh # C6 acervo RPCs reject anon, C6 acervo RPCs reject a session without an active` | count unknown | - | pass |
| C6 | `walk - abrir /admin/acervo sem sessão e com a identidade sintética sem vínculo ativo` | - | - | pass (Walked) |
| C7 | `walk - abrir /admin/contatos com a identidade sintética e acionar Acervo de equipamentos` | - | - | pass (Walked) |
| C8 | `bash scripts/acervo-test-db.sh # C8 create unit derives the owner entity from the session and persists every f` | count unknown | - | pass |
| C9 | `walk - cadastrar uma unidade sintética em /admin/acervo e conferir confirmação e painel` | - | - | pass (Walked) |
| C10 | `bash scripts/acervo-test-db.sh # C10 blank identifier is stored as null, C10 identifier is trimmed and preserv` | count unknown | - | pass |
| C11 | `bash scripts/acervo-test-db.sh # C11 duplicate identifier in the same entity is rejected, C11 the same identif` | count unknown | - | pass |
| C12 | `bash scripts/acervo-test-db.sh # C12 invalid creation inputs are rejected without unit or audit` | count unknown | - | pass |
| C12 | `bash scripts/acervo-test-db.sh # C12 all four entry origins are accepted` | count unknown | - | pass |
| C13 | `bash scripts/acervo-test-db.sh # C13 creation writes one unit_created audit with the complete actor and values` | count unknown | - | pass |
| C14 | `bash scripts/acervo-test-db.sh # C14 update changes only visible code, storage location and situation` | count unknown | - | pass |
| C15 | `bash scripts/acervo-test-db.sh # C15 every situation can transition to every other situation with audit` | count unknown | - | pass |
| C15 | `bash scripts/acervo-test-db.sh # C15 doado and baixado are no longer terminal for the inventory panel` | count unknown | - | pass |
| C16 | `bash scripts/acervo-test-db.sh # C16 repeating the same update creates no extra audit row` | count unknown | - | pass |
| C17 | `bash scripts/acervo-test-db.sh # C17 foreign and unknown unit identifiers receive the same generic denial` | count unknown | - | pass |
| C18 | `bash scripts/acervo-test-db.sh # C18 effective updates are serialized and each leaves one audit` | count unknown | - | pass |
| C18 | `walk - duas sessões SQL locais simultâneas na mesma unidade sintética; a segunda aguardou o travamento da prim` | - | - | pass (Walked) |
| C19 | `walk - alterar a situação de uma unidade sintética em /admin/acervo e conferir confirmação e painel` | - | - | pass (Walked) |
| C20 | `bash scripts/acervo-test-db.sh # C20 client and service roles cannot read or write units and audit directly, C` | count unknown | - | pass |
| C21 | `walk - enviar o formulário com resposta local atrasada e tentar acionar duas vezes` | - | - | pass (Walked) |
| C22 | `walk - provocar identificador repetido e interrupção de rede no formulário` | - | - | pass (Walked) |
| C23 | `walk - revisar /admin/acervo a 360 px com dados sintéticos` | - | - | pass (Walked) |
| C24 | `bash scripts/acervo-test-db.sh # C24 options return active types and every storage location` | count unknown | - | pass |
| C24 | `walk - abrir o cadastro e conferir as opções e os campos vazios` | - | - | pass (Walked) |
| C25 | `bash scripts/acervo-test-db.sh # C25 an inactive type remains readable and its unit remains editable` | count unknown | - | pass |
| Build | `npm run build` | - | - | pass |
| Build | `npx eslint src/app/admin src/lib/acervo` | - | - | pass |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| identifier length bound 64 -> 63 (64 must still be accepted) | `supabase/migrations/20261028000000_acervo_unidades_fisicas.sql:310` | yes |
| collection order: null identifiers last -> first | `supabase/migrations/20261028000000_acervo_unidades_fisicas.sql:215` | yes |
| idempotency guard: unchanged values still write a new audit | `supabase/migrations/20261028000000_acervo_unidades_fisicas.sql:437` | yes |
