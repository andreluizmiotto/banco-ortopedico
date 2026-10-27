# acervo-unidades-fisicas-fr-018-fr-025-fr-029 proofs

**HEAD**: 4ab7a98
**Tree**: dirty - docs/arquitetura/autenticacao-e-autorizacao.md, docs/arquitetura/decisoes/0001-nextjs-supabase.md, docs/arquitetura/visao-geral.md, docs/produto/regras-de-negocio.md, docs/produto/requisitos.md
**Result**: 32 pass, 0 fail; mutations 0 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C1 acervo collection retur` | count unknown | - | pass |
| C2 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C2 situation counts cover ` | count unknown | - | pass |
| C3 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C3 units are ordered by ty` | count unknown | - | pass |
| C4 | `walk - entrar com a identidade sintética de uma entidade sem unidades e abrir /admin/acervo` | - | - | pass (Walked) |
| C5 | `walk - interromper a leitura local e reabrir /admin/acervo` | - | - | pass (Walked) |
| C6 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C6 acervo RPCs reject anon` | count unknown | - | pass |
| C6 | `walk - abrir /admin/acervo sem sessão e com a identidade sintética sem vínculo ativo` | - | - | pass (Walked) |
| C7 | `walk - abrir /admin/contatos com a identidade sintética e acionar Acervo de equipamentos` | - | - | pass (Walked) |
| C8 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C8 create unit derives the` | count unknown | - | pass |
| C9 | `walk - cadastrar uma unidade sintética em /admin/acervo e conferir confirmação e painel` | - | - | pass (Walked) |
| C10 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C10 blank identifier is st` | count unknown | - | pass |
| C11 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C11 duplicate identifier i` | count unknown | - | pass |
| C12 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C12 invalid creation input` | count unknown | - | pass |
| C12 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C12 all four entry origins` | count unknown | - | pass |
| C13 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C13 creation writes one un` | count unknown | - | pass |
| C14 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C14 update changes only vi` | count unknown | - | pass |
| C15 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C15 every situation can tr` | count unknown | - | pass |
| C15 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C15 doado and baixado are ` | count unknown | - | pass |
| C16 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C16 repeating the same upd` | count unknown | - | pass |
| C17 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C17 foreign and unknown un` | count unknown | - | pass |
| C18 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C18 effective updates are ` | count unknown | - | pass |
| C18 | `walk - duas sessões SQL locais simultâneas na mesma unidade sintética; a segunda aguardou o travamento da prim` | - | - | pass (Walked) |
| C19 | `walk - alterar a situação de uma unidade sintética em /admin/acervo e conferir confirmação e painel` | - | - | pass (Walked) |
| C20 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C20 client and service rol` | count unknown | - | pass |
| C21 | `walk - enviar o formulário com resposta local atrasada e tentar acionar duas vezes` | - | - | pass (Walked) |
| C22 | `walk - provocar identificador repetido e interrupção de rede no formulário` | - | - | pass (Walked) |
| C23 | `walk - revisar /admin/acervo a 360 px com dados sintéticos` | - | - | pass (Walked) |
| C24 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C24 options return active ` | count unknown | - | pass |
| C24 | `walk - abrir o cadastro e conferir as opções e os campos vazios` | - | - | pass (Walked) |
| C25 | `npx --yes supabase@latest test db supabase/tests/acervo-unidades-fisicas.test.sql # C25 an inactive type remai` | count unknown | - | pass |
| Build | `npm run build` | - | - | pass |
| Build | `npx eslint src/app/admin src/lib/acervo` | - | - | pass |
