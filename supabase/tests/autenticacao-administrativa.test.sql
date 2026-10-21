begin;

select plan(26);

select ok(
  to_regprocedure('extensions.crypt(text,text)') is not null
    and to_regprocedure('extensions.gen_salt(text,integer)') is not null,
  'C11 local seed can hash the synthetic Auth password with pgcrypto'
);

select ok(
  (
    select relrowsecurity and relforcerowsecurity
    from pg_class
    where oid = 'catalog.user_roles'::regclass
  ),
  'C6 admin authorization keeps RLS enabled and forced on user roles'
);
select ok(
  exists (
    select 1
    from pg_index as idx
    where idx.indexrelid =
      'catalog.user_roles_admin_banco_one_active_entity_idx'::regclass
      and idx.indisunique
      and pg_get_expr(idx.indpred, idx.indrelid) ilike '%admin_banco%'
      and pg_get_expr(idx.indpred, idx.indrelid) ilike '%is_active%'
  ),
  'C7 database uniquely limits each user to one active admin_banco entity'
);
select ok(
  (
    select prosecdef
      and pg_get_userbyid(proowner) = 'admin_bank_authorization_checker'
      and proconfig @> array['search_path=""', 'row_security=on']::text[]
    from pg_proc
    where oid = 'public.current_admin_bank_entity_id()'::regprocedure
  ),
  'C6 entity resolver uses a fixed path and a restricted RLS owner'
);
select ok(
  (
    select not rolsuper and not rolbypassrls and not rolcanlogin
    from pg_roles
    where rolname = 'admin_bank_authorization_checker'
  ),
  'C6 authorization function owner cannot bypass RLS or log in'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.current_admin_bank_entity_id()',
    'EXECUTE'
  ),
  'C6 authenticated session can resolve its own authorized entity'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.current_admin_bank_entity_id()',
    'EXECUTE'
  )
    and not has_function_privilege(
      'service_role',
      'public.current_admin_bank_entity_id()',
      'EXECUTE'
    ),
  'C9 anon and service_role cannot call the browser authorization resolver'
);
select ok(
  not has_table_privilege('anon', 'catalog.user_roles', 'SELECT')
    and not has_table_privilege('authenticated', 'catalog.user_roles', 'SELECT')
    and not has_table_privilege('service_role', 'catalog.user_roles', 'SELECT'),
  'C9 client roles cannot select catalog.user_roles directly'
);
select is(
  pg_get_function_result('public.current_admin_bank_entity_id()'::regprocedure),
  'uuid',
  'C6 entity resolver returns only one entity UUID'
);
select is(
  pg_get_function_arguments('public.current_admin_bank_entity_id()'::regprocedure),
  '',
  'C6 entity resolver accepts no browser-supplied identity or entity arguments'
);

insert into catalog.entities (id, code, public_name, is_bank, is_active)
values
  ('92000000-0000-4000-8000-000000000001', 'SYN-ADMIN-A', 'Banco sintético Auth A', true, true),
  ('92000000-0000-4000-8000-000000000002', 'SYN-ADMIN-B', 'Banco sintético Auth B', true, true),
  ('92000000-0000-4000-8000-000000000003', 'SYN-ADMIN-C', 'Banco sintético Auth C', true, true),
  ('92000000-0000-4000-8000-000000000004', 'SYN-ADMIN-D', 'Banco sintético Auth D', true, true);

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
  ('91000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'admin-a@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('91000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'admin-b@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('91000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'community@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('91000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', 'companion@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('91000000-0000-4000-8000-000000000005', 'authenticated', 'authenticated', 'general@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('91000000-0000-4000-8000-000000000006', 'authenticated', 'authenticated', 'inactive-admin@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('91000000-0000-4000-8000-000000000007', 'authenticated', 'authenticated', 'no-role@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp());

insert into catalog.user_roles (user_id, role, entity_id, is_active)
values
  ('91000000-0000-4000-8000-000000000001', 'admin_banco', '92000000-0000-4000-8000-000000000001', true),
  ('91000000-0000-4000-8000-000000000002', 'admin_banco', '92000000-0000-4000-8000-000000000002', true),
  ('91000000-0000-4000-8000-000000000003', 'comunidade', null, true),
  ('91000000-0000-4000-8000-000000000004', 'companheiro', null, true),
  ('91000000-0000-4000-8000-000000000005', 'admin_geral', null, true),
  ('91000000-0000-4000-8000-000000000006', 'admin_banco', '92000000-0000-4000-8000-000000000003', false);

select is(
  (
    select count(*)::integer
    from catalog.entities
    where code in ('SYN-ADMIN-A', 'SYN-ADMIN-B', 'SYN-ADMIN-C', 'SYN-ADMIN-D')
  ),
  4,
  'C9 authorization test covers four synthetic entities'
);
select is(
  (
    select count(*)::integer
    from catalog.user_roles
    where user_id = '91000000-0000-4000-8000-000000000001'
      and role = 'admin_banco'
      and is_active
  ),
  1,
  'C7 authorized test identity has exactly one active admin_banco entity'
);

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claim.sub', '91000000-0000-4000-8000-000000000001', true);

select is(
  public.current_admin_bank_entity_id(),
  '92000000-0000-4000-8000-000000000001'::uuid,
  'C6 resolver derives entity A from the authenticated uid'
);
select set_config('request.jwt.claims', '{"sub":"91000000-0000-4000-8000-000000000001","role":"admin_geral","entity_id":"forged"}', true);
select set_config('request.jwt.claim.role', 'admin_geral', true);
select set_config(
  'request.jwt.claim.entity_id',
  '92000000-0000-4000-8000-000000000002',
  true
);
select is(
  public.current_admin_bank_entity_id(),
  '92000000-0000-4000-8000-000000000001'::uuid,
  'C9 resolver ignores browser role and entity claims'
);
select throws_ok(
  $$select * from catalog.user_roles$$,
  '42501',
  null,
  'C9 authenticated browser cannot read role rows directly'
);

reset role;
select throws_ok(
  $$insert into catalog.user_roles (user_id, role, entity_id, is_active)
    values (
      '91000000-0000-4000-8000-000000000001',
      'admin_banco',
      '92000000-0000-4000-8000-000000000002',
      true
    )$$,
  '23505',
  null,
  'C7 second active admin_banco entity is rejected'
);

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claim.sub', '91000000-0000-4000-8000-000000000002', true);
select is(
  public.current_admin_bank_entity_id(),
  '92000000-0000-4000-8000-000000000002'::uuid,
  'C9 resolver returns only admin B linked entity'
);
select set_config('request.jwt.claim.sub', '91000000-0000-4000-8000-000000000003', true);
select is(
  public.current_admin_bank_entity_id(),
  null::uuid,
  'C9 Community without admin_banco resolves no entity'
);
select set_config('request.jwt.claim.sub', '91000000-0000-4000-8000-000000000004', true);
select is(
  public.current_admin_bank_entity_id(),
  null::uuid,
  'C9 Companion without admin_banco resolves no entity'
);
select set_config('request.jwt.claim.sub', '91000000-0000-4000-8000-000000000005', true);
select is(
  public.current_admin_bank_entity_id(),
  null::uuid,
  'C9 admin_geral without admin_banco resolves no entity'
);
select set_config('request.jwt.claim.sub', '91000000-0000-4000-8000-000000000006', true);
select is(
  public.current_admin_bank_entity_id(),
  null::uuid,
  'C9 inactive admin_banco resolves no entity'
);
select set_config('request.jwt.claim.sub', '91000000-0000-4000-8000-000000000007', true);
select is(
  public.current_admin_bank_entity_id(),
  null::uuid,
  'C9 authenticated user without any role resolves no entity'
);

reset role;
set local role anon;
select set_config('request.jwt.claim.role', 'anon', true);
select set_config('request.jwt.claim.sub', '', true);
select throws_ok(
  $$select public.current_admin_bank_entity_id()$$,
  '42501',
  null,
  'C9 anon cannot call the admin entity resolver'
);
select throws_ok(
  $$select * from catalog.user_roles$$,
  '42501',
  null,
  'C9 anon cannot read role rows directly'
);

reset role;
select is(
  pg_get_function_result('public.equipment_availability(text)'::regprocedure),
  'TABLE(bank_name text, available_quantity integer)',
  'C10 equipment_availability public result remains bank_name and available_quantity'
);

update catalog.user_roles
set is_active = false
where user_id = '91000000-0000-4000-8000-000000000001'
  and role = 'admin_banco'
  and entity_id = '92000000-0000-4000-8000-000000000001';

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claim.sub', '91000000-0000-4000-8000-000000000001', true);
select is(
  public.current_admin_bank_entity_id(),
  null::uuid,
  'C8 revoked admin_banco has no resolved entity on the next database request'
);

select * from finish();
rollback;
