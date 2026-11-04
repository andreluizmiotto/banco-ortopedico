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
  ('d1000000-0000-4000-8000-000000000001', 'BV', 'Banco Boa Vista', true, true, 90),
  ('d1000000-0000-4000-8000-000000000002', 'TV', 'Banco Tres Vendas', true, true, 45);

insert into auth.users (
  id, aud, role, email, email_confirmed_at, encrypted_password,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
select
  fixture.id::uuid,
  'authenticated',
  'authenticated',
  fixture.email,
  clock_timestamp(),
  '',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb,
  clock_timestamp(),
  clock_timestamp()
from (
  values
    ('a3000000-0000-4000-8000-000000000001', 'admin.boavista@example.test'),
    ('a3000000-0000-4000-8000-000000000002', 'admin.tresvendas@example.test'),
    ('a3000000-0000-4000-8000-000000000010', 'maria.oliveira@example.test'),
    ('a3000000-0000-4000-8000-000000000011', 'joao.pereira@example.test'),
    ('a3000000-0000-4000-8000-000000000012', 'ana.souza@example.test'),
    ('a3000000-0000-4000-8000-000000000013', 'ana.souza.santos@example.test')
) as fixture(id, email);

insert into auth.users (
  id, aud, role, email, email_confirmed_at, encrypted_password,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
select
  ('a3000000-0000-4000-8000-0000000000' || (20 + series)::text)::uuid,
  'authenticated',
  'authenticated',
  'pessoa.bortolini.' || series || '@example.test',
  clock_timestamp(),
  '',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb,
  clock_timestamp(),
  clock_timestamp()
from generate_series(0, 10) as series;

insert into catalog.community_profiles (id, name, cpf, phone, privacy_notice_version)
values
  ('a3000000-0000-4000-8000-000000000010', 'Maria Oliveira', '11144477735', '+5554999990001', 'v1'),
  ('a3000000-0000-4000-8000-000000000011', 'João Pereira', '52998224725', '+5554999990002', 'v1'),
  ('a3000000-0000-4000-8000-000000000012', 'Ana Souza', '39053344705', '+5554999990003', 'v1'),
  ('a3000000-0000-4000-8000-000000000013', 'Ana Souza', '15350946056', '+5554999990004', 'v1');

insert into catalog.community_profiles (id, name, cpf, phone, privacy_notice_version)
select
  ('a3000000-0000-4000-8000-0000000000' || (20 + series)::text)::uuid,
  fixture.name,
  fixture.cpf,
  '+55549999901' || lpad(series::text, 2, '0'),
  'v1'
from (
  values
    (0, 'Alice Bortolini', '86288366757'),
    (1, 'Bruno Bortolini', '24681357900'),
    (2, 'Carla Bortolini', '13579246800'),
    (3, 'Diego Bortolini', '97531864200'),
    (4, 'Elisa Bortolini', '86420975300'),
    (5, 'Fabio Bortolini', '75315985200'),
    (6, 'Gabriela Bortolini', '95175348600'),
    (7, 'Heitor Bortolini', '14725836900'),
    (8, 'Iara Bortolini', '36925814700'),
    (9, 'Jonas Bortolini', '25814736900'),
    (10, 'Katia Bortolini', '74185296300')
) as fixture(series, name, cpf);

insert into catalog.user_roles (user_id, role, entity_id, is_active)
select
  profile.id,
  'community',
  null,
  true
from catalog.community_profiles as profile
where profile.id::text like 'a3000000-0000-4000-8000-0000000000%';

insert into catalog.user_roles (user_id, role, entity_id, is_active)
values
  ('a3000000-0000-4000-8000-000000000001', 'bank_admin', 'd1000000-0000-4000-8000-000000000001', true),
  ('a3000000-0000-4000-8000-000000000002', 'bank_admin', 'd1000000-0000-4000-8000-000000000002', true);

insert into catalog.loans (
  id, public_code, entity_id, borrower_user_id, delivery_date, due_date,
  status, created_by_user_id, completed_at
)
values
  (
    'f1000000-0000-4000-8000-000000000001',
    'AAAA00000001',
    'd1000000-0000-4000-8000-000000000001',
    'a3000000-0000-4000-8000-000000000010',
    current_date,
    current_date + 90,
    'draft',
    'a3000000-0000-4000-8000-000000000001',
    null
  ),
  (
    'f1000000-0000-4000-8000-000000000002',
    'BBBB00000002',
    'd1000000-0000-4000-8000-000000000002',
    'a3000000-0000-4000-8000-000000000010',
    current_date,
    current_date + 45,
    'active',
    'a3000000-0000-4000-8000-000000000002',
    clock_timestamp()
  );

set local role authenticated;
select pg_temp.loan_login('a3000000-0000-4000-8000-000000000001');

select results_eq(
  $$ select full_name from public.admin_search_people('maria') $$,
  $$ values ('Maria Oliveira'::text) $$,
  'C1 a name search finds the account by part of the name'
);

select results_eq(
  $$ select full_name from public.admin_search_people('JOAO') $$,
  $$ values ('João Pereira'::text) $$,
  'C1 a name search ignores letter case and accents'
);

select ok(
  (
    select count(*) = 10 and bool_and(has_more)
    from public.admin_search_people('bortolini')
  )
    and (
    select string_agg(full_name, '|' order by full_name) =
      'Alice Bortolini|Bruno Bortolini|Carla Bortolini|Diego Bortolini|'
      || 'Elisa Bortolini|Fabio Bortolini|Gabriela Bortolini|Heitor Bortolini|'
      || 'Iara Bortolini|Jonas Bortolini'
    from public.admin_search_people('bortolini')
  ),
  'C2 eleven matches return ten in name order and flag that more exist'
);

select ok(
  (
    select count(distinct user_id) = 1
    from public.admin_search_people('111.444.777-35')
  )
    and (
    select user_id = (
      select user_id from public.admin_search_people('11144477735')
    )
    from public.admin_search_people('111.444.777-35')
  ),
  'C3 a CPF search accepts the value with and without punctuation'
);

select throws_ok(
  $$ select * from public.admin_search_people('ma') $$,
  'P0002',
  null,
  'C4 two letters are refused'
);

select throws_ok(
  $$ select * from public.admin_search_people('1114447773') $$,
  'P0002',
  null,
  'C4 ten digits are refused'
);

select results_eq(
  $$ select masked_cpf, masked_phone from public.admin_search_people('maria') $$,
  $$ values ('***.***.***-35'::text, '(54) *****-0001'::text) $$,
  'C5 the result carries a masked CPF and a masked phone'
);

select ok(
  (
    select count(distinct user_id) = 2
      and count(distinct masked_cpf) = 2
    from public.admin_search_people('ana souza')
  ),
  'C6 two homonyms come back as two distinct results'
);

select results_eq(
  $$ select open_loan_count from public.admin_search_people('maria') $$,
  $$ values (1) $$,
  'C7 the open loan count only counts loans of the session bank'
);

select results_eq(
  $$ select open_loan_count from public.admin_search_people('11144477735') $$,
  $$ values (1) $$,
  'C7 the CPF search also counts only the session bank'
);

select results_eq(
  $$ select count(*) from public.admin_search_people('zzz') $$,
  $$ values (0::bigint) $$,
  'C8 a name without an account returns no result'
);

select ok(
  not exists (
    select 1
    from public.admin_search_people('admin.boavista')
  ),
  'C8 an account without the community role is not returned'
);

reset role;

select * from finish();

rollback;
