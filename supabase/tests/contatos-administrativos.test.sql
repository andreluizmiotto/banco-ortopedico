begin;

select plan(51);

select ok(
  exists (
    select 1
    from auth.users as auth_user
    join catalog.user_roles as user_role
      on user_role.user_id = auth_user.id
      and user_role.role = 'admin_banco'
      and user_role.is_active
    join catalog.entities as entity
      on entity.id = user_role.entity_id
    where auth_user.id = '90000000-0000-4000-8000-000000000001'
      and auth_user.instance_id = '00000000-0000-0000-0000-000000000000'
      and auth_user.email = 'admin-rotary-boa-vista@banco-ortopedico.test'
      and entity.code = 'SYN-ROTARY-BOA-VISTA'
  )
    and (
      select count(*) = 1
      from catalog.user_roles
      where user_id = '90000000-0000-4000-8000-000000000001'
        and role = 'admin_banco'
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
    where oid = 'catalog.community_contact_situation_audit'::regclass
  ),
  'C6 contact and situation audit tables enforce RLS'
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
    where oid = 'public.admin_set_contact_situation(text,text)'::regprocedure
  ),
  'C6 situation RPC uses a fixed path and restricted RLS owner'
);

select ok(
  not has_table_privilege('anon', 'catalog.community_contacts', 'SELECT')
    and not has_table_privilege('authenticated', 'catalog.community_contacts', 'SELECT')
    and not has_table_privilege('service_role', 'catalog.community_contacts', 'SELECT')
    and not has_table_privilege(
      'anon',
      'catalog.community_contact_situation_audit',
      'SELECT'
    )
    and not has_table_privilege(
      'authenticated',
      'catalog.community_contact_situation_audit',
      'SELECT'
    )
    and not has_table_privilege(
      'service_role',
      'catalog.community_contact_situation_audit',
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
      'public.admin_set_contact_situation(text,text)',
      'EXECUTE'
    )
    and not has_function_privilege(
      'anon',
      'public.admin_bank_contacts(text)',
      'EXECUTE'
    )
    and not has_function_privilege(
      'anon',
      'public.admin_set_contact_situation(text,text)',
      'EXECUTE'
    )
    and not has_function_privilege(
      'service_role',
      'public.admin_bank_contacts(text)',
      'EXECUTE'
    )
    and not has_function_privilege(
      'service_role',
      'public.admin_set_contact_situation(text,text)',
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
select fixtures.user_id, 'admin_banco', entity.id, true
from (
  values
    ('94000000-0000-4000-8000-000000000002'::uuid, 'SYN-A'),
    ('94000000-0000-4000-8000-000000000003'::uuid, 'SYN-B'),
    ('94000000-0000-4000-8000-000000000004'::uuid, 'SYN-C')
) as fixtures(user_id, entity_code)
join catalog.entities as entity on entity.code = fixtures.entity_code;

insert into catalog.user_roles (user_id, role, entity_id, is_active)
values
  ('95000000-0000-4000-8000-000000000001', 'comunidade', null, true),
  ('95000000-0000-4000-8000-000000000002', 'companheiro', null, true),
  (
    '95000000-0000-4000-8000-000000000003',
    'admin_banco',
    (select id from catalog.entities where code = 'SYN-A'),
    false
  );

insert into catalog.equipment_types (code, name, is_active, display_order)
values ('SYN-ADMIN-CONTACTS', 'Tipo sintético para contatos', true, 990);

insert into catalog.community_contacts (
  id,
  codigo,
  user_id,
  entity_id,
  equipment_type_code,
  recipient_user_id,
  recipient_role,
  origem,
  situacao,
  created_at
)
select
  fixture.id::uuid,
  fixture.codigo,
  '95000000-0000-4000-8000-000000000001'::uuid,
  entity.id,
  'SYN-ADMIN-CONTACTS',
  fixture.recipient_user_id::uuid,
  'responsavel',
  'detalhe_equipamento',
  'novo',
  fixture.created_at
from (
  values
    ('96000000-0000-4000-8000-000000000001', 'A1B2C3D4E5F6', 'SYN-ROTARY-BOA-VISTA', '90000000-0000-4000-8000-000000000001', clock_timestamp() - interval '49 hours'),
    ('96000000-0000-4000-8000-000000000002', 'A7B8C9D0E1F2', 'SYN-ROTARY-BOA-VISTA', '90000000-0000-4000-8000-000000000001', clock_timestamp() - interval '47 hours'),
    ('96000000-0000-4000-8000-000000000003', 'B1C2D3E4F5A6', 'SYN-A', '94000000-0000-4000-8000-000000000002', clock_timestamp() - interval '1 hour'),
    ('96000000-0000-4000-8000-000000000004', 'C1D2E3F4A5B6', 'SYN-B', '94000000-0000-4000-8000-000000000003', clock_timestamp() - interval '1 hour'),
    ('96000000-0000-4000-8000-000000000005', 'D1E2F3A4B5C6', 'SYN-C', '94000000-0000-4000-8000-000000000004', clock_timestamp() - interval '1 hour')
) as fixture(id, codigo, entity_code, recipient_user_id, created_at)
join catalog.entities as entity on entity.code = fixture.entity_code;

create temporary table contact_snapshot on commit drop as
select
  id,
  codigo,
  user_id,
  entity_id,
  equipment_type_code,
  recipient_user_id,
  recipient_role,
  origem,
  created_at
from catalog.community_contacts
where id between
  '96000000-0000-4000-8000-000000000001'::uuid
  and '96000000-0000-4000-8000-000000000005'::uuid;

select is(
  (
    select count(*)::integer
    from catalog.entities
    where code in ('SYN-A', 'SYN-B', 'SYN-C', 'SYN-ROTARY-BOA-VISTA')
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
    select bank_name, codigo, situacao
    from public.admin_bank_contacts(null)
    where codigo is not null
    order by codigo
  $$,
  $$
    values
      ('Rotary Boa Vista (sintético)'::text, 'A1B2C3D4E5F6'::text, 'novo'::text),
      ('Rotary Boa Vista (sintético)'::text, 'A7B8C9D0E1F2'::text, 'novo'::text)
  $$,
  'C2 Rotary Boa Vista collection returns the canonical bank name and each authorized row once; C6 admin contact collection is isolated across four synthetic entities - C6 admin Rotary sees only its synthetic contacts'
);

select results_eq(
  $$
    select bank_name, codigo, situacao
    from public.admin_bank_contacts('A1B2C3D4E5F6')
    where codigo is not null
  $$,
  $$
    values ('Rotary Boa Vista (sintético)'::text, 'A1B2C3D4E5F6'::text, 'novo'::text)
  $$,
  'C3 exact message code search returns the same code and current situation'
);

select ok(
  exists (
    select 1
    from public.admin_bank_contacts(null)
    where codigo = 'A1B2C3D4E5F6'
      and situacao = 'novo'
      and destaque_48_horas
  )
    and exists (
    select 1
    from public.admin_bank_contacts(null)
    where codigo = 'A7B8C9D0E1F2'
      and situacao = 'novo'
      and not destaque_48_horas
    ),
  'C4 synthetic new contacts straddle the 48-hour highlight threshold'
);
reset role;
update catalog.community_contacts
set created_at = transaction_timestamp() - interval '48 hours'
where codigo = 'A7B8C9D0E1F2';
set local role authenticated;
select is(
  (
    select destaque_48_horas
    from public.admin_bank_contacts('A7B8C9D0E1F2')
    where codigo = 'A7B8C9D0E1F2'
      and situacao = 'novo'
  ),
  true,
  'C4 exact 48-hour boundary is highlighted and situation stays novo'
);

select ok(
  (
    select count(*)::integer = 0
    from public.admin_bank_contacts('A1B2')
    where codigo is not null
  )
    and (
      select count(*)::integer = 0
      from public.admin_bank_contacts('a1b2c3d4e5f6')
      where codigo is not null
    )
    and (
      select count(*)::integer = 0
      from public.admin_bank_contacts('FFFFFFFFFFFF')
      where codigo is not null
    )
    and (
      select count(*)::integer = 0
      from public.admin_bank_contacts('B1C2D3E4F5A6')
      where codigo is not null
    ),
  'C5 exact search rejects malformed, missing, and other-entity codes'
);

select set_config(
  'request.jwt.claims',
  json_build_object(
    'sub', '90000000-0000-4000-8000-000000000001',
    'role', 'admin_geral',
    'entity_id', '93000000-0000-4000-8000-000000000002'
  )::text,
  true
);
select set_config('request.jwt.claim.role', 'admin_geral', true);
select set_config(
  'request.jwt.claim.entity_id',
  '93000000-0000-4000-8000-000000000002',
  true
);
select is(
  (
    select count(*)::integer
    from public.admin_bank_contacts('B1C2D3E4F5A6')
    where codigo is not null
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
  $$select * from catalog.community_contact_situation_audit$$,
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
  $$select public.admin_set_contact_situation('A1B2C3D4E5F6', 'atendido')$$,
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
    where codigo is not null
  ),
  1,
  'C6 admin contact collection is isolated across four synthetic entities - C6 admin SYN-A sees only its synthetic contacts'
);
select results_eq(
  $$
    select bank_name, codigo, situacao
    from public.admin_bank_contacts(null)
    where codigo is not null
  $$,
  $$
    values ('Entidade Sintética A'::text, 'B1C2D3E4F5A6'::text, 'novo'::text)
  $$,
  'C6 admin contact collection is isolated across four synthetic entities - SYN-A row data'
);
select throws_ok(
  $$select public.admin_set_contact_situation('A1B2C3D4E5F6', 'atendido')$$,
  'P0001',
  'Contato indisponível',
  'C6 admin_banco from another entity cannot change a Rotary contact'
);

select set_config(
  'request.jwt.claim.sub',
  '94000000-0000-4000-8000-000000000003',
  true
);
select results_eq(
  $$
    select bank_name, codigo, situacao
    from public.admin_bank_contacts(null)
    where codigo is not null
  $$,
  $$
    values ('Entidade Sintética B'::text, 'C1D2E3F4A5B6'::text, 'novo'::text)
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
    select bank_name, codigo, situacao
    from public.admin_bank_contacts(null)
    where codigo is not null
  $$,
  $$
    values ('Entidade Sintética C'::text, 'D1E2F3A4B5C6'::text, 'novo'::text)
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
    where codigo is not null
  ),
  0,
  'C6 Community without admin_banco receives no administrative contacts'
);
select throws_ok(
  $$select public.admin_set_contact_situation('A1B2C3D4E5F6', 'atendido')$$,
  'P0001',
  'Contato indisponível',
  'C6 Community without admin_banco cannot change a contact'
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
    where codigo is not null
  ),
  0,
  'C6 Companion without admin_banco receives no administrative contacts'
);
select throws_ok(
  $$select public.admin_set_contact_situation('A1B2C3D4E5F6', 'atendido')$$,
  'P0001',
  'Contato indisponível',
  'C6 Companion without admin_banco cannot change a contact'
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
    where codigo is not null
  ),
  0,
  'C6 inactive admin_banco receives no administrative contacts'
);
select throws_ok(
  $$select public.admin_set_contact_situation('A1B2C3D4E5F6', 'atendido')$$,
  'P0001',
  'Contato indisponível',
  'C6 inactive admin_banco cannot change a contact'
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
    where codigo is not null
  ),
  0,
  'C6 authenticated user without an active admin_banco receives no contacts'
);
select throws_ok(
  $$select public.admin_set_contact_situation('A1B2C3D4E5F6', 'atendido')$$,
  'P0001',
  'Contato indisponível',
  'C6 authenticated user without admin_banco cannot change a contact'
);

select set_config(
  'request.jwt.claim.sub',
  '90000000-0000-4000-8000-000000000001',
  true
);
select is(
  public.admin_set_contact_situation('A1B2C3D4E5F6', 'atendido'),
  'atendido',
  'C7 atendido changes the situation from novo'
);
reset role;
select ok(
  exists (
    select 1
    from catalog.community_contacts as contact
    join contact_snapshot as snapshot on snapshot.id = contact.id
    where contact.codigo = 'A1B2C3D4E5F6'
      and contact.situacao = 'atendido'
      and contact.codigo = snapshot.codigo
      and contact.user_id = snapshot.user_id
      and contact.entity_id = snapshot.entity_id
      and contact.equipment_type_code = snapshot.equipment_type_code
      and contact.recipient_user_id = snapshot.recipient_user_id
      and contact.recipient_role = snapshot.recipient_role
      and contact.origem = snapshot.origem
      and contact.created_at = snapshot.created_at
  ),
  'C7 atendido changes only situation and preserves the contact fields'
);

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config(
  'request.jwt.claim.sub',
  '90000000-0000-4000-8000-000000000001',
  true
);
select throws_ok(
  $$select public.admin_set_contact_situation('A1B2C3D4E5F6', 'novo')$$,
  'P0001',
  'Contato indisponível',
  'C7 transition back to novo is rejected'
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
  public.admin_set_contact_situation('B1C2D3E4F5A6', 'sem_retorno'),
  'sem_retorno',
  'C7 sem_retorno changes the situation from novo'
);
reset role;
select ok(
  exists (
    select 1
    from catalog.community_contacts as contact
    join contact_snapshot as snapshot on snapshot.id = contact.id
    where contact.codigo = 'B1C2D3E4F5A6'
      and contact.situacao = 'sem_retorno'
      and contact.codigo = snapshot.codigo
      and contact.user_id = snapshot.user_id
      and contact.entity_id = snapshot.entity_id
      and contact.equipment_type_code = snapshot.equipment_type_code
      and contact.recipient_user_id = snapshot.recipient_user_id
      and contact.recipient_role = snapshot.recipient_role
      and contact.origem = snapshot.origem
      and contact.created_at = snapshot.created_at
  ),
  'C7 sem_retorno changes only situation and preserves the contact fields'
);

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config(
  'request.jwt.claim.sub',
  '94000000-0000-4000-8000-000000000003',
  true
);
select is(
  public.admin_set_contact_situation('C1D2E3F4A5B6', 'virou_emprestimo'),
  'virou_emprestimo',
  'C7 virou_emprestimo changes the situation from novo'
);
reset role;
select ok(
  exists (
    select 1
    from catalog.community_contacts as contact
    join contact_snapshot as snapshot on snapshot.id = contact.id
    where contact.codigo = 'C1D2E3F4A5B6'
      and contact.situacao = 'virou_emprestimo'
      and contact.codigo = snapshot.codigo
      and contact.user_id = snapshot.user_id
      and contact.entity_id = snapshot.entity_id
      and contact.equipment_type_code = snapshot.equipment_type_code
      and contact.recipient_user_id = snapshot.recipient_user_id
      and contact.recipient_role = snapshot.recipient_role
      and contact.origem = snapshot.origem
      and contact.created_at = snapshot.created_at
  ),
  'C7 virou_emprestimo changes only situation and preserves the contact fields'
);

select ok(
  exists (
    select 1
    from catalog.community_contact_situation_audit as audit
    where audit.actor_user_id = '94000000-0000-4000-8000-000000000002'
      and audit.action = 'contact_situation_changed'
      and audit.entity_id = (
        select id from catalog.entities where code = 'SYN-A'
      )
      and audit.contact_id = '96000000-0000-4000-8000-000000000003'
      and audit.previous_situation = 'novo'
      and audit.new_situation = 'sem_retorno'
      and audit.created_at is not null
  ),
  'C8 audit records actor, action, entity, internal contact, previous/new situation and time'
);
select is(
  (
    select array_agg(attribute.attname::text order by attribute.attnum)
    from pg_attribute as attribute
    where attribute.attrelid =
      'catalog.community_contact_situation_audit'::regclass
      and attribute.attnum > 0
      and not attribute.attisdropped
  ),
  array[
    'id',
    'actor_user_id',
    'action',
    'entity_id',
    'contact_id',
    'previous_situation',
    'new_situation',
    'created_at'
  ]::text[],
  'C8 audit schema contains no PII columns'
);
select is(
  (
    select count(*)::integer
    from catalog.community_contact_situation_audit
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
  public.admin_set_contact_situation('D1E2F3A4B5C6', 'sem_retorno'),
  'sem_retorno',
  'C9 first destination is confirmed for the synthetic contact'
);
select is(
  public.admin_set_contact_situation('D1E2F3A4B5C6', 'sem_retorno'),
  'sem_retorno',
  'C9 retrying the same destination returns the confirmed situation'
);
reset role;
select ok(
  (
    select count(*)::integer = 1
    from catalog.community_contact_situation_audit as audit
    where audit.contact_id = '96000000-0000-4000-8000-000000000005'
  )
    and exists (
      select 1
      from catalog.community_contacts as contact
      where contact.id = '96000000-0000-4000-8000-000000000005'
        and contact.codigo = 'D1E2F3A4B5C6'
        and contact.situacao = 'sem_retorno'
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
  public.admin_set_contact_situation('A7B8C9D0E1F2', 'atendido'),
  'atendido',
  'C10 first competing destination is confirmed'
);
select throws_ok(
  $$select public.admin_set_contact_situation('A7B8C9D0E1F2', 'sem_retorno')$$,
  'P0002',
  'Situação já registrada',
  'C10 a competing destination cannot overwrite the confirmed situation or add another audit row'
);
reset role;
select ok(
  (
    select count(*)::integer = 1
    from catalog.community_contact_situation_audit as audit
    where audit.contact_id = '96000000-0000-4000-8000-000000000002'
  )
    and exists (
      select 1
      from catalog.community_contacts as contact
      where contact.id = '96000000-0000-4000-8000-000000000002'
        and contact.situacao = 'atendido'
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
  $$select public.admin_set_contact_situation('B1C2D3E4F5A6', 'atendido')$$,
  'P0001',
  'Contato indisponível',
  'C15 foreign and unknown contact codes receive the same generic denial - foreign code'
);
select throws_ok(
  $$select public.admin_set_contact_situation('FFFFFFFFFFFF', 'atendido')$$,
  'P0001',
  'Contato indisponível',
  'C15 foreign and unknown contact codes receive the same generic denial - unknown code'
);

select * from finish();
rollback;
