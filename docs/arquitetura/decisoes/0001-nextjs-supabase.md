# ADR-0001: Next.js e Supabase

- **Status**: Aceita
- **Data**: 2026-10
- **Escopo**: aplicacao web, autenticacao, persistencia e arquivos

## Contexto

O sistema precisa funcionar primeiro no celular, ter controle de acesso por banco, gerar documentos, armazenar fotos e permitir evolucao sem manter um backend operacional separado no MVP.

## Decisao

- Usar Next.js com React para a aplicacao web responsiva. A linguagem e as convencoes do scaffold devem seguir a decisao registrada no repositorio do codigo.
- Usar Supabase PostgreSQL como banco principal.
- Usar Supabase Auth para identidade e sessao.
- Usar Row Level Security (RLS) para separar entidades e papeis.
- Usar Supabase Storage para fotos e documentos, sempre com buckets privados quando o arquivo nao for publico.
- Usar rotas de servidor, Server Actions ou Edge Functions para operacoes que exigem segredo, geracao de PDF ou integracao com provedores externos.
- Usar links externos para mapa e WhatsApp no MVP, sem integrar conversas ou mapa embutido.

## Limites da decisao

Esta ADR nao escolhe:

- provedor de SMS ou WhatsApp Business;
- dominio e titularidade das contas;
- plataforma e regiao de hospedagem da aplicacao;
- biblioteca de PDF;
- estrategia final de observabilidade;
- formato de assinatura eletronica;
- modelo juridico de controlador conjunto ou controladores independentes.

Esses pontos precisam de ADR ou decisao operacional antes da producao.

## Consequencias positivas

- RLS fica proximo dos dados e pode ser testado diretamente.
- Auth, PostgreSQL e Storage possuem uma integracao coerente.
- O frontend pode usar renderizacao no servidor para paginas publicas e manter operacoes sensiveis no servidor.
- O MVP evita criar e manter uma API CRUD duplicada sem necessidade.

## Consequencias e riscos

- Politicas RLS incorretas podem vazar dados; elas precisam de testes negativos por papel e por entidade.
- A chave `service_role` nunca pode ser enviada ao navegador, registrada em log ou commitada.
- O login por CPF nao deve levar a armazenamento manual de senha. A estrategia de mapeamento entre CPF e identidade do Supabase precisa ser implementada no servidor e documentada.
- Funcionalidades muito dependentes de fornecedor devem ficar atras de uma interface de servico para permitir troca de SMS, PDF ou mapas.
- Custos de mensagens, armazenamento e hospedagem precisam ser monitorados.

## Alternativas consideradas

- **Backend customizado separado**: adiado por aumentar a superficie operacional do MVP.
- **Aplicativo nativo**: adiado; PWA atende a primeira fase e reduz custo de distribuicao.
- **Mapa embutido**: adiado; link com coordenadas fixas atende o caso de uso.
- **Envio automatico de WhatsApp**: adiado; o MVP abre mensagem pre-preenchida para evitar custo, bloqueio e complexidade de consentimento.

## Validacao obrigatoria

Antes do lancamento, demonstrar:

1. isolamento entre entidades com chamadas diretas a API;
2. ausencia de segredo no bundle do navegador;
3. acesso privado a arquivos por URL assinada;
4. restauracao de backup em ambiente de teste;
5. fluxo de troca do provedor de SMS sem alterar regras de negocio.
