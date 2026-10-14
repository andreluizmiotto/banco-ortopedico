begin;

select plan(27);

insert into catalog.equipment_types (code, name, is_active, display_order)
values ('SYN-AVAIL-C1', 'Equipamento sintetico C1', true, 901);

insert into catalog.pontos_atendimento (code, name)
values ('SYN-C1-A', 'Ponto Sintetico A');

insert into catalog.equipment_units (
  equipment_type_code,
  owner_entity_id,
  storage_location_id,
  situacao
)
select
  'SYN-AVAIL-C1',
  entity.id,
  location.id,
  unit.situacao::catalog.equipment_situation
from (
  values
    ('SYN-A', 'SYN-C1-A', 'disponivel'),
    ('SYN-A', 'SYN-C1-A', 'disponivel'),
    ('SYN-A', 'SYN-C1-A', 'disponivel'),
    ('SYN-A', 'SYN-C1-A', 'reservado'),
    ('SYN-A', 'SYN-C1-A', 'emprestado'),
    ('SYN-A', 'SYN-C1-A', 'manutencao'),
    ('SYN-A', 'SYN-C1-A', 'doado'),
    ('SYN-A', 'SYN-C1-A', 'baixado'),
    ('SYN-B', 'SYN-SHARED', 'disponivel'),
    ('SYN-B', 'SYN-SHARED', 'disponivel')
) as unit(entity_code, point_code, situacao)
join catalog.entities as entity on entity.code = unit.entity_code
join catalog.pontos_atendimento as location on location.code = unit.point_code;

select is(
  (
    select array_agg(status::text order by ordinal)
    from unnest(enum_range(null::catalog.equipment_situation))
      with ordinality as status_values(status, ordinal)
  ),
  array[
    'disponivel',
    'reservado',
    'emprestado',
    'manutencao',
    'doado',
    'baixado'
  ]::text[],
  'C1 database situation enum uses exactly the six normalized values'
);

select results_eq(
  $$
    select bank_name, available_quantity
    from public.equipment_availability('SYN-AVAIL-C1')
    order by bank_name
  $$,
  $$
    values
      ('Entidade Sintética A'::text, 3),
      ('Entidade Sintética B'::text, 2)
  $$,
  'C1 counts only disponivel units: A=3 and B=2'
);

select results_eq(
  $$
    select bank_name, available_quantity
    from public.equipment_availability('SYN-AVAIL-C1')
    order by bank_name
  $$,
  $$
    values
      ('Entidade Sintética A'::text, 3),
      ('Entidade Sintética B'::text, 2)
  $$,
  'C2 initial aggregate assigns the shared point to each owner, not the point'
);

update catalog.equipment_units
set storage_location_id = (
  select id
  from catalog.pontos_atendimento
  where code = 'SYN-SHARED'
)
where id = (
  select id
  from catalog.equipment_units
  where owner_entity_id = (
  select id from catalog.entities where code = 'SYN-A'
  )
    and equipment_type_code = 'SYN-AVAIL-C1'
    and situacao = 'disponivel'
  order by id
  limit 1
);

select is(
  (
    select entity.code || ':' || location.code
    from catalog.equipment_units as unit
    join catalog.entities as entity on entity.id = unit.owner_entity_id
    join catalog.pontos_atendimento as location
      on location.id = unit.storage_location_id
    where entity.code = 'SYN-A'
      and location.code = 'SYN-SHARED'
      and unit.equipment_type_code = 'SYN-AVAIL-C1'
      and unit.situacao = 'disponivel'
    order by unit.id
    limit 1
  ),
  'SYN-A:SYN-SHARED',
  'C2 location update changes storage location but not owning entity'
);

select results_eq(
  $$
    select bank_name, available_quantity
    from public.equipment_availability('SYN-AVAIL-C1')
    order by bank_name
  $$,
  $$
    values
      ('Entidade Sintética A'::text, 3),
      ('Entidade Sintética B'::text, 2)
  $$,
  'C2 changing only the shared storage point leaves A=3 and B=2'
);

select ok(
  (select relrowsecurity from pg_class where oid = 'catalog.equipment_units'::regclass),
  'C4 RLS is enabled on individual equipment units'
);
select ok(
  (select relforcerowsecurity from pg_class where oid = 'catalog.equipment_units'::regclass),
  'C4 RLS is forced on individual equipment units'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'catalog.entities'::regclass),
  'C4 RLS is enabled on owning entities'
);
select ok(
  (select relforcerowsecurity from pg_class where oid = 'catalog.entities'::regclass),
  'C4 RLS is forced on owning entities'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'catalog.pontos_atendimento'::regclass),
  'C4 RLS is enabled on service points'
);
select ok(
  (select relforcerowsecurity from pg_class where oid = 'catalog.pontos_atendimento'::regclass),
  'C4 RLS is forced on service points'
);
select ok(
  (
    select not rolsuper and not rolbypassrls and not rolcanlogin
    from pg_roles
    where rolname = 'availability_reader'
  ),
  'C4 aggregate function owner is neither superuser nor RLS bypass role'
);
select ok(
  (
    select prosecdef and pg_get_userbyid(proowner) = 'availability_reader'
    from pg_proc
    where oid = 'public.equipment_availability(text)'::regprocedure
  ),
  'C4 public aggregate runs with its restricted non-login owner'
);
select ok(
  (
    select proconfig @> array['search_path=""']::text[]
    from pg_proc
    where oid = 'public.equipment_availability(text)'::regprocedure
  ),
  'C4 public aggregate fixes its search path to empty'
);
select ok(
  not has_table_privilege('anon', 'catalog.equipment_units', 'SELECT')
    and not has_table_privilege('anon', 'catalog.entities', 'SELECT')
    and not has_table_privilege('anon', 'catalog.pontos_atendimento', 'SELECT'),
  'C4 anon has no direct SELECT on private inventory, owner, or location tables'
);
select ok(
  not has_table_privilege('authenticated', 'catalog.equipment_units', 'SELECT')
    and not has_table_privilege('authenticated', 'catalog.entities', 'SELECT')
    and not has_table_privilege('authenticated', 'catalog.pontos_atendimento', 'SELECT'),
  'C4 authenticated has no direct SELECT on private inventory, owner, or location tables'
);
select ok(
  has_function_privilege('anon', 'public.equipment_availability(text)', 'EXECUTE'),
  'C4 anon can execute only the public aggregate contract'
);
select ok(
  has_function_privilege('authenticated', 'public.equipment_availability(text)', 'EXECUTE'),
  'C4 authenticated can execute only the public aggregate contract'
);
select ok(
  exists (
    select 1
    from pg_policies
    where schemaname = 'catalog'
      and tablename = 'equipment_units'
      and roles @> array['availability_reader'::name]
      and cmd = 'SELECT'
  ),
  'C4 only the restricted aggregate reader has an equipment-unit SELECT policy'
);
select ok(
  exists (
    select 1
    from pg_policies
    where schemaname = 'catalog'
      and tablename = 'entities'
      and roles @> array['availability_reader'::name]
      and cmd = 'SELECT'
  ),
  'C4 aggregate reader policy limits owner rows to public active banks'
);
select ok(
  exists (
    select 1
    from pg_policies
    where schemaname = 'catalog'
      and tablename = 'equipment_types'
      and roles @> array['availability_reader'::name]
      and cmd = 'SELECT'
  ),
  'C4 aggregate reader policy limits type rows to active public types'
);

set local role anon;

select throws_ok(
  $$select * from catalog.equipment_units$$,
  '42501',
  null,
  'C4 anon cannot select individual equipment units'
);
select throws_ok(
  $$select * from catalog.entities$$,
  '42501',
  null,
  'C4 anon cannot select entity records'
);
select throws_ok(
  $$select * from catalog.pontos_atendimento$$,
  '42501',
  null,
  'C4 anon cannot select service points or addresses'
);

set local role authenticated;

select throws_ok(
  $$select * from catalog.equipment_units$$,
  '42501',
  null,
  'C4 authenticated cannot select individual equipment units'
);
select throws_ok(
  $$select * from catalog.entities$$,
  '42501',
  null,
  'C4 authenticated cannot select entity records'
);
select throws_ok(
  $$select * from catalog.pontos_atendimento$$,
  '42501',
  null,
  'C4 authenticated cannot select service points or addresses'
);

select * from finish();
rollback;
