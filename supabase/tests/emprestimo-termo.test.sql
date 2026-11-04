begin;

select plan(17);

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
  ('d3000000-0000-4000-8000-000000000001', 'BV', 'Banco Boa Vista', true, true, 90),
  ('d3000000-0000-4000-8000-000000000002', 'NM', 'Banco Sem Modelo', true, true, 90);

insert into auth.users (
  id, aud, role, email, email_confirmed_at, encrypted_password,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  ('a5000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'bv.admin@example.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a5000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'nm.admin@example.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a5000000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', 'maria.oliveira@example.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, clock_timestamp(), clock_timestamp());

insert into catalog.community_profiles (id, name, cpf, phone, privacy_notice_version)
values ('a5000000-0000-4000-8000-000000000010', 'Maria Oliveira', '11144477735', '+5554999990001', 'v1');

insert into catalog.user_roles (user_id, role, entity_id, is_active)
values
  ('a5000000-0000-4000-8000-000000000001', 'bank_admin', 'd3000000-0000-4000-8000-000000000001', true),
  ('a5000000-0000-4000-8000-000000000002', 'bank_admin', 'd3000000-0000-4000-8000-000000000002', true),
  ('a5000000-0000-4000-8000-000000000010', 'community', null, true);

insert into catalog.document_models (id, entity_id, document_type, version, body, review_status)
values (
  'f3000000-0000-4000-8000-000000000001',
  'd3000000-0000-4000-8000-000000000001',
  'loan_term',
  1,
  'Termo de {bank_name} para {borrower_name}',
  'pending_legal_review'
);

insert into catalog.equipment_units (
  id, equipment_type_code, owner_entity_id, status, visible_code
)
values
  ('e3000000-0000-4000-8000-000000000001', 'CR', 'd3000000-0000-4000-8000-000000000001', 'reserved', 'BVCR0201'),
  ('e3000000-0000-4000-8000-000000000002', 'AN', 'd3000000-0000-4000-8000-000000000001', 'reserved', 'BVAN0201'),
  ('e3000000-0000-4000-8000-000000000003', 'CR', 'd3000000-0000-4000-8000-000000000001', 'reserved', 'BVCR0202'),
  ('e3000000-0000-4000-8000-000000000004', 'CR', 'd3000000-0000-4000-8000-000000000002', 'reserved', 'NMCR0201');

insert into catalog.loans (
  id, public_code, entity_id, borrower_user_id, patient_name, condition_note,
  delivery_date, due_date, status, created_by_user_id
)
values
  (
    'f3000000-0000-4000-8000-000000000010',
    'CCCC00000010',
    'd3000000-0000-4000-8000-000000000001',
    'a5000000-0000-4000-8000-000000000010',
    'Ana Souza',
    'bom estado',
    current_date,
    current_date + 30,
    'draft',
    'a5000000-0000-4000-8000-000000000001'
  ),
  (
    'f3000000-0000-4000-8000-000000000011',
    'CCCC00000011',
    'd3000000-0000-4000-8000-000000000001',
    'a5000000-0000-4000-8000-000000000010',
    null,
    null,
    current_date,
    current_date + 30,
    'draft',
    'a5000000-0000-4000-8000-000000000001'
  ),
  (
    'f3000000-0000-4000-8000-000000000012',
    'CCCC00000012',
    'd3000000-0000-4000-8000-000000000002',
    'a5000000-0000-4000-8000-000000000010',
    null,
    null,
    current_date,
    current_date + 30,
    'draft',
    'a5000000-0000-4000-8000-000000000002'
  );

insert into catalog.loan_lines (loan_id, unit_id)
values
  ('f3000000-0000-4000-8000-000000000010', 'e3000000-0000-4000-8000-000000000001'),
  ('f3000000-0000-4000-8000-000000000010', 'e3000000-0000-4000-8000-000000000002'),
  ('f3000000-0000-4000-8000-000000000011', 'e3000000-0000-4000-8000-000000000003'),
  ('f3000000-0000-4000-8000-000000000012', 'e3000000-0000-4000-8000-000000000004');

set local role authenticated;
select pg_temp.loan_login('a5000000-0000-4000-8000-000000000001');

create temp table term_data as
select * from public.admin_loan_term_data('CCCC00000010');

select results_eq(
  $$
    select model_version, model_review_status, next_version, next_storage_path
    from term_data
  $$,
  $$
    values (
      1,
      'pending_legal_review'::text,
      1,
      ('d3000000-0000-4000-8000-000000000001/'
        || 'f3000000-0000-4000-8000-000000000010/1.pdf')::text
    )
  $$,
  'C29 the term data carries the active model version and the next storage path'
);

select results_eq(
  $$
    select public.admin_record_loan_term(
      'CCCC00000010',
      1,
      (select next_storage_path from term_data),
      repeat('a', 64)
    )
  $$,
  $$ values (1) $$,
  'C29 recording the generated file returns its version'
);

reset role;

select ok(
  (
    select count(*) = 1
      and bool_and(document_model_id = 'f3000000-0000-4000-8000-000000000001')
      and bool_and(is_current)
      and bool_and(version = 1)
    from catalog.loan_documents
    where loan_id = 'f3000000-0000-4000-8000-000000000010'
  )
    and (
    select count(*) = 1
      and bool_and(document_model_version = 1)
      and bool_and(content_hash = repeat('a', 64))
    from catalog.loan_event_audit
    where loan_id = 'f3000000-0000-4000-8000-000000000010'
      and action = 'loan_term_generated'
  ),
  'C29 the file records the model and the audit records version and hash'
);

set local role authenticated;
select pg_temp.loan_login('a5000000-0000-4000-8000-000000000001');

select results_eq(
  $$
    select current_version, current_content_hash
    from public.admin_loan_term_data('CCCC00000010')
  $$,
  $$ values (1, repeat('a', 64)) $$,
  'C29 the term data reports the current file so an identical term is not uploaded again'
);

reset role;

set local role authenticated;
select pg_temp.loan_login('a5000000-0000-4000-8000-000000000002');

select throws_ok(
  $$ select * from public.admin_loan_term_data('CCCC00000012') $$,
  'P0003',
  null,
  'C30 a bank without an active model refuses to build the term'
);

reset role;

select ok(
  (select count(*) from catalog.loan_documents) = 1
    and (
      select count(*) from catalog.loan_event_audit
      where action = 'loan_term_generated'
    ) = 1,
  'C30 the refusal writes no file and no audit'
);

reset role;

select ok(
  (
    select storage_path = (
      'd3000000-0000-4000-8000-000000000001/'
      || 'f3000000-0000-4000-8000-000000000010/1.pdf'
    )
      and storage_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9]{1,4}\.pdf$'
    from catalog.loan_documents
    where loan_id = 'f3000000-0000-4000-8000-000000000010'
  ),
  'C31 the file path is the bank, the loan and the version, with no personal data'
);

set local role authenticated;
select pg_temp.loan_login('a5000000-0000-4000-8000-000000000001');

select throws_ok(
  $$ select public.admin_record_loan_term(
       'CCCC00000010',
       1,
       'd3000000-0000-4000-8000-000000000001/f3000000-0000-4000-8000-000000000010/9.pdf',
       repeat('c', 64)
     ) $$,
  'P0002',
  null,
  'C31 a path outside the expected one is refused, so a failed upload records nothing'
);

select results_eq(
  $$
    select public.admin_record_loan_term(
      'CCCC00000010',
      1,
      (select next_storage_path from term_data),
      repeat('a', 64)
    )
  $$,
  $$ values (1) $$,
  'C32 recording the same content again keeps the same version'
);

reset role;

select ok(
  (
    select count(*) = 1
    from catalog.loan_documents
    where loan_id = 'f3000000-0000-4000-8000-000000000010'
      and is_current
  )
    and (
    select count(*) = 1
    from catalog.loan_event_audit
    where loan_id = 'f3000000-0000-4000-8000-000000000010'
      and action = 'loan_term_generated'
  ),
  'C32 the resend keeps one current file and one audit row'
);

update catalog.loans
set condition_note = 'com marcas de uso'
where id = 'f3000000-0000-4000-8000-000000000010';

set local role authenticated;
select pg_temp.loan_login('a5000000-0000-4000-8000-000000000001');

create temp table term_data_v2 as
select * from public.admin_loan_term_data('CCCC00000010');

select results_eq(
  $$
    select public.admin_record_loan_term(
      'CCCC00000010',
      1,
      (select next_storage_path from term_data_v2),
      repeat('b', 64)
    )
  $$,
  $$ values (2) $$,
  'C33 a changed draft records the next version'
);

reset role;

select ok(
  (
    select count(*) = 2
    from catalog.loan_documents
    where loan_id = 'f3000000-0000-4000-8000-000000000010'
  )
    and (
    select count(*) = 1
      and bool_and(version = 2)
    from catalog.loan_documents
    where loan_id = 'f3000000-0000-4000-8000-000000000010'
      and is_current
  )
    and (
    select count(*) = 1
      and bool_and(not is_current)
    from catalog.loan_documents
    where loan_id = 'f3000000-0000-4000-8000-000000000010'
      and version = 1
  ),
  'C33 the previous version is kept and only the newest is current'
);

set local role authenticated;
select pg_temp.loan_login('a5000000-0000-4000-8000-000000000001');

select throws_ok(
  $$ select public.admin_loan_term_file('CCCC00000012') $$,
  'P0005',
  'Empréstimo não encontrado',
  'C37 a loan of another bank is refused with the generic answer'
);

select throws_ok(
  $$ select public.admin_loan_term_file('ZZZZ00000000') $$,
  'P0005',
  'Empréstimo não encontrado',
  'C37 an unknown code is refused with the same generic answer'
);

select throws_ok(
  $$ select public.admin_loan_term_file('CCCC00000011') $$,
  'P0005',
  'Empréstimo não encontrado',
  'C37 a loan without a generated term is refused with the same generic answer'
);

select results_eq(
  $$ select borrower_cpf from public.admin_loan_term_data('CCCC00000010') $$,
  $$ values ('11144477735'::text) $$,
  'C56 the term data carries the full CPF of the borrower of its own draft'
);

select throws_ok(
  $$ select * from public.admin_loan_term_data('CCCC00000012') $$,
  'P0005',
  null,
  'C56 the term data of another bank is refused, so no CPF leaves the bank'
);

reset role;

select * from finish();

rollback;
