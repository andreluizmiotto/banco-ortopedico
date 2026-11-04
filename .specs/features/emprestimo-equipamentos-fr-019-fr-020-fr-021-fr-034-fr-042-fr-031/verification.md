# Empréstimo de equipamentos verification

**Verdict**: FAIL
**Mutations**: 3 - probed C7, C22, C18 (as três sobreviveram)
**Proofs**: `proofs.md` at `5a58014` (o commit `a011ce7`, HEAD, só alterou `.specs/`)
**Verifier**: independent sub-agent (author != verifier)

## Findings

| # | Finding | Severity | Evidence | Fix | Closed |
| --- | --- | --- | --- | --- | --- |
| 1 | Os 18 checks provados por `walk` estão `pass (Walked)` no `proofs.md`, mas a própria linha do Handoff diz que a conferência visual está pendente: nenhum deles foi feito, e C51/C52/C53 (acessibilidade, estados de rede) não têm outra prova | Alto | `grep -n Walked .specs/features/.../checks.md` -> `253:- **Walked:** pendente - a conferência visual do desenvolvedor cobre C9, C11, C26, ...`; `grep -c "pass \(Walked\)" .specs/features/.../proofs.md` -> `18` | Fazer a conferência nas telas, corrigir o que aparecer e reescrever a linha com a data e o que foi visto (`**Walked:** 2026-11-04 - ...`); só então `check_proofs.py` vira prova | |
| 2 | O `validate_verification.py` não consegue ler o `proofs.md`: a linha do comando de prova vai entre crases sem escapar o `\|` do `grep`, então `split_row` corta cada linha em 6 células e o portão lê a coluna "Ran" (`-`) como resultado. As 41 provas de teste viram `reads '-'` e o portão não fecha, mesmo com todas verdes | Alto | `check_proofs.py:224` escreve `` `{p.replace('`', '')[:110]}` `` sem escapar `\|`; `split_row` da linha `\| C1 \|` devolve 6 células - `C1`, o começo do `npx ... test db ...`, `grep -e "^ok [0-9]* `, `count unknown`, `-`, `pass` - e o portão lê a quinta (`-`) como resultado; `python3 .opencode/skills/tlc-spec-lean/scripts/validate_verification.py <feature> \| grep -c "reads '-'"` -> `41` | Escapar o `\|` ao escrever a célula (`p.replace('\|', '\\\\\|')`), como `mutate.py:cell()` já faz; sem isso o portão nunca enxerga as provas deste recorte | |
| 3 | C7 não distingue "conta só rascunhos" de "conta rascunhos e empréstimo entregue": na fixture do banco da sessão só existe um `draft`, e o único `active` está no outro banco. Se `admin_search_people` contar apenas `draft`, quem já saiu com o equipamento aparece com `0 empréstimos em aberto` e nenhum teste falha | Médio | Mutação `and loan.status in ('draft', 'active')` -> `and loan.status = 'draft'` (`20261104000000_loans.sql:591`): `mutate.py` -> `C7 open loan count drops the active loan of the session bank ... no`; a prova do check continua verde (`ok 9 - C7 ...`, `ok 10 - C7 ...`); com uma fixture de um `draft` e um `active` no mesmo banco, `admin_search_people` devolve `have: (1) want: (2)` (probe abaixo) | Acrescentar ao teste de busca um empréstimo `active` no banco da sessão para a mesma pessoa e asserir `open_loan_count = 2`; manter o `draft` do outro banco para o caso do `0` | |
| 4 | A segunda metade de C22 (peça trazida à mão para `available` com linha de empréstimo aberta) assere só o SQLSTATE: a mensagem que o AC 22 fixa (`O equipamento <tipo> <identificador> não está mais disponível...`) não é verificada. Apagar a guarda de linha aberta deixa o check verde, porque o índice único e o `exception when unique_violation` levantam o mesmo `P0003` com outra mensagem | Médio | Mutação: a guarda (`20261104000000_loans.sql:839-856`) trocada por um comentário -> `mutate.py`: `C22 open line guard removed ... no`; `loan-draft.test.sql` segue `Result: PASS` (`ok 23 - C22 a unit released by hand ...`), porque o teste usa `throws_ok(..., 'P0003', null, ...)` (`loan-draft.test.sql:365-373`); a mensagem muda: em HEAD `O equipamento Cadeira de rodas M2CR0001 não está mais disponível. Atualize a lista e escolha outro.`, com a guarda removida `Um dos equipamentos escolhidos não está mais disponível. Atualize a lista e escolha outro.` | Asserir a mensagem no caso da peça liberada à mão (texto exato, ou `throws_like` com `%` para o tipo e o número), como já se faz com o `P0003` | |
| 5 | O `## Coverage` afirma "2 caracteres C18 · 120 caracteres C18" e "200 caracteres C20", mas nenhum teste usa esses valores: o teste grava um nome de 9 letras e recusa 1 e 121; grava uma nota curta e recusa 201. Os limites aceitos de paciente e de anotação não têm prova | Médio | Mutação `not between 2 and 120` -> `not between 3 and 119` (`20261104000000_loans.sql:723`): `mutate.py` -> `C18 patient name bounds shifted ... no`; `ok 16 - C18 and C20 the patient name and the condition note are stored trimmed` continua verde; o probe com 2 letras passa em HEAD e falha sob a mutação (`ERROR: Paciente inválido`). `grep -n "repeat('a', 121)\|repeat('a', 201)\|Ana Souza" supabase/tests/loan-draft.test.sql` -> `153`, `163`, `221`, `385` (não há 2, 120 nem 200) | Asserir 2 e 120 caracteres aceitos em C18 e 200 caracteres aceitos em C20, para o `Coverage` dizer a verdade | |
| 6 | C47 cobre `execute` de `anon`/`service_role` em 3 das 10 RPCs e só `SELECT` (nível de tabela) nas tabelas: liberar `execute` a `anon` numa quarta RPC, ou `insert/update/delete` a `authenticated` em `catalog.loans`, mantém o check verde | Baixo | `grant execute on function public.admin_loan_term_data(text) to authenticated, anon;` na migration + `db reset` -> `has_function_privilege('anon', ...)` = `t` e o check inteiro verde (`ok 1..5 - C47`); `grant insert, update, delete on catalog.loans to authenticated;` -> `t\|f` e o check inteiro verde (`ok 1..5 - C47`). Não há vazamento hoje: `anon` recebe `42501 Empréstimo indisponível` e `authenticated` recebe `new row violates row-level security policy` | Trocar as 5 asserções nominais por um laço sobre as 10 assinaturas (`has_function_privilege('anon', p, 'EXECUTE')` para cada uma) e asserir `not has_table_privilege(role, tabela, 'INSERT'/'UPDATE'/'DELETE')` nas cinco tabelas | |
| 7 | C37 exige "a mesma recusa" nos três casos (outro banco, código inexistente, sem termo), mas o teste assere só o SQLSTATE (`throws_ok(..., 'P0005', null, ...)`, `emprestimo-termo.test.sql:297-316`). Trocar a mensagem de um dos ramos mantém o check verde | Baixo | Probe dos três casos em HEAD: `P7 other bank sqlstate=P0005 message=Empréstimo não encontrado`, `P7 unknown code ... Empréstimo não encontrado`, `P7 no term ... Empréstimo não encontrado` - hoje iguais, mas nada no teste fixa isso | Asserir a mensagem em cada um dos três `throws_ok` | |
| 8 | Gerar o termo de novo sem alteração deixa um PDF órfão no bucket: `generateAdminLoanTerm` envia para `next_storage_path` (a versão seguinte) e só depois registra; como o hash não mudou, `admin_record_loan_term` devolve a versão atual e não grava linha. O objeto recém-enviado - com nome e CPF do responsável - fica em `loan-terms/<entity>/<loan>/<n>.pdf` sem `loan_documents` e sem auditoria | Baixo | `src/lib/loans/admin-server.ts:582` (`storage.upload(row.next_storage_path, bytes, ...)`) antes de `:589` (`admin_record_loan_term`); `20261104000000_loans.sql:1262-1276` devolve `v_next_version` da linha atual e sai sem `insert`, que é o que `ok 20 - C32 recording the same content again keeps the same version` prova; o caminho enviado vem de `admin_loan_term_data` com `max(version) + 1` (`:1139-1142`, `:1181-1182`). Sem a chave de serviço nesta sessão, a prova é a leitura do caminho de escrita mais a prova SQL do retorno antecipado | `admin_loan_term_data` devolver o hash atual e o app não enviar quando ele for igual (ou apagar o objeto no caminho de reemissão sem mudança) | |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| C7 open loan count drops the active loan of the session bank | `supabase/migrations/20261104000000_loans.sql:591` | no |
| C22 open line guard removed, leaving only the unique index | `supabase/migrations/20261104000000_loans.sql:839` | no |
| C18 patient name bounds shifted from 2..120 to 3..119 | `supabase/migrations/20261104000000_loans.sql:723` | no |

As três são de migration, e `supabase test db` roda contra o banco já migrado: a prova em
`mutations.json` é `npx --yes supabase@latest db reset && npx --yes supabase@latest test db ...`,
senão a mutação não chega ao banco e o resultado não quer dizer nada. Comando usado:

```
python3 .opencode/skills/tlc-spec-lean/scripts/mutate.py \
  --spec .specs/features/emprestimo-equipamentos-fr-019-fr-020-fr-021-fr-034-fr-042-fr-031/mutations.json
| Mutation | Location | Killed |
| C7 open loan count drops the active loan of the session bank | `supabase/migrations/20261104000000_loans.sql:591` | no |
| C22 open line guard removed, leaving only the unique index | `supabase/migrations/20261104000000_loans.sql:839` | no |
| C18 patient name bounds shifted from 2..120 to 3..119 | `supabase/migrations/20261104000000_loans.sql:723` | no |
mutate: 0 killed, 3 survived, 0 blocked
```

Depois de cada mutação a árvore foi restaurada com `git checkout -- supabase/migrations/20261104000000_loans.sql`
e o banco com `npx --yes supabase@latest db reset`.

## Probes

Valores que nem o plano nem os checks nomeiam, rodados como teste descartável (apagado no fim):

| Probe | HEAD | Sob a mutação |
| --- | --- | --- |
| `Outra data` com 1 dia e com 365 dias | aceitos, `due_date = hoje + 1` e `hoje + 365` | - |
| `Sem data de devolução` com revisão 1 e 365 | aceitos, `review_date = hoje + 1` e `hoje + 365` | - |
| `catalog.entities.loan_suggested_days` = 1 e = 365 | `suggested_days` devolve 1 e 365 | - |
| busca com exatamente 10 correspondentes | `count(*) = 10`, `has_more = false` | - |
| mesma pessoa com um `draft` e um `active` no banco da sessão | `open_loan_count = 2` | `= 1` com a mutação de C7 |
| paciente com 2 letras | gravado como `Al` | `ERROR: Paciente inválido` com a mutação de C18 |
| reenvio idêntico do termo | devolve a versão atual, sem linha nova | - |
| peça liberada à mão com linha aberta | `P0003 O equipamento Cadeira de rodas ... não está mais disponível...` | `P0003 Um dos equipamentos escolhidos não está mais disponível...` |
| termo de outro banco / código inexistente / sem termo | `P0005 Empréstimo não encontrado` nos três | - |

As regras do plano que testei por conta própria estão corretas; o que falta é a prova, não o
comportamento.

## Judged without a mutation

- **C23** (concorrência): `bash scripts/loans-concurrency-test.sh --only C23` -> `C23 ok: one draft accepted, the concurrent one refused with 409`. Duas sessões `psql` reais, a primeira segura a transação por 3 s, a segunda bloqueia no `for update` e recebe `P0003`; o script assere o código de retorno das duas, o `P0003` no `stderr` e as contagens de empréstimo, linha e peça. Prova o que o check diz.
- **C24** (idempotência): a comparação usa `is not distinct from` nas datas, paciente e anotação (`:775-784`); trocar por `is distinct from` faria a busca não achar o rascunho e o índice único recusaria o segundo empréstimo, então a prova do C24 cairia. O teste também confere que não há segundo empréstimo nem segunda auditoria. Segura.
- **C32/C33** (versão e hash): o retorno antecipado exige o mesmo hash **e** o mesmo modelo (`:1262-1276`), então trocar o modelo ativo gera a versão seguinte (é o que o C33 prova); o C32 assere um único atual e uma única auditoria. Segura (o defeito do achado 8 é do app, não do RPC).
- **C56**: o CPF completo só sai de `admin_loan_term_data` para rascunho do próprio banco; outro banco devolve `P0005`. Segura.
- **C50**: as duas asserções fixam a máscara por igualdade exata (`'***.***.***-35'`, `'(54) *****-0001'`) e o caso do detalhe também nega o valor completo; o que sobra (URL, `Referer`, log) é `walk` e está no achado 1.
- **C55**: a fixture cria o rascunho há 40 dias, assere que aparece na lista com `created_at < now() - 39 days` e que a peça continua `reserved`; um filtro de data ou de situação na listagem quebraria o teste. Segura, embora prove ausência de expiração (não há agendador).
