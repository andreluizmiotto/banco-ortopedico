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

-- Development fixtures only. Club names come from the product documentation;
-- every address, phone and e-mail below is fictional and no real inventory,
-- person or CPF is loaded. E-mails use the reserved .test domain.
insert into catalog.entities (code, public_name, is_bank, is_active)
values
  ('ROTARY-BOA-VISTA', 'Banco Ortopédico Rotary Boa Vista', true, true),
  ('ROTARY-TRES-VENDAS', 'Banco Ortopédico Três Vendas', true, true),
  ('ROTARY-CASA-AMIZADE', 'Casa da Amizade — Banco Ortopédico', true, true),
  ('ROTARY-ERECHIM', 'Banco Ortopédico Rotary Erechim', true, true)
on conflict (code) do update
set
  public_name = excluded.public_name,
  is_bank = excluded.is_bank,
  is_active = excluded.is_active;

insert into catalog.storage_locations (code, name)
values
  ('SEDE-BOA-VISTA', 'Sede do Rotary Boa Vista'),
  ('SEDE-TRES-VENDAS', 'Salão comunitário de Três Vendas'),
  ('SEDE-CASA-AMIZADE', 'Casa da Amizade'),
  ('APOIO-ERECHIM', 'Ponto de apoio — Erechim')
on conflict (code) do update
set name = excluded.name;

-- GoTrue's email/password lookup uses the zero instance UUID.
-- Local-only fixture credentials; do not use this identity outside local development.
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
  'admin.boavista@rotary.test',
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
  'bank_admin',
  entity.id,
  true
from catalog.entities as entity
where entity.code = 'ROTARY-BOA-VISTA'
on conflict (id) do update
set
  user_id = excluded.user_id,
  role = excluded.role,
  entity_id = excluded.entity_id,
  is_active = excluded.is_active;

-- Units without a label yet: they exercise the public availability aggregate
-- across the three clubs that share equipment.
insert into catalog.equipment_units (
  id,
  equipment_type_code,
  owner_entity_id,
  storage_location_id,
  status
)
select
  fixture.id::uuid,
  fixture.equipment_type_code,
  entity.id,
  location.id,
  fixture.status::catalog.equipment_status
from (
  values
    ('00000000-0000-4000-8000-000000000001', 'CR', 'ROTARY-BOA-VISTA', 'SEDE-BOA-VISTA', 'available'),
    ('00000000-0000-4000-8000-000000000002', 'CR', 'ROTARY-BOA-VISTA', 'SEDE-BOA-VISTA', 'available'),
    ('00000000-0000-4000-8000-000000000003', 'CR', 'ROTARY-BOA-VISTA', 'SEDE-BOA-VISTA', 'available'),
    ('00000000-0000-4000-8000-000000000004', 'CR', 'ROTARY-BOA-VISTA', 'SEDE-BOA-VISTA', 'reserved'),
    ('00000000-0000-4000-8000-000000000005', 'CR', 'ROTARY-BOA-VISTA', 'SEDE-BOA-VISTA', 'on_loan'),
    ('00000000-0000-4000-8000-000000000006', 'CR', 'ROTARY-BOA-VISTA', 'SEDE-BOA-VISTA', 'under_maintenance'),
    ('00000000-0000-4000-8000-000000000007', 'CR', 'ROTARY-BOA-VISTA', 'SEDE-BOA-VISTA', 'donated'),
    ('00000000-0000-4000-8000-000000000008', 'CR', 'ROTARY-BOA-VISTA', 'SEDE-BOA-VISTA', 'written_off'),
    ('00000000-0000-4000-8000-000000000009', 'CR', 'ROTARY-TRES-VENDAS', 'SEDE-TRES-VENDAS', 'available'),
    ('00000000-0000-4000-8000-000000000010', 'CR', 'ROTARY-TRES-VENDAS', 'SEDE-TRES-VENDAS', 'available'),
    ('00000000-0000-4000-8000-000000000011', 'CR', 'ROTARY-CASA-AMIZADE', 'SEDE-CASA-AMIZADE', 'reserved')
) as fixture(id, equipment_type_code, entity_code, location_code, status)
join catalog.entities as entity on entity.code = fixture.entity_code
join catalog.storage_locations as location on location.code = fixture.location_code
on conflict (id) do update
set
  equipment_type_code = excluded.equipment_type_code,
  owner_entity_id = excluded.owner_entity_id,
  storage_location_id = excluded.storage_location_id,
  status = excluded.status;

-- Labelled inventory with entry origin for the administrative panel of the
-- local fixture administrator (Boa Vista). No real inventory data.
insert into catalog.equipment_units (
  id,
  equipment_type_code,
  owner_entity_id,
  storage_location_id,
  status,
  visible_code,
  entry_origin
)
select
  fixture.id::uuid,
  fixture.equipment_type_code,
  entity.id,
  location.id,
  fixture.status::catalog.equipment_status,
  fixture.visible_code,
  fixture.entry_origin::catalog.equipment_entry_origin
from (
  values
    ('10000000-0000-4000-8000-000000000001', 'CR', 'available', 'BVCR0001', 'donation'),
    ('10000000-0000-4000-8000-000000000002', 'CR', 'reserved', 'BVCR0002', 'purchase'),
    ('10000000-0000-4000-8000-000000000003', 'CM', 'on_loan', 'BVCM0001', 'repair_return'),
    ('10000000-0000-4000-8000-000000000004', 'AN', 'under_maintenance', null, 'return_from_other_bank'),
    ('10000000-0000-4000-8000-000000000005', 'MU', 'donated', 'BVMU0001', 'donation'),
    ('10000000-0000-4000-8000-000000000006', 'CB', 'written_off', null, 'purchase')
) as fixture(id, equipment_type_code, status, visible_code, entry_origin)
join catalog.entities as entity on entity.code = 'ROTARY-BOA-VISTA'
left join catalog.storage_locations as location on location.code = 'SEDE-BOA-VISTA'
on conflict (id) do update
set
  equipment_type_code = excluded.equipment_type_code,
  owner_entity_id = excluded.owner_entity_id,
  storage_location_id = excluded.storage_location_id,
  status = excluded.status,
  visible_code = excluded.visible_code,
  entry_origin = excluded.entry_origin;
