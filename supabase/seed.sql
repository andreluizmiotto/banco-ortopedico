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
  ('SYN-C', 'Entidade Sintética C', true, true),
  ('SYN-ROTARY-BOA-VISTA', 'Rotary Boa Vista (sintético)', true, true)
on conflict (code) do update
set
  public_name = excluded.public_name,
  is_bank = excluded.is_bank,
  is_active = excluded.is_active;

-- GoTrue's email/password lookup uses the zero instance UUID.
-- Local-only synthetic credentials; do not use this identity outside local development.
insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  email_confirmed_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change,
  encrypted_password,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values (
  '00000000-0000-0000-0000-000000000000',
  '90000000-0000-4000-8000-000000000001',
  'authenticated',
  'authenticated',
  'admin-rotary-boa-vista@banco-ortopedico.test',
  clock_timestamp(),
  '',
  '',
  '',
  '',
  extensions.crypt(
    'Rotary-Local-Synthetic-2026!',
    extensions.gen_salt('bf')
  ),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb,
  clock_timestamp(),
  clock_timestamp()
)
on conflict (id) do update
set
  instance_id = excluded.instance_id,
  aud = excluded.aud,
  role = excluded.role,
  email = excluded.email,
  email_confirmed_at = excluded.email_confirmed_at,
  confirmation_token = excluded.confirmation_token,
  recovery_token = excluded.recovery_token,
  email_change_token_new = excluded.email_change_token_new,
  email_change = excluded.email_change,
  encrypted_password = excluded.encrypted_password,
  raw_app_meta_data = excluded.raw_app_meta_data,
  raw_user_meta_data = excluded.raw_user_meta_data,
  updated_at = excluded.updated_at;

insert into catalog.user_roles (id, user_id, role, entity_id, is_active)
select
  '90000000-0000-4000-8000-000000000002',
  '90000000-0000-4000-8000-000000000001',
  'admin_banco',
  entity.id,
  true
from catalog.entities as entity
where entity.code = 'SYN-ROTARY-BOA-VISTA'
on conflict (id) do update
set
  user_id = excluded.user_id,
  role = excluded.role,
  entity_id = excluded.entity_id,
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

-- Synthetic acervo for the administrative inventory panel; no real inventory data.
insert into catalog.equipment_units (
  id,
  equipment_type_code,
  owner_entity_id,
  storage_location_id,
  situacao,
  visible_code,
  entry_origin
)
select
  fixture.id::uuid,
  fixture.equipment_type_code,
  entity.id,
  location.id,
  fixture.situacao::catalog.equipment_situation,
  fixture.visible_code,
  fixture.entry_origin::catalog.equipment_entry_origin
from (
  values
    ('10000000-0000-4000-8000-000000000001', 'CR', 'disponivel', 'BVCR0001', 'doacao'),
    ('10000000-0000-4000-8000-000000000002', 'CR', 'reservado', 'BVCR0002', 'compra'),
    ('10000000-0000-4000-8000-000000000003', 'CM', 'emprestado', 'BVCM0001', 'retorno_conserto'),
    ('10000000-0000-4000-8000-000000000004', 'AN', 'manutencao', null, 'devolucao_outro_banco'),
    ('10000000-0000-4000-8000-000000000005', 'MU', 'doado', 'BVMU0001', 'doacao'),
    ('10000000-0000-4000-8000-000000000006', 'CB', 'baixado', null, 'compra')
) as fixture(id, equipment_type_code, situacao, visible_code, entry_origin)
join catalog.entities as entity on entity.code = 'SYN-ROTARY-BOA-VISTA'
left join catalog.pontos_atendimento as location on location.code = 'SYN-SHARED'
on conflict (id) do update
set
  equipment_type_code = excluded.equipment_type_code,
  owner_entity_id = excluded.owner_entity_id,
  storage_location_id = excluded.storage_location_id,
  situacao = excluded.situacao,
  visible_code = excluded.visible_code,
  entry_origin = excluded.entry_origin;
