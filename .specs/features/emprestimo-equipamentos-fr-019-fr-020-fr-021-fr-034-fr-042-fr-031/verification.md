# Empréstimo de equipamentos verification

**Verdict**: FAIL
**Mutations**: 3 - C7, C22, C18 (as três morrem nesta rodada: `3 killed, 0 not`)
**Proofs**: `proofs.md` at `54ef3ae` - `check_proofs.py --mutations` nesta rodada: 43 provas verdes, 18 `walk` abertos, `Build` verde, `Tree` clean
**Verifier**: independent sub-agent (autor != verificador)

## Findings

| # | Finding | Severity | Evidence | Fix | Closed |
| --- | --- | --- | --- | --- | --- |
| 1 | Os 18 checks provados por `walk` continuam sem conferência visual. O `proofs.md` desta rodada já não mente: cada uma dessas linhas lê `no Walked line`, e o portão as conta como vermelhas | Alto | `check_proofs.py --mutations` -> `43 pass, 18 fail`; os 18 `fail` são `C8, C9, C11, C26, C27, C28, C31, C34, C35, C36, C37, C42, C46, C50, C51, C52, C53, C54: no Walked line`; `validate_verification.py` devolve `ERROR ... proofs.md - C8 reads '**no Walked line**'` e mais 17, além de `ERROR checks.md has a walk proof but its ## Handoff has no **Walked:** line`; `checks.md` não tem a linha `**Walked:**` (Handoff, `Pending walk`) | Fazer a conferência nas telas e escrever `**Walked:** 2026-11-0X - <o que foi visto>`; só então as 18 linhas viram `pass (Walked)` | open - por decisão explícita do `AGENTS.md`, que proíbe automação de navegador e entrega a conferência visual ao desenvolvedor. Não é uma correção pendente do autor: é trabalho humano pendente, e o recorte está agora declarado com honestidade em vez de `pass (Walked)` |
| 2 | O `validate_verification.py` não conseguia ler o `proofs.md`: a célula do comando levava um `grep` com pipe, `split_row` cortava a linha em 6 células e o portão lia a coluna `Ran` (`-`) como resultado | Alto | Antes: `validate_verification.py` -> `41` linhas `reads '-'`. Agora todas as provas chamam `bash scripts/loan-proof.sh <arquivo> --only C<id>` e nenhuma célula tem pipe: `validate_verification.py` -> `0` linhas `reads '-'`, as 43 provas e o `Build` lidos como `pass` | - | 54ef3ae |
| 3 | C7 não distinguia "conta só rascunhos" de "conta rascunhos e empréstimo entregue": a fixture só tinha um `draft` no banco da sessão | Médio | Mutação `and loan.status in ('draft', 'active')` -> `and loan.status = 'draft'` (`20261104000000_loans.sql:591`): `Killed: yes`. Rodada à mão com a mutação aplicada: `not ok 9 - C7 the open loan count sums drafts and active loans of the session bank`, `have: (1)`, `not ok 10 - C7 the CPF search also counts the session bank only`, `have: (1)`, `Result: FAIL` | Empréstimo `active` `BBBB00000003` no banco da sessão para a mesma pessoa e `open_loan_count = 2` nas duas asserções | bb3d2c8 |
| 4 | A segunda metade de C22 asseria só o SQLSTATE: apagar a guarda de linha aberta levantava o mesmo `P0003` pelo índice único, com outra mensagem | Médio | Mutação: guarda (`20261104000000_loans.sql:839-856`) trocada por comentário -> `Killed: yes`; a asserção agora fixa `O equipamento Cadeira de rodas BVCR0105 não está mais disponível. Atualize a lista e escolha outro.` | Asserir a mensagem exata no caso da peça liberada à mão | bb3d2c8 |
| 5 | O `## Coverage` afirmava "2 caracteres C18, 120 caracteres C18, 200 caracteres C20" e nenhum teste usava esses valores | Médio | Mutação `not between 2 and 120` -> `not between 3 and 119` (`:723`): `Killed: yes`; o teste agora grava `Al` (2), `repeat('a', 120)` e 200 letras cercadas de dois espaços nas pontas, e assere o valor guardado já sem as pontas, com 1, 121 e 201 ainda recusados em C19/C20 | Asserir os limites aceitos, não só os recusados | bb3d2c8 |
| 6 | C47 continua menor que o critério: a asserção cobre as 10 RPCs só para `authenticated`; para `anon` são 3 de 10 e para `service_role` 3 de 10, e das 45 células role x tabela x privilégio das cinco tabelas 14 são asseridas | Baixo | Com `grant execute on function public.admin_create_loan_draft(uuid, uuid[], text, text, text, integer, integer) to anon` na migration e `db reset`, `has_function_privilege('anon', ...)` = `t` e `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C47` -> `exit=0` (leak invisível). O mesmo com `grant delete on catalog.loan_lines to authenticated` (`has_table_privilege` = `t`) -> `exit=0`. Hoje não há vazamento: as 10 RPCs dão `anon=false svc=false` e nenhuma tabela é legível | Laço sobre as 10 assinaturas para `anon` e para `service_role`, e `not has_table_privilege` para `INSERT`/`UPDATE`/`DELETE` nas seis tabelas em cada uma das três roles | a0e830a - C47 agora varre 6 tabelas x 3 roles x 4 privilégios e 10 RPCs x 3 roles |
| 7 | C37 exigia "a mesma recusa" nos três casos e asseria só o SQLSTATE | Baixo | Trocar a mensagem do ramo "sem termo" (`:1397`) para `Empréstimo sem termo gerado`: `not ok 13 - C37 a loan of another bank is refused with the generic answer`, `caught: P0005: Empréstimo sem termo gerado`, `wanted: P0005: Empréstimo não encontrado`, `not ok 15 - C37 a loan without a generated term ...`, `Result: FAIL` | Asserir a mensagem nos três `throws_ok` | bb3d2c8 |
| 8 | Gerar o termo de novo sem alteração deixava um PDF órfão no bucket | Baixo | `src/lib/loans/admin-server.ts:585-593` devolve a versão atual antes do `storage.upload` quando `row.current_content_hash === contentHash`; `admin_loan_term_data` devolve `current_version` e `current_content_hash` (`20261104000000_loans.sql:1184-1195`) e a nova asserção `C29 the term data reports the current file ...` morre com `select document.version + 1` (`not ok 4 - C29 ...`, `Result: FAIL`). Probe de determinismo do PDF: `renderLoanTermPdf` com a mesma entrada dá `1210 bytes` e o mesmo sha256 em dois processos, então a comparação pode mesmo casar | Devolver o hash atual e não enviar quando ele é igual | bb3d2c8 (a guarda do app não tem teste automatizado - ver "Judged without a mutation") |
| 9 | A correção de C47 apagou três asserções negativas que existiam em `5a58014` e não as repôs: um vazamento que o teste da rodada 1 pegava passou a passar verde | Médio | `git show bb3d2c8 -- supabase/tests/emprestimo-isolamento.test.sql` remove `not has_function_privilege('anon', 'public.admin_search_people(text)', 'EXECUTE')`, a mesma para `admin_create_loan_draft` e `not has_function_privilege('service_role', 'public.admin_search_people(text)', 'EXECUTE')`; repuseram `admin_loan_detail`, `admin_loan_term_file`, `admin_cancel_loan_draft` (anon) e `admin_loan_term_data`, `admin_complete_loan`, `admin_bank_loans` (service_role). Probe: `grant execute ... to anon` em `admin_create_loan_draft` (exatamente o que o teste de `5a58014` cobria) -> `--only C47` `exit=0` | Repor as três asserções e fechar o achado 6 com o laço sobre as 10 assinaturas | a0e830a - as três asserções voltaram dentro do laço; os dois probes do Verifier (`grant execute ... to anon` em uma RPC e `grant delete on catalog.loan_lines to authenticated`) passaram a matar `C47` |

## Mutations

`mutations.json` não precisou de ajuste: cada prova já faz `db reset` e roda o arquivo inteiro mais a asserção nomeada (54ef3ae). Saída de `check_proofs.py --mutations` nesta rodada:

| Mutation | Location | Killed |
| --- | --- | --- |
| C7 open loan count drops the active loan of the session bank | `supabase/migrations/20261104000000_loans.sql:591` | yes |
| C22 open line guard removed, leaving only the unique index | `supabase/migrations/20261104000000_loans.sql:839` | yes |
| C18 patient name bounds shifted from 2..120 to 3..119 | `supabase/migrations/20261104000000_loans.sql:723` | yes |

Como a prova de cada mutação engole a saída do `db reset` (`>/dev/null 2>&1 && ...`), um `reset` quebrado
mataria a mutação pelo motivo errado. Conferi C7 à mão, com a mutação aplicada e o `db reset` visível:
`have: (1)` nas duas asserções, `Result: FAIL` - morte pelo motivo certo. A árvore foi restaurada com
`git checkout -- supabase/migrations/20261104000000_loans.sql` e o banco com `npx --yes supabase@latest db reset`
depois de cada probe.

## Probes

Testes descartáveis e mutações à mão, todos revertidos; banco resetado no fim.

| Probe | Resultado |
| --- | --- |
| `--only` esconde falha em outro check do mesmo arquivo? (expectativa de C31 alterada, depois `--only C37`) | `exit=1` - não esconde: o script exige `Result: PASS` do arquivo inteiro |
| `renderLoanTermPdf` é determinístico entre processos? | sim: `1210:8068386732930125eb1b442b2a3da56d4fd07f34aa46f56d56d8f85add15aa75` em dois processos |
| `admin_loan_term_data` com `current_version + 1` | `not ok 4 - C29 the term data reports the current file so an identical term is not uploaded again` |
| mensagem do ramo "sem termo" de `admin_loan_term_file` trocada | `not ok 13` e `not ok 15 - C37 ...`, `caught` vs `wanted` mostram a mensagem |
| `grant execute` em `admin_create_loan_draft` para `anon` | `--only C47` `exit=0` (achado 9) |
| `grant delete` em `catalog.loan_lines` para `authenticated` | `--only C47` `exit=0` (achado 6) |
| privilégios atuais das 10 RPCs para `anon`/`service_role` | `anon=false svc=false` nas 10 - sem vazamento hoje |

## Judged without a mutation

- **C23** (concorrência): `scripts/loans-concurrency-test.sh --only C23` inalterado desde `5a58014`; segue provando o `for update` com duas sessões reais.
- **C24/C32/C33/C56/C50/C55**: inalterados nesta rodada; a análise da rodada 1 (comparação `is not distinct from`, retorno antecipado por hash **e** modelo, máscara por igualdade exata) continua valendo.
- **Guarda do achado 8**: `admin-server.ts:585-593` é a única prova do "não envia de novo" - o repositório não tem teste de app (nenhum `*.test.ts` em `src/`). A asserção C29 fixa a coluna que a guarda consulta; a decisão de não chamar o `upload` é provada por leitura. Aceitável para o escopo do `AGENTS.md`, mas é prova de inspeção, não de execução.
- **Guarda do app x modelo (residual)**: a comparação é só de hash, enquanto `admin_record_loan_term` exige hash **e** o mesmo `document_model_id`. Um modelo `approved` cujo corpo não muda o PDF (o rodapé com a versão só existe em `pending_legal_review`, `term-pdf.ts:58-70`) faria o app devolver a versão antiga onde o RPC gravaria a seguinte. Não observei caso real e o arquivo registrado continua batendo com o PDF impresso; fica registrado como risco, não como achado.
