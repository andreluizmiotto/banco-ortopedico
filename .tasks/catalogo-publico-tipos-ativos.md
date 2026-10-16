# Catalogo publico de tipos ativos

> Construa isto com **tlc-implement**.
> Cada criterio abaixo vira uma verificacao com evidencia referenciada pelo numero. Nada em
> `Unresolved` deve ser decidido durante a implementacao.

## Intent

O requisito aprovado permite que qualquer pessoa consulte tipos de equipamento ativos sem cadastro (FR-001). Hoje, porem, o repositorio nao tem migrations, seed ou testes do Supabase, e `src/app/page.tsx` ainda e a pagina inicial de scaffold. Nao ha uma lista de tipos que o visitante consiga consultar neste projeto; os documentos nao quantificam o impacto atual.

Este incremento entrega uma leitura anonima e somente de leitura do catalogo global de tipos ativos pela Data API do Supabase. A documentacao nao declara este requisito como prioridade temporal; ele foi escolhido por ser o menor resultado observavel que nao depende de modelar o acervo. O resultado e a lista aprovada de tipos, sem disponibilidade por banco; nao conclui FR-002, FR-003 nem AC-001.

4 criterios em 1 recorte; 1 porta unidirecional; 1 pendencia aberta, 0 que bloqueiam este recorte.

## Criteria

### Consulta publica de tipos ativos

1. Dado um banco local reconstruido com as migrations e o seed configurado, quando uma requisicao sem sessao consulta o catalogo pela Data API do Supabase, entao recebe exatamente este conjunto de 13 tipos ativos: `Cadeira de rodas`, `Cama hospitalar`, `Cadeira de banho`, `Andador`, `Muletas`, `Colchao para cama hospitalar`, `Cadeira infantil ou adaptada`, `Bota ortopedica`, `Tipoia de braco`, `Suporte para soro`, `Assento sanitario elevado`, `Banheira ou apoio para banho` e `Outros`. `Peruca` (`PE`) permanece desativada na referencia e nao aparece na resposta.
2. Quando a consulta retorna a lista, os cinco tipos prioritarios aparecem primeiro e nesta ordem: `Cadeira de rodas`, `Cama hospitalar`, `Cadeira de banho`, `Andador`, `Muletas`. Os demais tipos seguem a ordem configurada; sua permutacao inicial nao e fixada pelo produto.
3. Sempre, RLS no banco limita a leitura aos tipos ativos para `anon` e `authenticated`, e privilegios explicitos permitem somente `SELECT` para esses papeis. Chamadas diretas pela Data API, sem filtro de interface, recebem somente dados publicos do catalogo, sem inventario por entidade, dados pessoais ou linhas de emprestimo; qualquer recurso exposto preserva a protecao RLS mesmo se a implementacao usar uma view.
4. Quando `anon` ou `authenticated` tenta criar, alterar ou remover um tipo pela Data API, a operacao e recusada e o catalogo permanece inalterado.

## Out of scope

- Disponibilidade agregada, cartoes por banco, detalhe de tipo e situacao de estoque (FR-002, FR-003 e AC-001 completo) - dependem de uma decisao explicita sobre a representacao fisica do acervo.
- Cadastro das quatro entidades iniciais (Boa Vista, Tres Vendas, Casa da Amizade e Erechim), dos tres pontos de atendimento, ou de entidades futuras - o catalogo deste recorte e global e nao impoe limite de quatro entidades.
- Prova completa de isolamento RLS entre as quatro entidades ou de autorizacao do Companheiro para dados operacionais - nao ha linhas por entidade, PII ou emprestimos neste recorte, portanto ele nao declara NFR-003, NFR-004 ou AC-017 cumpridos para os demais recursos.
- Equipamento ou lote, quantidade, unidade individual, dono, ponto de atendimento atual (`catalog.pontos_atendimento`), movimentacao, minimo de estoque e qualquer relacao entre essas informacoes - o dono do equipamento e seu ponto atual de guarda continuam conceitos distintos.
- Busca textual (FR-004), fotos, descricoes curtas, tela publica ou integracao da pagina Next.js com o Supabase - a pagina atual permanece inalterada.
- Cadastro de perfil, CPF, autenticacao, papeis de operacao, emprestimos ou dados de pessoas. Nenhuma senha ou hash de senha e armazenado em perfil.
- Painel do Companheiro, dados por banco, consulta cruzada de emprestimos ou linhas individuais de emprestimo. O Companheiro continua restrito a dados publicos ou agregados, sem PII.
- Retencao, anonimizacao ou exclusao automatica. Os prazos propostos aguardam aprovacao juridica; este recorte nao coleta dados pessoais.
- CRUD administrativo dos tipos, novas dependencias, ADR, alteracao de configuracao ou mudancas em documentos de produto.

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen publica | estados vazio, carregamento, erro e sem permissao | n/a - nenhuma tela e alterada; a pagina Next.js permanece scaffold |
| API Supabase Data API | resultado da leitura anonima | 1 |
| API Supabase Data API | ordenacao do conjunto | 2 |
| API Supabase Data API | quem pode ler | 3 |
| API Supabase Data API | quem pode escrever | 4 |
| API Supabase Data API | formato/codigos de erro | existing - erros nativos da Data API; nao ha rota ou transformacao de erro propria neste recorte |
| API Supabase Data API | versionamento | n/a - nao e criada uma rota versionada da aplicacao |
| API Supabase Data API | limite de requisicoes | n/a - nao ha limite especifico no requisito de catalogo e este recorte nao cria limitador proprio |
| comando ou tarefa agendada | output, opcoes, codigos de saida e falha parcial | n/a - nenhum comando ou tarefa agendada e criado |
| documento ou texto de interface | estrutura, tom e proximo passo | n/a - nenhum documento ou texto de interface e alterado |
| colecao do catalogo | agrupamento, nomes, excecao e duplicidade | 1 |
| colecao do catalogo | ordem inicial prioritaria | 2 |

## Swept

- validation: 1 - a resposta contem exatamente os 13 tipos ativos aprovados e omite a referencia inativa `PE`.
- failure modes: n/a - nao ha cliente, tela ou tratador de erro proprio neste incremento; erros permanecem sob o contrato nativo da Data API.
- idempotency and retry: n/a - a operacao exposta e somente leitura; nao ha escrita de negocio nem logica de repeticao.
- authorization: 3, 4 - a permissao e aplicada no PostgreSQL por RLS e privilegios minimos, nao por filtro de interface.
- concurrency and ordering: concorrencia n/a - nao ha escrita concorrente; ordenacao 2 - cinco prioridades definidas e demais conforme ordem configurada.
- data lifecycle: 1 - `PE` permanece desativada e fora da leitura publica; nao ha dado pessoal ou historico de emprestimo neste recorte.
- external-dependency failure: n/a - nenhum cliente ou fallback e construido; esta tarefa verifica a propria Data API e nao define comportamento offline.
- state transitions: n/a - nao ha fluxo administrativo de ativacao/desativacao; os estados iniciais sao dados de referencia.
- observability: n/a - nao ha requisito de telemetria para esta leitura; nao adicionar analytics ou logs com dados pessoais. A evidencia fica nos testes do banco/API.

## Impact

| Front | What changes |
|---|---|
| domain | novo termo: catalogo global de tipos de equipamento - conceitos aprovados que podem ser consultados sem cadastro; nao representa estoque fisico |
| stored data | primeira migration e dados de referencia com os nomes aprovados no produto; identificadores e fixtures adicionais devem ser sinteticos. Nenhum inventario real, PII ou dado existente e migrado |
| Supabase Data API | nova leitura publica somente de tipos ativos; nao ha consumidor Supabase na aplicacao atual |
| application | `src/app/page.tsx` permanece scaffold e nao e alterada. `AGENTS.md` cita `@supabase/ssr`, ausente das dependencias de `package.json`; este recorte nao resolve essa divergencia de estado |
| seed e testes | `supabase/config.toml` habilita migrations/seeds e aponta para `supabase/seed.sql`, mas o arquivo nao existe. Nao ha migrations, seeds, testes Supabase ou script de teste existentes; esta tarefa precisa fornecer evidencia no fluxo Supabase sem alterar a configuracao existente |

## Decided

| Decision | Shape | Alternative rejected |
|---|---|---|
| A leitura publica deste primeiro recorte usa a Data API Supabase ja configurada, com a autorizacao no banco. | Recurso de leitura sem sessao, apenas para dados publicos de tipos ativos; `anon` e `authenticated` leem, nao escrevem. RLS e privilegios do PostgreSQL sao verificados diretamente pela API. O nome fisico do recurso e os nomes de campos nao sao aprovados neste plano. | Filtrar tipos inativos apenas na interface ou atender a leitura com acesso privilegiado do servidor foi rejeitado para este recorte: nao protege a fronteira direta da API como exige NFR-003 e acrescentaria uma camada sem consumidor existente. |

## Relations

O tipo de equipamento e um conceito global distinto da unidade fisica ou da contagem de inventario. Este recorte nao cria relacionamento armazenado com entidade, ponto de atendimento (`catalog.pontos_atendimento`), equipamento/lote, pessoa ou emprestimo. Quando equipamento for modelado, propriedade e ponto atual de guarda devem continuar distintos; nenhuma relacao ou cardinalidade fisica e decidida aqui.

## Surface

| Route | In | Out | Status | Criteria |
|---|---|---|---|---|
| Supabase Data API: `GET` do recurso publico do catalogo de tipos (o identificador fisico e escolhido na implementacao e nao e fixado aqui) | requisicao sem sessao, no papel `anon` | tipos ativos segundo 1 e 2; sem disponibilidade por entidade, PII ou emprestimos | resposta nativa da Data API; a recusa de escrita e verificada em 4; sem contrato proprio de codigos de erro | 1, 2, 3, 4 |

## Sources

- [Indice da documentacao](../docs/README.md) - define a documentacao de produto como fonte de requisitos e migrations/testes como implementacao executavel.
- [Requisitos do Produto](../docs/produto/requisitos.md) - FR-001 a FR-003, FR-040, NFR-003 e NFR-004; FR-001 e o unico resultado funcional deste recorte.
- [Regras de Negocio](../docs/produto/regras-de-negocio.md) - tipos iniciais, `PE` desativada, prioridade inicial e suporte requerido a contagem e inventario individual.
- [Criterios de Aceite](../docs/produto/criterios-de-aceite.md) - AC-001 e evidencia com dados sinteticos; este recorte nao declara AC-001 completo.
- [Modelo Conceitual](../docs/arquitetura/modelo-conceitual.md) - tipo global, entidade/ponto de atendimento e desenho fisico de contagem/unidade ainda em aberto.
- [Autenticacao e Autorizacao](../docs/arquitetura/autenticacao-e-autorizacao.md) - matriz publica e regras RLS; estrategia CPF/Supabase Auth ainda pendente e fora deste recorte.
- [Visao Geral da Arquitetura](../docs/arquitetura/visao-geral.md) e [ADR-0001](../docs/arquitetura/decisoes/0001-nextjs-supabase.md) - Supabase/PostgreSQL, RLS e limites de confianca.
- [Requisitos de Dados e Privacidade](../docs/privacidade/requisitos-de-dados.md) - classificacao publica, restricoes do Companheiro e aprovacao juridica antes de automatizar retencao.
- [`supabase/config.toml`](../supabase/config.toml) - `public` esta entre os schemas expostos; migrations/seeds estao habilitados e o caminho configurado para seed nao existe no estado atual.
- [`AGENTS.md`](../AGENTS.md), [`package.json`](../package.json) e [`src/app/page.tsx`](../src/app/page.tsx) - instrucoes da stack, dependencias e estado do scaffold; nao ha integracao ou consumidor atual.
- [Supabase: Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security) - grants e politicas RLS sao controles combinados; testes de banco podem usar `supabase test db`.
- [Supabase: Securing your API](https://supabase.com/docs/guides/api/securing-your-api) - objetos expostos pela Data API precisam de privilegios explicitos e RLS; nao depender de filtro no cliente.

## Unresolved

> Esta tabela registra o estado da tarefa quando o recorte foi planejado. A resolucao posterior abaixo preserva o historico do recorte e nao altera seus criterios nem suas evidencias.

| # | Kind | Question | Until answered |
|---|---|---|---|
| 1 | open | Antes de incluir disponibilidade por banco em FR-002/FR-003, qual desenho fisico suporta as duas fases sem descartar contagem ou historico: representacoes separadas com transicao explicita, ou uma representacao que suporte contagem e unidades individuais? | Recomendacao: resolver e revisar a decisao de modelagem antes da tarefa de disponibilidade. Este recorte continua limitado a tipos globais; nenhum registro de estoque, unidade, propriedade/ponto de atendimento ou emprestimo pode ser criado para contornar a pendencia. |

## Resolucao posterior da modelagem

Depois da conclusao deste recorte, a representacao foi decidida: o acervo operacional tem uma linha por unidade fisica desde a Fase 1; um saldo inicial N cria N unidades sem codigo visivel, e a Fase 2 atribui codigos as mesmas unidades apos conferencia fisica. A disponibilidade por tipo, entidade proprietaria e situacao e derivada da contagem de unidades disponiveis, sem saldo agregado editavel. Emprestimos permanecem separados e cada linha referencia uma unidade.

Esta resolucao desbloqueia o planejamento de FR-002/FR-003, mas nao altera o resultado nem declara completos os criterios deste recorte. A regra para divergencias entre o saldo N e a quantidade fisica encontrada, inclusive unidades em emprestimos abertos, continua em aberto. Detalhes vigentes estao em [Regras de Negocio](../docs/produto/regras-de-negocio.md) e [Modelo Conceitual](../docs/arquitetura/modelo-conceitual.md).
