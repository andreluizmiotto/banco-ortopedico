# Decisions

## Active

### AD-001 - O administrador do banco ajusta qualquer situação no acervo

**Date**: 2026-10-27
**Status**: active

O painel de acervo permite ao `bank_admin` da entidade proprietária mudar uma
unidade para qualquer um dos seis valores de `catalog.equipment_status`,
inclusive a partir de `donated` e `written_off`, que as Regras de Negócio tratam como
terminais para esse papel. Toda mudança grava ator, entidade, unidade, situação
anterior, situação nova e data/hora em `catalog.equipment_unit_change_audit`.

Motivo: o usuário confirmou, em 2026-10-27, que esta é uma tela de gestão e
ajuste de inventário, não o fluxo operacional de empréstimo/devolução. A
alternativa de seguir apenas as transições normais foi oferecida e recusada.

Consequência: as transições normais continuam valendo para os fluxos
operacionais futuros; esta decisão vale somente para `/admin/acervo`.

### AD-002 - Identificador visível livre, nulo e único por banco

**Date**: 2026-10-27
**Status**: active

A coluna `catalog.equipment_units.visible_code` é `text` nulável, editável e
única por `owner_entity_id` quando preenchida. O formato sugerido nas Regras de
Negócio (`BVCR0001`) não é imposto; o campo aceita texto livre de até 64
caracteres e serve para a futura vinculação por QR Code.

Motivo: o usuário definiu texto livre, nulável e editável em 2026-10-27 e
confirmou a unicidade por banco para que o QR futuro resolva uma única unidade.

### AD-003 - Origem da entrada registrada por unidade

**Date**: 2026-10-27
**Status**: active

Cada unidade criada em `/admin/acervo` exige `entry_origin`, um dos valores
`donation`, `purchase`, `repair_return` e `return_from_other_bank` (FR-018). A
coluna é nulável para preservar unidades anteriores, que não têm origem
conhecida; a RPC de criação rejeita origem nula ou fora do conjunto.

Motivo: o usuário confirmou origem obrigatória no cadastro em 2026-10-27. Não há
backfill: registros anteriores permanecem sem origem e a interface os apresenta
sem esse dado.

### AD-004 - Estoque mínimo e alerta de estoque baixo ficam fora deste recorte

**Date**: 2026-10-27
**Status**: active

O painel de `/admin/acervo` mostra contagens derivadas por situação para as seis
situações. Não há cadastro de mínimo por entidade e tipo nem destaque de estoque
abaixo do mínimo nesta tarefa; FR-025 permanece parcialmente coberto.

Motivo: não existe tabela de mínimo configurado e o usuário confirmou o recorte
somente com contagens em 2026-10-27. A alternativa de incluir o mínimo foi
oferecida e recusada.

### AD-006 - O estado do equipamento no termo é uma anotação livre por empréstimo

**Date**: 2026-10-28
**Status**: active

As Regras de Negócio §9 exigem que o termo de empréstimo identifique o estado dos
equipamentos, mas nenhuma fonte diz onde esse dado nasce. O termo passa a imprimir
uma anotação opcional de até 200 caracteres, escrita pelo administrador no próprio
empréstimo e repetida sob cada equipamento. Não existe condição por peça nem coluna
nova em `catalog.equipment_units`.

Motivo: o usuário escolheu, em 2026-10-28, "Uma anotação por empréstimo, opcional
(até 200 caracteres)". As alternativas oferecidas e recusadas foram uma condição por
peça com lista fechada, que inventaria uma taxonomia sem fonte, e omitir o estado do
termo, que contraria a seção 9.

### AD-007 - Prazo sugerido provisório de 90 dias em todas as entidades

**Date**: 2026-10-28
**Status**: active

`catalog.entities.loan_suggested_days` recebe 90 dias para as quatro entidades e
passa a ser a sugestão de prazo do fluxo de empréstimo, editável por banco. O prazo
customizado aceita de 1 a 365 dias e a opção sem data de devolução exige data de
revisão, sugerida em 90 dias. O valor por banco continua pendente de confirmação em
`requisitos.md` §8.

Motivo: o usuário escolheu, em 2026-10-28, "Configuração por entidade com 90 dias
padrão; customizado de 1 a 365 dias". Recusadas: tabela separada de configuração de
prazo e sugestão fixa no código, que contraria AC-037.

### AD-008 - A foto do termo assinado fica fora do recorte de empréstimo

**Date**: 2026-10-28
**Status**: active

O recorte de empréstimo guarda apenas o PDF gerado pelo sistema, em bucket privado,
entregue por rota autenticada. O anexo da foto do termo assinado previsto em
`requisitos.md` §3 e FR-036 fica para um recorte próprio, junto com a retenção de
documentos.

Motivo: o usuário escolheu, em 2026-10-28, "Fora deste recorte: o termo gerado é
privado; a foto assinada fica para outro recorte". Recusadas: incluir o envio da foto
agora, que ampliaria o escopo com upload e prova de autorização, e não guardar arquivo
nenhum do termo.

### AD-009 - O fluxo de empréstimo não coleta endereço nesta fase

**Date**: 2026-10-28
**Status**: active

Nem a tela nem o termo têm campo de endereço. Quando a revisão jurídica definir um
modelo que exija o dado, isso volta como recorte próprio, com finalidade explicada,
quem pode ver e auditoria de leitura.

Motivo: o usuário escolheu, em 2026-10-28, "Não coletar nesta fase; sem campo de
endereço". Recusados: um campo opcional no empréstimo e coletar endereço sempre, que
contraria `requisitos.md` §2.

### AD-010 - A área administrativa passa a ter as rotas de empréstimo

**Date**: 2026-10-28
**Status**: active

`docs/ux/acessibilidade-e-fluxos.md` §3 e §6 descrevem a área administrativa com
apenas `/admin/entrar` e `/admin/contatos`. A área passa a ter
`/admin/emprestimos`, `/admin/emprestimos/novo` e `/admin/emprestimos/[codigo]`, com
o link `Empréstimos` na navegação administrativa.

Motivo: o recorte aprovado em 2026-10-28 exige o fluxo de empréstimo nas rotas
administrativas. O documento de UX descreve as rotas existentes e não é aprovado como
lista fechada; a atualização do documento fica pendente.

### AD-011 - O empréstimo tem código público de 12 caracteres hexadecimais

**Date**: 2026-10-28
**Status**: active

Cada empréstimo recebe `codigo text` único no formato `^[A-F0-9]{12}$`, igual ao
código de `catalog.community_contacts`. O código aparece no termo, no caminho das
rotas `/admin/emprestimos/[codigo]` e `/admin/emprestimos/[codigo]/termo`, e serve à
futura devolução sem expor nome, CPF ou telefone em URL.

Motivo: nenhuma fonte define identificador de empréstimo, e o fluxo precisa de um
identificador sem dado pessoal para tela, termo e URL. O padrão já existe no projeto.
