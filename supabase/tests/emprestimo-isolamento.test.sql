begin;

select plan(12);

create function pg_temp.loan_login(p_sub text)
returns void
language plpgsql
as $function$
begin
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  perform set_config('request.jwt.claim.sub', p_sub, true);
end
$function$;

insert into catalog.entities (id, code, public_name, is_bank, is_active, loan_suggested_days)
values
  ('d5000000-0000-4000-8000-000000000001', 'BV', 'Banco Boa Vista', true, true, 90),
  ('d5000000-0000-4000-8000-000000000002', 'TV', 'Banco Tres Vendas', true, true, 45),
  ('d5000000-0000-4000-8000-000000000003', 'EC', 'Banco Erechim', true, true, 60);

insert into auth.users (
  id, aud, role, email, email_confirmed_at, encrypted_password,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  ('a7000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'bv.admin@example.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a7000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'tv.admin@example.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a7000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'ec.admin@example.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a7000000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', 'maria.oliveira@example.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, clock_timestamp(), clock_timestamp());

insert into catalog.community_profiles (id, name, cpf, phone, privacy_notice_version)
values ('a7000000-0000-4000-8000-000000000010', 'Maria Oliveira', '11144477735', '+5554999990001', 'v1');

insert into catalog.user_roles (user_id, role, entity_id, is_active)
values
  ('a7000000-0000-4000-8000-000000000001', 'bank_admin', 'd5000000-0000-4000-8000-000000000001', true),
  ('a7000000-0000-4000-8000-000000000002', 'bank_admin', 'd5000000-0000-4000-8000-000000000002', true),
  ('a7000000-0000-4000-8000-000000000003', 'bank_admin', 'd5000000-0000-4000-8000-000000000003', true),
  ('a7000000-0000-4000-8000-000000000010', 'community', null, true);

insert into catalog.equipment_units (
  id, equipment_type_code, owner_entity_id, status, visible_code
)
values
  ('e5000000-0000-4000-8000-000000000001', 'CR', 'd5000000-0000-4000-8000-000000000001', 'reserved', 'BVCR0401'),
  ('e5000000-0000-4000-8000-000000000002', 'CR', 'd5000000-0000-4000-8000-000000000001', 'available', 'BVCR0402'),
  ('e5000000-0000-4000-8000-000000000003', 'CR', 'd5000000-0000-4000-8000-000000000002', 'reserved', 'TVCR0401');

insert into catalog.loans (
  id, public_code, entity_id, borrower_user_id, delivery_date, due_date,
  status, created_by_user_id, created_at
)
values
  (
    'f5000000-0000-4000-8000-000000000010',
    'EEEE00000010',
    'd5000000-0000-4000-8000-000000000001',
    'a7000000-0000-4000-8000-000000000010',
    current_date,
    current_date + 30,
    'draft',
    'a7000000-0000-4000-8000-000000000001',
    clock_timestamp() - interval '40 days'
  ),
  (
    'f5000000-0000-4000-8000-000000000011',
    'EEEE00000011',
    'd5000000-0000-4000-8000-000000000002',
    'a7000000-0000-4000-8000-000000000010',
    current_date,
    current_date + 30,
    'draft',
    'a7000000-0000-4000-8000-000000000002',
    clock_timestamp()
  );

insert into catalog.loan_lines (loan_id, unit_id)
values
  ('f5000000-0000-4000-8000-000000000010', 'e5000000-0000-4000-8000-000000000001'),
  ('f5000000-0000-4000-8000-000000000011', 'e5000000-0000-4000-8000-000000000003');

select ok(
  not exists (
    select 1
    from (
      values
        ('catalog.loans'),
        ('catalog.loan_lines'),
        ('catalog.loan_documents'),
        ('catalog.loan_event_audit'),
        ('catalog.document_models'),
        ('catalog.community_profiles')
    ) as target(name)
    cross join (
      values ('anon'), ('authenticated'), ('service_role')
    ) as actor(role_name)
    cross join (
      values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE')
    ) as privilege(kind)
    where has_table_privilege(actor.role_name, target.name, privilege.kind)
  ),
  'C47 no Data API role holds any privilege on the six tables, for every role, table and privilege'
);

select ok(
  (
    select count(*) = 10
      and bool_and(
        has_function_privilege('authenticated', signature, 'EXECUTE')
      )
    from (
      values
        ('public.admin_search_people(text)'),
        ('public.admin_loan_available_units()'),
        ('public.admin_create_loan_draft(uuid,uuid[],text,text,text,integer,integer)'),
        ('public.admin_bank_loans()'),
        ('public.admin_loan_detail(text)'),
        ('public.admin_loan_term_data(text)'),
        ('public.admin_record_loan_term(text,integer,text,text)'),
        ('public.admin_loan_term_file(text)'),
        ('public.admin_complete_loan(text)'),
        ('public.admin_cancel_loan_draft(text)')
    ) as loan_rpc(signature)
  )
    and not exists (
    select 1
    from (
      values
        ('public.admin_search_people(text)'),
        ('public.admin_loan_available_units()'),
        ('public.admin_create_loan_draft(uuid,uuid[],text,text,text,integer,integer)'),
        ('public.admin_bank_loans()'),
        ('public.admin_loan_detail(text)'),
        ('public.admin_loan_term_data(text)'),
        ('public.admin_record_loan_term(text,integer,text,text)'),
        ('public.admin_loan_term_file(text)'),
        ('public.admin_complete_loan(text)'),
        ('public.admin_cancel_loan_draft(text)')
    ) as loan_rpc(signature)
    cross join (
      values ('anon'), ('service_role')
    ) as actor(role_name)
    where has_function_privilege(actor.role_name, loan_rpc.signature, 'EXECUTE')
  ),
  'C47 all ten loan RPCs are executable by authenticated and by no other Data API role'
);

set local role anon;

select throws_ok(
  $$ select * from public.admin_loan_available_units() $$,
  '42501',
  null,
  'C47 an anonymous session cannot call the loan RPCs'
);

reset role;
set local role authenticated;
select pg_temp.loan_login('a7000000-0000-4000-8000-000000000002');

select throws_ok(
  $$ select * from public.admin_loan_detail('EEEE00000010') $$,
  'P0005',
  null,
  'C47 a bank admin cannot read the loan of another bank'
);

reset role;
set local role authenticated;
select pg_temp.loan_login('a7000000-0000-4000-8000-000000000010');

select throws_ok(
  $$ select * from public.admin_loan_available_units() $$,
  '42501',
  null,
  'C47 a session without the bank admin role is refused'
);

reset role;
set local role authenticated;
select pg_temp.loan_login('a7000000-0000-4000-8000-000000000001');

select ok(
  exists (
    select 1
    from public.admin_bank_equipment_units()
    where unit_id = 'e5000000-0000-4000-8000-000000000001'
      and status = 'reserved'
  ),
  'C48 a unit held by a draft shows as reserved in the inventory panel'
);

select results_eq(
  $$ select available_quantity from public.equipment_availability('CR') where bank_name = 'Banco Boa Vista' $$,
  $$ values (1) $$,
  'C49 the public availability stops counting the unit held by a draft'
);

select ok(
  (
    select masked_cpf = '***.***.***-35'
      and masked_phone = '(54) *****-0001'
    from public.admin_search_people('maria')
  ),
  'C50 the search answer carries only masked CPF and phone'
);

select ok(
  (
    select masked_cpf = '***.***.***-35'
      and masked_phone = '(54) *****-0001'
      and masked_cpf <> '11144477735'
      and masked_phone <> '+5554999990001'
    from public.admin_loan_detail('EEEE00000010')
  ),
  'C50 the loan detail carries only masked CPF and phone'
);

select ok(
  exists (
    select 1
    from public.admin_bank_loans()
    where public_code = 'EEEE00000010'
      and created_at < clock_timestamp() - interval '39 days'
  ),
  'C55 a draft created forty days ago is still listed'
);

reset role;

select ok(
  (
    select status = 'reserved'
    from catalog.equipment_units
    where id = 'e5000000-0000-4000-8000-000000000001'
  ),
  'C55 the unit of an old draft is still held, with no automatic expiry'
);

reset role;
set local role authenticated;
select pg_temp.loan_login('a7000000-0000-4000-8000-000000000003');

select results_eq(
  $$ select bank_name, public_code from public.admin_bank_loans() $$,
  $$ values ('Banco Erechim'::text, null::text) $$,
  'C57 a bank with no draft still receives its name, so the page shows the empty state'
);

select * from finish();

rollback;
