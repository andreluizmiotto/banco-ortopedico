# Disponibilidade publica e cartoes por banco

State: BUILT. C1-C10 executados localmente; verificacao independente pendente.

Sources:

- `.tasks/disponibilidade-publica-fr-002-fr-003.md` - intent, C1-C10, limites, gate de producao e unresolved
- `docs/produto/requisitos.md` - FR-002/003, FR-013/015 e NFR-002 a NFR-004
- `docs/produto/regras-de-negocio.md` - propriedade versus guarda, situacoes e disponibilidade derivada
- `docs/produto/criterios-de-aceite.md` - AC-001/002/018/027 e evidencia sintetica
- `docs/ux/acessibilidade-e-fluxos.md` - **fonte vinculante para o fluxo** da lista/detalhe, CTA e estados remotos (secoes 3.2-3.9); a tela inicial da secao 3.1 foi explicitamente adiada nesta task pela clarificacao abaixo
- `docs/arquitetura/autenticacao-e-autorizacao.md` - papeis, RLS e limite de confianca; autenticacao permanece fora
- `docs/privacidade/requisitos-de-dados.md` - minimizacao, classificacao e proibicao de PII em fixtures/logs
- `docs/arquitetura/modelo-conceitual.md` - unidade individual, entidade proprietaria, ponto de guarda e linha de emprestimo
- `.tasks/catalogo-publico-tipos-ativos.md` e `.checks/catalogo-publico-tipos-ativos.verified.md` - recurso publico de tipos ativo e evidencia anterior
- `supabase/migrations/20261009000000_catalogo_publico_tipos.sql`, `supabase/seed.sql` e `supabase/tests/catalogo-publico.test.sql` - schema, fixtures e harness Supabase existente
- `scripts/test-public-catalog-api.mjs` - padrao do teste anonimo direto da Data API
- `supabase/config.toml`, `package.json` e `src/app/page.tsx` - schemas expostos, comandos existentes e scaffold publico
- `AGENTS.md` - regras de Next local, paleta Rotary, linguagem, acessibilidade e isolamento
- `node_modules/next/dist/docs/01-app/03-api-reference/01-directives/use-client.md`, `node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/page.md`, `node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/dynamic-routes.md`, `node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/loading.md`, `node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/error.md`, `node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/layout.md`, `node_modules/next/dist/docs/01-app/03-api-reference/01-directives/use-cache.md` e `node_modules/next/dist/docs/01-app/03-api-reference/05-config/01-next-config-js/cacheComponents.md` - convencoes da versao local Next 16.4
- `node_modules/next/dist/docs/01-app/02-guides/environment-variables.md` e `node_modules/next/dist/docs/01-app/01-getting-started/05-server-and-client-components.md` - fronteira de ambiente e componentes
- `node_modules/@supabase/ssr/README.md` - cliente sem sessao; para este recorte anonimo, `supabase-js` sem persistencia de sessao evita introduzir autenticacao
- https://playwright.dev/docs/test-cli e https://playwright.dev/docs/test-webserver - filtro `--grep`, servidor local e ambiente sintetico do runner autorizado nesta conversa
- Conversa desta tarefa - enum DB `disponivel/reservado/emprestado/manutencao/doado/baixado`, tabela `pontos_atendimento`, textos de UI, CTA `/entrar`, apenas fixtures sinteticas e runner local autorizado

## Out of scope

- Carga real da Fase 1, conferencia/etiquetagem da Fase 2 e conciliacao de divergencias.
- Autenticacao por CPF, cadastro e contato direto por `wa.me`; pertencem ao recorte seguinte. O CTA atual apenas aponta para `/entrar`.
- Alteracoes em tipos ativos, descricoes, fotos, movimentacoes, emprestimos ou dados pessoais.
- Dados reais de inventario, pessoa, telefone, endereco ou contato em fixtures e evidencias.
- Criar a rota/tela `/entrar`, expor qualquer recurso operacional ou criar saldos agregados editaveis.
- Tela inicial separada com objetivo do servico, acoes de cadastro/entrada e acessos a FAQ/privacidade descrita em `docs/ux/acessibilidade-e-fluxos.md:30`; a entrada deste recorte e a lista publica em `/`.

## User Clarification

- Apos o G1 do Verifier independente na rodada 1, o usuario confirmou manter C1-C10 e adiar a tela inicial, FAQ e privacidade do fluxo mais amplo. A secao 3.1 de `docs/ux/acessibilidade-e-fluxos.md` nao define o limite desta task; o fluxo de lista/detalhe das secoes 3.2-3.9 continua vinculante. Autenticacao/cadastro continuam fora, e `/entrar` segue apenas como destino do CTA C7. Nenhum criterio C1-C10 foi alterado.

## Landing

Uma fatia vertical: modelo privado de unidades, agregado autorizado no PostgreSQL, lista e detalhe publicos. Reutiliza `public.equipment_types`; a interface consome somente o agregado e nao recebe linhas operacionais.

| One-way door | Literal shape | Alternative rejected |
|---|---|---|
| Fonte tecnica do saldo | `catalog.equipment_units` guarda unidades individuais; `catalog.pontos_atendimento` guarda local atual; `catalog.equipment_situation` tem `disponivel`, `reservado`, `emprestado`, `manutencao`, `doado`, `baixado`; `em_casa` -> `disponivel`, `separado` -> `reservado`, `em_conserto` -> `manutencao`, `doado_definitivo` -> `doado`; disponibilidade conta somente `disponivel` por tipo e proprietario | Saldo editavel/agrupado por local, ou persistir nomes antigos no enum |
| Contrato anonimo | `public.equipment_availability(p_equipment_type_code text)` retorna exatamente `(bank_name text, available_quantity integer)`; funcao `SECURITY DEFINER` pertence a `availability_reader` sem login, `search_path` vazio e RLS forcada nas tabelas lidas | Dar SELECT anonimo nas unidades ou usar credencial privilegiada na aplicacao |
| Cartao e ordem | Preservar cada banco com zero e texto `Todos emprestados no momento`; embaralhar positivos por consulta e anexar zeros depois | Omitir indisponiveis ou manter ordem fixa entre bancos positivos |
| Acao do visitante | Todos os cartoes usam `Entrar para conversar` com `href="/entrar"`; nenhum telefone/destino/`wa.me`; a rota nao e criada | Contato direto antes da autenticacao ou esconder a acao sem saldo |
| Prova da interface | `@playwright/test` com servidor Next local, respostas Supabase interceptadas e fixtures sinteticas; provas filtradas por C1-C10 | Inspecao somente de fonte/build, incapaz de medir viewport, interacao e estados remotos |

- Nada mais neste recorte e uma porta unidirecional.

## Checks

### S1 - Consulta publica de disponibilidade por tipo e cartoes - 17 arquivos estimados - ~374 KB - ~94k tokens

**C1** - Com fixtures de um tipo, a entidade sintetica A tem 3 unidades `disponivel` e uma em cada valor nao disponivel (`reservado`, `emprestado`, `manutencao`, `doado`, `baixado`); B tem 2 `disponivel`. O agregado retorna A=3 e B=2, contando `situacao = 'disponivel'` e sem saldo editavel. Isso corresponde a `em_casa` no requisito de produto.
Proof: `npm exec --yes --package=supabase@2.120.0 -- supabase test db supabase/tests/disponibilidade-publica.test.sql --local` - asserts nomeados C1 com enum exato e resultado 3/2.

**C2** - Alterar somente `storage_location_id` de uma unidade de A para o ponto compartilhado usado por B mantem A e B com as mesmas quantidades agregadas.
Proof: `npm exec --yes --package=supabase@2.120.0 -- supabase test db supabase/tests/disponibilidade-publica.test.sql --local` - asserts C2 antes/depois do update, ordenados pelo nome publico.

**C3** - Uma chamada anonima direta `POST /rest/v1/rpc/equipment_availability` com `p_equipment_type_code=CR` retorna, por resultado, exatamente `bank_name` e `available_quantity` inteiro; nao retorna codigo do tipo, unidade, situacao ou contato.
Proof: `npm exec --yes --package=supabase@2.120.0 -- node scripts/test-public-availability-api.mjs --check=C3` - assert do conjunto exato de chaves, tipos e agregados sinteticos A=3, B=2, C=0.

**C4** - `anon` e um token local `authenticated` sintetico nao leem linhas de `catalog.equipment_units`, `catalog.entities` ou `catalog.pontos_atendimento`; a Data API tambem nao expoe unidades, movimentacoes, emprestimos, linhas ou perfis/dados pessoais. A funcao publica continua executavel e limitada ao agregado.
Proof: `npm exec --yes --package=supabase@2.120.0 -- supabase test db supabase/tests/disponibilidade-publica.test.sql --local` - asserts C4 de RLS/`FORCE ROW LEVEL SECURITY`, grants e privilegios.
Proof: `npm exec --yes --package=supabase@2.120.0 -- node scripts/test-public-availability-api.mjs --check=C4` - chamadas diretas anon/autenticada aos schemas/recursos operacionais e asserts de nenhuma resposta 2xx ou registro.

**C5** - No detalhe, banco com uma unidade sintetica somente em situacao indisponivel continua visivel com quantidade 0 e texto exato `Todos emprestados no momento`.
Proof: `npm run test:e2e -- tests/disponibilidade-publica.spec.ts --grep "C5"` - teste Playwright `C5` com resposta RPC sintetica interceptada.

**C6** - Com A=3, B=2 e C=0, duas permutacoes controladas distintas produzem B,A,C e A,B,C; em ambas todos os positivos precedem C.
Proof: `npm run test:e2e -- tests/disponibilidade-publica.spec.ts --grep "C6"` - teste Playwright `C6` injeta valores deterministas na funcao de ordenacao usada pela interface.

**C7** - Cartao zero mostra `Entrar para conversar` com `href="/entrar"`; nao cria `/entrar`, nao contem `wa.me`, telefone ou destino de contato.
Proof: `npm run test:e2e -- tests/disponibilidade-publica.spec.ts --grep "C7"` - teste Playwright `C7` inspeciona DOM/hrefs; C3 valida que a resposta anonima nao tem campos de contato.

**C8** - Lista e detalhe em viewport 360x800 nao excedem 360 px de largura; texto corrido >=18 px; titulo >=26 px; CTA >=56 px e texto em negrito >=20 px; variaveis CSS correspondem a paleta oficial; quantidade positiva mostra exatamente `Disponível no depósito` e disponibilidade e sempre textual.
Proof: `npm run test:e2e -- tests/disponibilidade-publica.spec.ts --grep "C8"` - teste Playwright `C8` mede dimensoes, estilos computados, tokens e textos nas duas rotas.

**C9** - Enquanto o RPC fica sem resposta, lista e detalhe mostram `role="status"` com indicador e texto `Carregando a disponibilidade...`.
Proof: `npm run test:e2e -- tests/disponibilidade-publica.spec.ts --grep "C9"` - teste Playwright `C9` segura a requisicao interceptada nas duas rotas e verifica o estado pendente.

**C10** - RPC com HTTP 503 mostra `Não foi possível carregar a disponibilidade. Tente novamente.` e acao `Tentar novamente`; a segunda chamada sintetica carrega os dados; a falha nunca e convertida em zero.
Proof: `npm run test:e2e -- tests/disponibilidade-publica.spec.ts --grep "C10"` - teste Playwright `C10` falha e depois libera o RPC em lista e detalhe.

## Go-live gate

- [ ] Carga autorizada dos saldos reais da Fase 1 como unidades individuais concluida fora deste recorte. A regra de divergencia N versus quantidade fisica, inclusive emprestimos abertos, permanece pendente e nao pode ser inferida por estes checks.

## Swept

- validation: C1 prova os seis valores enum e conta somente `disponivel`; C2 prova propriedade independente do local atual.
- failure modes: C10 converte HTTP 503 em mensagem recuperavel, nunca em quantidade zero.
- idempotency and retry: leituras nao escrevem; C10 reexecuta o RPC sem criar registros.
- authorization: C3/C4 provam contrato minimo, RLS e negacao de recursos operacionais; C7 fixa o CTA sem contato direto.
- concurrency: n/a - nao ha escrita concorrente neste recorte.
- ordering: C6 controla duas permutacoes do grupo positivo e mantem todos os zeros no final.
- data lifecycle: fixtures exclusivamente sinteticas; nenhuma carga Fase 1/2; gate de producao continua aberto.
- external-dependency failure: C9/C10 simulam RPC pendente e HTTP 503 com recuperacao.
- state transitions: n/a - a consulta nao altera `situacao`.
- observability: testes imprimem somente identificadores de criterio; nao registrar PII, telefone ou payload operacional.

## Handoff

- Perfil: `light` (padrao; `AGENTS.md` nao declara perfil TLC); handoff: `on` (padrao da skill).
- S1 e a unica fatia vertical. Estimativa antes do codigo: 258.900 bytes dos arquivos existentes do recorte (`wc -c`, incluindo o lockfile) + ~115 KB para migration, testes, interface, runner e delta de dependencias = ~374 KB / 4 = ~94k tokens; abaixo do teto 150k, sem divisao.
- Manter C1-C10 juntos: banco, Data API, lista, detalhe, estados remotos e limite de privacidade.
- Antes dos checks C1-C4, reconstruir somente o Supabase local: `npm exec --yes --package=supabase@2.120.0 -- supabase db reset --local`.
- Playwright local autorizado nesta conversa; `playwright.config.ts` inicia `npm run dev` com URL/chave anonimas sinteticas e interceptacoes, sem acessar projeto remoto.
- Os comandos e asserts acima definem o bar antes do codigo; nao reduzir criterio para acomodar implementacao.
- O gate de producao nao substitui os checks funcionais e nao autoriza fechar a regra operacional de divergencias.
