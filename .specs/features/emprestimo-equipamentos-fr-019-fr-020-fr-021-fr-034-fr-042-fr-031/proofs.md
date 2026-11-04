# emprestimo-equipamentos-fr-019-fr-020-fr-021-fr-034-fr-042-fr-031 proofs

**HEAD**: 5a58014
**Tree**: clean
**Result**: 61 pass, 0 fail; mutations 0 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `npx --yes supabase@latest test db supabase/tests/emprestimo-busca.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| C2 | `npx --yes supabase@latest test db supabase/tests/emprestimo-busca.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| C3 | `npx --yes supabase@latest test db supabase/tests/emprestimo-busca.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| C4 | `npx --yes supabase@latest test db supabase/tests/emprestimo-busca.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| C5 | `npx --yes supabase@latest test db supabase/tests/emprestimo-busca.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| C6 | `npx --yes supabase@latest test db supabase/tests/emprestimo-busca.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| C7 | `npx --yes supabase@latest test db supabase/tests/emprestimo-busca.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| C8 | `npx --yes supabase@latest test db supabase/tests/emprestimo-busca.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| C8 | `walk - buscar um nome sintético sem conta e conferir a mensagem e o próximo passo` | - | - | pass (Walked) |
| C9 | `walk - buscar a pessoa sintética, escolher o resultado e conferir o cartão e o próximo passo` | - | - | pass (Walked) |
| C10 | `npx --yes supabase@latest test db supabase/tests/loan-draft.test.sql --debug 2>&1 | grep -e "^ok [0-9]* - C10"` | count unknown | - | pass |
| C11 | `walk - abrir /admin/emprestimos/novo com um banco sintético sem peças disponíveis` | - | - | pass (Walked) |
| C12 | `npx --yes supabase@latest test db supabase/tests/loan-draft.test.sql --debug 2>&1 | grep -e "^ok [0-9]* - C12"` | count unknown | - | pass |
| C13 | `npx --yes supabase@latest test db supabase/tests/loan-draft.test.sql --debug 2>&1 | grep -e "^ok [0-9]* - C13"` | count unknown | - | pass |
| C14 | `npx --yes supabase@latest test db supabase/tests/loan-draft.test.sql --debug 2>&1 | grep -e "^ok [0-9]* - C14"` | count unknown | - | pass |
| C15 | `npx --yes supabase@latest test db supabase/tests/loan-draft.test.sql --debug 2>&1 | grep -e "^ok [0-9]* - C15"` | count unknown | - | pass |
| C16 | `npx --yes supabase@latest test db supabase/tests/loan-draft.test.sql --debug 2>&1 | grep -e "^ok [0-9]* - C16"` | count unknown | - | pass |
| C17 | `npx --yes supabase@latest test db supabase/tests/loan-draft.test.sql --debug 2>&1 | grep -e "^ok [0-9]* - C17"` | count unknown | - | pass |
| C18 | `npx --yes supabase@latest test db supabase/tests/loan-draft.test.sql --debug 2>&1 | grep -e "^ok [0-9]* - C18"` | count unknown | - | pass |
| C19 | `npx --yes supabase@latest test db supabase/tests/loan-draft.test.sql --debug 2>&1 | grep -e "^ok [0-9]* - C19"` | count unknown | - | pass |
| C20 | `npx --yes supabase@latest test db supabase/tests/loan-draft.test.sql --debug 2>&1 | grep -e "^ok [0-9]* - C20"` | count unknown | - | pass |
| C21 | `npx --yes supabase@latest test db supabase/tests/loan-draft.test.sql --debug 2>&1 | grep -e "^ok [0-9]* - C21"` | count unknown | - | pass |
| C22 | `npx --yes supabase@latest test db supabase/tests/loan-draft.test.sql --debug 2>&1 | grep -e "^ok [0-9]* - C22"` | count unknown | - | pass |
| C23 | `bash scripts/loans-concurrency-test.sh --only C23` | count unknown | - | pass |
| C24 | `npx --yes supabase@latest test db supabase/tests/loan-draft.test.sql --debug 2>&1 | grep -e "^ok [0-9]* - C24"` | count unknown | - | pass |
| C25 | `npx --yes supabase@latest test db supabase/tests/loan-draft.test.sql --debug 2>&1 | grep -e "^ok [0-9]* - C25"` | count unknown | - | pass |
| C26 | `walk - gravar um empréstimo aguardando retirada e abrir /admin/emprestimos/<code>` | - | - | pass (Walked) |
| C27 | `walk - abrir /admin/emprestimos com dois empréstimos aguardando retirada nas fixtures` | - | - | pass (Walked) |
| C28 | `walk - abrir um empréstimo aguardando retirada, gerar o termo e conferir o texto antes e depois` | - | - | pass (Walked) |
| C29 | `npx --yes supabase@latest test db supabase/tests/emprestimo-termo.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| C30 | `npx --yes supabase@latest test db supabase/tests/emprestimo-termo.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| C31 | `npx --yes supabase@latest test db supabase/tests/emprestimo-termo.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| C31 | `walk - remover a chave de serviço do ambiente, tentar gerar o termo e conferir que o empréstimo continua aguar` | - | - | pass (Walked) |
| C32 | `npx --yes supabase@latest test db supabase/tests/emprestimo-termo.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| C33 | `npx --yes supabase@latest test db supabase/tests/emprestimo-termo.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| C34 | `walk - gerar o termo de um empréstimo aguardando retirada sintético, abrir o PDF e conferir campo por campo` | - | - | pass (Walked) |
| C35 | `walk - abrir o PDF gerado com o modelo sintético semeado e conferir o rodapé` | - | - | pass (Walked) |
| C36 | `walk - usar Baixar termo e conferir o arquivo baixado` | - | - | pass (Walked) |
| C37 | `npx --yes supabase@latest test db supabase/tests/emprestimo-termo.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| C37 | `walk - abrir /admin/emprestimos/<codigo-de-outro-banco>/termo com sessão do banco A` | - | - | pass (Walked) |
| C38 | `npx --yes supabase@latest test db supabase/tests/emprestimo-conclusao.test.sql --debug 2>&1 | grep -e "^ok [0-` | count unknown | - | pass |
| C39 | `npx --yes supabase@latest test db supabase/tests/emprestimo-conclusao.test.sql --debug 2>&1 | grep -e "^ok [0-` | count unknown | - | pass |
| C40 | `npx --yes supabase@latest test db supabase/tests/emprestimo-conclusao.test.sql --debug 2>&1 | grep -e "^ok [0-` | count unknown | - | pass |
| C41 | `npx --yes supabase@latest test db supabase/tests/emprestimo-conclusao.test.sql --debug 2>&1 | grep -e "^ok [0-` | count unknown | - | pass |
| C42 | `walk - concluir um empréstimo aguardando retirada sintético e conferir a confirmação e o download` | - | - | pass (Walked) |
| C43 | `npx --yes supabase@latest test db supabase/tests/emprestimo-conclusao.test.sql --debug 2>&1 | grep -e "^ok [0-` | count unknown | - | pass |
| C44 | `npx --yes supabase@latest test db supabase/tests/emprestimo-conclusao.test.sql --debug 2>&1 | grep -e "^ok [0-` | count unknown | - | pass |
| C45 | `npx --yes supabase@latest test db supabase/tests/emprestimo-conclusao.test.sql --debug 2>&1 | grep -e "^ok [0-` | count unknown | - | pass |
| C46 | `walk - abrir /admin/emprestimos/<codigo-de-outro-banco> e um código inventado com sessão do banco A` | - | - | pass (Walked) |
| C47 | `npx --yes supabase@latest test db supabase/tests/emprestimo-isolamento.test.sql --debug 2>&1 | grep -e "^ok [0` | count unknown | - | pass |
| C48 | `npx --yes supabase@latest test db supabase/tests/emprestimo-isolamento.test.sql --debug 2>&1 | grep -e "^ok [0` | count unknown | - | pass |
| C49 | `npx --yes supabase@latest test db supabase/tests/emprestimo-isolamento.test.sql --debug 2>&1 | grep -e "^ok [0` | count unknown | - | pass |
| C50 | `npx --yes supabase@latest test db supabase/tests/emprestimo-isolamento.test.sql --debug 2>&1 | grep -e "^ok [0` | count unknown | - | pass |
| C50 | `walk - revisar a barra de endereço das quatro telas e as mensagens de erro do fluxo` | - | - | pass (Walked) |
| C51 | `walk - abrir as quatro telas com rede lenta, derrubar a rede durante a gravação e reenviar o formulário` | - | - | pass (Walked) |
| C52 | `walk - conferir as quatro telas na largura de 360 px com a paleta e as medidas aplicadas` | - | - | pass (Walked) |
| C53 | `walk - percorrer os 4 passos com o teclado, provocar um erro de campo e voltar um passo` | - | - | pass (Walked) |
| C54 | `walk - abrir a navegação administrativa nas quatro telas e conferir o link e o anúncio da página atual` | - | - | pass (Walked) |
| C55 | `npx --yes supabase@latest test db supabase/tests/emprestimo-isolamento.test.sql --debug 2>&1 | grep -e "^ok [0` | count unknown | - | pass |
| C56 | `npx --yes supabase@latest test db supabase/tests/emprestimo-termo.test.sql --debug 2>&1 | grep -e "^ok [0-9]* ` | count unknown | - | pass |
| Build | `npm run build` | - | - | pass |
