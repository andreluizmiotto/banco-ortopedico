begin;

select plan(14);

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
values ('d4000000-0000-4000-8000-000000000001', 'BV', 'Banco Boa Vista', true, true, 90);

insert into auth.users (
  id, aud, role, email, email_confirmed_at, encrypted_password,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  ('a6000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'bv.admin@example.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a6000000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', 'maria.oliveira@example.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, clock_timestamp(), clock_timestamp());

insert into catalog.community_profiles (id, name, cpf, phone, privacy_notice_version)
values ('a6000000-0000-4000-8000-000000000010', 'Maria Oliveira', '11144477735', '+5554999990001', 'v1');

insert into catalog.user_roles (user_id, role, entity_id, is_active)
values
  ('a6000000-0000-4000-8000-000000000001', 'bank_admin', 'd4000000-0000-4000-8000-000000000001', true),
  ('a6000000-0000-4000-8000-000000000010', 'community', null, true);

insert into catalog.document_models (id, entity_id, document_type, version, body)
values (
  'f4000000-0000-4000-8000-000000000001',
  'd4000000-0000-4000-8000-000000000001',
  'loan_term',
  1,
  'Termo de {bank_name}'
);

insert into catalog.equipment_units (
  id, equipment_type_code, owner_entity_id, status, visible_code
)
values
  ('e4000000-0000-4000-8000-000000000001', 'CR', 'd4000000-0000-4000-8000-000000000001', 'reserved', 'BVCR0301'),
  ('e4000000-0000-4000-8000-000000000002', 'AN', 'd4000000-0000-4000-8000-000000000001', 'reserved', 'BVAN0301'),
  ('e4000000-0000-4000-8000-000000000003', 'CR', 'd4000000-0000-4000-8000-000000000001', 'reserved', 'BVCR0302'),
  ('e4000000-0000-4000-8000-000000000004', 'CR', 'd4000000-0000-4000-8000-000000000001', 'reserved', 'BVCR0303'),
  ('e4000000-0000-4000-8000-000000000005', 'CR', 'd4000000-0000-4000-8000-000000000001', 'on_loan', 'BVCR0304'),
  ('e4000000-0000-4000-8000-000000000006', 'CR', 'd4000000-0000-4000-8000-000000000001', 'reserved', 'BVCR0305'),
  ('e4000000-0000-4000-8000-000000000007', 'CR', 'd4000000-0000-4000-8000-000000000001', 'on_loan', 'BVCR0306');

insert into catalog.loans (
  id, public_code, entity_id, borrower_user_id, delivery_date, due_date,
  status, created_by_user_id, completed_at
)
values
  ('f4000000-0000-4000-8000-000000000010', 'DDDD00000010', 'd4000000-0000-4000-8000-000000000001', 'a6000000-0000-4000-8000-000000000010', current_date, current_date + 30, 'draft', 'a6000000-0000-4000-8000-000000000001', null),
  ('f4000000-0000-4000-8000-000000000011', 'DDDD00000011', 'd4000000-0000-4000-8000-000000000001', 'a6000000-0000-4000-8000-000000000010', current_date, current_date + 30, 'draft', 'a6000000-0000-4000-8000-000000000001', null),
  ('f4000000-0000-4000-8000-000000000012', 'DDDD00000012', 'd4000000-0000-4000-8000-000000000001', 'a6000000-0000-4000-8000-000000000010', current_date, current_date + 30, 'draft', 'a6000000-0000-4000-8000-000000000001', null),
  ('f4000000-0000-4000-8000-000000000013', 'DDDD00000013', 'd4000000-0000-4000-8000-000000000001', 'a6000000-0000-4000-8000-000000000010', current_date, current_date + 30, 'active', 'a6000000-0000-4000-8000-000000000001', clock_timestamp()),
  ('f4000000-0000-4000-8000-000000000014', 'DDDD00000014', 'd4000000-0000-4000-8000-000000000001', 'a6000000-0000-4000-8000-000000000010', current_date, current_date + 30, 'draft', 'a6000000-0000-4000-8000-000000000001', null),
  ('f4000000-0000-4000-8000-000000000015', 'DDDD00000015', 'd4000000-0000-4000-8000-000000000001', 'a6000000-0000-4000-8000-000000000010', current_date, current_date + 30, 'active', 'a6000000-0000-4000-8000-000000000001', clock_timestamp());

insert into catalog.loan_lines (loan_id, unit_id)
values
  ('f4000000-0000-4000-8000-000000000010', 'e4000000-0000-4000-8000-000000000001'),
  ('f4000000-0000-4000-8000-000000000010', 'e4000000-0000-4000-8000-000000000002'),
  ('f4000000-0000-4000-8000-000000000011', 'e4000000-0000-4000-8000-000000000003'),
  ('f4000000-0000-4000-8000-000000000012', 'e4000000-0000-4000-8000-000000000004'),
  ('f4000000-0000-4000-8000-000000000013', 'e4000000-0000-4000-8000-000000000005'),
  ('f4000000-0000-4000-8000-000000000014', 'e4000000-0000-4000-8000-000000000006'),
  ('f4000000-0000-4000-8000-000000000015', 'e4000000-0000-4000-8000-000000000007');

insert into catalog.loan_documents (
  loan_id, document_model_id, version, storage_path, content_hash, is_current, created_by_user_id
)
values
  (
    'f4000000-0000-4000-8000-000000000010',
    'f4000000-0000-4000-8000-000000000001',
    1,
    'd4000000-0000-4000-8000-000000000001/f4000000-0000-4000-8000-000000000010/1.pdf',
    repeat('a', 64),
    true,
    'a6000000-0000-4000-8000-000000000001'
  ),
  (
    'f4000000-0000-4000-8000-000000000012',
    'f4000000-0000-4000-8000-000000000001',
    1,
    'd4000000-0000-4000-8000-000000000001/f4000000-0000-4000-8000-000000000012/1.pdf',
    repeat('b', 64),
    true,
    'a6000000-0000-4000-8000-000000000001'
  ),
  (
    'f4000000-0000-4000-8000-000000000014',
    'f4000000-0000-4000-8000-000000000001',
    1,
    'd4000000-0000-4000-8000-000000000001/f4000000-0000-4000-8000-000000000014/1.pdf',
    repeat('c', 64),
    true,
    'a6000000-0000-4000-8000-000000000001'
  );

set local role authenticated;
select pg_temp.loan_login('a6000000-0000-4000-8000-000000000001');

select results_eq(
  $$ select status from public.admin_complete_loan('DDDD00000010') $$,
  $$ values ('active'::text) $$,
  'C38 completing the delivery moves the loan to active'
);

reset role;

select ok(
  (
    select count(*) = 2
    from catalog.equipment_units
    where id in (
      'e4000000-0000-4000-8000-000000000001',
      'e4000000-0000-4000-8000-000000000002'
    )
      and status = 'on_loan'
  )
    and (
    select completed_at is not null
    from catalog.loans
    where id = 'f4000000-0000-4000-8000-000000000010'
  ),
  'C38 every held unit becomes on_loan and the loan records the completion time'
);

select ok(
  (
    select count(*) = 1
      and bool_and(action = 'loan_completed')
      and bool_and(array_length(unit_ids, 1) = 2)
    from catalog.loan_event_audit
    where loan_id = 'f4000000-0000-4000-8000-000000000010'
  )
    and (
    select count(*) = 2
      and bool_and(action = 'unit_updated')
      and bool_and(previous_status = 'reserved')
      and bool_and(new_status = 'on_loan')
    from catalog.equipment_unit_change_audit
    where entity_id = 'd4000000-0000-4000-8000-000000000001'
  ),
  'C38 the completion writes the loan audit and one unit audit per unit'
);

set local role authenticated;
select pg_temp.loan_login('a6000000-0000-4000-8000-000000000001');

select throws_ok(
  $$ select * from public.admin_complete_loan('DDDD00000011') $$,
  'P0002',
  null,
  'C39 completing without a current term is refused'
);

reset role;

select ok(
  (
    select status = 'draft' and completed_at is null
    from catalog.loans
    where id = 'f4000000-0000-4000-8000-000000000011'
  )
    and (
    select status = 'reserved'
    from catalog.equipment_units
    where id = 'e4000000-0000-4000-8000-000000000003'
  ),
  'C39 the refusal changes neither the loan nor the unit'
);

update catalog.equipment_units
set status = 'available'
where id = 'e4000000-0000-4000-8000-000000000004';

set local role authenticated;
select pg_temp.loan_login('a6000000-0000-4000-8000-000000000001');

select throws_ok(
  $$ select * from public.admin_complete_loan('DDDD00000012') $$,
  'P0003',
  null,
  'C40 completing with a unit that left reserved is refused'
);

reset role;

select ok(
  (
    select status = 'draft'
    from catalog.loans
    where id = 'f4000000-0000-4000-8000-000000000012'
  )
    and (
    select status = 'available'
    from catalog.equipment_units
    where id = 'e4000000-0000-4000-8000-000000000004'
  ),
  'C40 the refusal changes neither the loan nor the unit'
);

set local role authenticated;
select pg_temp.loan_login('a6000000-0000-4000-8000-000000000001');

select throws_ok(
  $$ select * from public.admin_complete_loan('DDDD00000013') $$,
  'P0003',
  null,
  'C41 completing a loan that is not a draft is refused'
);

select throws_ok(
  $$ select public.admin_record_loan_term(
       'DDDD00000013',
       1,
       'd4000000-0000-4000-8000-000000000001/f4000000-0000-4000-8000-000000000013/1.pdf',
       repeat('d', 64)
     ) $$,
  'P0003',
  null,
  'C41 recording a term for a loan that is not a draft is refused'
);

select results_eq(
  $$ select public.admin_cancel_loan_draft('DDDD00000014') $$,
  $$ values ('cancelled'::text) $$,
  'C43 giving up the draft cancels the loan'
);

reset role;

select ok(
  (
    select status = 'cancelled' and cancelled_at is not null
    from catalog.loans
    where id = 'f4000000-0000-4000-8000-000000000014'
  )
    and (
    select released_at is not null
    from catalog.loan_lines
    where loan_id = 'f4000000-0000-4000-8000-000000000014'
  )
    and (
    select status = 'available'
    from catalog.equipment_units
    where id = 'e4000000-0000-4000-8000-000000000006'
  ),
  'C43 the cancellation releases the line and returns the unit to available'
);

select ok(
  (
    select count(*) = 1
      and bool_and(action = 'loan_draft_cancelled')
      and bool_and(previous_status = 'draft')
      and bool_and(new_status = 'cancelled')
    from catalog.loan_event_audit
    where loan_id = 'f4000000-0000-4000-8000-000000000014'
  ),
  'C43 the cancellation writes its audit row'
);

set local role authenticated;
select pg_temp.loan_login('a6000000-0000-4000-8000-000000000001');

select throws_ok(
  $$ select public.admin_cancel_loan_draft('DDDD00000015') $$,
  'P0003',
  null,
  'C44 giving up a loan that is not a draft is refused'
);

select ok(
  (
    select public_code <> 'DDDD00000014'
    from public.admin_create_loan_draft(
      'a6000000-0000-4000-8000-000000000010',
      array['e4000000-0000-4000-8000-000000000006']::uuid[],
      null, null, 'custom', 30, null
    )
  ),
  'C45 the same person and unit accept a new draft after the cancellation'
);

reset role;

select * from finish();

rollback;
