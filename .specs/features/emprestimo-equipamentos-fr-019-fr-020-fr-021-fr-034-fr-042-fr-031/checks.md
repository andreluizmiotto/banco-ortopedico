# Empréstimo de equipamentos checks

Mutations: 3
Build: `npm run build`
Plan: `.specs/features/emprestimo-equipamentos-fr-019-fr-020-fr-021-fr-034-fr-042-fr-031/plan.md`

56 checks em 3 fatias · 7 portas unidirecionais · 0 perguntas abertas

As provas SQL rodam os arquivos pgTAP de `supabase/tests/` com `supabase test db`.
Cada asserção `ok(...)` recebe a descrição começando pelo identificador do check
(`C12 ...`), e a prova termina em `grep -e "^ok [0-9]* - C12"`, de modo que o código
de saída decide se aquela asserção, e não o arquivo inteiro, passou. O `AGENTS.md`
limita a automação a `npm run build` e `supabase test db` e proíbe automação de
navegador; por isso todo critério de tela é provado por `walk`, com a conferência
visual feita pelo desenvolvedor.

## Checks

### S1 - Localizar a pessoa e segurar os equipamentos

**C1** - A busca por 3 ou mais letras do nome devolve as contas da comunidade cujo nome contém o texto, sem diferenciar maiúsculas nem acentos (AC 1)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C1`

**C2** - Com 11 pessoas correspondentes, a busca devolve 10 em ordem de nome e sinaliza que há mais (AC 6)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C2`

**C3** - A busca por CPF aceita o valor com e sem pontuação e devolve a mesma pessoa (AC 2)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C3`

**C4** - Busca com 2 letras e busca com 10 dígitos são recusadas com `400` e nenhuma consulta é executada (AC 3)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C4`

**C5** - Cada resultado devolve o CPF como `***.***.***-25` e o telefone como `(54) *****-1234`, sem os valores completos (AC 4)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C5`

**C6** - Dois homônimos aparecem como dois resultados distintos, sem escolha automática de um deles (AC 5)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C6`

**C7** - A contagem de empréstimos em aberto de cada resultado conta apenas empréstimos do banco da sessão, com `0` para quem só tem empréstimo em outro banco (AC 7)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C7`

**C8** - Pessoa sem conta da comunidade não aparece em nenhum resultado e a tela mostra `Não encontramos ninguém com esse nome ou CPF.` com um único próximo passo (AC 8, AC 26)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-busca.test.sql --only C8`
Proof: walk - buscar um nome sintético sem conta e conferir a mensagem e o próximo passo

**C9** - Escolher um resultado mostra `Pessoa escolhida` com nome completo e CPF mascarado e libera o passo de equipamentos (AC 9)
Proof: walk - buscar a pessoa sintética, escolher o resultado e conferir o cartão e o próximo passo

**C10** - A lista de equipamentos traz somente peças `available` do banco da sessão, agrupadas por tipo e ordenadas por número do equipamento crescente (AC 10)
Proof: `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C10`

**C11** - Banco sem peça `available` mostra estado vazio com explicação e um único próximo passo para `/admin/acervo` (AC 11)
Proof: walk - abrir `/admin/emprestimos/novo` com um banco sintético sem peças disponíveis

**C12** - Um envio com 3 peças de 2 tipos grava 1 empréstimo e 3 linhas, com a entidade derivada da sessão e sem aceitar entidade vinda do navegador (AC 12)
Proof: `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C12`

**C13** - O prazo sugerido vem de `catalog.entities.loan_suggested_days` da entidade: `90` na entidade A e `45` na entidade B configurada assim (AC 13)
Proof: `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C13`

**C14** - `Outra data` com 30 dias grava devolução igual a hoje mais 30 dias e revisão nula (AC 14)
Proof: `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C14`

**C15** - Prazo customizado com 0 dias, 366 dias ou sem número é recusado com `400` e nada é gravado (AC 15)
Proof: `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C15`

**C16** - `Sem data de devolução` com a revisão sugerida grava devolução nula e revisão igual a hoje mais 90 dias, e aceita revisão entre 1 e 365 dias (AC 16)
Proof: `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C16`

**C17** - `Sem data de devolução` sem revisão, com revisão 0 ou com revisão 366 é recusado com `400` e nada é gravado (AC 17)
Proof: `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C17`

**C18** - Paciente `Outra pessoa` grava o nome sem espaços nas extremidades; `A própria pessoa` grava paciente nulo (AC 18)
Proof: `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C18`

**C19** - Nome de paciente com 1 caractere e com 121 caracteres é recusado com `400` e nada é gravado (AC 19)
Proof: `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C19`

**C20** - Anotação de estado com 200 caracteres grava sem espaços nas extremidades; com 201 caracteres é recusada com `400` e nada é gravado (AC 20)
Proof: `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C20`

**C21** - Gravar o empréstimo aguardando retirada deixa cada peça `reserved` e cria uma auditoria `loan_draft_created` com ator, entidade, empréstimo, peças e datas (AC 21)
Proof: `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C21`

**C22** - Peça `under_maintenance` escolhida recusa a operação inteira com `409` e nada é gravado; a peça trazida manualmente para `available` em `/admin/acervo` mas com linha de empréstimo aberta também recusa com `409` (AC 22)
Proof: `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C22`

**C23** - Duas transações concorrentes na mesma peça deixam exatamente uma com `200` e a outra com `409` (AC 23)
Proof: `bash scripts/loans-concurrency-test.sh --only C23`

**C24** - Reenviar o mesmo empréstimo com a mesma pessoa, peças e datas devolve o mesmo código, sem segundo empréstimo e sem segunda auditoria (AC 24)
Proof: `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C24`

**C25** - Entidade inativa recusa o empréstimo com `403` e nada é gravado (AC 25)
Proof: `bash scripts/loan-proof.sh supabase/tests/loan-draft.test.sql --only C25`

**C26** - A página do empréstimo aguardando retirada mostra código, pessoa, peças seguradas, data de entrega e data de devolução ou de revisão (AC 27)
Proof: walk - gravar um empréstimo aguardando retirada e abrir `/admin/emprestimos/<code>`

**C27** - A lista de `/admin/emprestimos` mostra os empréstimos aguardando retirada do mais recente para o mais antigo, com código, pessoa, quantidade e data, e uma única ação principal (AC 28)
Proof: walk - abrir `/admin/emprestimos` com dois empréstimos aguardando retirada nas fixtures

### S2 - Termo gerado e entrega confirmada

**C28** - O empréstimo aguardando retirada mostra `Termo ainda não gerado` e, depois de gerar, `Termo gerado em <data e hora> — versão <n>` (AC 29)
Proof: walk - abrir um empréstimo aguardando retirada, gerar o termo e conferir o texto antes e depois

**C29** - Gerar o termo usa o modelo ativo da entidade e registra no arquivo o modelo e a versão usados (AC 30)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C29`

**C30** - Entidade sem modelo ativo recusa a geração com `409` e não grava arquivo nem auditoria (AC 31)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C30`

**C31** - O arquivo é gravado no caminho `<entity_id>/<loan_id>/<version>.pdf`, sem nome, CPF ou telefone, e a auditoria `loan_term_generated` registra a versão do modelo e o hash; quando o envio ao bucket falha, nenhum arquivo nem auditoria é gravado (AC 34)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C31`
Proof: walk - remover a chave de serviço do ambiente, tentar gerar o termo e conferir que o empréstimo continua aguardando retirada e sem termo

**C32** - Gerar de novo sem alteração mantém um único arquivo atual e não cria segunda auditoria (AC 35)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C32`

**C33** - Gerar de novo depois de alterar o empréstimo grava a versão seguinte, mantém a anterior e marca só a nova como atual (AC 36)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C33`

**C34** - O PDF traz banco cedente, nome e CPF formatado do responsável, paciente quando houver, cada equipamento com tipo e identificador, a anotação de estado, as datas, o código do empréstimo e as duas linhas de assinatura, sem telefone nem endereço (AC 32)
Proof: walk - gerar o termo de um empréstimo aguardando retirada sintético, abrir o PDF e conferir campo por campo

**C35** - O PDF de modelo pendente de revisão traz no rodapé `Modelo provisório — versão <n> — pendente de revisão jurídica` (AC 33)
Proof: walk - abrir o PDF gerado com o modelo sintético semeado e conferir o rodapé

**C36** - Baixar o termo devolve `200`, `application/pdf` e `Content-Disposition: attachment; filename="termo-<code>.pdf"` (AC 37)
Proof: walk - usar `Baixar termo` e conferir o arquivo baixado

**C37** - Empréstimo de outro banco, código inexistente e empréstimo sem termo recebem a mesma recusa: `400` na leitura do arquivo e `404` na rota de download (AC 38)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C37`
Proof: walk - abrir `/admin/emprestimos/<codigo-de-outro-banco>/termo` com sessão do banco A

**C38** - Concluir a saída muda o empréstimo para `ativo`, cada peça segurada para `on_loan` e grava `loan_completed` mais uma auditoria `unit_updated` por peça (AC 39)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C38`

**C39** - Concluir sem termo atual recusa com `400` e não muda empréstimo nem peça (AC 40)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C39`

**C40** - Concluir com peça que saiu de `reserved` recusa com `409` e não muda empréstimo nem peça (AC 41)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C40`

**C41** - Gerar termo ou concluir em empréstimo que não está aguardando retirada recusa com `409`, sem arquivo, peça ou auditoria (AC 42)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C41`

**C42** - Depois de concluir, a tela mostra o código, a data de devolução ou de revisão e um único próximo passo, e o termo continua baixável (AC 43)
Proof: walk - concluir um empréstimo aguardando retirada sintético e conferir a confirmação e o download

**C43** - Desistir do empréstimo aguardando retirada muda o empréstimo para `cancelado`, marca `released_at`, devolve cada peça para `available` e grava `loan_draft_cancelled` (AC 44)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C43`

**C44** - Desistir de empréstimo que não está aguardando retirada recusa com `409` e não altera peça nem situação (AC 45)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C44`

**C45** - Depois de cancelar, a mesma pessoa e as mesmas peças aceitam um novo empréstimo (AC 46)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-conclusao.test.sql --only C45`

**C46** - Código de outro banco e código inexistente mostram a mesma recusa `Empréstimo não encontrado neste banco.`, sem nome nem dado (AC 47)
Proof: walk - abrir `/admin/emprestimos/<codigo-de-outro-banco>` e um código inventado com sessão do banco A

### S3 - Isolamento, leitores, estados e acessibilidade

**C47** - `anon`, sessão sem `bank_admin` ativo, sessão de outra entidade e papel forjado pelo navegador são negados pelo banco, e nenhuma role da Data API lê ou escreve as cinco tabelas novas nem `catalog.community_profiles` (AC 48)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C47`

**C48** - Peça segurada por empréstimo aguardando retirada aparece em `admin_bank_equipment_units` com a situação `reserved` (AC 49)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C48`

**C49** - `public.equipment_availability` deixa de contar a peça segurada por empréstimo aguardando retirada: 2 disponíveis caem para 1 (AC 50)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C49`

**C50** - Nenhuma resposta de busca ou detalhe traz CPF ou telefone completo, e o caminho das rotas, o `Referer` e as mensagens de erro não carregam nome, CPF ou telefone (AC 51)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C50`
Proof: walk - revisar a barra de endereço das quatro telas e as mensagens de erro do fluxo

**C51** - Cada tela mostra carregamento com texto, falha com ação de tentar novamente, falta de permissão sem dado e impede envio duplicado enquanto grava (AC 52)
Proof: walk - abrir as quatro telas com rede lenta, derrubar a rede durante a gravação e reenviar o formulário

**C52** - A 360 px não há rolagem horizontal, botões principais têm 56 px e texto negrito de 20 px, texto corrido 18 px, títulos 26 px, uma ação principal por tela e a paleta `#17458F`, `#F7A81B`, `#54565A`, `#1E7B3C` e `#B3261E` (AC 53)
Proof: walk - conferir as quatro telas na largura de 360 px com a paleta e as medidas aplicadas

**C53** - O formulário é dividido em 4 passos com `Passo 1 de 4` até `Passo 4 de 4`, rótulo associado, foco visível, erro ligado ao campo e `Voltar` em posição previsível (AC 54)
Proof: walk - percorrer os 4 passos com o teclado, provocar um erro de campo e voltar um passo

**C54** - A navegação administrativa oferece `Empréstimos` para `/admin/emprestimos` e anuncia a página atual (AC 55)
Proof: walk - abrir a navegação administrativa nas quatro telas e conferir o link e o anúncio da página atual

**C55** - Um empréstimo aguardando retirada criado há 40 dias continua na lista e com as peças em `Reservado para retirada`, sem expiração automática (AC 56)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-isolamento.test.sql --only C55`

**C56** - A RPC do termo devolve o CPF completo apenas do responsável do próprio empréstimo do banco da sessão: o rascunho do banco devolve `11144477735` e o empréstimo de outro banco é recusado com `P0005` (AC 32, AC 51)
Proof: `bash scripts/loan-proof.sh supabase/tests/emprestimo-termo.test.sql --only C56`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| `GET /admin/emprestimos` statuses (3) | `200` C27 · `307` C54 · `200` falta de permissão C51 | - |
| `GET /admin/emprestimos/novo` statuses (3) | `200` C10 · `307` C54 · `200` falta de permissão C51 | - |
| `GET /admin/emprestimos/[code]` statuses (3) | `200` C26 · `307` C54 · recusa genérica C46 | - |
| `GET /admin/emprestimos/[code]/termo` statuses (3) | `200` C36 · `307` C54 · `404` C37 | - |
| `POST /rest/v1/rpc/admin_search_people` statuses (4) | `200` C1 · `400` C4 · `401` C47 · `403` C47 | - |
| `POST /rest/v1/rpc/admin_loan_available_units` statuses (3) | `200` C10 · `401` C47 · `403` C47 | - |
| `POST /rest/v1/rpc/admin_create_loan_draft` statuses (5) | `200` C12 · `400` C15 · `403` C25 · `409` C22 · `401` C47 | - |
| `POST /rest/v1/rpc/admin_loan_detail` statuses (4) | `200` C26 · `400` C46 · `401` C47 · `403` C47 | - |
| `POST /rest/v1/rpc/admin_loan_term_data` statuses (5) | `200` C29 · `400` C41 · `409` C30 · `401` C47 · `403` C47 | - |
| `POST /rest/v1/rpc/admin_record_loan_term` statuses (5) | `200` C29 · `400` C31 · `409` C41 · `401` C47 · `403` C47 | - |
| `POST /rest/v1/rpc/admin_loan_term_file` statuses (4) | `200` C36 · `400` C37 · `401` C47 · `403` C47 | - |
| `POST /rest/v1/rpc/admin_complete_loan` statuses (5) | `200` C38 · `400` C39 · `409` C40 · `401` C47 · `403` C47 | - |
| `POST /rest/v1/rpc/admin_cancel_loan_draft` statuses (4) | `200` C43 · `409` C44 · `401` C47 · `403` C47 | - |
| door: prazo sugerido por entidade (1) | prazo lido da entidade C13 | - |
| door: modelo versionado por entidade e tipo (3) | modelo ativo usado C29 · entidade sem modelo C30 · versão seguinte C33 | - |
| door: empréstimo, linhas e trava de peça (4) | empréstimo e linhas C12 · trava de peça C22 · concorrência C23 · `released_at` C43 | - |
| door: arquivo do termo e bucket privado (4) | caminho C31 · um arquivo atual C32 · versões C33 · download C36 | - |
| door: auditoria de empréstimo (4) | `loan_draft_created` C21 · `loan_term_generated` C31 · `loan_completed` C38 · `loan_draft_cancelled` C43 | - |
| door: geração de PDF no servidor (2) | campos do PDF C34 · rodapé provisório C35 | - |
| door: caminho de escrita privado (1) | grants e RLS C47 | - |
| stored: `catalog.entities.loan_suggested_days` (1) | prazo sugerido C13 | - |
| stored: `catalog.document_models` (3) | ativo C29 · ausente C30 · nova versão C33 | - |
| stored: `catalog.loans` (3) | criação C12 · reenvio C24 · entidade inativa C25 | - |
| stored: `catalog.loan_lines` (4) | uma linha por peça C21 · trava C22 · concorrência C23 · liberação C43 | - |
| stored: `catalog.loan_documents` (3) | caminho e hash C31 · atual único C32 · versões C33 | - |
| stored: `catalog.loan_event_audit` (4) | `loan_draft_created` C21 · `loan_term_generated` C31 · `loan_completed` C38 · `loan_draft_cancelled` C43 | - |
| stored: bucket `loan-terms` (2) | caminho C31 · download C36 | - |
| prazo, AC 14 a AC 17 (6 examples) | 30 dias C14 · 0 dias C15 · 366 dias C15 · sem número C15 · sem data com 90 C16 · sem data sem revisão C17 | - |
| paciente, AC 18 e AC 19 (4 examples) | 2 caracteres C18 · 120 caracteres C18 · 1 caractere C19 · 121 caracteres C19 | - |
| anotação de estado, AC 20 (2 examples) | 200 caracteres C20 · 201 caracteres C20 | - |
| máscara de pessoa, AC 4 (2 fields) | CPF C5 · telefone C5 | - |
| CPF completo no termo, AC 32 e AC 51 (2 cases) | próprio rascunho C56 · empréstimo de outro banco C56 | - |
| captura de tela (0) | n/a - nenhuma fonte visual acompanhou o pedido | - |

## Swept

- validation: C4, C15, C17, C19, C20
- failure modes: C22 e C39 (operações inteiras desfeitas), C40 (nada muda quando a guarda falha)
- idempotency: C24, C32
- authorization: C25, C47; a busca que revela pessoas C7, C8
- concurrency: C23
- data lifecycle: C43, C45, C55
- dependency failure: C31 (envio ao bucket falha, nada é registrado), C30 (modelo ausente)
- state transitions: C21, C38, C40, C41, C43, C44
- observability: C21, C31, C38, C43

## Handoff

- **Settled mid-build:** 2026-11-04 - o AC 32 manda imprimir o CPF completo e o AC 51 proíbe CPF completo em resposta de termo; o usuário escolheu "Termo imprime o CPF completo; AC 51 vale para busca e detalhe". C50 passou a cobrir busca e detalhe, e C56 foi acrescentado para provar o limite da RPC do termo.
- **Dispatched:** Verifier round 1 at `5a58014` (8 achados); round 2 at `54ef3ae` (fechou 2, 3, 4, 5, 7 e 8; manteve 1 como trabalho humano e reabriu 6, virando o achado 9).
- **Boundary:** as 43 provas automatizadas passam; as 18 provas de `walk` continuam abertas até a conferência visual do desenvolvedor. C47 refeito depois da rodada 2 e as duas mutações do Verifier (`execute` para `anon` numa RPC, `delete` para `authenticated` em `catalog.loan_lines`) passaram a matar a prova.
- **Abandoned:** dblink dentro do pgTAP - o papel de teste não é superusuário e o dblink recusa a conexão; C23 passou a ser provada por `scripts/loans-concurrency-test.sh`, com duas sessões psql reais.
- **Walk findings:** 2026-11-06 - a primeira conferência visual encontrou que nenhum banco tinha modelo de termo: o `insert ... select from catalog.entities` morava na migration, que roda antes de `seed.sql` criar os bancos, então gravou zero linhas. O modelo passou para `seed.sql`, C29 ganhou a asserção "todo banco semeado começa com um modelo ativo", e as fixtures do seed deixaram de usar CPFs e UUIDs que os testes já usavam. Refazer C28, C34 e C35.
- **Pending walk:** a conferência visual do desenvolvedor cobre C9, C11, C26, C27, C28, C31 (falha do bucket), C34, C35, C36, C37, C42, C46, C50, C51, C52, C53 e C54. Nenhuma foi feita ainda; por isso a linha de Walked não existe e `check_proofs.py` marca essas provas como abertas.
