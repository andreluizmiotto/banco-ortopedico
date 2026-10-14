insert into catalog.equipment_types (code, name, is_active, display_order)
values
  ('CR', 'Cadeira de rodas', true, 1),
  ('CM', 'Cama hospitalar', true, 2),
  ('CB', 'Cadeira de banho', true, 3),
  ('AN', 'Andador', true, 4),
  ('MU', 'Muletas', true, 5),
  ('CO', 'Colchão para cama hospitalar', true, 6),
  ('CI', 'Cadeira infantil ou adaptada', true, 7),
  ('BO', 'Bota ortopédica', true, 8),
  ('TI', 'Tipoia de braço', true, 9),
  ('SS', 'Suporte para soro', true, 10),
  ('AE', 'Assento sanitário elevado', true, 11),
  ('BA', 'Banheira ou apoio para banho', true, 12),
  ('OU', 'Outros', true, 13),
  ('PE', 'Peruca', false, 14)
on conflict (code) do update
set
  name = excluded.name,
  is_active = excluded.is_active,
  display_order = excluded.display_order;

-- Synthetic development fixtures only; no production inventory is loaded.
insert into catalog.entities (code, public_name, is_bank, is_active)
values
  ('SYN-A', 'Entidade Sintética A', true, true),
  ('SYN-B', 'Entidade Sintética B', true, true),
  ('SYN-C', 'Entidade Sintética C', true, true)
on conflict (code) do update
set
  public_name = excluded.public_name,
  is_bank = excluded.is_bank,
  is_active = excluded.is_active;

insert into catalog.pontos_atendimento (code, name)
values ('SYN-SHARED', 'Ponto Sintetico Compartilhado')
on conflict (code) do update
set name = excluded.name;

insert into catalog.equipment_units (
  id,
  equipment_type_code,
  owner_entity_id,
  storage_location_id,
  situacao
)
select
  fixture.id::uuid,
  fixture.equipment_type_code,
  entity.id,
  location.id,
  fixture.situacao::catalog.equipment_situation
from (
  values
    ('00000000-0000-4000-8000-000000000001', 'CR', 'SYN-A', 'disponivel'),
    ('00000000-0000-4000-8000-000000000002', 'CR', 'SYN-A', 'disponivel'),
    ('00000000-0000-4000-8000-000000000003', 'CR', 'SYN-A', 'disponivel'),
    ('00000000-0000-4000-8000-000000000004', 'CR', 'SYN-A', 'reservado'),
    ('00000000-0000-4000-8000-000000000005', 'CR', 'SYN-A', 'emprestado'),
    ('00000000-0000-4000-8000-000000000006', 'CR', 'SYN-A', 'manutencao'),
    ('00000000-0000-4000-8000-000000000007', 'CR', 'SYN-A', 'doado'),
    ('00000000-0000-4000-8000-000000000008', 'CR', 'SYN-A', 'baixado'),
    ('00000000-0000-4000-8000-000000000009', 'CR', 'SYN-B', 'disponivel'),
    ('00000000-0000-4000-8000-000000000010', 'CR', 'SYN-B', 'disponivel'),
    ('00000000-0000-4000-8000-000000000011', 'CR', 'SYN-C', 'reservado')
) as fixture(id, equipment_type_code, entity_code, situacao)
join catalog.entities as entity on entity.code = fixture.entity_code
join catalog.pontos_atendimento as location on location.code = 'SYN-SHARED'
on conflict (id) do update
set
  equipment_type_code = excluded.equipment_type_code,
  owner_entity_id = excluded.owner_entity_id,
  storage_location_id = excluded.storage_location_id,
  situacao = excluded.situacao;
