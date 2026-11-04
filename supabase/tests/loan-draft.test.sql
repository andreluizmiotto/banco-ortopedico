begin;

select plan(25);

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
  ('d2000000-0000-4000-8000-000000000001', 'BV', 'Banco Boa Vista', true, true, 90),
  ('d2000000-0000-4000-8000-000000000002', 'TV', 'Banco Tres Vendas', true, true, 45),
  ('d2000000-0000-4000-8000-000000000003', 'OFF', 'Banco Encerrado', true, false, 90);

insert into catalog.storage_locations (id, code, name)
values ('b2000000-0000-4000-8000-000000000001', 'BV-SEDE', 'Sede Boa Vista');

insert into auth.users (
  id, aud, role, email, email_confirmed_at, encrypted_password,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  ('a4000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'bv.admin@example.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a4000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'tv.admin@example.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a4000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'off.admin@example.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a4000000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', 'maria.oliveira@example.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, clock_timestamp(), clock_timestamp());

insert into catalog.community_profiles (id, name, cpf, phone, privacy_notice_version)
values ('a4000000-0000-4000-8000-000000000010', 'Maria Oliveira', '11144477735', '+5554999990001', 'v1');

insert into catalog.user_roles (user_id, role, entity_id, is_active)
values
  ('a4000000-0000-4000-8000-000000000001', 'bank_admin', 'd2000000-0000-4000-8000-000000000001', true),
  ('a4000000-0000-4000-8000-000000000002', 'bank_admin', 'd2000000-0000-4000-8000-000000000002', true),
  ('a4000000-0000-4000-8000-000000000003', 'bank_admin', 'd2000000-0000-4000-8000-000000000003', true),
  ('a4000000-0000-4000-8000-000000000010', 'community', null, true);

insert into catalog.equipment_units (
  id, equipment_type_code, owner_entity_id, storage_location_id, status, visible_code
)
values
  ('e2000000-0000-4000-8000-000000000001', 'CR', 'd2000000-0000-4000-8000-000000000001', 'b2000000-0000-4000-8000-000000000001', 'available', 'BVCR0101'),
  ('e2000000-0000-4000-8000-000000000002', 'AN', 'd2000000-0000-4000-8000-000000000001', null, 'available', 'BVAN0101'),
  ('e2000000-0000-4000-8000-000000000003', 'CM', 'd2000000-0000-4000-8000-000000000001', null, 'available', null),
  ('e2000000-0000-4000-8000-000000000004', 'CR', 'd2000000-0000-4000-8000-000000000001', null, 'under_maintenance', 'BVCR0102'),
  ('e2000000-0000-4000-8000-000000000005', 'CR', 'd2000000-0000-4000-8000-000000000001', null, 'available', 'BVCR0103'),
  ('e2000000-0000-4000-8000-000000000006', 'CR', 'd2000000-0000-4000-8000-000000000001', null, 'available', 'BVCR0104'),
  ('e2000000-0000-4000-8000-000000000007', 'CR', 'd2000000-0000-4000-8000-000000000001', null, 'available', 'BVCR0105'),
  ('e2000000-0000-4000-8000-000000000008', 'CR', 'd2000000-0000-4000-8000-000000000001', null, 'available', 'BVCR0106'),
  ('e2000000-0000-4000-8000-000000000009', 'CR', 'd2000000-0000-4000-8000-000000000002', null, 'available', 'TVCR0101');

set local role authenticated;
select pg_temp.loan_login('a4000000-0000-4000-8000-000000000001');

select results_eq(
  $$
    select visible_code
    from public.admin_loan_available_units()
  $$,
  $$
    values
      ('BVCR0101'::text),
      ('BVCR0103'::text),
      ('BVCR0104'::text),
      ('BVCR0105'::text),
      ('BVCR0106'::text),
      (null::text),
      ('BVAN0101'::text)
  $$,
  'C10 only available units of the session bank, grouped by type and ordered by code'
);

select throws_ok(
  $$ select * from public.admin_create_loan_draft(
       'a4000000-0000-4000-8000-000000000010',
       array['e2000000-0000-4000-8000-000000000001']::uuid[],
       null, null, 'custom', 0, null) $$,
  'P0002',
  null,
  'C15 a zero day custom term is refused'
);

select throws_ok(
  $$ select * from public.admin_create_loan_draft(
       'a4000000-0000-4000-8000-000000000010',
       array['e2000000-0000-4000-8000-000000000001']::uuid[],
       null, null, 'custom', 366, null) $$,
  'P0002',
  null,
  'C15 a 366 day custom term is refused'
);

select throws_ok(
  $$ select * from public.admin_create_loan_draft(
       'a4000000-0000-4000-8000-000000000010',
       array['e2000000-0000-4000-8000-000000000001']::uuid[],
       null, null, 'custom', null, null) $$,
  'P0002',
  null,
  'C15 a custom term without a number is refused'
);

select throws_ok(
  $$ select * from public.admin_create_loan_draft(
       'a4000000-0000-4000-8000-000000000010',
       array['e2000000-0000-4000-8000-000000000001']::uuid[],
       null, null, 'no_due_date', null, null) $$,
  'P0002',
  null,
  'C17 a loan without a due date and without a review is refused'
);

select throws_ok(
  $$ select * from public.admin_create_loan_draft(
       'a4000000-0000-4000-8000-000000000010',
       array['e2000000-0000-4000-8000-000000000001']::uuid[],
       null, null, 'no_due_date', null, 0) $$,
  'P0002',
  null,
  'C17 a zero day review is refused'
);

select throws_ok(
  $$ select * from public.admin_create_loan_draft(
       'a4000000-0000-4000-8000-000000000010',
       array['e2000000-0000-4000-8000-000000000001']::uuid[],
       null, null, 'no_due_date', null, 366) $$,
  'P0002',
  null,
  'C17 a 366 day review is refused'
);

select throws_ok(
  $$ select * from public.admin_create_loan_draft(
       'a4000000-0000-4000-8000-000000000010',
       array['e2000000-0000-4000-8000-000000000001']::uuid[],
       'A', null, 'custom', 30, null) $$,
  'P0002',
  null,
  'C19 a one character patient name is refused'
);

select throws_ok(
  $$ select * from public.admin_create_loan_draft(
       'a4000000-0000-4000-8000-000000000010',
       array['e2000000-0000-4000-8000-000000000001']::uuid[],
       repeat('a', 121), null, 'custom', 30, null) $$,
  'P0002',
  null,
  'C19 a 121 character patient name is refused'
);

select throws_ok(
  $$ select * from public.admin_create_loan_draft(
       'a4000000-0000-4000-8000-000000000010',
       array['e2000000-0000-4000-8000-000000000001']::uuid[],
       null, repeat('a', 201), 'custom', 30, null) $$,
  'P0002',
  null,
  'C20 a 201 character condition note is refused'
);

select throws_ok(
  $$ select * from public.admin_create_loan_draft(
       'a4000000-0000-4000-8000-000000000010',
       array['e2000000-0000-4000-8000-000000000004']::uuid[],
       null, null, 'custom', 30, null) $$,
  'P0003',
  null,
  'C22 a unit under maintenance refuses the whole draft'
);

reset role;
set local role authenticated;
select pg_temp.loan_login('a4000000-0000-4000-8000-000000000003');

select throws_ok(
  $$ select * from public.admin_create_loan_draft(
       'a4000000-0000-4000-8000-000000000010',
       array['e2000000-0000-4000-8000-000000000001']::uuid[],
       null, null, 'custom', 30, null) $$,
  '42501',
  null,
  'C25 an inactive bank refuses a new loan'
);

reset role;

select ok(
  (select count(*) from catalog.loans) = 0
    and (select count(*) from catalog.loan_lines) = 0
    and (select count(*) from catalog.loan_event_audit) = 0
    and (
      select count(*) from catalog.equipment_units
      where status = 'reserved'
        and owner_entity_id in (
          'd2000000-0000-4000-8000-000000000001',
          'd2000000-0000-4000-8000-000000000002'
        )
    ) = 0,
  'C22 a refused draft writes no loan, no line, no audit and reserves no unit'
);

set local role authenticated;
select pg_temp.loan_login('a4000000-0000-4000-8000-000000000001');

create temp table draft_a as
select * from public.admin_create_loan_draft(
  'a4000000-0000-4000-8000-000000000010',
  array[
    'e2000000-0000-4000-8000-000000000001',
    'e2000000-0000-4000-8000-000000000002',
    'e2000000-0000-4000-8000-000000000003'
  ]::uuid[],
  '  Ana Souza  ',
  '  bom estado  ',
  'custom',
  30,
  null
);

reset role;

select ok(
  (select count(*) from catalog.loans) = 1
    and (select count(*) from catalog.loan_lines) = 3
    and (
      select count(*) from catalog.loans
      where entity_id = 'd2000000-0000-4000-8000-000000000001'
    ) = 1,
  'C12 three units of two types become one loan with three lines in the session bank'
);

select results_eq(
  $$
    select due_date, review_date
    from catalog.loans
    where id = (select id from catalog.loans limit 1)
  $$,
  $$
    values (
      ((now() at time zone 'America/Sao_Paulo')::date + 30),
      null::date
    )
  $$,
  'C14 a 30 day custom term stores the due date and no review date'
);

select results_eq(
  $$ select patient_name, condition_note from catalog.loans $$,
  $$ values ('Ana Souza'::text, 'bom estado'::text) $$,
  'C18 and C20 the patient name and the condition note are stored trimmed'
);

select ok(
  (
    select count(*) = 3
    from catalog.equipment_units
    where id in (
      'e2000000-0000-4000-8000-000000000001',
      'e2000000-0000-4000-8000-000000000002',
      'e2000000-0000-4000-8000-000000000003'
    )
      and status = 'reserved'
  ),
  'C21 the draft reserves every chosen unit'
);

select ok(
  (
    select count(*) = 1
      and bool_and(action = 'loan_draft_created')
      and bool_and(array_length(unit_ids, 1) = 3)
      and bool_and(actor_user_id = 'a4000000-0000-4000-8000-000000000001')
      and bool_and(entity_id = 'd2000000-0000-4000-8000-000000000001')
      and bool_and(due_date = (now() at time zone 'America/Sao_Paulo')::date + 30)
    from catalog.loan_event_audit
  ),
  'C21 the draft writes one audit row with actor, bank, units and dates'
);

set local role authenticated;
select pg_temp.loan_login('a4000000-0000-4000-8000-000000000001');

select results_eq(
  $$
    select due_date
    from public.admin_create_loan_draft(
      'a4000000-0000-4000-8000-000000000010',
      array['e2000000-0000-4000-8000-000000000005']::uuid[],
      null, null, 'suggested', null, null
    )
  $$,
  $$ values ((now() at time zone 'America/Sao_Paulo')::date + 90) $$,
  'C13 the suggested term comes from the bank configuration of 90 days'
);

reset role;
set local role authenticated;
select pg_temp.loan_login('a4000000-0000-4000-8000-000000000002');

select results_eq(
  $$
    select due_date
    from public.admin_create_loan_draft(
      'a4000000-0000-4000-8000-000000000010',
      array['e2000000-0000-4000-8000-000000000009']::uuid[],
      null, null, 'suggested', null, null
    )
  $$,
  $$ values ((now() at time zone 'America/Sao_Paulo')::date + 45) $$,
  'C13 a second bank suggests its own 45 days'
);

reset role;
set local role authenticated;
select pg_temp.loan_login('a4000000-0000-4000-8000-000000000001');

select results_eq(
  $$
    select due_date, review_date
    from public.admin_create_loan_draft(
      'a4000000-0000-4000-8000-000000000010',
      array['e2000000-0000-4000-8000-000000000007']::uuid[],
      null, null, 'no_due_date', null, 90
    )
  $$,
  $$
    values (
      null::date,
      ((now() at time zone 'America/Sao_Paulo')::date + 90)
    )
  $$,
  'C16 a loan without a due date stores the 90 day review and no due date'
);

select results_eq(
  $$
    select review_date
    from public.admin_create_loan_draft(
      'a4000000-0000-4000-8000-000000000010',
      array['e2000000-0000-4000-8000-000000000008']::uuid[],
      null, null, 'no_due_date', null, 120
    )
  $$,
  $$ values ((now() at time zone 'America/Sao_Paulo')::date + 120) $$,
  'C16 the review date accepts any value between 1 and 365 days'
);

reset role;

update catalog.equipment_units
set status = 'available'
where id = 'e2000000-0000-4000-8000-000000000007';

set local role authenticated;
select pg_temp.loan_login('a4000000-0000-4000-8000-000000000001');

select throws_ok(
  $$ select * from public.admin_create_loan_draft(
       'a4000000-0000-4000-8000-000000000010',
       array['e2000000-0000-4000-8000-000000000007']::uuid[],
       null, null, 'custom', 30, null) $$,
  'P0003',
  null,
  'C22 a unit released by hand in the inventory but still held by an open loan is refused'
);

select results_eq(
  $$
    select public_code
    from public.admin_create_loan_draft(
      'a4000000-0000-4000-8000-000000000010',
      array[
        'e2000000-0000-4000-8000-000000000001',
        'e2000000-0000-4000-8000-000000000002',
        'e2000000-0000-4000-8000-000000000003'
      ]::uuid[],
      '  Ana Souza  ',
      '  bom estado  ',
      'custom',
      30,
      null
    )
  $$,
  $$ values ((select public_code from draft_a)) $$,
  'C24 resending the same draft returns the same public code'
);

reset role;

select ok(
  (select count(*) from catalog.loans) = 5
    and (
      select count(*) from catalog.loan_event_audit
      where action = 'loan_draft_created'
    ) = 5,
  'C24 the resend creates no second loan and no second audit'
);

select * from finish();

rollback;
