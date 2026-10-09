# Visao Geral da Arquitetura

Status da stack: Next.js e Supabase definidos. Integracoes, hospedagem e alguns detalhes de autenticacao permanecem em aberto. A decisao registrada esta em [ADR-0001](decisoes/0001-nextjs-supabase.md).

## 1. Componentes

| Componente | Responsabilidade |
|---|---|
| Next.js | Paginas publicas, interface responsiva e fluxos autenticados |
| Supabase Auth | Identidade, sessao, verificacao e recuperacao de credencial |
| Supabase PostgreSQL | Dados de dominio, constraints, funcoes e RLS |
| Supabase Storage | Fotos e PDFs, em buckets publicos somente quando o conteudo puder ser publico |
| Rotas de servidor ou funcoes protegidas | Operacoes privilegiadas, geracao de PDF e integracoes externas |
| Provedor de SMS | Envio de codigos de confirmacao e recuperacao; fornecedor a escolher |
| ViaCEP ou equivalente | Preenchimento auxiliar de endereco a partir do CEP |
| WhatsApp | Conversa entre pessoa atendida e responsavel, fora do sistema |
| Mapas | Link de rota com coordenadas configuradas, sem mapa embutido no MVP |

## 2. Limites de confianca

- O navegador e ambiente nao confiavel. Validacao de permissao e regras de negocio devem ocorrer no servidor e/ou no banco.
- RLS e a barreira final para leitura e escrita de linhas por usuario e entidade.
- A chave `service_role` e outros segredos existem apenas no servidor e no gerenciador de segredos do deploy.
- A aplicacao nunca usa Storage publico para documentos de emprestimo, fotos de documentos assinados ou dados privados.
- Links de WhatsApp sao montados com dados minimizados. O sistema nao envia mensagens automaticamente nem le conversas.
- Enderecos e telefones operacionais sao configuracao privada de producao, nao constantes do repositorio.

## 3. Fluxo de dados principal

1. Visitante consulta catalogo e disponibilidade agregada por endpoints que expoem somente campos publicos.
2. Pessoa autentica ou cria conta por um fluxo que associa CPF a uma identidade Supabase sem implementar armazenamento proprio de senha.
3. Pessoa autenticada solicita um contato; a operacao valida sessao, cria ou deduplica o contato e retorna um link de WhatsApp.
4. Administrador autorizado registra entrada, saida, devolucao, conserto ou baixa.
5. A operacao valida as regras, atualiza registros relacionados e grava auditoria dentro de uma transacao ou funcao segura.
6. O gerador de documento aplica o modelo versionado e armazena o PDF em bucket privado.
7. A pessoa autorizada recebe um link temporario para visualizar ou baixar o PDF.

## 4. Organizacao do codigo relacionada a esta documentacao

A estrutura final do projeto deve manter responsabilidades separadas, por exemplo:

- interface e componentes Next.js;
- regras de aplicacao no servidor;
- migrations e seeds sinteticos do Supabase;
- testes de RLS e fluxos de autorizacao;
- configuracao publica do frontend;
- segredos fornecidos pelo ambiente de deploy.

Esta documentacao nao substitui migrations. Toda alteracao de schema deve ser versionada como migration e testada contra uma instancia local ou de CI.

## 5. Decisoes tecnicas pendentes

- fluxo seguro de entrada usando CPF como identificador e Supabase Auth;
- provedor, custo e limites de SMS;
- plataforma e regiao de hospedagem da aplicacao;
- biblioteca e estrategia de renderizacao de PDF;
- servico de email, caso seja adotado;
- estrategia de telemetria sem rastreamento de pessoa;
- rotina operacional de backup e teste de restauracao;
- modelo de responsabilidade entre entidades para dados pessoais.

As decisoes devem ser registradas em ADRs curtas, com status, contexto, decisao e consequencias. Ao substituir uma decisao, mantenha o historico e marque a ADR anterior como substituida.
