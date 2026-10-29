begin;

select plan(27);

select is(
  (
    select array_agg(code || '=' || name order by code)
    from catalog.equipment_types
    where is_active
  ),
  array[
    'AE=Assento sanitário elevado',
    'AN=Andador',
    'BA=Banheira ou apoio para banho',
    'BO=Bota ortopédica',
    'CB=Cadeira de banho',
    'CI=Cadeira infantil ou adaptada',
    'CM=Cama hospitalar',
    'CO=Colchão para cama hospitalar',
    'CR=Cadeira de rodas',
    'MU=Muletas',
    'OU=Outros',
    'SS=Suporte para soro',
    'TI=Tipoia de braço'
  ]::text[],
  'the seed contains exactly the 13 approved active codes and names'
);

select is(
  (select is_active from catalog.equipment_types where code = 'PE'),
  false,
  'PE remains inactive in the catalog'
);

select is(
  (
    select array_agg(name order by display_order, code)
    from (
      select name, display_order, code
      from catalog.equipment_types
      where is_active
      order by display_order, code
      limit 5
    ) priorities
  ),
  array[
    'Cadeira de rodas',
    'Cama hospitalar',
    'Cadeira de banho',
    'Andador',
    'Muletas'
  ]::text[],
  'the five required priorities occupy the first five positions'
);

select ok(
  (
    select relrowsecurity
    from pg_class
    where oid = 'catalog.equipment_types'::regclass
  ),
  'row-level security is enabled on the backing table'
);

select ok(
  (
    select reloptions @> array['security_invoker=true']::text[]
    from pg_class
    where oid = 'public.equipment_types'::regclass
  ),
  'the public view invokes the backing table with caller privileges and RLS'
);

select ok(
  has_table_privilege('anon', 'catalog.equipment_types', 'SELECT')
    and not has_table_privilege('anon', 'catalog.equipment_types', 'INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'),
  'anon has only SELECT on the backing table'
);

select ok(
  has_table_privilege('authenticated', 'catalog.equipment_types', 'SELECT')
    and not has_table_privilege('authenticated', 'catalog.equipment_types', 'INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'),
  'authenticated has only SELECT on the backing table'
);

select ok(
  has_table_privilege('anon', 'public.equipment_types', 'SELECT')
    and not has_table_privilege('anon', 'public.equipment_types', 'INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'),
  'anon has only SELECT on the public view'
);

select ok(
  has_table_privilege('authenticated', 'public.equipment_types', 'SELECT')
    and not has_table_privilege('authenticated', 'public.equipment_types', 'INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'),
  'authenticated has only SELECT on the public view'
);

set local role anon;

select is(
  (select count(*)::integer from catalog.equipment_types),
  13,
  'anon reads only the 13 active backing rows'
);

select is(
  (select count(*)::integer from public.equipment_types),
  13,
  'anon reads the 13 active public rows'
);

select throws_ok(
  $$insert into catalog.equipment_types (code, name, is_active, display_order)
    values ('ZZ', 'Tipo sintetico', true, 99)$$,
  '42501',
  null,
  'anon cannot insert into the backing table'
);

select throws_ok(
  $$update catalog.equipment_types set name = 'Nome alterado' where code = 'CR'$$,
  '42501',
  null,
  'anon cannot update the backing table'
);

select throws_ok(
  $$delete from catalog.equipment_types where code = 'CR'$$,
  '42501',
  null,
  'anon cannot delete from the backing table'
);

select throws_ok(
  $$insert into public.equipment_types (code, name, display_order)
    values ('ZZ', 'Tipo sintetico', 99)$$,
  '42501',
  null,
  'anon cannot insert through the public view'
);

select throws_ok(
  $$update public.equipment_types set name = 'Nome alterado' where code = 'CR'$$,
  '42501',
  null,
  'anon cannot update through the public view'
);

select throws_ok(
  $$delete from public.equipment_types where code = 'CR'$$,
  '42501',
  null,
  'anon cannot delete through the public view'
);

select results_eq(
  $$select name from catalog.equipment_types where code = 'CR'$$,
  array['Cadeira de rodas']::text[],
  'anon write denials leave the priority row unchanged'
);

set local role authenticated;

select is(
  (select count(*)::integer from catalog.equipment_types),
  13,
  'authenticated reads only the 13 active backing rows'
);

select is(
  (select count(*)::integer from public.equipment_types),
  13,
  'authenticated reads the 13 active public rows'
);

select throws_ok(
  $$insert into catalog.equipment_types (code, name, is_active, display_order)
    values ('ZZ', 'Tipo sintetico', true, 99)$$,
  '42501',
  null,
  'authenticated cannot insert into the backing table'
);

select throws_ok(
  $$update catalog.equipment_types set name = 'Nome alterado' where code = 'CR'$$,
  '42501',
  null,
  'authenticated cannot update the backing table'
);

select throws_ok(
  $$delete from catalog.equipment_types where code = 'CR'$$,
  '42501',
  null,
  'authenticated cannot delete from the backing table'
);

select throws_ok(
  $$insert into public.equipment_types (code, name, display_order)
    values ('ZZ', 'Tipo sintetico', 99)$$,
  '42501',
  null,
  'authenticated cannot insert through the public view'
);

select throws_ok(
  $$update public.equipment_types set name = 'Nome alterado' where code = 'CR'$$,
  '42501',
  null,
  'authenticated cannot update through the public view'
);

select throws_ok(
  $$delete from public.equipment_types where code = 'CR'$$,
  '42501',
  null,
  'authenticated cannot delete through the public view'
);

select results_eq(
  $$select name from catalog.equipment_types where code = 'CR'$$,
  array['Cadeira de rodas']::text[],
  'authenticated write denials leave the priority row unchanged'
);

select * from finish();
rollback;
