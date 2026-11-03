begin;

select plan(53);

create function pg_temp.aq_login(p_sub text)
returns void
language plpgsql
as $function$
begin
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  perform set_config('request.jwt.claim.sub', p_sub, true);
end
$function$;

insert into catalog.equipment_types (code, name, is_active, display_order)
values
  ('SYN-AQ-CR', 'Tipo sintetico de inventory', true, 991),
  ('SYN-AQ-INACTIVE', 'Tipo sintetico inativo', false, 992);

insert into catalog.entities (id, code, public_name, is_bank, is_active)
values
  ('c1000000-0000-4000-8000-000000000001', 'SYN-AQ-A', 'Entidade Sintetica AQ A', true, true),
  ('c1000000-0000-4000-8000-000000000002', 'SYN-AQ-B', 'Entidade Sintetica AQ B', true, true),
  ('c1000000-0000-4000-8000-000000000003', 'SYN-AQ-C', 'Entidade Sintetica AQ C', true, true),
  ('c1000000-0000-4000-8000-000000000004', 'SYN-AQ-D', 'Entidade Sintetica AQ D', true, true);

insert into catalog.storage_locations (id, code, name)
values
  ('b0000000-0000-4000-8000-000000000001', 'SYN-AQ-P1', 'Ponto Sintetico AQ 1'),
  ('b0000000-0000-4000-8000-000000000002', 'SYN-AQ-P2', 'Ponto Sintetico AQ 2');

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
  ('a1000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'inventory-a@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a1000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'inventory-b@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a1000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'inventory-c@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a1000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', 'inventory-d@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a1000000-0000-4000-8000-000000000005', 'authenticated', 'authenticated', 'inventory-inactive@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a1000000-0000-4000-8000-000000000006', 'authenticated', 'authenticated', 'inventory-community@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('a1000000-0000-4000-8000-000000000007', 'authenticated', 'authenticated', 'inventory-no-role@synthetic.test', clock_timestamp(), '', '{"provider":"email","providers":["email"]}', '{}'::jsonb, clock_timestamp(), clock_timestamp());

insert into catalog.user_roles (user_id, role, entity_id, is_active)
select fixtures.user_id, 'bank_admin', entity.id, true
from (
  values
    ('a1000000-0000-4000-8000-000000000001'::uuid, 'SYN-AQ-A'),
    ('a1000000-0000-4000-8000-000000000002'::uuid, 'SYN-AQ-B'),
    ('a1000000-0000-4000-8000-000000000003'::uuid, 'SYN-AQ-C'),
    ('a1000000-0000-4000-8000-000000000004'::uuid, 'SYN-AQ-D')
) as fixtures(user_id, entity_code)
join catalog.entities as entity on entity.code = fixtures.entity_code;

insert into catalog.user_roles (user_id, role, entity_id, is_active)
values
  ('a1000000-0000-4000-8000-000000000005', 'bank_admin', ('c1000000-0000-4000-8000-000000000001'::uuid), false),
  ('a1000000-0000-4000-8000-000000000006', 'community', null, true);

insert into catalog.equipment_units (
  id,
  equipment_type_code,
  owner_entity_id,
  storage_location_id,
  status,
  visible_code,
  entry_origin
)
select
  fixture.id::uuid,
  fixture.equipment_type_code,
  entity.id,
  location.id,
  fixture.status::catalog.equipment_status,
  fixture.visible_code,
  'donation'
from (
  values
    ('a0000000-0000-4000-8000-000000000001', 'SYN-AQ-CR', 'SYN-AQ-A', 'SYN-AQ-P1', 'available', 'AQ-0001'),
    ('a0000000-0000-4000-8000-000000000002', 'SYN-AQ-CR', 'SYN-AQ-A', 'SYN-AQ-P1', 'under_maintenance', 'AQ-0002'),
    ('a0000000-0000-4000-8000-000000000003', 'SYN-AQ-INACTIVE', 'SYN-AQ-A', null, 'written_off', null),
    ('a0000000-0000-4000-8000-000000000004', 'SYN-AQ-CR', 'SYN-AQ-B', 'SYN-AQ-P2', 'available', 'AQ-B-0001'),
    ('a0000000-0000-4000-8000-000000000005', 'SYN-AQ-CR', 'SYN-AQ-C', 'SYN-AQ-P1', 'reserved', 'AQ-C-0001'),
    ('a0000000-0000-4000-8000-000000000006', 'SYN-AQ-CR', 'SYN-AQ-D', 'SYN-AQ-P2', 'on_loan', 'AQ-D-0001'),
    ('a0000000-0000-4000-8000-000000000007', 'SYN-AQ-CR', 'SYN-AQ-A', null, 'reserved', null)
) as fixture(id, equipment_type_code, entity_code, point_code, status, visible_code)
join catalog.entities as entity on entity.code = fixture.entity_code
left join catalog.storage_locations as location on location.code = fixture.point_code;

select ok(
  not has_table_privilege('anon', 'catalog.equipment_units', 'SELECT')
    and not has_table_privilege('authenticated', 'catalog.equipment_units', 'SELECT')
    and not has_table_privilege('service_role', 'catalog.equipment_units', 'SELECT')
    and not has_table_privilege('anon', 'catalog.equipment_unit_change_audit', 'SELECT')
    and not has_table_privilege('authenticated', 'catalog.equipment_unit_change_audit', 'SELECT')
    and not has_table_privilege('service_role', 'catalog.equipment_unit_change_audit', 'SELECT')
    and not has_table_privilege('authenticated', 'catalog.equipment_units', 'INSERT')
    and not has_table_privilege('authenticated', 'catalog.equipment_units', 'UPDATE')
    and not has_table_privilege('authenticated', 'catalog.equipment_unit_change_audit', 'INSERT'),
  'C20 client and service roles cannot read or write units and audit directly'
);

select ok(
  has_function_privilege('authenticated', 'public.admin_bank_equipment_units()', 'EXECUTE')
    and has_function_privilege('authenticated', 'public.admin_bank_equipment_options()', 'EXECUTE')
    and has_function_privilege('authenticated', 'public.admin_create_equipment_unit(text,text,uuid,text,text)', 'EXECUTE')
    and has_function_privilege('authenticated', 'public.admin_update_equipment_unit(uuid,text,uuid,text)', 'EXECUTE')
    and not has_function_privilege('anon', 'public.admin_bank_equipment_units()', 'EXECUTE')
    and not has_function_privilege('anon', 'public.admin_bank_equipment_options()', 'EXECUTE')
    and not has_function_privilege('anon', 'public.admin_create_equipment_unit(text,text,uuid,text,text)', 'EXECUTE')
    and not has_function_privilege('anon', 'public.admin_update_equipment_unit(uuid,text,uuid,text)', 'EXECUTE')
    and not has_function_privilege('service_role', 'public.admin_bank_equipment_units()', 'EXECUTE')
    and not has_function_privilege('service_role', 'public.admin_create_equipment_unit(text,text,uuid,text,text)', 'EXECUTE'),
  'C20 client and service roles cannot call the inventory RPCs'
);

set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

select results_eq(
  $$
    select bank_name, unit_id::text
    from public.admin_bank_equipment_units()
    where unit_id is not null
  $$,
  $$
    values
      ('Entidade Sintetica AQ A'::text, 'a0000000-0000-4000-8000-000000000001'::text),
      ('Entidade Sintetica AQ A'::text, 'a0000000-0000-4000-8000-000000000002'::text),
      ('Entidade Sintetica AQ A'::text, 'a0000000-0000-4000-8000-000000000007'::text),
      ('Entidade Sintetica AQ A'::text, 'a0000000-0000-4000-8000-000000000003'::text)
  $$,
  'C1 inventory collection returns the canonical bank and only its units'
);

reset role;
set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000002');

select results_eq(
  $$
    select bank_name, unit_id::text
    from public.admin_bank_equipment_units()
    where unit_id is not null
  $$,
  $$
    values
      ('Entidade Sintetica AQ B'::text, 'a0000000-0000-4000-8000-000000000004'::text)
  $$,
  'C1 inventory collection isolates the second synthetic entity'
);

reset role;
set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000003');

select results_eq(
  $$
    select bank_name, unit_id::text
    from public.admin_bank_equipment_units()
    where unit_id is not null
  $$,
  $$
    values
      ('Entidade Sintetica AQ C'::text, 'a0000000-0000-4000-8000-000000000005'::text)
  $$,
  'C1 inventory collection isolates the third synthetic entity'
);

reset role;
set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000004');

select results_eq(
  $$
    select bank_name, unit_id::text
    from public.admin_bank_equipment_units()
    where unit_id is not null
  $$,
  $$
    values
      ('Entidade Sintetica AQ D'::text, 'a0000000-0000-4000-8000-000000000006'::text)
  $$,
  'C1 inventory collection isolates the fourth synthetic entity'
);

reset role;
set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

select ok(
  (
    select count(*) = 1
    from public.admin_bank_equipment_units()
    where status = 'available'
  )
    and (
    select count(*) = 1
    from public.admin_bank_equipment_units()
    where status = 'under_maintenance'
  )
    and (
    select count(*) = 1
    from public.admin_bank_equipment_units()
    where status = 'written_off'
  )
    and (
    select count(*) = 1
    from public.admin_bank_equipment_units()
    where status = 'reserved'
  )
    and (
    select count(*) = 0
    from public.admin_bank_equipment_units()
    where status = 'on_loan'
  )
    and (
    select count(*) = 0
    from public.admin_bank_equipment_units()
    where status = 'donated'
  ),
  'C2 status counts cover all six values including zero'
);

select results_eq(
  $$
    select unit_id::text
    from public.admin_bank_equipment_units()
    where unit_id is not null
  $$,
  $$
    values
      ('a0000000-0000-4000-8000-000000000001'::text),
      ('a0000000-0000-4000-8000-000000000002'::text),
      ('a0000000-0000-4000-8000-000000000007'::text),
      ('a0000000-0000-4000-8000-000000000003'::text)
  $$,
  'C3 units are ordered by type then identifier with nulls last'
);

select ok(
  exists (
    select 1
    from public.admin_bank_equipment_options()
    where option_kind = 'equipment_type'
      and option_code = 'SYN-AQ-CR'
  )
    and not exists (
    select 1
    from public.admin_bank_equipment_options()
    where option_kind = 'equipment_type'
      and option_code = 'SYN-AQ-INACTIVE'
  )
    and (
    select count(*) = 2
    from public.admin_bank_equipment_options()
    where option_kind = 'storage_location'
      and option_code in (
        'b0000000-0000-4000-8000-000000000001',
        'b0000000-0000-4000-8000-000000000002'
      )
  ),
  'C24 options return active types and every storage location'
);

select ok(
  exists (
    select 1
    from public.admin_bank_equipment_units()
    where unit_id = 'a0000000-0000-4000-8000-000000000003'
      and equipment_type_name = 'Tipo sintetico inativo'
      and status = 'written_off'
  ),
  'C25 an inactive type remains readable and its unit remains editable'
);

select is(
  public.admin_update_equipment_unit(
    'a0000000-0000-4000-8000-000000000003',
    null,
    null,
    'available'
  ),
  'available',
  'C25 an inactive type unit can still be edited'
);

create temp table aq_created as
select public.admin_create_equipment_unit(
  'SYN-AQ-CR',
  ' AQ-0003 ',
  ('b0000000-0000-4000-8000-000000000002'::uuid),
  'reserved',
  'purchase'
) as id;

reset role;

select ok(
  (
    select
      unit.owner_entity_id = ('c1000000-0000-4000-8000-000000000001'::uuid)
      and unit.equipment_type_code = 'SYN-AQ-CR'
      and unit.visible_code = 'AQ-0003'
      and unit.storage_location_id = ('b0000000-0000-4000-8000-000000000002'::uuid)
      and unit.status = 'reserved'
      and unit.entry_origin = 'purchase'
    from catalog.equipment_units as unit
    where unit.id = (select id from aq_created)
  ),
  'C8 create unit derives the owner entity from the session and persists every field'
);

select ok(
  (
    select count(*) = 1
      and bool_and(actor_user_id = 'a1000000-0000-4000-8000-000000000001')
      and bool_and(entity_id = ('c1000000-0000-4000-8000-000000000001'::uuid))
      and bool_and(unit_id = (select id from aq_created))
      and bool_and(action = 'unit_created')
      and bool_and(previous_status is null)
      and bool_and(new_status = 'reserved')
      and bool_and(new_storage_location_id = ('b0000000-0000-4000-8000-000000000002'::uuid))
      and bool_and(previous_storage_location_id is null)
      and bool_and(previous_visible_code is null)
      and bool_and(new_visible_code = 'AQ-0003')
      and bool_and(entry_origin = 'purchase')
      and bool_and(created_at is not null)
    from catalog.equipment_unit_change_audit
    where unit_id = (select id from aq_created)
  ),
  'C13 creation writes one unit_created audit with the complete actor and values'
);

set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

create temp table aq_blank as
select public.admin_create_equipment_unit(
  'SYN-AQ-CR',
  '   ',
  null,
  'available',
  'donation'
) as id;

reset role;

select is(
  (select visible_code from catalog.equipment_units where id = (select id from aq_blank)),
  null::text,
  'C10 blank identifier is stored as null'
);

set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

create temp table aq_trimmed as
select public.admin_create_equipment_unit(
  'SYN-AQ-CR',
  ' AQ-0004 ',
  null,
  'available',
  'donation'
) as id;

reset role;

select is(
  (select visible_code from catalog.equipment_units where id = (select id from aq_trimmed)),
  'AQ-0004',
  'C10 identifier is trimmed and preserves its internal text'
);

set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

select throws_ok(
  $$select public.admin_create_equipment_unit('SYN-AQ-CR', repeat('x', 65), null, 'available', 'donation')$$,
  'P0002',
  'Invalid unit data',
  'C10 identifier longer than 64 characters is rejected'
);

create temp table aq_max_identifier as
select public.admin_create_equipment_unit(
  'SYN-AQ-CR',
  repeat('x', 64),
  null,
  'available',
  'donation'
) as id;

reset role;

select is(
  (
    select char_length(visible_code)
    from catalog.equipment_units
    where id = (select id from aq_max_identifier)
  ),
  64,
  'C10 identifier with exactly 64 characters is accepted'
);

set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

select throws_ok(
  $$select public.admin_create_equipment_unit('SYN-AQ-CR', 'AQ-0001', null, 'available', 'donation')$$,
  'P0003',
  'Identifier already in use',
  'C11 duplicate identifier in the same entity is rejected'
);

reset role;
set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000002');

create temp table aq_other_entity as
select public.admin_create_equipment_unit(
  'SYN-AQ-CR',
  'AQ-0001',
  null,
  'available',
  'donation'
) as id;

reset role;

select ok(
  (
    select owner_entity_id = ('c1000000-0000-4000-8000-000000000002'::uuid)
    from catalog.equipment_units
    where id = (select id from aq_other_entity)
  ),
  'C11 the same identifier is accepted in another entity'
);

reset role;
create temp table aq_before_invalid as
select
  (select count(*) from catalog.equipment_units
   where owner_entity_id = 'c1000000-0000-4000-8000-000000000001') as unit_count,
  (select count(*) from catalog.equipment_unit_change_audit
   where entity_id = 'c1000000-0000-4000-8000-000000000001') as audit_count;

set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

select throws_ok(
  $$select public.admin_create_equipment_unit('SYN-AQ-UNKNOWN', null, null, 'available', 'donation')$$,
  'P0002',
  'Invalid unit data',
  'C12 invalid creation inputs are rejected without unit or audit - unknown type'
);

select throws_ok(
  $$select public.admin_create_equipment_unit('SYN-AQ-INACTIVE', null, null, 'available', 'donation')$$,
  'P0002',
  'Invalid unit data',
  'C12 invalid creation inputs are rejected without unit or audit - inactive type'
);

select throws_ok(
  $$select public.admin_create_equipment_unit('SYN-AQ-CR', null, 'b0000000-0000-4000-8000-000000000099', 'available', 'donation')$$,
  'P0002',
  'Invalid unit data',
  'C12 invalid creation inputs are rejected without unit or audit - unknown location'
);

select throws_ok(
  $$select public.admin_create_equipment_unit('SYN-AQ-CR', null, null, 'lost', 'donation')$$,
  'P0002',
  'Invalid unit data',
  'C12 invalid creation inputs are rejected without unit or audit - invalid status'
);

select throws_ok(
  $$select public.admin_create_equipment_unit('SYN-AQ-CR', null, null, 'available', 'made_up')$$,
  'P0002',
  'Invalid unit data',
  'C12 invalid creation inputs are rejected without unit or audit - invalid origin'
);

reset role;

select is(
  (
    select count(*)
    from catalog.equipment_units
    where owner_entity_id = 'c1000000-0000-4000-8000-000000000001'
  ),
  (select unit_count from aq_before_invalid),
  'C12 invalid creation attempts leave no unit behind'
);

select is(
  (
    select count(*)
    from catalog.equipment_unit_change_audit
    where entity_id = 'c1000000-0000-4000-8000-000000000001'
  ),
  (select audit_count from aq_before_invalid),
  'C12 invalid creation attempts leave no audit behind'
);

set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

select public.admin_create_equipment_unit('SYN-AQ-CR', 'AQ-O-1', null, 'available', 'donation');
select public.admin_create_equipment_unit('SYN-AQ-CR', 'AQ-O-2', null, 'available', 'purchase');
select public.admin_create_equipment_unit('SYN-AQ-CR', 'AQ-O-3', null, 'available', 'repair_return');
select public.admin_create_equipment_unit('SYN-AQ-CR', 'AQ-O-4', null, 'available', 'return_from_other_bank');

reset role;

select results_eq(
  $$
    select visible_code, entry_origin::text
    from catalog.equipment_units
    where visible_code in ('AQ-O-1', 'AQ-O-2', 'AQ-O-3', 'AQ-O-4')
    order by visible_code
  $$,
  $$
    values
      ('AQ-O-1'::text, 'donation'::text),
      ('AQ-O-2'::text, 'purchase'::text),
      ('AQ-O-3'::text, 'repair_return'::text),
      ('AQ-O-4'::text, 'return_from_other_bank'::text)
  $$,
  'C12 all four entry origins are accepted'
);

set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

select is(
  public.admin_update_equipment_unit(
    (select id from aq_created),
    'AQ-0003-X',
    ('b0000000-0000-4000-8000-000000000002'::uuid),
    'under_maintenance'
  ),
  'under_maintenance',
  'C14 update changes only visible code, storage location and status'
);

reset role;

select ok(
  (
    select
      unit.equipment_type_code = 'SYN-AQ-CR'
      and unit.owner_entity_id = ('c1000000-0000-4000-8000-000000000001'::uuid)
      and unit.visible_code = 'AQ-0003-X'
      and unit.storage_location_id = ('b0000000-0000-4000-8000-000000000002'::uuid)
      and unit.status = 'under_maintenance'
    from catalog.equipment_units as unit
    where unit.id = (select id from aq_created)
  ),
  'C14 update preserves the equipment type and owner'
);

select ok(
  (
    select count(*) = 2
    from catalog.equipment_unit_change_audit
    where unit_id = (select id from aq_created)
  )
    and exists (
    select 1
    from catalog.equipment_unit_change_audit
    where unit_id = (select id from aq_created)
      and action = 'unit_updated'
      and previous_status = 'reserved'
      and new_status = 'under_maintenance'
      and previous_visible_code = 'AQ-0003'
      and new_visible_code = 'AQ-0003-X'
  ),
  'C15 every status can transition to every other situation with audit'
);

create function pg_temp.aq_transition_works(p_from text, p_to text)
returns boolean
language plpgsql
as $function$
declare
  v_unit_id uuid;
begin
  v_unit_id := public.admin_create_equipment_unit(
    'SYN-AQ-CR',
    null,
    null,
    p_from,
    'donation'
  );
  return public.admin_update_equipment_unit(v_unit_id, null, null, p_to) = p_to;
exception
  when others then
    return false;
end
$function$;

set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

select ok(
  (
    select bool_and(pg_temp.aq_transition_works(source, target))
    from unnest(array[
      'available',
      'reserved',
      'on_loan',
      'under_maintenance',
      'donated',
      'written_off'
    ]) as source
    cross join unnest(array[
      'available',
      'reserved',
      'on_loan',
      'under_maintenance',
      'donated',
      'written_off'
    ]) as target
  ),
  'C15 all six statuses can reach every other situation'
);

create temp table aq_terminal_doado as
select public.admin_create_equipment_unit('SYN-AQ-CR', 'AQ-TERM-1', null, 'donated', 'donation') as id;

select is(
  public.admin_update_equipment_unit((select id from aq_terminal_doado), null, null, 'available'),
  'available',
  'C15 donated and written_off are no longer terminal for the inventory panel - donated'
);

create temp table aq_terminal_baixado as
select public.admin_create_equipment_unit('SYN-AQ-CR', 'AQ-TERM-2', null, 'written_off', 'donation') as id;

select is(
  public.admin_update_equipment_unit((select id from aq_terminal_baixado), null, null, 'donated'),
  'donated',
  'C15 donated and written_off are no longer terminal for the inventory panel - written_off'
);

reset role;

select ok(
  exists (
    select 1
    from catalog.equipment_unit_change_audit
    where unit_id = (select id from aq_terminal_doado)
      and action = 'unit_updated'
      and previous_status = 'donated'
      and new_status = 'available'
  )
    and exists (
    select 1
    from catalog.equipment_unit_change_audit
    where unit_id = (select id from aq_terminal_baixado)
      and action = 'unit_updated'
      and previous_status = 'written_off'
      and new_status = 'donated'
  ),
  'C15 terminal transitions record previous and new status'
);

set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

create temp table aq_idempotent as
select public.admin_create_equipment_unit('SYN-AQ-CR', 'AQ-IDEM', null, 'available', 'donation') as id;

select public.admin_update_equipment_unit((select id from aq_idempotent), null, null, 'reserved');

reset role;

select is(
  (
    select count(*)
    from catalog.equipment_unit_change_audit
    where unit_id = (select id from aq_idempotent)
  ),
  2::bigint,
  'C16 repeating the same update creates no extra audit row - before repeat'
);

set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

select is(
  public.admin_update_equipment_unit((select id from aq_idempotent), null, null, 'reserved'),
  'reserved',
  'C16 repeating the same update keeps the unit status'
);

reset role;

select is(
  (
    select count(*)
    from catalog.equipment_unit_change_audit
    where unit_id = (select id from aq_idempotent)
  ),
  2::bigint,
  'C16 repeating the same update creates no extra audit row'
);

set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

select throws_ok(
  format(
    'select public.admin_update_equipment_unit(%L, null, null, %L)',
    'a0000000-0000-4000-8000-000000000004',
    'available'
  ),
  'P0001',
  'Unit unavailable',
  'C17 foreign and unknown unit identifiers receive the same generic denial - foreign unit'
);

select throws_ok(
  format(
    'select public.admin_update_equipment_unit(%L, null, null, %L)',
    'a0000000-0000-4000-8000-000000000099',
    'available'
  ),
  'P0001',
  'Unit unavailable',
  'C17 foreign and unknown unit identifiers receive the same generic denial - unknown unit'
);

reset role;

select ok(
  (
    select count(*) = 0
    from catalog.equipment_unit_change_audit
    where unit_id = 'a0000000-0000-4000-8000-000000000004'
  )
    and (
    select status = 'available'
    from catalog.equipment_units
    where id = 'a0000000-0000-4000-8000-000000000004'
  ),
  'C17 denied updates leave the foreign unit and its audit unchanged'
);

set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

select throws_ok(
  format(
    'select public.admin_update_equipment_unit(%L, null, null, %L)',
    'a0000000-0000-4000-8000-000000000004',
    'written_off'
  ),
  'P0001',
  'Unit unavailable',
  'C20 another entity cannot update a unit'
);

create temp table aq_concurrent as
select public.admin_create_equipment_unit('SYN-AQ-CR', 'AQ-CONC', null, 'available', 'donation') as id;

select public.admin_update_equipment_unit((select id from aq_concurrent), null, null, 'reserved');

select is(
  public.admin_update_equipment_unit((select id from aq_concurrent), null, null, 'under_maintenance'),
  'under_maintenance',
  'C18 effective updates are serialized and each leaves one audit - final status'
);

reset role;

select is(
  (
    select count(*)
    from catalog.equipment_unit_change_audit
    where unit_id = (select id from aq_concurrent)
      and action = 'unit_updated'
  ),
  2::bigint,
  'C18 effective updates are serialized and each leaves one audit'
);

set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000001');

select set_config('request.jwt.claim.role', 'general_admin', true);
select set_config(
  'request.jwt.claim.entity_id',
  'c1000000-0000-4000-8000-000000000002',
  true
);

create temp table aq_forged as
select public.admin_create_equipment_unit('SYN-AQ-CR', 'AQ-FORGED', null, 'available', 'donation') as id;

reset role;

select ok(
  (
    select owner_entity_id = ('c1000000-0000-4000-8000-000000000001'::uuid)
    from catalog.equipment_units
    where id = (select id from aq_forged)
  ),
  'C20 forged browser role and entity claims do not change the bank scope'
);

reset role;
set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000005');

select throws_ok(
  $$select * from public.admin_bank_equipment_units()$$,
  '42501',
  'Inventory unavailable',
  'C6 inventory RPCs reject an inactive bank_admin'
);

reset role;
set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000006');

select throws_ok(
  $$select * from public.admin_bank_equipment_units()$$,
  '42501',
  'Inventory unavailable',
  'C6 inventory RPCs reject a session without an active bank_admin'
);

select throws_ok(
  $$select * from public.admin_bank_equipment_options()$$,
  '42501',
  'Inventory unavailable',
  'C6 inventory options reject a session without an active bank_admin'
);

reset role;
set local role authenticated;
select pg_temp.aq_login('a1000000-0000-4000-8000-000000000007');

select throws_ok(
  $$select * from public.admin_bank_equipment_units()$$,
  '42501',
  'Inventory unavailable',
  'C6 inventory RPCs reject an authenticated user without bank_admin'
);

reset role;
set local role anon;

select throws_ok(
  $$select * from public.admin_bank_equipment_units()$$,
  '42501',
  null,
  'C6 inventory RPCs reject anon'
);

select throws_ok(
  $$select * from public.admin_bank_equipment_options()$$,
  '42501',
  null,
  'C6 inventory RPCs reject anon options'
);

select throws_ok(
  $$select * from catalog.equipment_units$$,
  '42501',
  null,
  'C20 anon cannot read the private units table directly'
);

reset role;

select ok(
  (
    select relrowsecurity and relforcerowsecurity
    from pg_class
    where oid = 'catalog.equipment_unit_change_audit'::regclass
  )
    and (
    select relrowsecurity and relforcerowsecurity
    from pg_class
    where oid = 'catalog.equipment_units'::regclass
  ),
  'C20 units and audit tables force RLS'
);

select ok(
  (
    select not rolcanlogin and not rolsuper and not rolbypassrls
    from pg_roles
    where rolname = 'admin_equipment_manager'
  )
    and (
    select prosecdef
      and pg_get_userbyid(proowner) = 'admin_equipment_manager'
      and proconfig @> array['search_path=""', 'row_security=on']::text[]
    from pg_proc
    where oid = 'public.admin_create_equipment_unit(text,text,uuid,text,text)'::regprocedure
  ),
  'C20 the inventory writer is a restricted fixed-path RPC owner'
);

select * from finish();
rollback;
