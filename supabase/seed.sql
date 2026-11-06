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

-- People who borrow the equipment in the seeded drafts. Names, CPFs and phones
-- are fictional; e-mails use the reserved .test domain. The CPFs are distinct
-- from the ones the SQL tests use as fixtures, so seeding and testing never
-- collide on the unique CPF.
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
values
  (
    '00000000-0000-0000-0000-000000000000',
    '91500000-0000-4000-8000-000000000001',
    'authenticated',
    'authenticated',
    'jessica.marina@comunidade.test',
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
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '91500000-0000-4000-8000-000000000002',
    'authenticated',
    'authenticated',
    'chico.bento@comunidade.test',
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

insert into catalog.community_profiles (id, name, cpf, phone, privacy_notice_version)
values
  ('91500000-0000-4000-8000-000000000001', 'Jessica Marina', '48291375682', '+5554999980001', 'v1'),
  ('91500000-0000-4000-8000-000000000002', 'Chico Bento', '59371426837', '+5554999980002', 'v1')
on conflict (id) do update
set
  name = excluded.name,
  cpf = excluded.cpf,
  phone = excluded.phone,
  privacy_notice_version = excluded.privacy_notice_version;

insert into catalog.user_roles (id, user_id, role, entity_id, is_active)
values
  ('91500000-0000-4000-8000-000000000011', '91500000-0000-4000-8000-000000000001', 'community', null, true),
  ('91500000-0000-4000-8000-000000000012', '91500000-0000-4000-8000-000000000002', 'community', null, true)
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

-- Equipment held by the two seeded drafts. A draft reserves its units, so these
-- stay out of the public availability aggregate while the loan is open.
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
  'reserved'::catalog.equipment_status,
  fixture.visible_code,
  fixture.entry_origin::catalog.equipment_entry_origin
from (
  values
    ('10000000-0000-4000-8000-000000000007', 'CR', 'BVCR0003', 'donation'),
    ('10000000-0000-4000-8000-000000000008', 'AN', 'BVAN0002', 'purchase'),
    ('10000000-0000-4000-8000-000000000009', 'CM', 'BVCM0002', 'repair_return'),
    ('10000000-0000-4000-8000-000000000010', 'MU', 'BVMU0002', 'donation')
) as fixture(id, equipment_type_code, visible_code, entry_origin)
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

-- Term model of every seeded bank. It is seeded here, not in the migration,
-- because the banks only exist once this file runs. The text is a provisional
-- draft pending legal review: it is not binding wording. Each bank keeps its own
-- version 1, and the seeded drafts below can generate a term with it.
insert into catalog.document_models (
  id,
  entity_id,
  document_type,
  version,
  body,
  review_status,
  is_active
)
select
  ('23000000-0000-4000-8000-0000000000' || lpad(row_number() over (order by entity.code)::text, 2, '0'))::uuid,
  entity.id,
  'loan_term',
  1,
  $body$TERMO DE EMPRÉSTIMO DE EQUIPAMENTO

{bank_name}, neste ato cedente, entrega em empréstimo ao responsável abaixo identificado os equipamentos relacionados neste termo, para uso próprio ou de paciente informado, comprometendo-se o responsável a devolvê-los nas condições recebidas e nas datas aqui registradas.

RESPONSÁVEL
Nome: {borrower_name}
CPF: {borrower_cpf}

PACIENTE
{patient_name}

DATAS
Entrega: {delivery_date}
Devolução prevista: {due_date}
Revisão: {review_date}

EQUIPAMENTOS E ESTADO NA ENTREGA
{equipment_list}

ANOTAÇÃO DE ESTADO
{condition_note}

Código do empréstimo: {public_code}

O responsável declara ter recebido os equipamentos em bom estado de conservação e assume a responsabilidade pela guarda e devolução. Este texto é um modelo provisório do banco e está pendente de revisão jurídica.

Assinatura do responsável: ______________________________

Assinatura do representante do banco: ______________________________$body$,
  'pending_legal_review',
  true
from catalog.entities as entity
on conflict (entity_id, document_type, version) do update
set
  body = excluded.body,
  review_status = excluded.review_status,
  is_active = excluded.is_active;

-- Two drafts registered by the fixture administrator of Boa Vista, ready to be
-- listed on /admin/emprestimos. One has a due date, the other a review date.
insert into catalog.loans (
  id,
  public_code,
  entity_id,
  borrower_user_id,
  patient_name,
  condition_note,
  delivery_date,
  due_date,
  review_date,
  status,
  created_by_user_id,
  created_at
)
select
  fixture.id::uuid,
  fixture.public_code,
  entity.id,
  fixture.borrower_user_id::uuid,
  fixture.patient_name,
  fixture.condition_note,
  fixture.delivery_date::date,
  fixture.due_date::date,
  fixture.review_date::date,
  'draft'::catalog.loan_status,
  '90000000-0000-4000-8000-000000000001'::uuid,
  fixture.created_at::timestamptz
from (
  values
    (
      '21000000-0000-4000-8000-000000000001',
      'B0A157E00001',
      '91500000-0000-4000-8000-000000000001',
      'Jessica Marina',
      'Cadeira de rodas e andador para recuperação após cirurgia no fêmur.',
      '2026-11-04',
      '2027-02-02',
      null,
      '2026-11-04 09:15:00-03'
    ),
    (
      '21000000-0000-4000-8000-000000000002',
      'B0A157E00002',
      '91500000-0000-4000-8000-000000000002',
      null,
      null,
      '2026-11-05',
      null,
      '2027-01-05',
      '2026-11-05 14:40:00-03'
    )
) as fixture(
  id,
  public_code,
  borrower_user_id,
  patient_name,
  condition_note,
  delivery_date,
  due_date,
  review_date,
  created_at
)
join catalog.entities as entity on entity.code = 'ROTARY-BOA-VISTA'
on conflict (id) do update
set
  public_code = excluded.public_code,
  entity_id = excluded.entity_id,
  borrower_user_id = excluded.borrower_user_id,
  patient_name = excluded.patient_name,
  condition_note = excluded.condition_note,
  delivery_date = excluded.delivery_date,
  due_date = excluded.due_date,
  review_date = excluded.review_date,
  status = excluded.status,
  completed_at = null,
  cancelled_at = null,
  created_by_user_id = excluded.created_by_user_id,
  created_at = excluded.created_at;

insert into catalog.loan_lines (loan_id, unit_id)
values
  ('21000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000007'),
  ('21000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000008'),
  ('21000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000009'),
  ('21000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000010')
on conflict (loan_id, unit_id) do update
set released_at = null;

insert into catalog.loan_event_audit (
  id,
  actor_user_id,
  entity_id,
  loan_id,
  action,
  previous_status,
  new_status,
  unit_ids,
  due_date,
  review_date,
  created_at
)
select
  fixture.id::uuid,
  '90000000-0000-4000-8000-000000000001'::uuid,
  entity.id,
  fixture.loan_id::uuid,
  'loan_draft_created',
  null,
  'draft'::catalog.loan_status,
  fixture.unit_ids::uuid[],
  fixture.due_date::date,
  fixture.review_date::date,
  fixture.created_at::timestamptz
from (
  values
    (
      '22000000-0000-4000-8000-000000000001',
      '21000000-0000-4000-8000-000000000001',
      '{10000000-0000-4000-8000-000000000007,10000000-0000-4000-8000-000000000008}',
      '2027-02-02',
      null,
      '2026-11-04 09:15:00-03'
    ),
    (
      '22000000-0000-4000-8000-000000000002',
      '21000000-0000-4000-8000-000000000002',
      '{10000000-0000-4000-8000-000000000009,10000000-0000-4000-8000-000000000010}',
      null,
      '2027-01-05',
      '2026-11-05 14:40:00-03'
    )
) as fixture(id, loan_id, unit_ids, due_date, review_date, created_at)
join catalog.entities as entity on entity.code = 'ROTARY-BOA-VISTA'
on conflict (id) do update
set
  actor_user_id = excluded.actor_user_id,
  entity_id = excluded.entity_id,
  loan_id = excluded.loan_id,
  action = excluded.action,
  previous_status = excluded.previous_status,
  new_status = excluded.new_status,
  unit_ids = excluded.unit_ids,
  due_date = excluded.due_date,
  review_date = excluded.review_date,
  created_at = excluded.created_at;
