# emprestimo-equipamentos-fr-019-fr-020-fr-021-fr-034-fr-042-fr-031 proofs

**HEAD**: d7bb571
**Tree**: clean
**Result**: 62 pass, 0 fail; mutations 3 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C1` | count unknown | - | pass |
| C2 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C2` | count unknown | - | pass |
| C3 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C3` | count unknown | - | pass |
| C4 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C4` | count unknown | - | pass |
| C5 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C5` | count unknown | - | pass |
| C6 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C6` | count unknown | - | pass |
| C7 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C7` | count unknown | - | pass |
| C8 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C8` | count unknown | - | pass |
| C8 | `walk - buscar um nome sintético sem conta e conferir a mensagem e o próximo passo` | - | - | pass (Walked) |
| C9 | `walk - buscar a pessoa sintética, escolher o resultado e conferir o cartão e o próximo passo` | - | - | pass (Walked) |
| C10 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C10` | count unknown | - | pass |
| C11 | `walk - abrir /admin/emprestimos/novo com um banco sintético sem peças disponíveis` | - | - | pass (Walked) |
| C12 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C12` | count unknown | - | pass |
| C13 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C13` | count unknown | - | pass |
| C14 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C14` | count unknown | - | pass |
| C15 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C15` | count unknown | - | pass |
| C16 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C16` | count unknown | - | pass |
| C17 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C17` | count unknown | - | pass |
| C18 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C18` | count unknown | - | pass |
| C19 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C19` | count unknown | - | pass |
| C20 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C20` | count unknown | - | pass |
| C21 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C21` | count unknown | - | pass |
| C22 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C22` | count unknown | - | pass |
| C23 | `bash scripts/loans-concurrency-test.sh --only C23` | count unknown | - | pass |
| C24 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C24` | count unknown | - | pass |
| C25 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C25` | count unknown | - | pass |
| C26 | `walk - gravar um empréstimo aguardando retirada e abrir /admin/emprestimos/<code>` | - | - | pass (Walked) |
| C27 | `walk - abrir /admin/emprestimos com dois empréstimos aguardando retirada nas fixtures` | - | - | pass (Walked) |
| C28 | `walk - abrir um empréstimo aguardando retirada, gerar o termo e conferir o texto antes e depois` | - | - | pass (Walked) |
| C29 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C29` | count unknown | - | pass |
| C30 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C30` | count unknown | - | pass |
| C31 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C31` | count unknown | - | pass |
| C31 | `walk - remover a chave de serviço do ambiente, tentar gerar o termo e conferir que o empréstimo continua aguar` | - | - | pass (Walked) |
| C32 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C32` | count unknown | - | pass |
| C33 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C33` | count unknown | - | pass |
| C34 | `walk - gerar o termo de um empréstimo aguardando retirada sintético, abrir o PDF e conferir campo por campo` | - | - | pass (Walked) |
| C35 | `walk - abrir o PDF gerado com o modelo sintético semeado e conferir o rodapé` | - | - | pass (Walked) |
| C36 | `walk - usar Baixar termo e conferir o arquivo baixado` | - | - | pass (Walked) |
| C37 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C37` | count unknown | - | pass |
| C37 | `walk - abrir /admin/emprestimos/<codigo-de-outro-banco>/termo com sessão do banco A` | - | - | pass (Walked) |
| C38 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C38` | count unknown | - | pass |
| C39 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C39` | count unknown | - | pass |
| C40 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C40` | count unknown | - | pass |
| C41 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C41` | count unknown | - | pass |
| C42 | `walk - concluir um empréstimo aguardando retirada sintético e conferir a confirmação e o download` | - | - | pass (Walked) |
| C43 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C43` | count unknown | - | pass |
| C44 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C44` | count unknown | - | pass |
| C45 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C45` | count unknown | - | pass |
| C46 | `walk - abrir /admin/emprestimos/<codigo-de-outro-banco> e um código inventado com sessão do banco A` | - | - | pass (Walked) |
| C47 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C47` | count unknown | - | pass |
| C48 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C48` | count unknown | - | pass |
| C49 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C49` | count unknown | - | pass |
| C50 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C50` | count unknown | - | pass |
| C50 | `walk - revisar a barra de endereço das quatro telas e as mensagens de erro do fluxo` | - | - | pass (Walked) |
| C51 | `walk - abrir as quatro telas com rede lenta, derrubar a rede durante a gravação e reenviar o formulário` | - | - | pass (Walked) |
| C52 | `walk - conferir as quatro telas na largura de 360 px com a paleta e as medidas aplicadas` | - | - | pass (Walked) |
| C53 | `walk - percorrer os 4 passos com o teclado, provocar um erro de campo e voltar um passo` | - | - | pass (Walked) |
| C54 | `walk - abrir a navegação administrativa nas quatro telas e conferir o link e o anúncio da página atual` | - | - | pass (Walked) |
| C55 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C55` | count unknown | - | pass |
| C56 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C56` | count unknown | - | pass |
| C57 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C57` | count unknown | - | pass |
| Build | `npm run build` | - | - | pass |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| C7 open loan count drops the active loan of the session bank | `supabase/migrations/20261104000000_loans.sql:550` | yes |
| C22 open line guard removed, leaving only the unique index | `supabase/migrations/20261104000000_loans.sql:798` | yes |
| C18 patient name bounds shifted from 2..120 to 3..119 | `supabase/migrations/20261104000000_loans.sql:682` | yes |
