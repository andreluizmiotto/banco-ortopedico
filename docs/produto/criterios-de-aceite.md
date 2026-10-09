# Criterios de Aceite do MVP

Os testes devem usar dados sinteticos e contas de teste. Nenhum nome, CPF, telefone, endereco ou documento real deve aparecer em fixture, screenshot ou relatorio.

## 1. Pre-condicoes

- Os quatro bancos e os tres locais fisicos do MVP estao cadastrados com dados de teste, incluindo um banco sem local fixo.
- Cada banco possui pelo menos um administrador de teste.
- Existem tipos de equipamento com disponibilidade, sem disponibilidade e em conserto.
- Existe pelo menos um minimo de estoque configurado para um tipo em um banco.
- Existem pelo menos dois perfis com papeis diferentes e um perfil com papeis acumulados.
- Existem modelos de termo de emprestimo, doacao e autorizacao de imagem de teste.

## 2. Criterios funcionais

- **AC-001**: o visitante consegue listar equipamentos, abrir um detalhe e ver disponibilidade agregada sem autenticar.
- **AC-002**: antes da autenticacao, a tela e a API nao revelam telefone, endereco, mapa, nome de responsavel ou link de WhatsApp.
- **AC-003**: uma pessoa consegue criar cadastro com CPF valido, confirmar telefone, criar senha de pelo menos oito caracteres sem informar endereco residencial e voltar ao equipamento originalmente escolhido.
- **AC-004**: uma pessoa consegue entrar com CPF com e sem pontuacao, desde que a senha esteja correta.
- **AC-005**: pelo menos tres das cinco pessoas de teste com mais de 60 anos conseguem recuperar a senha pelo codigo, sem intervencao de administrador, em ate tres minutos e dentro do limite operacional definido pelo provedor.
- **AC-006**: cinco usuarios de teste representando o publico idoso conseguem localizar um equipamento e abrir o contato em ate sete minutos, sem ajuda.
- **AC-007**: todo contato criado aparece para o administrador do banco correto com o mesmo codigo exibido na mensagem.
- **AC-008**: contatos repetidos na janela de deduplicacao nao geram duplicidade indevida.
- **AC-009**: o modo substituto altera o destinatario do novo contato sem alterar historico de contatos anteriores.
- **AC-010**: dois administradores conseguem registrar entrada, emprestimo com termo e devolucao sem ajuda, cada tarefa em ate tres minutos depois do treinamento.
- **AC-011**: uma devolucao pode marcar equipamento como pronto, em conserto ou sem condicao de uso.
- **AC-012**: uma doacao definitiva sai da disponibilidade e permanece no historico.
- **AC-013**: lembretes mostram emprestimos vencendo, vencidos e revisoes pendentes.
- **AC-014**: o termo de cada entidade usa o modelo e os campos corretos, sem clausula obrigatoria de imagem e com o texto de privacidade aprovado.
- **AC-015**: a pessoa consegue consultar, corrigir, baixar e solicitar exclusao dos proprios dados.
- **AC-016**: um administrador consegue mover equipamento para conserto e liberar acesso de companheiro por meio dos quadros, em desktop e celular.

## 3. Criterios de autorizacao e seguranca

- **AC-017**: administrador do banco A nao consegue ler ou alterar registro do banco B por chamada direta a API.
- **AC-018**: consultas autorizadas pelo papel Companheiro recebem somente dados publicos e agregados; nunca recebem dados pessoais, incluindo primeiro nome, bairro, CPF, endereco, telefone ou linha individual de emprestimo. Dados proprios so ficam disponiveis pelo papel Comunidade e ao titular.
- **AC-019**: usuario nao consegue acessar arquivo privado de outro usuario ou banco, mesmo conhecendo o caminho do Storage.
- **AC-020**: a alteracao de telefone por administrador exige permissao, registro de auditoria e justificativa.
- **AC-021**: CPF, telefone e nome nao aparecem em URL, logs de aplicacao ou mensagens de erro.
- **AC-022**: todas as transicoes invalidas de equipamento sao rejeitadas pelo servidor, nao apenas escondidas na interface.

## 4. Criterios de experiencia e acessibilidade

- **AC-023**: as telas principais atingem nota minima 90 no Lighthouse Accessibility, sem substituir testes manuais.
- **AC-024**: as telas funcionam em largura de 360 px sem rolagem horizontal.
- **AC-025**: botoes principais possuem pelo menos 56 px de altura e texto legivel conforme [acessibilidade e fluxos](../ux/acessibilidade-e-fluxos.md).
- **AC-026**: toda informacao comunicada por cor tambem aparece em texto ou rotulo.
- **AC-027**: fluxos de erro, sucesso, carregamento e rede indisponivel possuem mensagem compreensivel e caminho de recuperacao.

## 5. Criterios funcionais complementares

- **AC-028**: o administrador consegue localizar uma pessoa por nome ou CPF dentro do fluxo do proprio banco e nao consegue consultar o historico de emprestimos de outra entidade.
- **AC-029**: quando a consulta cruzada tiver aprovacao juridica, um alerta de tres ou mais emprestimos ativos ou de atraso superior a 30 dias nao bloqueia a operacao e nao revela banco, equipamento, datas ou historico; sem aprovacao, a consulta fica desativada.
- **AC-030**: no cadastro assistido, a pessoa confirma o telefone e o aviso de privacidade; o administrador nao define nem visualiza a senha.
- **AC-031**: o painel do Companheiro mostra os agregados previstos e permite filtrar por banco sem retornar dados pessoais ou linhas individuais pela tela ou API.
- **AC-032**: o painel destaca indisponibilidade total e estoque abaixo do minimo configurado para o banco e tipo correspondentes.
- **AC-033**: o banco itinerante pode operar sem endereco fixo e usar um local de apoio sem que a configuracao exija um endereco proprio.
- **AC-034**: o catalogo inicia na ordem definida para os tipos mais procurados e respeita a ordem configurada para os demais.
- **AC-035**: mensagens iniciadas pelo WhatsApp nao contem CPF, nome do paciente, endereco, diagnostico ou motivo de saude, permitem revisao e nunca sao enviadas automaticamente pelo sistema.
- **AC-036**: uma frase-senha de pelo menos oito caracteres e aceita sem exigir combinacao de maiusculas, numeros ou simbolos, e a pessoa consegue mostrar ou ocultar o texto digitado.
- **AC-037**: cada banco consegue usar um prazo sugerido proprio e o administrador pode altera-lo; emprestimos sem data de devolucao exigem uma data de revisao editavel e geram lembrete, nao cobranca automatica.
- **AC-038**: visitantes conseguem abrir as perguntas frequentes e a politica de privacidade sem autenticar.

## 6. Evidencias exigidas

Cada criterio deve ter pelo menos uma evidencia versionada ou vinculada ao CI:

- teste automatizado de unidade, integracao ou RLS;
- teste manual com roteiro e resultado;
- screenshot gerado com dados sinteticos, quando a evidencia visual for necessaria;
- relatorio Lighthouse para criterios de acessibilidade;
- log de migracao ou seed sintetico para criterios de dados.

## 7. Definicao de pronto do MVP

O MVP so pode ser marcado como pronto quando todos os criterios AC-001 a AC-038 estiverem aprovados ou quando uma excecao formal tiver responsavel, justificativa, risco e prazo de correcao.
