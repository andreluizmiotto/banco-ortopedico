# Documentos Gerados pelo Sistema

Este documento descreve o contrato entre o dominio e o gerador de PDFs. Os textos juridicos finais devem ser revisados antes do uso em producao.

## 1. Principios

- O sistema gera um PDF preenchido a partir de um modelo versionado.
- O modelo pertence a uma entidade e a um tipo de documento.
- A versao utilizada deve ficar registrada no emprestimo ou na doacao.
- O PDF gerado e um artefato privado, acessivel somente aos perfis autorizados.
- O sistema nao deve persistir uma copia de modelo sem a sua versao e data de ativacao.
- Os modelos publicos deste repositorio devem conter apenas placeholders e dados sinteticos.

## 2. Tipos de documento

| Tipo | Uso | MVP |
|---|---|---|
| `termo_emprestimo` | Formaliza cessao gratuita e devolucao | Sim |
| `termo_doacao` | Formaliza doacao definitiva | Sim |
| `autorizacao_imagem` | Autoriza usos especificos de foto ou video | Sim, opcional |
| `termo_renovacao` | Novo termo quando a regra da entidade exigir | Pode usar o modelo de emprestimo no MVP |

## 3. Campos disponiveis

### Entidade

- nome oficial e nome publico;
- identificador juridico, quando a entidade realmente exigir no termo;
- endereco institucional cadastrado;
- telefone institucional;
- logo autorizado.

### Responsavel pelo emprestimo

- nome completo;
- CPF;
- RG somente quando exigido pelo modelo aprovado;
- endereco e telefone somente quando necessarios ao termo.

Esses campos nao sao todos exigidos na criacao da conta. O endereco so deve ser solicitado no fluxo do emprestimo quando o modelo aprovado realmente precisar dele.

### Paciente

- nome informado pelo responsavel;
- nenhum diagnostico, doenca, receita ou motivo medico.

### Operacao

- tipos, quantidades e codigos dos equipamentos;
- estado na saida e na devolucao;
- data de retirada;
- data prevista ou data de revisao;
- tipo de saida;
- administrador que realizou a entrega;
- bloco de devolucao.

## 4. Modelo base de emprestimo

O modelo base deve conter, em linguagem juridicamente aprovada:

1. identificacao do cedente e do responsavel;
2. identificacao opcional do paciente;
3. lista de equipamentos e estado na saida;
4. gratuidade e proibicao de venda, aluguel ou repasse sem autorizacao;
5. uso adequado e devolucao;
6. possibilidade de prorrogacao por concordancia do banco;
7. comunicacao de perda ou dano;
8. foro e demais clausulas aprovadas;
9. aviso de privacidade;
10. campos de assinatura e devolucao.

O texto final nao deve carregar autorizacao generica ou irrevogavel de uso de nome, voz ou imagem.

## 5. Termo de doacao definitiva

O termo de doacao deve reutilizar a identificacao da entidade, pessoa e equipamento, mas substituir as regras de devolucao por:

- transferencia definitiva conforme a decisao do banco;
- proibicao de venda ou repasse quando juridicamente aplicavel;
- registro de data, recebedor e administrador;
- aviso de privacidade adequado.

## 6. Autorizacao de imagem

A autorizacao deve ser gerada separadamente do termo e conter:

- finalidade clara;
- entidade responsavel;
- usos selecionaveis individualmente;
- opcionalidade expressa;
- informacao de que a recusa nao prejudica o atendimento;
- possibilidade de revogacao;
- data, versao do texto e assinatura.

Para criancas ou adolescentes, a aplicacao deve seguir a revisao juridica especifica e nao exibir nome completo em divulgacao.

## 7. Geracao e armazenamento

- A geracao deve ocorrer no servidor ou em funcao protegida, nunca com chave privilegiada no navegador.
- O arquivo deve ser gravado em bucket privado com caminho que nao contenha CPF ou nome.
- O download deve usar URL assinada com validade curta e verificar autorizacao antes de gerar o link.
- O sistema deve oferecer impressao no MVP.
- Envio pelo WhatsApp pode apenas abrir uma mensagem pre-preenchida no MVP; nao deve fazer upload publico nem envio automatico.
- Foto do termo assinado e opcional e segue a mesma politica de retencao do documento.

## 8. Revisao obrigatoria

Antes do primeiro uso real, revisar:

- texto de privacidade;
- bases legais e responsabilidades entre entidades;
- clausulas de cessao, emprestimo e doacao;
- necessidade de RG, data de nascimento e endereco em cada modelo;
- regras para menores de idade;
- permissao de uso dos logos.
