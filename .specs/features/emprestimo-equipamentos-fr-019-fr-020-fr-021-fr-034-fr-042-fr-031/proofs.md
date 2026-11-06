# emprestimo-equipamentos-fr-019-fr-020-fr-021-fr-034-fr-042-fr-031 proofs

**HEAD**: ec70639
**Tree**: dirty - src/lib/loans/admin-server.ts, supabase/tests/emprestimo-isolamento.test.sql, supabase/migrations/20261106000000_admin_bank_loans_empty_bank.sql
**Result**: 43 pass, 18 fail; mutations 0 killed, 0 not

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
| C8 | `walk - buscar um nome sintético sem conta e conferir a mensagem e o próximo passo` | - | - | **no Walked line** |
| C9 | `walk - buscar a pessoa sintética, escolher o resultado e conferir o cartão e o próximo passo` | - | - | **no Walked line** |
| C10 | `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C10` | count unknown | - | pass |
| C11 | `walk - abrir /admin/emprestimos/novo com um banco sintético sem peças disponíveis` | - | - | **no Walked line** |
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
| C26 | `walk - gravar um empréstimo aguardando retirada e abrir /admin/emprestimos/<code>` | - | - | **no Walked line** |
| C27 | `walk - abrir /admin/emprestimos com dois empréstimos aguardando retirada nas fixtures` | - | - | **no Walked line** |
| C28 | `walk - abrir um empréstimo aguardando retirada, gerar o termo e conferir o texto antes e depois` | - | - | **no Walked line** |
| C29 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C29` | count unknown | - | pass |
| C30 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C30` | count unknown | - | pass |
| C31 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C31` | count unknown | - | pass |
| C31 | `walk - remover a chave de serviço do ambiente, tentar gerar o termo e conferir que o empréstimo continua aguar` | - | - | **no Walked line** |
| C32 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C32` | count unknown | - | pass |
| C33 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C33` | count unknown | - | pass |
| C34 | `walk - gerar o termo de um empréstimo aguardando retirada sintético, abrir o PDF e conferir campo por campo` | - | - | **no Walked line** |
| C35 | `walk - abrir o PDF gerado com o modelo sintético semeado e conferir o rodapé` | - | - | **no Walked line** |
| C36 | `walk - usar Baixar termo e conferir o arquivo baixado` | - | - | **no Walked line** |
| C37 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C37` | count unknown | - | pass |
| C37 | `walk - abrir /admin/emprestimos/<codigo-de-outro-banco>/termo com sessão do banco A` | - | - | **no Walked line** |
| C38 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C38` | count unknown | - | pass |
| C39 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C39` | count unknown | - | pass |
| C40 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C40` | count unknown | - | pass |
| C41 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C41` | count unknown | - | pass |
| C42 | `walk - concluir um empréstimo aguardando retirada sintético e conferir a confirmação e o download` | - | - | **no Walked line** |
| C43 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C43` | count unknown | - | pass |
| C44 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C44` | count unknown | - | pass |
| C45 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C45` | count unknown | - | pass |
| C46 | `walk - abrir /admin/emprestimos/<codigo-de-outro-banco> e um código inventado com sessão do banco A` | - | - | **no Walked line** |
| C47 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C47` | count unknown | - | pass |
| C48 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C48` | count unknown | - | pass |
| C49 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C49` | count unknown | - | pass |
| C50 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C50` | count unknown | - | pass |
| C50 | `walk - revisar a barra de endereço das quatro telas e as mensagens de erro do fluxo` | - | - | **no Walked line** |
| C51 | `walk - abrir as quatro telas com rede lenta, derrubar a rede durante a gravação e reenviar o formulário` | - | - | **no Walked line** |
| C52 | `walk - conferir as quatro telas na largura de 360 px com a paleta e as medidas aplicadas` | - | - | **no Walked line** |
| C53 | `walk - percorrer os 4 passos com o teclado, provocar um erro de campo e voltar um passo` | - | - | **no Walked line** |
| C54 | `walk - abrir a navegação administrativa nas quatro telas e conferir o link e o anúncio da página atual` | - | - | **no Walked line** |
| C55 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C55` | count unknown | - | pass |
| C56 | `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C56` | count unknown | - | pass |
| Build | `npm run build` | - | - | pass |
