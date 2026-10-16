# Verificação independente — Entrada da Comunidade e contato pelo WhatsApp

**Veredito: FAIL — verificação incompleta.** Comprovados: **1/15** (C14); manuais pendentes: **14/15** (C1–C13 e C15). Os dois comandos automatizados passaram; nenhuma falha automatizada foi observada.

**Perfil:** `light` (padrão; nenhum perfil declarado em `AGENTS.md`)
**Diff range:** `7f9389a90de0b79352f949d0a653d5080a4660ac..43812d9f7024c2bdf01519282a787ade4d4b9bd0`
**Round:** `1 — full`
**Autor do feature commit:** Andre Luiz Miotto (`43812d9`)
**Verifier:** subagente independente; autor ≠ verifier
**Handoff:** `on`; S1 e S2 foram revisadas juntas, como uma única batch (`.checks/autenticacao-comunidade-whatsapp-fr-013-fr-015.md:128-132`).

## Fontes lidas

| Fonte | Leitura | Escopo nesta verificação |
|---|---|---|
| `AGENTS.md` | Completa | Estratégia automatizada limitada a build e testes RLS; revisão de tela é manual (`:29-35`). |
| `.tasks/autenticacao-comunidade-whatsapp-fr-013-fr-015.md` | Completa | C1–C15, limites e `Unresolved 1–6` lidos (`:17-38`, `:164-173`). |
| `.checks/autenticacao-comunidade-whatsapp-fr-013-fr-015.md` | Completa | Provas M-C1–M-C15, comandos e Handoff lidos (`:44-132`). |
| `docs/ux/acessibilidade-e-fluxos.md` | Completa | Fonte vinculante da interface. A comparação própria do profile `ui` não se aplica ao profile `light`. |
| `docs/produto/requisitos.md` | Completa | FR-005–FR-016, limites de privacidade e autorização lidos. |
| `docs/produto/regras-de-negocio.md` | Completa | Seção 6: destinatário, deduplicação e mensagem lidos. |
| `docs/produto/mensagens-padrao.md` | Completa | Texto aprovado e campo `{codigo}` lidos. |
| `docs/arquitetura/autenticacao-e-autorizacao.md` | Completa | Papéis, RLS e limites de acesso lidos. |
| `docs/privacidade/requisitos-de-dados.md` | Completa | Minimização, aviso, logs e retenção lidos. |
| `.opencode/skills/tlc-implement/references/verify.md` | Completa | Procedimento independente de verificação seguido. |

## Provas executadas em `HEAD`

| Comando | Exit code | Resultado |
|---|---:|---|
| `npm run build` | 0 | Build Next.js concluído; compilação e TypeScript passaram. |
| `npx --yes supabase@latest test db` | 0 | `Files=4, Tests=135`; `All tests successful`, `Result: PASS`. Os arquivos `autenticacao-comunidade.test.sql` e `contatos-comunidade.test.sql` apareceram como `ok`. |

O comando Supabase conectou ao banco local e executou os testes transacionais existentes. Não foi executado `db reset`, não foram reiniciados containers e nenhum outro comando de teste foi usado.

## Checks C1–C15

| Check | Resultado | Prova/evidência |
|---|---|---|
| C1 | **NOT RUN — verificação manual exigida pelo `AGENTS.md`** | M-C1 em `.checks/...md:50-51`; não observado manualmente. `AGENTS.md:31-35` proíbe inferir conformidade visual por automação/build. |
| C2 | **NOT RUN — verificação manual exigida pelo `AGENTS.md`** | M-C2 em `.checks/...md:53-54`; entrada manual não executada. |
| C3 | **NOT RUN — verificação manual exigida pelo `AGENTS.md`** | M-C3 em `.checks/...md:56-57`; cadastro e OTP manual não executados. |
| C4 | **NOT RUN — verificação manual exigida pelo `AGENTS.md`** | M-C4 em `.checks/...md:59-60`; comparação das mensagens/validação manual não executada. |
| C5 | **NOT RUN — verificação manual exigida pelo `AGENTS.md`** | M-C5 em `.checks/...md:62-63`; limite de tentativas não exercitado manualmente. |
| C6 | **NOT RUN — verificação manual exigida pelo `AGENTS.md`** | M-C6 em `.checks/...md:65-66`; redirecionamentos/URLs não exercitados manualmente. |
| C7 | **NOT RUN — verificação manual exigida pelo `AGENTS.md`** | M-C7 em `.checks/...md:68-69`; estados Auth/rede/OTP não exercitados manualmente. |
| C8 | **NOT RUN — verificação manual exigida pelo `AGENTS.md`** | M-C8 em `.checks/...md:73-74`; visitante, Companheiro e Comunidade não foram percorridos na interface. |
| C9 | **NOT RUN — verificação manual exigida pelo `AGENTS.md`** | M-C9 em `.checks/...md:76-77`; fluxo de contato não percorrido manualmente. |
| C10 | **NOT RUN — verificação manual exigida pelo `AGENTS.md`** | M-C10 em `.checks/...md:79-80`; concorrência de interface não testada. As chamadas sequenciais usadas por outras assertions SQL não substituem M-C10. |
| C11 | **NOT RUN — verificação manual exigida pelo `AGENTS.md`** | M-C11 em `.checks/...md:82-83`; URL/texto não foram abertos em WhatsApp nem revisados pela interface. |
| C12 | **NOT RUN — verificação manual exigida pelo `AGENTS.md`** | M-C12 em `.checks/...md:85-86`; alternativas `wa.me`/`tel:` não foram percorridas manualmente. |
| C13 | **NOT RUN — verificação manual exigida pelo `AGENTS.md`** | M-C13 em `.checks/...md:88-89`; falha/retry e inspeção manual de logs não executados. |
| C14 | **PASS** | `npx --yes supabase@latest test db`, exit 0; assertions executadas e localizadas abaixo. |
| C15 | **NOT RUN — verificação manual exigida pelo `AGENTS.md`** | M-C15 em `.checks/...md:94-95`; nenhuma conformidade visual foi inferida do CSS/build. |

### Evidência específica de C14

O comando executou ambos os arquivos que o checklist nomeia para C14 (`.checks/...md:91-92`): `supabase/tests/autenticacao-comunidade.test.sql .. ok` e `supabase/tests/contatos-comunidade.test.sql ...... ok`.

- **Anon/Companheiro sem leitura ou início de contato:** `autenticacao-comunidade.test.sql:30-54` verifica privilégios negados a `anon` para perfis/CPF e papéis; `:138-176` nega ao navegador a função CPF→telefone e funções de bloqueio. Em `contatos-comunidade.test.sql:179-207`, `throws_ok(..., '42501', ...)` cobre leitura de perfil/CPF, contatos e destinatários e chamadas anônimas às RPCs de contato. Para Companheiro, `:215-249` verifica `has_community_role() = false`, método `unavailable`, falha `42501` ao iniciar e falha de leitura de perfil, contato, telefone e configuração substituta.
- **Comunidade e identidade própria:** `contatos-comunidade.test.sql:266-267` define o `request.jwt.claim.sub` sintético e afirma `public.has_community_role() = true` com a descrição “derived from auth.uid()”; `:337-359` confirma que Comunidade também não lê diretamente perfis, contatos, destinos ou configuração. O wrapper implementado retorna `auth.uid()` (`supabase/migrations/20261014020000_perfil_privado_e_uid_rls.sql:28-36`); a policy de inserção limita `user_id` a `catalog.current_auth_uid()` e exige papel Comunidade ativo (`supabase/migrations/20261014010000_contatos_comunidade.sql:132-145`). A RPC recebe apenas banco/tipo, não `user_id`, papel ou `entity_id` do navegador (`:280-310` da mesma migration).
- **Quatro entidades sintéticas e destinatário isolado:** o teste cria A–D (`contatos-comunidade.test.sql:8-13`) e destinatários distintos, incluindo substituto para C e nenhum telefone para D (`:69-82`). As assertions `public.community_contact_method(...)` esperam os métodos de A, B, C e D, respectivamente (`:267-286`). As assertions de início conferem o URL `wa.me` com o destino A (`:289-307`), `tel:+12025550132` para B (`:309-316`), o telefone do substituto C no URL (`:318-327`) e `href is null` para D (`:329-335`). A função filtra por `v_entity_id`, papel destinatário e papel ativo (`supabase/migrations/20261014010000_contatos_comunidade.sql:343-360`). São fixtures sintéticas, não os contatos reais das entidades.
- **Contrato agregado anônimo:** `contatos-comunidade.test.sql:165-172` afirma que `array_to_string(proargnames[2:3], ',') = 'bank_name,available_quantity'`. O teste de disponibilidade existente também compara os resultados agregados nome/quantidade (`supabase/tests/disponibilidade-publica.test.sql:55-66`). O `RETURNS TABLE` atual contém esses dois campos (`supabase/migrations/20261013000000_disponibilidade_publica.sql:78-80`).
- **Telefone somente no link externo autorizado:** `contatos-comunidade.test.sql:156-164` verifica a saída da RPC como `contact_code,method,href`, sem coluna de telefone separada; a assinatura atual declara exatamente esses campos (`supabase/migrations/20261014010000_contatos_comunidade.sql:280-284`). A função só prossegue para papel Comunidade ativo (`:303-310`), e monta o telefone no URL `https://wa.me/…` ou `tel:` (`:426-436`). No servidor, o destino é reduzido ao método até a ação autorizada; `src/lib/contacts/server.ts:39-57,67-75,95-140` valida o papel e aceita somente os padrões de URL externos permitidos. O detalhe passa à interface apenas o método (`src/app/_components/equipment-detail.tsx:52-56`). Isso é evidência estática/SQL do limite do payload; não substitui M-C11 nem uma abertura manual do link.

## Itens fora do profile `light`

Não executei fault injection, o join de `Coverage`, `Test policy` nem a comparação de UI do profile `ui`; esses passos não se aplicam a `light`. Nenhum fault foi injetado. Os resultados SQL incidentais com rótulos C9/C10/C12 não foram usados para marcar os respectivos procedimentos M-C9/M-C10/M-C12 como executados.

## Limites e verificações de escopo

- **Verificação manual pendente:** M-C1–M-C13 e M-C15 permanecem `NOT RUN — verificação manual exigida pelo AGENTS.md`. Não houve automação de navegador; layout, viewport de 360 px, acessibilidade visual, Auth/OTP, interação, concorrência de interface e abertura de links externos não foram observados. O build e o CSS não foram tratados como prova visual.
- **Auth local/OTP:** em relação à base, `supabase/config.toml` muda a senha mínima de 6 para 8 e habilita cadastro/confirmação SMS, além de adicionar OTP sintético (`:182-186,258-270`; a base anterior está descrita no task em `.tasks/...md:111`). O serviço Auth local precisa ser recarregado após essa mudança para aplicar a configuração antes da prova OTP manual. Esta verificação não recarregou/reiniciou serviço algum; `test db` apenas conectou ao banco. Portanto, não está provado que o Auth em execução tenha carregado a configuração atual, e M-C3 continua pendente até isso ser confirmado pelo desenvolvedor.
- **`Unresolved` não decidido:** os itens 1–5 continuam gates de go-live e o item 6 continua aberto (`.tasks/...md:164-173`; `.checks/...md:107-114`). O OTP configurado é local/sintético; Twilio continua desabilitado e sem credenciais (`supabase/config.toml:268-270,293-300`). O aviso local é explicitamente sintético e produção exige configuração aprovada (`src/lib/auth/privacy-notice.ts:8-22`). O fallback `/` segue como comportamento provisório documentado (`src/lib/auth/return-to.ts:1-7`), não como resolução do item 6. Não há configuração de destinatários reais, aprovação jurídica, política de retenção aprovada ou painel administrativo de contatos neste diff.
- **Dados:** não encontrei dados reais adicionados. Migrações não carregam contatos reais; fixtures usam entidades `SYN-*`, usuários sintéticos e telefones `202-555-01xx`; o OTP em `supabase/config.toml:268-270` está comentado como fictício/local. `supabase/seed.sql` não está no diff.
- **Dependências/runners:** nenhum runner de navegador foi adicionado; `package.json` e lockfiles não aparecem no diff `7f9389a..HEAD`. O uso de `npx --yes` para o CLI não alterou esses manifestos.
- O relatório é a única alteração feita por este verifier. Arquivos não rastreados preexistentes em `.checks/disponibilidade-publica-fr-002-fr-003*` e `.tasks/` foram deixados intactos.
