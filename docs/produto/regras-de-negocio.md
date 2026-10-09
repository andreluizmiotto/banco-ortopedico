# Regras de Negocio

As regras deste documento sao normativas para o dominio. Regras de autorizacao tecnica e isolamento de dados estao em [autenticacao e autorizacao](../arquitetura/autenticacao-e-autorizacao.md).

## 1. Entidades, bancos e locais

- O produto apresenta um catalogo unico, mas cada banco conserva propriedade, atendimento, documentos e decisoes sobre o proprio acervo.
- O MVP considera quatro bancos: Boa Vista, Tres Vendas, Casa da Amizade e Erechim, atendidos em tres locais fisicos. Um banco pode funcionar sem local fixo e usar outro local como apoio.
- Entidades da Familia Rotaria sem banco podem existir para vincular companheiros e administradores futuros.
- Uma entidade pode funcionar sem local fixo.
- Um local pode atender mais de uma entidade.
- Propriedade e localizacao fisica sao atributos diferentes. Mover um equipamento para outro local nao muda seu dono.
- Enderecos, coordenadas, horarios e telefones de producao devem ser cadastrados somente por perfil autorizado. Este repositorio nao contem esses valores.

## 2. Tipos e unidades de equipamento

Tipo de equipamento e o conceito exibido para a comunidade. Equipamento fisico e a unidade patrimonial controlada por um banco.

Tipos iniciais:

| Sigla | Tipo | Regra especial |
|---|---|---|
| CM | Cama hospitalar | Sem atributo adicional no MVP |
| CO | Colchao para cama hospitalar | Pode receber descricao especifica |
| CR | Cadeira de rodas | Largura aberta em centimetros |
| CI | Cadeira infantil ou adaptada | Pode ser doacao definitiva |
| CB | Cadeira de banho | Largura aberta em centimetros |
| AN | Andador | Disponibilidade agregada |
| MU | Muletas | Unidade de controle e par |
| BO | Bota ortopedica | Disponibilidade agregada |
| TI | Tipoia de braco | Disponibilidade agregada |
| SS | Suporte para soro | Disponibilidade agregada |
| AE | Assento sanitario elevado | Disponibilidade agregada |
| BA | Banheira ou apoio para banho | Disponibilidade agregada |
| OU | Outros | Exige descricao do administrador |
| PE | Peruca | Desativado ate decisao especifica |

O administrador geral pode criar, ordenar, renomear, desativar e configurar tipos. Desativar um tipo nao apaga o historico.

A ordem inicial do catalogo deve priorizar cadeira de rodas, cama hospitalar, cadeira de banho, andador e muletas. O administrador geral pode ajustar a ordem conforme a procura observada.

Muletas devem ser controladas como par no catalogo e no termo. Se parte do par for perdida ou danificada, o administrador deve registrar a ocorrencia e retirar o par da disponibilidade ate regularizacao.

## 3. Controle inicial e inventario

O sistema deve suportar dois modos de controle:

1. **Contagem por tipo**: uma linha representa uma quantidade agregada antes do inventario individual.
2. **Controle individual**: cada unidade possui codigo, fotos opcionais, situacao e historico.

A carga inicial pode usar contagem por tipo. Na fase de inventario, cada unidade deve ser identificada, fotografada quando aplicavel, medida quando necessario e receber codigo. A migracao deve preservar o total e registrar divergencias, nunca apagar silenciosamente a contagem anterior.

Cada banco pode definir um minimo opcional de unidades disponiveis por tipo. O painel indica um tipo como indisponivel quando nenhum banco tem unidades disponiveis e indica estoque baixo para o banco cuja quantidade esteja abaixo do proprio minimo. Sem minimo configurado, so se aplica o alerta de indisponibilidade total.

Formato sugerido para codigo individual: `SIGLA_ENTIDADE + SIGLA_TIPO + SEQUENCIAL_DE_4_DIGITOS`, por exemplo `BVCR0001`. O codigo nao e exibido para a comunidade.

## 4. Situacao do equipamento

| Situacao | Significado | Conta como disponivel? |
|---|---|---|
| `em_casa` | Disponivel no local do banco | Sim |
| `separado` | Reservado informalmente, aguardando retirada | Nao |
| `emprestado` | Em posse de um responsavel | Nao |
| `em_conserto` | Quebrado, incompleto ou aguardando reparo | Nao |
| `doado_definitivo` | Saiu do acervo sem previsao de retorno | Nao |
| `baixado` | Perdido, inutilizado ou nao devolvido | Nao |

Transicoes normais:

- `em_casa` -> `separado`, `emprestado`, `em_conserto`, `doado_definitivo` ou `baixado`;
- `separado` -> `em_casa` ou `emprestado`;
- `emprestado` -> `em_casa`, `em_conserto` ou `baixado`;
- `em_conserto` -> `em_casa` ou `baixado`.

`doado_definitivo` e `baixado` sao estados terminais para administradores de banco. Correcao posterior exige administrador geral, justificativa e auditoria.

Toda transicao deve registrar ator, data, situacao anterior, situacao nova e motivo quando aplicavel.

## 5. Emprestimos

- O responsavel e a pessoa cadastrada que assina o termo e responde pela devolucao.
- O paciente e a pessoa que usara o equipamento. No MVP, quando for diferente do responsavel, guarda-se somente o nome informado.
- O cadastro da comunidade e destinado a um adulto responsavel. O paciente menor pode ser identificado pelo nome, sem coletar diagnostico; regras de representacao e assinatura por menor precisam de validacao juridica antes da producao.
- O cadastro inicial nao exige endereco residencial. O endereco so pode ser coletado no fluxo de emprestimo se o modelo de termo aprovado exigir, explicando a finalidade a pessoa.
- No fluxo de emprestimo ou devolucao do proprio banco, o administrador pode localizar por nome ou CPF e reutilizar a conta global existente, sem criar uma conta duplicada. A busca retorna apenas os dados minimos para a operacao e o historico do proprio banco; nunca revela o historico detalhado de outro banco.
- Quando a pessoa nao consegue se cadastrar sozinha, o administrador pode iniciar um cadastro assistido. A pessoa confirma o telefone com um codigo e recebe o aviso de privacidade; o administrador nao define nem visualiza a senha.
- Um emprestimo pode conter mais de um tipo ou unidade.
- Um equipamento individual nao pode estar em dois emprestimos ativos.
- O prazo nao e global: cada banco configura uma sugestao e o administrador pode altera-la.
- Os valores iniciais de prazo sao configuracao de cada banco, nao uma regra global. As propostas atuais sao seis meses para a Casa da Amizade, 90 dias para Tres Vendas, data negociada para Boa Vista e definicao pendente para Erechim; cada banco deve confirmar seu valor antes do uso real.
- A opcao sem data definida exige uma data de revisao. O formulario pode sugerir 90 dias, mas a data e editavel; a revisao gera lembrete, nao cobranca automatica.
- Renovacao deve preservar historico de datas e, quando o modelo exigir, gerar novo termo.
- Se aprovado juridicamente, o sistema pode mostrar um alerta nao bloqueante quando houver tres ou mais emprestimos ativos ou algum emprestimo vencido ha mais de 30 dias em qualquer banco. O alerta nao informa banco, equipamento, datas ou historico; sem aprovacao, essa consulta cruzada fica desativada.
- A decisao final sobre conceder emprestimo pertence ao administrador autorizado.

## 6. Contato por WhatsApp

- O botao aparece mesmo quando a quantidade disponivel e zero; o responsavel pode orientar sobre alternativa ou fila informal.
- Bancos com disponibilidade aparecem antes dos demais. A ordenacao entre bancos disponiveis pode variar para evitar favorecimento sistematico.
- O numero de destino vem da configuracao autorizada da entidade ou do responsavel ativo; a comunidade nao o digita.
- O sistema abre WhatsApp ou WhatsApp Web, mas nao envia mensagem nem le conversas.
- A mensagem pre-preenchida deve conter apenas os dados necessarios para o atendimento e um codigo de contato. Nunca deve conter CPF, nome do paciente, endereco, diagnostico ou motivo de saude; a pessoa ou o administrador pode revisar o texto antes de enviar.
- Mensagens de lembrete devem usar somente campos dinamicos aprovados. O administrador confirma o destinatario e envia pelo proprio WhatsApp; o sistema nao dispara a mensagem.
- Cada contato guarda entidade, tipo, origem, ator autenticado, destinatario efetivo, data, hora e situacao.
- Toques da mesma pessoa para o mesmo tipo e banco em uma janela de 30 minutos devem ser tratados como um contato, para evitar duplicidade.
- Contato sem acao por 48 horas deve ser destacado ao administrador.
- Contatos que nao viraram emprestimo devem ser eliminados conforme a politica de retencao.

Situacoes permitidas: `novo`, `atendido`, `virou_emprestimo` e `sem_retorno`.

## 7. Lembretes

O sistema deve gerar a lista de hoje para:

- emprestimos com devolucao prevista em sete dias;
- emprestimos com devolucao prevista para hoje;
- emprestimos vencidos;
- emprestimos sem data definida cuja revisao venceu.

Para cada lembrete, o administrador pode abrir mensagem pronta, ligar, registrar que falou, registrar que nao atendeu ou definir nova data. Tres tentativas sem resposta aumentam a prioridade visual, sem bloquear outras operacoes.

Os textos iniciais e os campos permitidos estao em [mensagens padrao](mensagens-padrao.md). O administrador deve confirmar o destinatario e revisar a mensagem no WhatsApp antes de envia-la.

## 8. Locais e mapa

Cada local possui nome, endereco, referencia textual, coordenadas fixadas manualmente, horario e foto opcional da fachada.

- O mapa deve usar as coordenadas salvas, nao uma nova geocodificacao do endereco a cada acesso.
- No MVP, o botao de rota pode abrir um link externo para o mapa.
- Enderecos e telefones ficam disponiveis somente depois da autenticacao.
- Para banco itinerante, o cartao deve informar "Local combinado pelo WhatsApp" e, se aplicavel, um local de apoio.

## 9. Documentos

- Cada banco pode manter seu proprio modelo de termo.
- O modelo deve ser versionado e associado a entidade e tipo de documento.
- O termo de emprestimo deve identificar cedente, responsavel, paciente, equipamentos, estado, datas e assinaturas.
- O termo de doacao definitiva nao deve apresentar obrigacao de devolucao.
- Uso de imagem nunca deve ser uma clausula obrigatoria do termo. Deve ser autorizacao separada, especifica, opcional e revogavel.
- A revisao juridica deve ocorrer antes de publicar qualquer modelo em producao.

## 10. Quadros administrativos

### Situacao dos equipamentos

Colunas: `Em casa`, `Separado`, `Emprestado`, `Em conserto`, `Doado em definitivo`, `Baixado`.

Movimentos para `Emprestado` e `Em casa` devem abrir os fluxos de emprestimo e devolucao, respectivamente. Os demais podem ser feitos diretamente, com confirmacao e motivo quando necessario.

### Dono e local

O administrador geral pode transferir propriedade com motivo. O administrador do banco pode solicitar ou registrar troca de local conforme sua permissao, sem alterar o dono.

### Acessos

Colunas: `Aguardando liberacao`, `Companheiro`, `Administrador do banco`, `Sem acesso`.

Retirar acesso nao exclui a conta de comunidade nem o historico legalmente necessario.

## 11. Integridade

- Quantidade disponivel nunca pode ser negativa.
- Equipamento individual so pode estar em um emprestimo ativo.
- Devolucao parcial deve deixar o emprestimo com situacao `parcial` ate encerramento.
- Uma entidade inativa nao pode receber novos emprestimos, mas seu historico deve permanecer consultavel por perfis autorizados.
- Alteracoes de situacao, dono, local, permissao e documento devem ser auditaveis.
- Regras de escopo entre bancos devem ser reforcadas pelo banco de dados com RLS.
