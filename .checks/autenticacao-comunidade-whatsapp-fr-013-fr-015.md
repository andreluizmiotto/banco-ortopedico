# Entrada da Comunidade e contato pelo WhatsApp

State: IMPLEMENTED. `npm run build` e `supabase test db` passaram; os procedimentos manuais M-C1–M-C13 e M-C15 continuam pendentes da verificacao visual/funcional do desenvolvedor.

Sources:

- `.tasks/autenticacao-comunidade-whatsapp-fr-013-fr-015.md` - intent, C1-C15, decisoes, limites e itens `Unresolved`
- `AGENTS.md` - paleta, linguagem publica, privacidade/RLS e estrategia Lean MVP
- `docs/produto/requisitos.md`, `docs/produto/regras-de-negocio.md`, `docs/produto/mensagens-padrao.md` - FR-005 a FR-016, deduplicacao e texto aprovado
- `docs/ux/acessibilidade-e-fluxos.md` - **fonte vinculante para a interface**: detalhe, entrada/cadastro, retorno e estados
- `docs/arquitetura/autenticacao-e-autorizacao.md`, `docs/arquitetura/modelo-conceitual.md`, `docs/arquitetura/visao-geral.md` - identidade, papeis, limites de confianca e RLS
- `docs/privacidade/requisitos-de-dados.md` - minimizacao, aceite, logs e retencao
- `src/app/_components/public-equipment.tsx`, `src/app/equipamentos/[code]/page.tsx`, `src/lib/public-supabase.ts`, `src/lib/availability.ts` - detalhe e agregado publico atuais
- `supabase/migrations/20261009000000_catalogo_publico_tipos.sql`, `supabase/migrations/20261013000000_disponibilidade_publica.sql`, `supabase/tests/disponibilidade-publica.test.sql`, `supabase/seed.sql`, `supabase/config.toml` - schema/RLS, fixtures sinteticas e Auth local
- `package.json`, `node_modules/next/dist/docs/01-app/02-guides/{authentication,forms,server-actions,data-security}.md`, `node_modules/@supabase/ssr/src/createServerClient.ts`, `node_modules/@supabase/auth-js/src/GoTrueClient.ts` - APIs instaladas e documentacao versionada

## Out of scope

- Recuperacao de senha, troca de telefone, cadastro assistido, painel/lista administrativa de contatos ou mudanca de situacao do contato.
- Envio/leitura automatica de WhatsApp, numeros reais, contas reais, destinatarios de producao ou outros dados pessoais em fixtures/evidencias.
- Automacao de navegador. Playwright, Cypress, Puppeteer e outros runners de navegador nao fazem parte da estrategia atual.
- Alteracao do contrato anonimo `equipment_availability`, da disponibilidade de acervo ou dos valores tecnicos de equipamento `disponivel`, `reservado`, `emprestado`, `manutencao`, `doado` e `baixado`.

## Landing

As rotas `/entrar` e `/equipamentos/[code]` reutilizam o layout publico existente; sessoes usam `@supabase/ssr` e Server Actions, e a autorizacao/operacao privada permanece no PostgreSQL. O schema `catalog` continua fora dos schemas expostos pela Data API; o agregado anonimo existente nao muda.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Localizar CPF sem inclui-lo no token | Perfil privado armazena o telefone que o servidor recebeu de Supabase Auth depois de confirmar OTP; `public.community_phone_for_cpf(text)` e executavel apenas por `service_role` e devolve somente esse telefone. CPF nao vai para `user_metadata`, URL ou JWT legivel pelo navegador. | Ler `auth.users` por uma role de funcao propria; o `postgres` local nao tem grant option no schema Auth gerenciado, entao nao e reproduzivel por migrations. Colocar CPF em metadata exporia PII. |
| Derivar o ator autenticado em funcoes/RLS privadas | `catalog.current_auth_uid()` e um wrapper sem parametros, `SECURITY DEFINER` e `search_path` fixo que retorna somente `auth.uid()`; funcoes privadas usam seu resultado em vez de receber `user_id` do cliente. | Dar `USAGE` em `auth` para roles de funcao, grant que o papel de migration do Supabase local nao pode conceder. |
| Manter a sessao fora do JavaScript do navegador | Cookie SSR `HttpOnly`, `SameSite=Lax`, `Path=/` e `Secure` em producao; componentes recebem somente o booleano de permissao, nunca `user`/telefone. | Cookie legivel por JavaScript ou props com objeto de usuario, que exporiam dados de Auth ao frontend. |
| Manter o bloqueio de entrada entre processos | `catalog.community_login_limits` persiste contador e bloqueio de 15 minutos por HMAC-SHA-256 da origem; nenhuma tabela armazena IP bruto. Proxy de deploy deve sobrescrever `X-Forwarded-For`; sem IP valido usa-se a origem `unknown`. | Estado em memoria, que reinicia e diverge entre instancias; IP bruto persistido, que e desnecessario para aplicar o limite. |
| Expor somente operacoes privadas estreitas | Tabelas privadas em `catalog`, RLS forcada e papeis de funcao `NOBYPASSRLS`; RPCs `public` autenticadas retornam somente papel/opcao/link permitido. Telefone de destino so sai dentro de URL autorizada `wa.me` ou `tel:`. | Expor todo o schema `catalog` ou retornar telefone como coluna/payload separado. |
| Resolver destinatario com configuracao confiavel | Configuracao privada por entidade e papel (`responsavel`/`substituto`), cruzada com papel ativo e modo substituto; nenhum telefone real em migration/seed. | Destinatario ou telefone escolhido pelo navegador, sem validacao por banco/papel. |
| Deduplicar pedidos concorrentes | Funcao transacional bloqueia `(auth.uid(), entidade, tipo)`, reutiliza contato dos 30 minutos anteriores e gera codigo no banco. | `SELECT`/`INSERT` sem lock, que permite duplicidade em requisicoes concorrentes. |
| Impedir uso de aviso nao aprovado | Aviso sintetico `local-synthetic-v1` so em desenvolvimento; em producao o cadastro exige `COMMUNITY_PRIVACY_NOTICE_APPROVED=true`, `COMMUNITY_PRIVACY_NOTICE_VERSION` e `COMMUNITY_PRIVACY_NOTICE_TEXT` server-side. A data de aceite e gravada pelo banco. | Hard-code de texto juridico nao aprovado ou cadastro real habilitado por padrao, contrariando `Unresolved 3`. |
| Receber telefone numerico sem perder E.164 | Campo numerico aceita digitos incluindo codigo do pais; servidor normaliza para `+` e 8-15 digitos para Supabase Auth. | Assumir somente `+55`, limitando telefones internacionais sem decisao de produto. |
| Limitar tamanho de nome armazenado | Perfil aceita nome aparado de 2-150 caracteres; o mesmo limite e validado no servidor e no banco. | Texto sem limite, que permite payloads arbitrariamente grandes sem valor para o cadastro. |

- Server Actions sao chamadas internas sem novo contrato HTTP publico/versionado; nenhum pacote novo e necessario.
- Nao ha outras decisoes de produto novas; os gates `Unresolved` da tarefa permanecem inalterados.

## Checks

As provas manuais abaixo sao procedimentos nomeados, nao automacao de navegador. Os unicos comandos automatizados seguem `AGENTS.md`: build e testes SQL de RLS.

### S1 - Entrada/cadastro e retorno ao detalhe · 4 arquivos existentes · 31,157 B · ~7.8k tokens de leitura

**C1 (criterio 1)** - Em `/equipamentos/CR`, verificar um cartao sintetico com quantidade positiva e outro com zero; ambos mostram `Entrar para conversar` e levam exatamente a `/entrar`. A resposta publica nao contem telefone, destinatario, `wa.me` ou `tel:`.
Prova: procedimento manual `M-C1` no detalhe usando somente o seed sintetico existente (`SYN-A`, `SYN-B`, `SYN-C`); conferir os dois estados e o `href`.

**C2 (criterio 2)** - A tela pergunta se a pessoa ja tem cadastro; entrada pede CPF, valida-o no servidor e depois pede senha. Com conta sintetica Comunidade confirmada, CPF pontuado e sem pontuacao autenticam via `phone/password`; a tela nao permite escolher papel.
Prova: procedimento manual `M-C2` em Supabase local; criar a conta sintetica por `M-C3`, entrar em sessao limpa com as duas formas de CPF e confirmar o retorno ao mesmo codigo.

**C3 (criterio 3)** - Criar perfil com nome, CPF sintetico valido, telefone E.164 confirmado por OTP local, senha de 8+ caracteres sem requisito artificial e aceite do aviso vigente. Perfil referencia `auth.users.id`, guarda telefone confirmado e CPF em 11 digitos com unicidade, papel `comunidade` e concedido pelo servidor, aceite guarda versao/data; mostrar/ocultar senha funciona e nao ha endereco residencial.
Prova: procedimento manual `M-C3` com OTP sintetico configurado apenas para Auth local; conferir o perfil/papel no banco local sem copiar PII para evidencia ou log.

**C4 (criterio 4)** - CPF com digito invalido e rejeitado antes da consulta; CPF valido sem perfil e senha incorreta exibem exatamente a mesma mensagem generica, sem ecoar CPF/telefone nem confirmar existencia.
Prova: procedimento manual `M-C4`; comparar literalmente as mensagens para CPF sintetico valido inexistente e conta sintetica com senha errada; enviar CPF invalido e confirmar a mensagem de validacao sem consulta de identidade.

**C5 (criterio 5)** - Cinco senhas invalidas da mesma origem criam bloqueio server-side; tentativa seguinte e recusada durante 15 minutos sem dados enviados na resposta.
Prova: procedimento manual `M-C5`; fazer cinco tentativas locais, inspecionar somente contador/hash/`locked_until` em `catalog.community_login_limits` e confirmar `locked_until` em `now() + 15 minutes` (tolerancia de 5 segundos); sexta tentativa recebe erro generico. Nao registrar IP, CPF ou senha.

**C6 (criterio 6)** - Entrada/cadastro iniciados em `/equipamentos/[code]` voltam ao mesmo detalhe; destino fornecido e sanitizado para apenas `/equipamentos/[code]`, URL nunca carrega CPF/telefone/nome e retorno invalido cai em `/`.
Prova: procedimento manual `M-C6`; testar sucesso nos dois fluxos, retorno externo/malformado e acesso direto sem origem; conferir URLs.

**C7 (criterio 7)** - Entrada/cadastro/OTP exibem carregamento perceptivel e desabilitam envio repetido; erro de codigo/rede/Auth e recuperavel, sem ativar sessao antes do OTP correto.
Prova: procedimento manual `M-C7`; submeter codigo sintetico incorreto e falha controlada, conferir texto/acao de nova tentativa e que a sessao so aparece depois da confirmacao.

### S2 - Contato autorizado, link, RLS e interface · 5 arquivos existentes · 19,134 B · ~4.8k tokens de leitura

**C8 (criterio 8)** - Comunidade ativa recebe `Conversar no WhatsApp` com disponibilidade zero/positiva quando ha WhatsApp autorizado; sem WhatsApp, recebe a alternativa `Ligar` quando autorizada; visitante e Companion nao recebem telefone nem URL direta.
Prova: procedimento manual `M-C8` com visitante, Companion sem papel comunidade e Comunidade sinteticos, nas duas quantidades; conferir tambem que a acao revalida permissao no servidor.

**C9 (criterio 9)** - Primeiro toque autorizado cria contato `novo`; repeticao da mesma pessoa/banco/tipo em 30 minutos retorna o mesmo codigo; destinatario e responsavel ativo ou substituto quando `substitute_mode` estiver ligado.
Prova: procedimento manual `M-C9`; usar configuracao de destinatario sintetica local e consultar `catalog.community_contacts` por `user_id`, entidade e tipo, sem exibir PII.

**C10 (criterio 10)** - Duas requisicoes simultaneas equivalentes deixam um contato e devolvem o mesmo codigo.
Prova: procedimento manual `M-C10` com dois acionamentos simultaneos em sessoes sinteticas; conferir exatamente uma linha e um codigo no banco local. Nao criar script de navegador.

**C11 (criterio 11)** - URL `wa.me` abre a mensagem editavel `Ola. Quero conversar sobre um emprestimo de equipamento. Codigo do contato: {codigo}.`, substituindo somente `{codigo}`; nao ha envio automatico nem CPF, telefone, nome, endereco ou dado de saude no texto.
Prova: procedimento manual `M-C11`; abrir sem enviar, decodificar `text` e comparar literalmente; verificar que telefone existe apenas dentro do proprio URL externo autorizado.

**C12 (criterio 12)** - Sem WhatsApp mas com telefone autorizado, apresenta `Ligar` com `tel:`; sem telefone autorizado, nenhum numero/link e exposto e a tela explica indisponibilidade; nao tenta detectar aplicativo.
Prova: procedimento manual `M-C12` com as tres configuracoes sinteticas (WhatsApp, somente ligacao, nenhum destino); confirmar link/ausencia de link em cada uma.

**C13 (criterio 13)** - Durante o pedido ha carregamento e prevencao de clique duplicado; falha mostra nova tentativa sem link a nao autorizado; retry reutiliza contato; PII e objetos brutos de erro do Auth nao vao para mensagens nem logs.
Prova: procedimento manual `M-C13`; provocar falha local, repetir, conferir uma linha de contato e inspecionar mensagem/logs sem registrar dados pessoais.

**C14 (criterio 14)** - `anon` e Companion sem Comunidade nao leem perfil/contato/destino nem iniciam contato; Comunidade so opera com `auth.uid()` e papeis ativos, destinatario fica no banco/tipo resolvido e quatro entidades sinteticas nao cruzam destino. O agregado anonimo continua com nome publico e quantidade apenas.
Prova automatizada: `supabase test db` deve passar as assertions C14 em `supabase/tests/autenticacao-comunidade.test.sql` e `supabase/tests/contatos-comunidade.test.sql`; fixture transacional sintetica e rollback.

**C15 (criterio 15)** - Em `/entrar` e no detalhe: largura 360 px sem rolagem horizontal; texto corrido >=18 px, titulos >=26 px e contraste >=4.5:1; botoes >=56 px com texto negrito >=20 px; foco visivel, voltar previsivel, teclados numericos, uma acao principal e cores oficiais; significado nao depende apenas de cor/icone.
Prova: verificacao visual manual do desenvolvedor em viewport 360 px; nao automatizar medidas de navegador.

## Automated checks

Executar somente os comandos permitidos pela estrategia Lean MVP:

- [x] `npm run build` - exit code 0; compilacao TypeScript/Next.js.
- [x] `supabase test db` - exit code 0; 4 arquivos, 135 assertions pgTAP, incluindo C14 em `autenticacao-comunidade.test.sql` e `contatos-comunidade.test.sql`. O CLI foi executado via `npx` por nao existir binario local no PATH.
- [ ] Procedimentos manuais M-C1–M-C13 e M-C15 - pendentes; exigem navegador/fixtures sinteticos e revisao visual pelo desenvolvedor, sem automacao.

Nenhum teste unitario de navegador, Playwright, Cypress, Puppeteer ou runner adicional sera instalado/criado. Auth, concorrencia de interface e acessibilidade permanecem procedimentos manuais sinteticos.

## Go-live gates

- [ ] Provedor SMS, credenciais e limites finais de codigo escolhidos e configurados no Supabase.
- [ ] Responsaveis/substitutos ativos e telefones reais de WhatsApp/ligacao configurados fora do Git por entidade.
- [ ] `SUPABASE_SERVICE_ROLE_KEY` configurada somente no servidor; proxy de producao sobrescreve cabecalho de origem confiavel.
- [ ] Texto/versionamento do aviso de privacidade aprovado juridicamente e configurado por ambiente, com `COMMUNITY_PRIVACY_NOTICE_APPROVED=true` somente apos a aprovacao.
- [ ] Prazo de retencao de contatos sem emprestimo aprovado; 12 meses e somente proposta atual.
- [ ] Tarefa de contatos administrativos (FR-017/AC-007) disponivel para localizar o codigo e acompanhar o atendimento.

## Swept

- validation: C2, C3, C4 e C9 - CPF/telefone/papel/entidade sao validados no servidor ou banco.
- failure modes: C4, C5, C7 e C13 - erros genericos, bloqueio persistente, retry e falha externa.
- idempotency and retry: C9, C10 e C13 - janela de 30 minutos, lock de transacao e retry apos falha.
- authorization: C8 e C14 - renderizacao e Server Action verificam sessao/papel; RLS/RPC negam anon e Companion.
- concurrency and ordering: C10 usa advisory lock por pessoa/entidade/tipo; ordenacao n/a - nao ha fila.
- data lifecycle: `Unresolved 4` mantido; perfil guarda versao/data do aceite; limiter guarda HMAC de origem (sem IP bruto), contato guarda codigo sem telefone; nenhuma retencao juridica de contato e automatizada.
- external-dependency failure: C7, C12 e C13 - Supabase Auth/SMS e link externo sem envio automatico.
- state transitions: C3, C5, C9 e C10 - telefone pendente/confirmado, bloqueio e contato `novo` criado/reutilizado.
- observability: C4, C11, C13 e C14 - sem CPF/telefone/nome ou erro bruto nos logs/mensagens; telefone autorizado somente em URL externa.

## Handoff

- Perfil `light` (nenhum perfil TLC declarado); `handoff: on` por padrao. S1 consulta 4 arquivos existentes = 31,157 B / 4 = ~7.8k tokens de leitura; S2 consulta 5 arquivos existentes = 19,134 B / 4 = ~4.8k tokens. O piso combinado de codigo existente e ~12.6k tokens; novas migrations, testes e implementacao estimados abaixo do limite de 150k, portanto S1+S2 permanecem numa unica batch sem cortar fatia.
- A fronteira natural continua entre S1 (entrada/perfil/RLS) e S2 (contato/link); ela nao exige handoff porque o conjunto cabe em uma batch.
- Reprovar qualquer dado real em migration, seed, log, captura ou prova; aviso, telefones, entidades e contas de validacao permanecem sinteticos.
