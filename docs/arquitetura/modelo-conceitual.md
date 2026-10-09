# Modelo Conceitual de Dados

Este e um mapa do dominio para orientar a modelagem no PostgreSQL. Nao e DDL nem substitui as migrations do Supabase. As migrations e os testes no repositorio do codigo sao a representacao executavel do schema.

## 1. Identidade e acesso

### Perfil de usuario

Dados de perfil separados das credenciais geridas pelo Supabase Auth:

- `auth_user_id`: referencia a identidade autenticada;
- CPF normalizado, quando aprovado como identificador de negocio;
- nome e telefone confirmados;
- endereco, somente se necessario ao termo aprovado, coletado no fluxo de emprestimo e nao na criacao da conta;
- situacao ativa ou desativada;
- pedido de exclusao, quando houver.

Nao criar coluna de senha ou de hash de senha na tabela de perfil. Hashes e sessoes sao responsabilidade do provedor de autenticacao.

### Papel

Relacao entre pessoa, papel, entidade e situacao de acesso:

- `comunidade`;
- `companheiro`;
- `admin_banco`;
- `admin_geral`.

Uma pessoa pode ter mais de um papel e mais de um vinculo institucional. Administradores de banco sempre precisam de escopo de entidade.

## 2. Entidades e locais

### Entidade

Representa organizacao mantenedora ou vinculadora. Campos conceituais: nome oficial, nome publico, tipo, sigla, indicador de possuir banco, identificador juridico opcional, logo permitido, contato operacional protegido, configuracao de atendimento, prazo sugerido e estado ativo.

### Local

Representa local fisico compartilhavel entre entidades. Campos conceituais: nome, endereco, referencia, coordenadas, horario e imagem opcional.

O relacionamento entre entidade e local deve suportar atendimento itinerante, local de apoio e mais de uma entidade usando o mesmo local.

## 3. Catalogo e acervo

### Tipo de equipamento

Representa o conceito visivel a comunidade. Campos: nome, sigla, descricao curta, imagem padrao, ordem, estado ativo e atributos especificos, como exigencia de largura.

### Minimo de estoque

Configuracao opcional por entidade e tipo de equipamento, com a quantidade minima que o banco quer manter disponivel. O painel usa essa configuracao para destacar estoque baixo sem associar o alerta a pessoas ou emprestimos individuais.

### Equipamento ou lote de inventario

Representa unidade fisica ou contagem agregada durante a fase de implantacao. Conceitos necessarios:

- entidade proprietaria;
- local atual;
- tipo;
- codigo individual opcional antes do inventario;
- quantidade agregada apenas enquanto o inventario for por contagem;
- situacao e condicao;
- largura, origem, doador e observacoes quando aplicaveis;
- fotos privadas ou publicas conforme classificacao.

O desenho fisico final deve escolher explicitamente como representar contagem inicial e unidade individual. A migracao para inventario individual precisa preservar contagens e historico.

### Movimentacao

Evento imutavel ou append-only que registra equipamento, origem, destino, ator, data, motivo e contexto. A situacao atual pode ser materializada, mas o historico nao deve ser sobrescrito.

## 4. Emprestimos e contatos

### Emprestimo

Representa a operacao com entidade, responsavel, nome do paciente quando diferente, tipo de saida, datas, situacao, modelo/versao do termo e administrador que entregou.

### Linha de emprestimo

Liga emprestimo a equipamento ou tipo agregado, quantidade, condicao na saida e devolucao, data de devolucao e responsavel por receber.

### Contato

Representa a solicitacao para conversar com um banco. Guarda codigo publico curto, tipo, entidade, destinatario efetivo, usuario autenticado, origem, situacao e datas de atendimento. O payload enviado ao cliente nunca deve incluir CPF.

### Tentativa de contato

Representa uma acao de acompanhamento de devolucao: emprestimo, ator, data, canal, resultado e observacao minimizada.

## 5. Consentimentos, documentos e auditoria

- **Consentimento**: pessoa, tipo, versao do texto, detalhes permitidos, data de aceite e eventual revogacao.
- **Pedido de titular**: tipo de solicitacao, situacao, datas de abertura e conclusao.
- **Modelo de documento**: entidade, tipo, conteudo com campos, versao, estado ativo e datas.
- **Arquivo gerado**: referencia privada ao PDF e a versao do modelo, sem CPF ou nome no caminho do Storage.
- **Oferta de doacao**: dados minimos de quem oferece, descricao, estado e contato autorizado.
- **Auditoria**: ator, acao, entidade, tabela/recurso, identificador interno, alteracao, data e contexto tecnico minimizado.
- **Codigo de verificacao**: finalidade, hash do codigo, validade, tentativas e uso; nunca armazenar o codigo em texto puro.

## 6. Invariantes de integridade

- Um equipamento individual nao pode estar em mais de um emprestimo ativo.
- Quantidades nunca podem ficar negativas.
- A autorizacao de linha precisa validar o vinculo ativo entre usuario, papel e entidade.
- Um registro de outro banco nao pode ser recuperado por ID quando o ator nao tem permissao.
- Dados pessoais nao devem ser incluidos em payloads de companheiro, catalogo publico, logs ou URLs.
- Paineis de Companheiro devem retornar apenas agregados, sem nome parcial, bairro ou identificadores de emprestimos.
- Alteracoes de situacao e permissao precisam manter ator e data para auditoria.

## 7. Mapeamento para Supabase

O desenho final deve:

1. mapear o perfil de negocio para `auth.users` por UUID;
2. normalizar CPF e definir unicidade no banco, apos escolher o fluxo de autenticacao;
3. aplicar RLS em toda tabela acessivel por cliente;
4. usar funcoes `SECURITY DEFINER` somente quando justificadas, com `search_path` fixo e validacao de ator;
5. isolar buckets privados e validar acesso tambem no Storage;
6. testar leitura, escrita, update e delete negados entre entidades;
7. definir constraints, indices e transacoes para operacoes de emprestimo e devolucao.

Detalhes de credencial e papeis estao em [Autenticacao e autorizacao](autenticacao-e-autorizacao.md).
