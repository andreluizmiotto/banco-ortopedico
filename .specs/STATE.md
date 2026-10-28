# Decisions

## Active

### AD-001 - O administrador do banco ajusta qualquer situação no acervo

**Date**: 2026-10-27
**Status**: active

O painel de acervo permite ao `admin_banco` da entidade proprietária mudar uma
unidade para qualquer um dos seis valores de `catalog.equipment_situation`,
inclusive a partir de `doado` e `baixado`, que as Regras de Negócio tratam como
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
`doacao`, `compra`, `retorno_conserto` e `devolucao_outro_banco` (FR-018). A
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
