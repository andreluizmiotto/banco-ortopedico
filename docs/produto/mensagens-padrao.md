# Mensagens Padrao

Estes textos sao pontos de partida para o MVP. O administrador geral pode revisar e
editar a redacao, mas nao pode incluir novos campos dinamicos sem aprovacao.

As mensagens apenas abrem o WhatsApp com o texto preenchido. A pessoa ou o
administrador revisa e envia a mensagem; o sistema nunca a envia sozinho.

## 1. Contato iniciado pela comunidade

> Ola. Quero conversar sobre um emprestimo de equipamento. Codigo do contato:
> {codigo}.

Campos permitidos: `{codigo}`.

## 2. Lembrete de devolucao

### Sete dias antes

> Ola. Estamos entrando em contato sobre a devolucao do equipamento emprestado.
> A data combinada e {data_prevista}. Se ainda precisar, fale com {entidade} para
> combinar.

Campos permitidos: `{data_prevista}`, `{entidade}`.

### Na data combinada

> Ola. A data combinada para conversar sobre a devolucao do equipamento e hoje.
> Se ainda precisar, fale com {entidade}.

Campos permitidos: `{entidade}`.

### Apos a data combinada

> Ola. Gostariamos de combinar a devolucao ou uma nova data para o equipamento
> emprestado. Fale com {entidade}.

Campos permitidos: `{entidade}`.

### Revisao sem data de devolucao

> Ola. Gostariamos de confirmar se voce ainda precisa do equipamento emprestado.
> Se precisar, fale com {entidade} para combinar.

Campos permitidos: `{entidade}`.

## 3. Limites de privacidade

As mensagens nao devem incluir CPF, nome do paciente, endereco, diagnostico,
motivo de saude, dados de outra entidade ou outros campos que identifiquem uma
pessoa alem do necessario para a conversa. Os textos devem ser revisados no
WhatsApp antes do envio.
