# Acessibilidade e Fluxos

O publico inclui pessoas idosas, familiares em situacao de urgencia e administradores com pouca familiaridade digital. As regras abaixo sao requisitos de produto e devem ser verificadas em celular e com usuarios reais.

## 1. Requisitos de interface

- Uma acao principal por tela.
- Botoes principais com pelo menos 56 px de altura, largura total no celular e texto em negrito com pelo menos 20 px.
- Texto corrido com pelo menos 18 px; titulos com pelo menos 26 px.
- Contraste minimo de 4,5:1 para texto normal.
- Nenhuma informacao pode depender somente de cor ou icone.
- Toda acao importante termina com confirmacao clara e proximo passo unico.
- Formularios longos devem ser divididos em passos curtos e indicar progresso.
- Botao Voltar deve estar em local previsivel.
- A navegacao principal da comunidade e do administrador nao deve depender de menu escondido.
- Layout sem rolagem horizontal a partir de 360 px.
- Imagens devem ser comprimidas e a pagina deve continuar utilizavel em rede lenta.
- Usar controles nativos acessiveis, labels associados, foco visivel e mensagens de erro ligadas ao campo.

## 2. Linguagem da interface

Preferir linguagem cotidiana. Evitar estes termos em textos exibidos ao publico: `login`, `dashboard`, `status`, `item`, `unidade`, `submeter`, `logout`, `cancelar operacao`, `acervo`, `ponto de guarda`, `rascunho` e `banco mantenedor`.

Preferir: `entrar`, `painel`, `situacao`, `equipamento`, `enviar`, `sair`, `voltar`, `equipamentos do banco`, `onde está guardado`, `número do equipamento` e `pedidos de contato`.

O vocabulario interno do codigo e do banco pode usar termos tecnicos, mas nao deve vazar para a interface. Por exemplo, `catalog.storage_locations` e `catalog.equipment_units.status = 'available'` sao identificadores tecnicos; a tela usa nomes cotidianos e os rotulos definidos em [Regras de Negocio](../produto/regras-de-negocio.md#4-situacao-tecnica-e-rotulos-de-tela).

## 3. Rotas e fluxo para encontrar equipamento

As rotas atuais de `src/app/` sao:

| Rota | Acesso | Comportamento atual |
|---|---|---|
| `/` | Publico | Lista tipos ativos e disponibilidade agregada. Esta lista e a pagina inicial atual. |
| `/equipamentos/[code]` | Publico, com acoes condicionadas ao papel | Mostra o detalhe do tipo e cartoes por banco. A acao de contato depende da sessao e do papel ativo. |
| `/entrar` | Comunidade | Permite entrar com CPF e senha ou iniciar cadastro com confirmacao de telefone. |
| `/admin/entrar` | Administrador do banco | Permite entrar com e-mail e senha do Supabase Auth; nao oferece cadastro administrativo. |
| `/admin/contatos` | `bank_admin` ativo | Area protegida para pesquisar pelo codigo e acompanhar ou marcar a situacao dos contatos recebidos do banco autorizado. |

As acoes executadas pelo servidor nao sao rotas de pagina. Nao ha rotas atuais
para emprestimos, devolucoes, equipamentos administrativos, painel do
Companheiro, pagina institucional ou FAQ.

### Jornada publica atual

1. A pessoa abre `/` e consulta a lista de tipos e a disponibilidade agregada.
   A lista atual mostra o nome e a disponibilidade em texto; descricoes curtas
   ainda nao sao exibidas.
2. Ao escolher **Ver disponibilidade**, abre `/equipamentos/[code]`.
3. O detalhe mostra um cartao por banco que possui aquele tipo. Bancos com
   disponibilidade aparecem primeiro, em ordem aleatoria a cada consulta;
   cartoes sem disponibilidade aparecem depois.
4. Quando um banco tem zero unidades com
   `catalog.equipment_units.status = 'available'`, seu cartao permanece
   visivel e mostra `Nenhum disponível no momento`. Para unidades disponiveis,
   a tela mostra **Disponível para empréstimo**.
5. Visitante sem sessao, ou sessao sem papel Comunidade ativo, ve
   **Entrar para conversar**, com destino `/entrar`; essa acao nao abre
   WhatsApp nem revela telefone ou destinatario.
6. Depois de entrar ou criar cadastro, a pessoa retorna ao detalhe solicitado
   quando a origem e valida.
7. Pessoa autenticada com papel Comunidade ativo pode iniciar o contato pelo
   WhatsApp mesmo quando a disponibilidade e zero. O sistema abre uma mensagem
   revisavel e nao a envia automaticamente nem cria uma reserva de equipamento.
8. Se nao houver destino WhatsApp, a tela oferece ligacao somente quando
   houver telefone autorizado; sem destino autorizado, nao apresenta link ou
   numero.

Na ordem inicial, priorizar cadeira de rodas, cama hospitalar, cadeira de
banho, andador e muletas. Os demais tipos seguem a ordem configurada.

### Escopo adiado

A rota `/` abre diretamente a lista do acervo. A pagina institucional separada
e o FAQ foram adiados para priorizar o fluxo de consulta, detalhe e contato.
O FAQ continua previsto em FR-045, mas ainda nao tem rota. A politica publica
de privacidade tambem nao tem rota; o aviso apresentado durante o cadastro e
uma superficie distinta.

## 4. Fluxo de entrada e cadastro

`/entrar` atende a Comunidade. A entrada usa CPF e senha; o cadastro confirma
o telefone por codigo antes de criar o perfil. A recuperacao de senha continua
sendo um requisito de produto, mas ainda nao tem fluxo implementado.

1. Perguntar se a pessoa ja possui cadastro.
2. Para entrada, pedir CPF e depois senha, em telas simples.
3. Para cadastro, coletar nome, CPF, telefone confirmado e senha com pelo menos oito caracteres. Permitir mostrar a senha e usar uma frase-senha. Nao pedir endereco residencial nessa etapa; se o termo exigir o dado, pedi-lo mais tarde no fluxo do emprestimo e explicar por que.
4. Exibir aviso de privacidade antes do aceite.
5. Mostrar sucesso em linguagem direta e oferecer um proximo passo.
6. A recuperacao deve indicar o destino de forma parcialmente mascarada sem revelar conta existente a terceiros.

O teclado deve ser numerico para CPF, telefone, CEP e codigo. CPF com ou sem pontuacao deve ser aceito.

## 5. Painel do Companheiro

O painel ainda nao faz parte das rotas atuais. Quando implementado, deve mostrar
quantidades agregadas **Disponível para empréstimo**, emprestadas, em conserto e
com prazo vencido. Deve permitir ver o conjunto dos bancos ou filtrar um banco,
e destacar falta total ou estoque abaixo do minimo configurado. Os valores
tecnicos usados para agrupar ficam ocultos; seus rotulos estao em
[Regras de Negocio](../produto/regras-de-negocio.md#4-situacao-tecnica-e-rotulos-de-tela).

O painel nunca mostra nome, nem mesmo primeiro nome, bairro, contato ou linha individual de emprestimo de uma pessoa atendida.

## 6. Fluxo do administrador

Atualmente, a area administrativa tem somente `/admin/entrar` e
`/admin/contatos`. As instrucoes abaixo descrevem os fluxos de acervo previstos
para implementacao; ainda nao ha telas de emprestimo, devolucao, entrada,
lembretes, estoque ou busca de pessoas.

Quando as demais telas forem implementadas, o inicio do administrador deve
priorizar as tarefas cotidianas: contatos recebidos, emprestimo, devolucao,
entrada, lembretes, estoque e busca de pessoa. Tarefas de organizacao menos
frequentes podem ficar em uma secao separada.

Na busca, o administrador pode informar nome ou CPF para localizar uma pessoa no fluxo de emprestimo ou devolucao. O resultado apresenta apenas os dados necessarios e o historico do proprio banco. Se a pessoa nao tiver conta e precisar de ajuda, o administrador pode iniciar o cadastro assistido; a pessoa confirma o telefone e recebe o aviso de privacidade, sem o administrador criar ou conhecer a senha.

### Registrar entrada

O formulario pede tipo, quantidade, origem e condicao. A foto e opcional; largura so e pedida para os tipos que precisam dessa medida.

### Registrar emprestimo ou doacao definitiva

O administrador localiza a pessoa, escolhe um ou mais equipamentos com o rotulo **Disponível para empréstimo** no proprio banco, informa se o equipamento e para a propria pessoa ou para outro paciente (somente o nome), escolhe a data sugerida ou outra data e confere o documento antes de gerar o PDF. Se nao houver data de devolucao, informa uma data de revisao.

### Registrar devolucao

O administrador localiza a pessoa, seleciona os equipamentos que voltaram e registra se cada um esta pronto para uso, precisa de conserto ou nao tem condicao de uso. A devolucao pode ser parcial.

### Acompanhar devolucoes

A lista inclui devolucoes previstas para os proximos sete dias, para hoje, vencidas e datas de revisao. O administrador pode abrir uma mensagem pronta ou ligar e registrar o resultado; tres tentativas sem resposta aumentam a prioridade visual.

Operacoes de estoque devem ter confirmacao, resumo dos dados e tela de sucesso. Em celular, quadros tipo kanban devem oferecer botao `Mover para` em vez de exigir arrastar e soltar.

## 7. Estados de interface

Toda tela que depende de dados remotos deve definir:

- carregamento com indicador e texto;
- sucesso vazio, com explicacao do que fazer;
- falha recuperavel, com acao para tentar novamente;
- falta de permissao, sem revelar a existencia de dados privados;
- ausencia de conexao ou interrupcao durante uma gravacao;
- prevencao de envio duplicado enquanto uma acao estiver em andamento.

## 8. Testes de usabilidade

Antes do lancamento, testar com pelo menos cinco pessoas com mais de 60 anos e dois administradores de banco. O roteiro cobre encontrar equipamento, criar conta, entrar, recuperar senha, abrir WhatsApp, registrar entrada, emprestimo e devolucao. A pessoa deve concluir sem ajuda, respeitando os tempos em [criterios de aceite](../produto/criterios-de-aceite.md).
