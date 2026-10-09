# Requisitos de Dados e Privacidade

Este documento converte os requisitos de privacidade do produto em controles verificaveis. A interpretacao juridica, os papeis de controlador/operador e os textos finais precisam de revisao juridica antes do lancamento.

## 1. Finalidade e minimizacao

Dados pessoais podem ser usados somente para cadastro, autenticacao, atendimento, emprestimo, devolucao, prestacao de contas autorizada e cumprimento de obrigacoes definidas pelo projeto.

- Coletar somente campos necessarios ao fluxo e ao modelo de termo aprovado.
- Nao exigir endereco residencial na criacao da conta. Coletar esse dado no fluxo de emprestimo somente quando o modelo aprovado exigir, com finalidade informada.
- Mensagens iniciadas pelo WhatsApp nao devem conter CPF, nome do paciente, endereco, diagnostico ou outro dado nao necessario; usar apenas campos dinamicos aprovados e permitir revisao antes do envio.
- Nao criar campo livre para diagnostico, doenca, receita, laudo ou motivo medico.
- O paciente pode ser pessoa diferente do responsavel; no MVP, armazenar apenas o nome quando necessario.
- Nao usar dados para publicidade, campanha, politica ou finalidade incompativel.
- Evitar analytics, pixels e identificadores de rastreamento. Qualquer metrica deve ser agregada e aprovada.

## 2. Classificacao e visibilidade

| Classe | Exemplos | Acesso |
|---|---|---|
| Publica | Nome e descricao do tipo, disponibilidade agregada | Visitante e perfis autenticados |
| Autenticada | Endereco e contato operacional aprovado | Somente apos autenticacao e conforme autorizacao |
| Pessoal | CPF, telefone, endereco residencial, emprestimos de uma pessoa | A propria pessoa e operadores estritamente autorizados |
| Operacional restrita | Termo assinado, fotos, auditoria, credenciais e codigos | Somente servico e papeis explicitamente autorizados |

O papel Companheiro nao recebe dados pessoais de terceiros. O painel deve usar views, consultas agregadas ou DTOs que nao selecionem esses campos; tambem nao deve exibir primeiro nome, bairro ou linhas individuais de emprestimo, pois esses elementos podem identificar pessoas em uma comunidade pequena. Dados proprios so podem ser consultados por uma funcao de autoatendimento autorizada pelo papel Comunidade.

## 3. Direitos da pessoa

O produto deve oferecer caminhos para a pessoa:

- consultar os dados e emprestimos proprios;
- corrigir nome, telefone verificado e endereco;
- baixar uma copia dos dados;
- solicitar exclusao;
- cancelar autorizacao de imagem.

Exclusao deve considerar emprestimo ativo, obrigacoes de retencao, anonimizacao e auditoria. A interface deve explicar o resultado antes da confirmacao.

## 4. Consentimento e transparencia

- Registrar versao e data do aviso/aceite aplicavel ao cadastro.
- Mudanca material na politica deve ser apresentada de forma clara.
- Uso de imagem e separado, opcional, por finalidade e revogavel.
- Recusa de uso de imagem nao afeta o atendimento.
- Nao confundir aceite de termos de uso, aviso de privacidade e autorizacao de imagem.

## 5. Retencao

Os prazos abaixo sao requisitos de produto derivados do levantamento e precisam de aprovacao juridica antes de serem automatizados:

| Dado | Prazo proposto |
|---|---|
| Cadastro sem emprestimo e sem acesso | Dois anos sem acesso; notificar antes da exclusao, se houver canal confirmado |
| Emprestimo encerrado | Cinco anos apos devolucao; depois anonimizar ou eliminar conforme aprovacao |
| Contato que nao virou emprestimo | Doze meses; depois eliminar |
| Codigo de verificacao | Ate 24 horas, ou menos conforme o fluxo |
| Foto de termo assinado | Mesmo prazo definido para o termo associado |
| Auditoria | Dois anos como prazo inicial, sujeito a validacao |
| Revogacao de imagem | Manter prova da revogacao; interromper novos usos |

Anonimizacao precisa remover identificadores diretos e impedir reidentificacao razoavel. Nao manter endereco residencial ou telefone em estatistica agregada.

## 6. Seguranca

- HTTPS obrigatorio.
- Credenciais e sessoes sob responsabilidade do Supabase Auth.
- RLS para toda tabela exposta a cliente.
- Buckets privados para documentos e fotos operacionais.
- Links assinados curtos e emitidos depois de checar permissao.
- Codigos de verificacao guardados apenas com hash, validade e limite de tentativas.
- Limites de tentativa para senha, recuperacao e envio de codigo.
- Auditoria para alteracoes de pessoa, emprestimo, equipamento e permissao.
- Backup automatizado e teste de restauracao.
- Segredos mantidos em variaveis de ambiente do servidor ou gerenciador de segredos; nunca no Git.
- Hospedagem de dados no Brasil e preferencia, sujeita a disponibilidade e revisao dos contratos do provedor.

## 7. Incidentes e responsabilidade

- Definir por escrito controlador, operadores, encarregado e canal de contato antes da producao.
- Aprovar juridicamente a necessidade e a base para alertas sobre emprestimos em outros bancos. Se aprovados, esses alertas devem revelar apenas a sinalizacao minima definida pelo produto, sem expor registros ou detalhes de outra entidade.
- Definir processo de triagem, contencao, registro e comunicacao de incidente.
- Meta operacional inicial: iniciar avaliacao em ate 48 horas; obrigacoes e prazos legais devem seguir orientacao juridica vigente.
- Documentar subprocessadores e transferencias internacionais relevantes.

## 8. Dados publicos de desenvolvimento

Esta pasta e apropriada para repositorio publico somente depois de revisao. Fixtures, seeds, screenshots, exemplos e logs devem ser sinteticos. Nunca importar para o Git os scans, fichas, contratos preenchidos, contatos operacionais ou inventario real.
