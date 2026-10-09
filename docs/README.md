# Banco Ortopedico

Documentacao publica do sistema de gestao dos bancos ortopedicos da Familia Rotaria de Erechim.

Esta documentacao acompanha a aplicacao no mesmo repositorio. Ela e a fonte de verdade para requisitos de produto, regras de negocio, arquitetura, experiencia de uso e privacidade. O codigo, as migrations do Supabase e os testes automatizados continuam sendo a fonte de verdade da implementacao executavel.

Materiais de levantamento e ideias originais orientam o produto, mas nao se tornam requisitos automaticamente. As decisoes aprovadas ficam nos documentos de produto; pendencias nao devem ser implementadas como se ja estivessem decididas.

## Por onde comecar

1. [Requisitos do produto](produto/requisitos.md)
2. [Regras de negocio](produto/regras-de-negocio.md)
3. [Visao geral da arquitetura](arquitetura/visao-geral.md)
4. [Autenticacao e autorizacao](arquitetura/autenticacao-e-autorizacao.md)
5. [Modelo conceitual de dados](arquitetura/modelo-conceitual.md)
6. [Acessibilidade e fluxos](ux/acessibilidade-e-fluxos.md)
7. [Requisitos de dados e privacidade](privacidade/requisitos-de-dados.md)
8. [Criterios de aceite do MVP](produto/criterios-de-aceite.md)

## Indice

### Produto

- [Requisitos funcionais e escopo](produto/requisitos.md)
- [Regras de negocio](produto/regras-de-negocio.md)
- [Criterios de aceite](produto/criterios-de-aceite.md)
- [Documentos gerados pelo sistema](produto/documentos-gerados.md)
- [Mensagens padrao](produto/mensagens-padrao.md)

### Arquitetura

- [Visao geral](arquitetura/visao-geral.md)
- [Modelo conceitual](arquitetura/modelo-conceitual.md)
- [Autenticacao e autorizacao](arquitetura/autenticacao-e-autorizacao.md)
- [ADR-0001: Next.js e Supabase](arquitetura/decisoes/0001-nextjs-supabase.md)

### Experiencia e identidade

- [Acessibilidade e fluxos](ux/acessibilidade-e-fluxos.md)
- [Identidade visual](ux/identidade-visual.md)
- [Referencias de fluxo](ux/referencias/README.md)

### Privacidade

- [Requisitos de dados e privacidade](privacidade/requisitos-de-dados.md)

## Convencoes

- **MVP**: necessario para o primeiro lancamento.
- **FASE 2**: deliberadamente fora do primeiro lancamento.
- **DECIDIDO**: regra de produto aprovada; alteracoes exigem revisao explicita.
- **EM ABERTO**: decisao que ainda precisa de responsavel e prazo.
- `FR-*`: requisito funcional.
- `RN-*`: regra de negocio.
- `NFR-*`: requisito nao funcional.
- `AC-*`: criterio de aceite.

Requisitos funcionais descrevem o comportamento esperado. A arquitetura descreve limites e responsabilidades tecnicas. O codigo e as migrations devem apontar de volta para estes documentos quando implementarem uma decisao relevante.

## Politica para repositorio publico

Nao adicionar a este repositorio:

- CPF, telefone, nome de pessoa atendida, endereco residencial ou qualquer outro dado pessoal real;
- scans, fotos ou transcricoes de fichas e contratos preenchidos;
- inventario de producao ou emprestimos reais;
- chaves, tokens, credenciais ou arquivos de ambiente;
- links assinados do Supabase Storage;
- dados reais em fixtures, seeds, screenshots ou mensagens de exemplo.

Exemplos e testes devem usar dados sinteticos. Nomes de entidades, regras de dominio e logos institucionais devem ser mantidos somente depois de confirmar que o projeto possui permissao para redistribui-los.

## Como atualizar

1. Altere primeiro o documento que e fonte do assunto.
2. Atualize os identificadores de requisitos e os criterios de aceite afetados.
3. Atualize a implementacao, migrations e testes no repositorio do projeto.
4. Gere o PDF ou outro material de distribuicao somente a partir dos Markdown, quando necessario.
5. Revise se a mudanca introduziu dados pessoais ou uma segunda fonte de verdade.

## Estado atual

- Stack definida: Next.js no frontend e Supabase para autenticacao, banco PostgreSQL e armazenamento.
- Escopo do MVP definido em [requisitos](produto/requisitos.md).
- Provedor de SMS, dominio, titularidade das contas e responsabilidades legais ainda precisam ser definidos.
- Os documentos originais de levantamento nao fazem parte desta versao publica.
