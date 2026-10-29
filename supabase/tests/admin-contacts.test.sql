begin;

select plan(51);

select ok(
  exists (
    select 1
    from auth.users as auth_user
    join catalog.user_roles as user_role
      on user_role.user_id = auth_user.id
      and user_role.role = 'bank_admin'
      and user_role.is_active
    join catalog.entities as entity
      on entity.id = user_role.entity_id
    where auth_user.id = '90000000-0000-4000-8000-000000000001'
      and auth_user.instance_id = '00000000-0000-0000-0000-000000000000'
      and auth_user.email = 'admin.boavista@rotary.test'
      and entity.code = 'ROTARY-BOA-VISTA'
  )
    and (
      select count(*) = 1
      from catalog.user_roles
      where user_id = '90000000-0000-4000-8000-000000000001'
        and role = 'bank_admin'
        and is_active
    ),
  'F0 local synthetic admin fixture is loaded for Rotary Boa Vista'
);

select ok(
  (
    select relrowsecurity and relforcerowsecurity
    from pg_class
    where oid = 'catalog.community_contacts'::regclass
  )
  and (
    select relrowsecurity and relforcerowsecurity
    from pg_class
    where oid = 'catalog.community_contact_status_audit'::regclass
  ),
  'C6 contact and status audit tables enforce RLS'
);

select ok(
  (
    select not rolcanlogin and not rolsuper and not rolbypassrls
    from pg_roles
    where rolname = 'admin_contact_manager'
  ),
  'C6 restricted contact function owner cannot log in or bypass RLS'
);
select ok(
  has_function_privilege(
    'admin_contact_manager',
    'public.current_admin_bank_entity_id()',
    'EXECUTE'
  ),
  'C6 contact manager can call the session-derived entity resolver'
);
select ok(
  has_function_privilege(
    'admin_contact_manager',
    'catalog.current_auth_uid()',
    'EXECUTE'
  ),
  'C6 contact manager can derive the authenticated actor'
);

select ok(
  (
    select prosecdef
      and pg_get_userbyid(proowner) = 'admin_contact_manager'
      and proconfig @> array['search_path=""', 'row_security=on']::text[]
    from pg_proc
    where oid = 'public.admin_bank_contacts(text)'::regprocedure
  ),
  'C6 contact collection RPC uses a fixed path and restricted RLS owner'
);

select ok(
  (
    select prosecdef
      and pg_get_userbyid(proowner) = 'admin_contact_manager'
      and proconfig @> array['search_path=""', 'row_security=on']::text[]
    from pg_proc
    where oid = 'public.admin_set_contact_status(text,text)'::regprocedure
  ),
  'C6 situation RPC uses a fixed path and restricted RLS owner'
);

select ok(
  not has_table_privilege('anon', 'catalog.community_contacts', 'SELECT')
    and not has_table_privilege('authenticated', 'catalog.community_contacts', 'SELECT')
    and not has_table_privilege('service_role', 'catalog.community_contacts', 'SELECT')
    and not has_table_privilege(
      'anon',
      'catalog.community_contact_status_audit',
      'SELECT'
    )
    and not has_table_privilege(
      'authenticated',
      'catalog.community_contact_status_audit',
      'SELECT'
    )
    and not has_table_privilege(
      'service_role',
      'catalog.community_contact_status_audit',
      'SELECT'
    ),
  'C6 client and service roles cannot select contact or audit rows directly'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.admin_bank_contacts(text)',
    'EXECUTE'
  )
    and has_function_privilege(
      'authenticated',
      'public.admin_set_contact_status(text,text)',
      'EXECUTE'
    )
    and not has_function_privilege(
      'anon',
      'public.admin_bank_contacts(text)',
      'EXECUTE'
    )
    and not has_function_privilege(
      'anon',
      'public.admin_set_contact_status(text,text)',
      'EXECUTE'
    )
    and not has_function_privilege(
      'service_role',
      'public.admin_bank_contacts(text)',
      'EXECUTE'
    )
    and not has_function_privilege(
      'service_role',
      'public.admin_set_contact_status(text,text)',
      'EXECUTE'
    ),
  'C6 only authenticated clients can call the administrative contact RPCs'
);

insert into auth.users (
  id,
  aud,
  role,
  email,
  email_confirmed_at,
  encrypted_password,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  ('94000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'admin-a@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('94000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'admin-b@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('94000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', 'admin-c@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('94000000-0000-4000-8000-000000000005', 'authenticated', 'authenticated', 'admin-d@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('95000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'contact-owner@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('95000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'companion@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('95000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'inactive-admin@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('95000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', 'no-role@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp());

insert into catalog.user_roles (user_id, role, entity_id, is_active)
select fixtures.user_id, 'bank_admin', entity.id, true
from (
  values
    ('94000000-0000-4000-8000-000000000002'::uuid, 'ROTARY-TRES-VENDAS'),
    ('94000000-0000-4000-8000-000000000003'::uuid, 'ROTARY-CASA-AMIZADE'),
    ('94000000-0000-4000-8000-000000000004'::uuid, 'ROTARY-ERECHIM')
) as fixtures(user_id, entity_code)
join catalog.entities as entity on entity.code = fixtures.entity_code;

insert into catalog.user_roles (user_id, role, entity_id, is_active)
values
  ('95000000-0000-4000-8000-000000000001', 'community', null, true),
  ('95000000-0000-4000-8000-000000000002', 'rotarian', null, true),
  (
    '95000000-0000-4000-8000-000000000003',
    'bank_admin',
    (select id from catalog.entities where code = 'ROTARY-TRES-VENDAS'),
    false
  );

insert into catalog.equipment_types (code, name, is_active, display_order)
values ('SYN-ADMIN-CONTACTS', 'Tipo sintético para contatos', true, 990);

insert into catalog.community_contacts (
  id,
  public_code,
  user_id,
  entity_id,
  equipment_type_code,
  recipient_user_id,
  recipient_role,
  source,
  status,
  created_at
)
select
  fixture.id::uuid,
  fixture.public_code,
  '95000000-0000-4000-8000-000000000001'::uuid,
  entity.id,
  'SYN-ADMIN-CONTACTS',
  fixture.recipient_user_id::uuid,
  'responsible',
  'equipment_detail',
  'new',
  fixture.created_at
from (
  values
    ('96000000-0000-4000-8000-000000000001', 'A1B2C3D4E5F6', 'ROTARY-BOA-VISTA', '90000000-0000-4000-8000-000000000001', clock_timestamp() - interval '49 hours'),
    ('96000000-0000-4000-8000-000000000002', 'A7B8C9D0E1F2', 'ROTARY-BOA-VISTA', '90000000-0000-4000-8000-000000000001', clock_timestamp() - interval '47 hours'),
    ('96000000-0000-4000-8000-000000000003', 'B1C2D3E4F5A6', 'ROTARY-TRES-VENDAS', '94000000-0000-4000-8000-000000000002', clock_timestamp() - interval '1 hour'),
    ('96000000-0000-4000-8000-000000000004', 'C1D2E3F4A5B6', 'ROTARY-CASA-AMIZADE', '94000000-0000-4000-8000-000000000003', clock_timestamp() - interval '1 hour'),
    ('96000000-0000-4000-8000-000000000005', 'D1E2F3A4B5C6', 'ROTARY-ERECHIM', '94000000-0000-4000-8000-000000000004', clock_timestamp() - interval '1 hour')
) as fixture(id, public_code, entity_code, recipient_user_id, created_at)
join catalog.entities as entity on entity.code = fixture.entity_code;

create temporary table contact_snapshot on commit drop as
select
  id,
  public_code,
  user_id,
  entity_id,
  equipment_type_code,
  recipient_user_id,
  recipient_role,
  source,
  created_at
from catalog.community_contacts
where id between
  '96000000-0000-4000-8000-000000000001'::uuid
  and '96000000-0000-4000-8000-000000000005'::uuid;

select is(
  (
    select count(*)::integer
    from catalog.entities
    where code in ('ROTARY-TRES-VENDAS', 'ROTARY-CASA-AMIZADE', 'ROTARY-ERECHIM', 'ROTARY-BOA-VISTA')
  ),
  4,
  'C6 authorization fixture covers four synthetic entities'
);

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config(
  'request.jwt.claim.sub',
  '90000000-0000-4000-8000-000000000001',
  true
);

select results_eq(
  $$
    select bank_name, public_code, status
    from public.admin_bank_contacts(null)
    where public_code is not null
    order by public_code
  $$,
  $$
    values
      ('Banco Ortopédico Rotary Boa Vista'::text, 'A1B2C3D4E5F6'::text, 'new'::text),
      ('Banco Ortopédico Rotary Boa Vista'::text, 'A7B8C9D0E1F2'::text, 'new'::text)
  $$,
  'C2 Rotary Boa Vista collection returns the canonical bank name and each authorized row once; C6 admin contact collection is isolated across four synthetic entities - C6 admin Rotary sees only its synthetic contacts'
);

select results_eq(
  $$
    select bank_name, public_code, status
    from public.admin_bank_contacts('A1B2C3D4E5F6')
    where public_code is not null
  $$,
  $$
    values ('Banco Ortopédico Rotary Boa Vista'::text, 'A1B2C3D4E5F6'::text, 'new'::text)
  $$,
  'C3 exact message code search returns the same code and current situation'
);

select ok(
  exists (
    select 1
    from public.admin_bank_contacts(null)
    where public_code = 'A1B2C3D4E5F6'
      and status = 'new'
      and overdue_48h
  )
    and exists (
    select 1
    from public.admin_bank_contacts(null)
    where public_code = 'A7B8C9D0E1F2'
      and status = 'new'
      and not overdue_48h
    ),
  'C4 synthetic new contacts straddle the 48-hour highlight threshold'
);
reset role;
update catalog.community_contacts
set created_at = transaction_timestamp() - interval '48 hours'
where public_code = 'A7B8C9D0E1F2';
set local role authenticated;
select is(
  (
    select overdue_48h
    from public.admin_bank_contacts('A7B8C9D0E1F2')
    where public_code = 'A7B8C9D0E1F2'
      and status = 'new'
  ),
  true,
  'C4 exact 48-hour boundary is highlighted and situation stays new'
);

select ok(
  (
    select count(*)::integer = 0
    from public.admin_bank_contacts('A1B2')
    where public_code is not null
  )
    and (
      select count(*)::integer = 0
      from public.admin_bank_contacts('a1b2c3d4e5f6')
      where public_code is not null
    )
    and (
      select count(*)::integer = 0
      from public.admin_bank_contacts('FFFFFFFFFFFF')
      where public_code is not null
    )
    and (
      select count(*)::integer = 0
      from public.admin_bank_contacts('B1C2D3E4F5A6')
      where public_code is not null
    ),
  'C5 exact search rejects malformed, missing, and other-entity codes'
);

select set_config(
  'request.jwt.claims',
  json_build_object(
    'sub', '90000000-0000-4000-8000-000000000001',
    'role', 'general_admin',
    'entity_id', '93000000-0000-4000-8000-000000000002'
  )::text,
  true
);
select set_config('request.jwt.claim.role', 'general_admin', true);
select set_config(
  'request.jwt.claim.entity_id',
  '93000000-0000-4000-8000-000000000002',
  true
);
select is(
  (
    select count(*)::integer
    from public.admin_bank_contacts('B1C2D3E4F5A6')
    where public_code is not null
  ),
  0,
  'C6 forged browser role and entity claims do not change the bank scope'
);
select throws_ok(
  $$select * from catalog.community_contacts$$,
  '42501',
  null,
  'C6 client roles cannot read private contact or audit rows directly - contacts'
);
select throws_ok(
  $$select * from catalog.community_contact_status_audit$$,
  '42501',
  null,
  'C6 client roles cannot read private contact or audit rows directly - audit'
);

reset role;
set local role anon;
select set_config('request.jwt.claim.role', 'anon', true);
select set_config('request.jwt.claim.sub', '', true);
select throws_ok(
  $$select * from public.admin_bank_contacts(null)$$,
  '42501',
  null,
  'C6 anon cannot call the administrative contact collection'
);
select throws_ok(
  $$select public.admin_set_contact_status('A1B2C3D4E5F6', 'answered')$$,
  '42501',
  null,
  'C6 anon cannot change a contact situation'
);

reset role;
set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config(
  'request.jwt.claim.sub',
  '94000000-0000-4000-8000-000000000002',
  true
);
select is(
  (
    select count(*)::integer
    from public.admin_bank_contacts(null)
    where public_code is not null
  ),
  1,
  'C6 admin contact collection is isolated across four synthetic entities - C6 admin SYN-A sees only its synthetic contacts'
);
select results_eq(
  $$
    select bank_name, public_code, status
    from public.admin_bank_contacts(null)
    where public_code is not null
  $$,
  $$
    values ('Banco Ortopédico Três Vendas'::text, 'B1C2D3E4F5A6'::text, 'new'::text)
  $$,
  'C6 admin contact collection is isolated across four synthetic entities - SYN-A row data'
);
select throws_ok(
  $$select public.admin_set_contact_status('A1B2C3D4E5F6', 'answered')$$,
  'P0001',
  'Contact unavailable',
  'C6 bank_admin from another entity cannot change a Rotary contact'
);

select set_config(
  'request.jwt.claim.sub',
  '94000000-0000-4000-8000-000000000003',
  true
);
select results_eq(
  $$
    select bank_name, public_code, status
    from public.admin_bank_contacts(null)
    where public_code is not null
  $$,
  $$
    values ('Casa da Amizade — Banco Ortopédico'::text, 'C1D2E3F4A5B6'::text, 'new'::text)
  $$,
  'C6 admin contact collection is isolated across four synthetic entities - C6 admin SYN-B sees only its synthetic contacts'
);

select set_config(
  'request.jwt.claim.sub',
  '94000000-0000-4000-8000-000000000004',
  true
);
select results_eq(
  $$
    select bank_name, public_code, status
    from public.admin_bank_contacts(null)
    where public_code is not null
  $$,
  $$
    values ('Banco Ortopédico Rotary Erechim'::text, 'D1E2F3A4B5C6'::text, 'new'::text)
  $$,
  'C6 admin contact collection is isolated across four synthetic entities - C6 admin SYN-C sees only its synthetic contacts'
);

select set_config(
  'request.jwt.claim.sub',
  '95000000-0000-4000-8000-000000000001',
  true
);
select is(
  (
    select count(*)::integer
    from public.admin_bank_contacts(null)
    where public_code is not null
  ),
  0,
  'C6 Community without bank_admin receives no administrative contacts'
);
select throws_ok(
  $$select public.admin_set_contact_status('A1B2C3D4E5F6', 'answered')$$,
  'P0001',
  'Contact unavailable',
  'C6 Community without bank_admin cannot change a contact'
);

select set_config(
  'request.jwt.claim.sub',
  '95000000-0000-4000-8000-000000000002',
  true
);
select is(
  (
    select count(*)::integer
    from public.admin_bank_contacts(null)
    where public_code is not null
  ),
  0,
  'C6 Companion without bank_admin receives no administrative contacts'
);
select throws_ok(
  $$select public.admin_set_contact_status('A1B2C3D4E5F6', 'answered')$$,
  'P0001',
  'Contact unavailable',
  'C6 Companion without bank_admin cannot change a contact'
);

select set_config(
  'request.jwt.claim.sub',
  '95000000-0000-4000-8000-000000000003',
  true
);
select is(
  (
    select count(*)::integer
    from public.admin_bank_contacts(null)
    where public_code is not null
  ),
  0,
  'C6 inactive bank_admin receives no administrative contacts'
);
select throws_ok(
  $$select public.admin_set_contact_status('A1B2C3D4E5F6', 'answered')$$,
  'P0001',
  'Contact unavailable',
  'C6 inactive bank_admin cannot change a contact'
);

select set_config(
  'request.jwt.claim.sub',
  '95000000-0000-4000-8000-000000000004',
  true
);
select is(
  (
    select count(*)::integer
    from public.admin_bank_contacts(null)
    where public_code is not null
  ),
  0,
  'C6 authenticated user without an active bank_admin receives no contacts'
);
select throws_ok(
  $$select public.admin_set_contact_status('A1B2C3D4E5F6', 'answered')$$,
  'P0001',
  'Contact unavailable',
  'C6 authenticated user without bank_admin cannot change a contact'
);

select set_config(
  'request.jwt.claim.sub',
  '90000000-0000-4000-8000-000000000001',
  true
);
select is(
  public.admin_set_contact_status('A1B2C3D4E5F6', 'answered'),
  'answered',
  'C7 answered changes the situation from new'
);
reset role;
select ok(
  exists (
    select 1
    from catalog.community_contacts as contact
    join contact_snapshot as snapshot on snapshot.id = contact.id
    where contact.public_code = 'A1B2C3D4E5F6'
      and contact.status = 'answered'
      and contact.public_code = snapshot.public_code
      and contact.user_id = snapshot.user_id
      and contact.entity_id = snapshot.entity_id
      and contact.equipment_type_code = snapshot.equipment_type_code
      and contact.recipient_user_id = snapshot.recipient_user_id
      and contact.recipient_role = snapshot.recipient_role
      and contact.source = snapshot.source
      and contact.created_at = snapshot.created_at
  ),
  'C7 answered changes only situation and preserves the contact fields'
);

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config(
  'request.jwt.claim.sub',
  '90000000-0000-4000-8000-000000000001',
  true
);
select throws_ok(
  $$select public.admin_set_contact_status('A1B2C3D4E5F6', 'new')$$,
  'P0001',
  'Contact unavailable',
  'C7 transition back to new is rejected'
);
reset role;

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config(
  'request.jwt.claim.sub',
  '94000000-0000-4000-8000-000000000002',
  true
);
select is(
  public.admin_set_contact_status('B1C2D3E4F5A6', 'no_response'),
  'no_response',
  'C7 no_response changes the situation from new'
);
reset role;
select ok(
  exists (
    select 1
    from catalog.community_contacts as contact
    join contact_snapshot as snapshot on snapshot.id = contact.id
    where contact.public_code = 'B1C2D3E4F5A6'
      and contact.status = 'no_response'
      and contact.public_code = snapshot.public_code
      and contact.user_id = snapshot.user_id
      and contact.entity_id = snapshot.entity_id
      and contact.equipment_type_code = snapshot.equipment_type_code
      and contact.recipient_user_id = snapshot.recipient_user_id
      and contact.recipient_role = snapshot.recipient_role
      and contact.source = snapshot.source
      and contact.created_at = snapshot.created_at
  ),
  'C7 no_response changes only situation and preserves the contact fields'
);

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config(
  'request.jwt.claim.sub',
  '94000000-0000-4000-8000-000000000003',
  true
);
select is(
  public.admin_set_contact_status('C1D2E3F4A5B6', 'converted_to_loan'),
  'converted_to_loan',
  'C7 converted_to_loan changes the situation from new'
);
reset role;
select ok(
  exists (
    select 1
    from catalog.community_contacts as contact
    join contact_snapshot as snapshot on snapshot.id = contact.id
    where contact.public_code = 'C1D2E3F4A5B6'
      and contact.status = 'converted_to_loan'
      and contact.public_code = snapshot.public_code
      and contact.user_id = snapshot.user_id
      and contact.entity_id = snapshot.entity_id
      and contact.equipment_type_code = snapshot.equipment_type_code
      and contact.recipient_user_id = snapshot.recipient_user_id
      and contact.recipient_role = snapshot.recipient_role
      and contact.source = snapshot.source
      and contact.created_at = snapshot.created_at
  ),
  'C7 converted_to_loan changes only situation and preserves the contact fields'
);

select ok(
  exists (
    select 1
    from catalog.community_contact_status_audit as audit
    where audit.actor_user_id = '94000000-0000-4000-8000-000000000002'
      and audit.action = 'contact_status_changed'
      and audit.entity_id = (
        select id from catalog.entities where code = 'ROTARY-TRES-VENDAS'
      )
      and audit.contact_id = '96000000-0000-4000-8000-000000000003'
      and audit.previous_status = 'new'
      and audit.new_status = 'no_response'
      and audit.created_at is not null
  ),
  'C8 audit records actor, action, entity, internal contact, previous/new situation and time'
);
select is(
  (
    select array_agg(attribute.attname::text order by attribute.attnum)
    from pg_attribute as attribute
    where attribute.attrelid =
      'catalog.community_contact_status_audit'::regclass
      and attribute.attnum > 0
      and not attribute.attisdropped
  ),
  array[
    'id',
    'actor_user_id',
    'action',
    'entity_id',
    'contact_id',
    'previous_status',
    'new_status',
    'created_at'
  ]::text[],
  'C8 audit schema contains no PII columns'
);
select is(
  (
    select count(*)::integer
    from catalog.community_contact_status_audit
  ),
  3,
  'C8 each of the three confirmed destinations writes one audit event'
);

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config(
  'request.jwt.claim.sub',
  '94000000-0000-4000-8000-000000000004',
  true
);
select is(
  public.admin_set_contact_status('D1E2F3A4B5C6', 'no_response'),
  'no_response',
  'C9 first destination is confirmed for the synthetic contact'
);
select is(
  public.admin_set_contact_status('D1E2F3A4B5C6', 'no_response'),
  'no_response',
  'C9 retrying the same destination returns the confirmed situation'
);
reset role;
select ok(
  (
    select count(*)::integer = 1
    from catalog.community_contact_status_audit as audit
    where audit.contact_id = '96000000-0000-4000-8000-000000000005'
  )
    and exists (
      select 1
      from catalog.community_contacts as contact
      where contact.id = '96000000-0000-4000-8000-000000000005'
        and contact.public_code = 'D1E2F3A4B5C6'
        and contact.status = 'no_response'
    ),
  'C9 repeating the same destination leaves one contact transition and one audit row'
);

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config(
  'request.jwt.claim.sub',
  '90000000-0000-4000-8000-000000000001',
  true
);
select is(
  public.admin_set_contact_status('A7B8C9D0E1F2', 'answered'),
  'answered',
  'C10 first competing destination is confirmed'
);
select throws_ok(
  $$select public.admin_set_contact_status('A7B8C9D0E1F2', 'no_response')$$,
  'P0002',
  'Status already registered',
  'C10 a competing destination cannot overwrite the confirmed situation or add another audit row'
);
reset role;
select ok(
  (
    select count(*)::integer = 1
    from catalog.community_contact_status_audit as audit
    where audit.contact_id = '96000000-0000-4000-8000-000000000002'
  )
    and exists (
      select 1
      from catalog.community_contacts as contact
      where contact.id = '96000000-0000-4000-8000-000000000002'
        and contact.status = 'answered'
    ),
  'C10 only one situation and one audit row remain after competing destinations'
);

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config(
  'request.jwt.claim.sub',
  '90000000-0000-4000-8000-000000000001',
  true
);
select throws_ok(
  $$select public.admin_set_contact_status('B1C2D3E4F5A6', 'answered')$$,
  'P0001',
  'Contact unavailable',
  'C15 foreign and unknown contact codes receive the same generic denial - foreign code'
);
select throws_ok(
  $$select public.admin_set_contact_status('FFFFFFFFFFFF', 'answered')$$,
  'P0001',
  'Contact unavailable',
  'C15 foreign and unknown contact codes receive the same generic denial - unknown code'
);

select * from finish();
rollback;
