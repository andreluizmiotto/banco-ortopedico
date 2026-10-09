# Requisitos do Produto

Status: `DECIDIDO` para o escopo do MVP, com pendencias listadas ao final.

## 1. Objetivo

Disponibilizar um catalogo unico de equipamentos ortopedicos para a comunidade de Erechim, preservando a autonomia de cada banco mantenedor.

O sistema deve:

- permitir que qualquer pessoa encontre tipos de equipamento e disponibilidade agregada sem cadastro;
- identificar a pessoa antes de revelar contatos, enderecos e locais de atendimento;
- encaminhar a conversa para o responsavel do banco por WhatsApp, sem tentar substituir a conversa humana;
- registrar o contato e permitir que o administrador converta o atendimento em emprestimo;
- controlar entradas, emprestimos, devolucoes, consertos, baixas e doacoes definitivas;
- oferecer uma visao agregada aos companheiros, sem expor dados pessoais de atendidos;
- garantir isolamento entre bancos no banco de dados, e nao apenas na interface.

## 2. Principios de produto

1. A simplicidade para pessoas idosas e administradores com pouca familiaridade digital tem prioridade sobre funcionalidades secundarias.
2. Cada banco continua responsavel pelo proprio acervo, atendimento, documentos e decisoes.
3. A comunidade ve tipos e quantidades agregadas; o Companheiro ve somente indicadores agregados, sem qualquer dado que identifique uma pessoa, inclusive primeiro nome ou bairro.
4. O contato pelo WhatsApp e uma ponte para atendimento, nao uma reserva automatica.
5. O sistema nao coleta diagnostico, doenca, receita, laudo ou motivo de saude.
6. Toda informacao critica deve estar disponivel em texto; cor e icone nunca podem ser a unica forma de comunicacao.
7. O MVP deve funcionar bem em celular simples, com conexao instavel e largura de 360 px.
8. O cadastro inicial nao pede endereco residencial; esse dado so e coletado no fluxo de emprestimo quando o modelo aprovado realmente exigir.

## 3. Escopo do MVP

### Incluido

- catalogo publico de tipos de equipamento;
- disponibilidade agregada por banco;
- cadastro e entrada por CPF e senha;
- confirmacao de telefone por codigo;
- recuperacao automatica de senha;
- perfis Comunidade, Companheiro, Administrador do banco e Administrador geral;
- cadastro inicial de quatro bancos e tres locais fisicos de atendimento, incluindo um banco itinerante que pode usar um local de apoio;
- registro de contatos iniciados no WhatsApp;
- modo de responsavel substituto;
- entradas por doacao, compra ou retorno de conserto;
- emprestimo para a propria pessoa ou para um paciente identificado apenas pelo nome;
- doacao definitiva;
- devolucao, conserto e baixa;
- lembretes e registro de tentativas de contato;
- geracao de termo em PDF para cada banco;
- armazenamento opcional de foto do termo assinado;
- painel agregado do Companheiro e estoque do proprio banco, incluindo indicacao de tipos em falta ou abaixo do minimo configurado;
- quadro de organizacao para equipamentos, dono/local e acessos;
- auditoria das alteracoes relevantes;
- direitos de acesso, correcao, portabilidade e exclusao dos dados;
- PWA ou experiencia instalavel no navegador, sem aplicativo de loja.

### Fora do MVP

- assinatura desenhada na tela;
- notificacoes push ou envio automatico de email;
- leitura de conversas do WhatsApp;
- envio automatico de mensagens em nome do sistema;
- QR Code para devolucao;
- graficos de patrimonio e historico avancado;
- perfil de voluntario;
- itens de consumo, como fraldas e roupas;
- banco de perucas, ate haver decisao especifica e avaliacao de privacidade;
- pagamentos ou controle financeiro.

## 4. Perfis e capacidades

| Perfil | Capacidades principais | Limite de acesso |
|---|---|---|
| Visitante | Consultar catalogo, fotos, descricoes e disponibilidade | Nao ve contatos, enderecos, mapa, telefones ou responsaveis |
| Comunidade | Tudo do visitante, contato, proprios emprestimos, dados pessoais e oferta de doacao | Nao ve dados de outras pessoas |
| Companheiro | Somente painel agregado; funcoes pessoais exigem tambem o papel Comunidade | O papel Companheiro nao recebe dados pessoais, nem primeiro nome ou bairro |
| Administrador do banco | Operar acervo, contatos, emprestimos, devolucoes, lembretes e acessos do proprio clube | Escopo limitado ao banco ou entidade autorizada |
| Administrador geral | Configurar entidades, locais, tipos, modelos, acessos, auditoria e dados globais | Pode operar todos os bancos; toda alteracao deve ser auditada |

Uma pessoa pode ter mais de um papel. O sistema nao deve criar contas duplicadas para a mesma pessoa.

## 5. Requisitos funcionais

### Catalogo e descoberta

- **FR-001**: o visitante deve conseguir consultar a lista de tipos de equipamento ativos.
- **FR-002**: cada tipo deve exibir nome, foto opcional, descricao curta e disponibilidade em linguagem simples.
- **FR-003**: o detalhe do tipo deve mostrar um cartao por banco que possua aquele tipo, com quantidade agregada e situacao.
- **FR-004**: o catalogo deve permitir busca textual simples por equipamento, sem filtros avancados no MVP.
- **FR-005**: a comunidade deve retornar ao equipamento originalmente solicitado depois de concluir cadastro ou entrada.

### Identidade e acesso

- **FR-006**: a entrada deve aceitar CPF normalizado e senha, sem permitir escolha manual de perfil.
- **FR-007**: o cadastro inicial deve coletar nome, CPF, telefone confirmado e credencial; nao deve exigir endereco residencial. O cadastro confirma o telefone por codigo.
- **FR-008**: o CPF deve ser validado pelo digito verificador e armazenado normalizado, sem pontuacao.
- **FR-009**: a senha deve ter pelo menos oito caracteres, permitir frases-senha e mostrar ou ocultar o valor digitado; nao exigir combinacoes artificiais de maiusculas, numeros ou simbolos.
- **FR-010**: depois de cinco tentativas invalidas consecutivas, a entrada deve sofrer bloqueio temporario.
- **FR-011**: a recuperacao de senha deve funcionar sem intervencao cotidiana de administrador.
- **FR-012**: a troca de telefone por perda do numero anterior deve exigir verificacao de identidade, permissao adequada e auditoria.

### Contato com bancos

- **FR-013**: o sistema deve mostrar o botao de contato somente para pessoa autenticada com papel Comunidade.
- **FR-014**: o toque no botao deve criar ou reutilizar um contato conforme a regra de deduplicacao de [regras de negocio](regras-de-negocio.md).
- **FR-015**: o sistema deve montar um link oficial do WhatsApp com mensagem pre-preenchida e editavel, sem envio automatico e sem incluir CPF, nome do paciente, endereco, diagnostico ou motivo de saude; os textos iniciais estao em [mensagens padrao](mensagens-padrao.md).
- **FR-016**: o destinatario deve ser o responsavel ativo ou o substituto quando o modo substituto estiver ligado.
- **FR-017**: o administrador deve conseguir marcar o contato como atendido, sem retorno ou convertido em emprestimo.

### Operacao do acervo

- **FR-018**: o administrador deve registrar entrada por doacao, compra, retorno de conserto ou devolucao de outro banco.
- **FR-019**: o administrador deve localizar a pessoa pelo nome ou CPF no fluxo do proprio banco, registrar o emprestimo para o responsavel cadastrado e informar o paciente quando for outra pessoa. O endereco so pode ser solicitado nessa etapa se o modelo aprovado exigir.
- **FR-020**: o fluxo de emprestimo deve permitir prazo sugerido, prazo customizado ou revisao sem data definida.
- **FR-021**: o sistema deve gerar o documento correspondente antes de concluir a saida.
- **FR-022**: o administrador deve registrar devolucao total ou parcial, estado na devolucao e destino posterior do equipamento.
- **FR-023**: o sistema deve registrar doacao definitiva separadamente de emprestimo.
- **FR-024**: o administrador deve registrar tentativas de contato e nova data de revisao.
- **FR-025**: o estoque deve exibir, por tipo, quantidades em casa, emprestadas, em conserto, doadas em definitivo e baixadas, e destacar indisponibilidade ou estoque abaixo do minimo configurado.

### Organizacao e administracao

- **FR-026**: o administrador do banco deve administrar somente registros permitidos para seu escopo.
- **FR-027**: o administrador geral deve administrar entidades, locais, tipos, modelos de documento e permissoes.
- **FR-028**: o quadro de situacao deve permitir corrigir movimentos administrativos com confirmacao e justificativa.
- **FR-029**: o quadro de dono/local deve distinguir propriedade do equipamento e local onde ele esta guardado.
- **FR-030**: o quadro de acessos deve permitir solicitar, liberar e retirar acesso sem apagar a conta de comunidade.
- **FR-031**: alteracoes de dados, permissoes, acervo e emprestimos devem gerar registro de auditoria.

### Dados pessoais e documentos

- **FR-032**: a pessoa deve consultar, corrigir, baixar e solicitar exclusao dos proprios dados.
- **FR-033**: o sistema deve manter o historico necessario para operacao e anonimizacao conforme a politica de retencao.
- **FR-034**: termos devem ser gerados a partir de modelo versionado por entidade e tipo de documento.
- **FR-035**: autorizacao de uso de imagem deve ser documento separado, opcional, especifico e revogavel.
- **FR-036**: informacoes privadas devem ser armazenadas em buckets privados e entregues por links temporarios.
- **FR-037**: a comunidade deve conseguir oferecer um equipamento para doacao por formulario curto; a oferta fica pendente para triagem administrativa.

### Conteudo e configuracao

- **FR-038**: o administrador geral deve poder alterar mensagens prontas, descricoes de tipos, perguntas frequentes e textos institucionais sem deploy; mensagens aceitam somente campos dinamicos aprovados e nunca incluem CPF, nome do paciente, endereco, diagnostico ou motivo de saude, conforme [mensagens padrao](mensagens-padrao.md).
- **FR-039**: configuracoes de telefone, horario e local de atendimento devem ser editaveis por perfil autorizado.
- **FR-040**: o sistema deve permitir cadastrar entidades futuras sem mudanca de codigo, respeitando o fluxo de autorizacao.
- **FR-041**: o administrador do banco deve conseguir iniciar, dentro do proprio banco, um cadastro assistido com papel Comunidade para uma pessoa sem conta; a pessoa confirma o proprio telefone e o aviso de privacidade, e o administrador nunca define nem visualiza a senha.
- **FR-042**: no fluxo de emprestimo ou devolucao do proprio banco, o administrador pode localizar e reutilizar a conta existente pelo nome ou CPF, com acesso apenas aos dados minimos necessarios; historico de emprestimos de outros bancos nunca e exibido.
- **FR-043**: o painel do Companheiro deve mostrar quantidades agregadas de equipamentos em casa, emprestados, em conserto e com prazo vencido, com filtro por banco, sem dados pessoais ou linhas de emprestimo.
- **FR-044**: o administrador do banco deve poder configurar um minimo opcional por tipo de equipamento dentro do proprio banco; o painel deve indicar tipos sem disponibilidade em todos os bancos e tipos abaixo do minimo daquele banco.
- **FR-045**: o visitante deve conseguir consultar perguntas frequentes e a politica de privacidade sem criar conta ou entrar no sistema.

## 6. Requisitos nao funcionais

- **NFR-001**: acessibilidade minima WCAG 2.1 AA para texto e controles principais; o criterio operacional esta em [acessibilidade e fluxos](../ux/acessibilidade-e-fluxos.md).
- **NFR-002**: nenhuma tela principal pode exigir rolagem horizontal em viewport de 360 px.
- **NFR-003**: dados entre bancos devem ser isolados por RLS no Supabase e testados diretamente contra a API.
- **NFR-004**: o servidor nunca deve devolver dados pessoais de terceiros a consultas do papel Companheiro, inclusive primeiro nome, bairro ou linhas de emprestimo; dados proprios so podem ser acessados pelo papel Comunidade e pelo titular.
- **NFR-005**: CPF, telefone e nome nao podem aparecer em URL, logs de aplicacao ou mensagens de erro.
- **NFR-006**: paginas publicas devem ser leves e imagens devem ter dimensoes e compressao adequadas ao celular.
- **NFR-007**: operacoes importantes devem ser idempotentes ou protegidas contra duplo envio.
- **NFR-008**: backups, restauracao e retencao devem ser configurados no ambiente Supabase conforme a politica operacional do projeto.

## 7. Implantacao

1. **Versao previa**: cadastrar entidades, locais, responsaveis e modelos; carregar estoque por contagem; treinar administradores e revisar fluxos com os bancos.
2. **Inventario individual**: conferir cada equipamento, registrar medidas/fotos quando aplicavel, atribuir codigo e importar emprestimos ainda abertos.
3. **Divulgacao**: ampliar a divulgacao publica depois de confirmar os dados e concluir o inventario planejado.
4. **Evolucao**: priorizar itens marcados FASE 2 apos o MVP.

## 8. Pendencias de produto

| Pendencia | Impacto | Responsavel sugerido | Prazo de decisao |
|---|---|---|---|
| Definir responsaveis e telefones de producao de cada banco | Configuracao de entidades e contato | Coordenacao do projeto | A definir |
| Definir controlador e encarregado de dados | Politica de privacidade e resposta a incidentes | Coordenacao e revisao juridica | A definir |
| Aprovar se e como gerar alertas sobre emprestimos em outros bancos | Minimizacao de dados e decisao de emprestimo | Coordenacao e revisao juridica | A definir |
| Confirmar regras de cadastro, representacao e assinatura quando houver menor de idade | Cadastro e validade dos documentos | Coordenacao e revisao juridica | A definir |
| Confirmar o prazo sugerido inicial de cada banco | Configuracao do fluxo de emprestimo | Responsaveis dos bancos | A definir |
| Escolher provedor de SMS ou WhatsApp Business | Cadastro, recuperacao e custo operacional | Equipe tecnica e coordenacao | A definir |
| Definir dominio, titulares de contas e custos | Deploy, billing e continuidade operacional | Coordenacao | A definir |
| Revisar juridicamente os termos e a politica | Liberacao para producao | Responsavel juridico | A definir |
| Definir regra de publicacao do banco de perucas | Escopo e tratamento de dado sensivel | Casa da Amizade e coordenacao | A definir |

Os responsaveis sao sugestoes, nao atribuicoes confirmadas. Os prazos ainda precisam ser definidos pela coordenacao antes de esta tabela ser usada como compromisso de entrega.
