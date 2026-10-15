begin;

select plan(48);

insert into catalog.equipment_types (code, name, is_active, display_order)
values ('SYN-RLS-C14', 'Tipo sintetico C14', true, 990);

insert into catalog.entities (code, public_name, is_bank, is_active)
values
  ('SYN-RLS-A', 'Entidade Sintetica RLS A', true, true),
  ('SYN-RLS-B', 'Entidade Sintetica RLS B', true, true),
  ('SYN-RLS-C', 'Entidade Sintetica RLS C', true, true),
  ('SYN-RLS-D', 'Entidade Sintetica RLS D', true, true);

insert into catalog.equipment_units (
  equipment_type_code,
  owner_entity_id,
  storage_location_id,
  situacao
)
select
  'SYN-RLS-C14',
  entity.id,
  location.id,
  'reservado'::catalog.equipment_situation
from catalog.entities as entity
cross join catalog.pontos_atendimento as location
where entity.code in ('SYN-RLS-A', 'SYN-RLS-B', 'SYN-RLS-C', 'SYN-RLS-D')
  and location.code = 'SYN-SHARED';

insert into auth.users (
  id,
  aud,
  role,
  phone,
  phone_confirmed_at,
  encrypted_password,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  ('30000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+12025550101', clock_timestamp(), '', '{"provider":"phone","providers":["phone"]}', '{}', clock_timestamp(), clock_timestamp()),
  ('30000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+12025550102', clock_timestamp(), '', '{"provider":"phone","providers":["phone"]}', '{}', clock_timestamp(), clock_timestamp()),
  ('30000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+12025550103', clock_timestamp(), '', '{"provider":"phone","providers":["phone"]}', '{}', clock_timestamp(), clock_timestamp()),
  ('30000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', '+12025550104', clock_timestamp(), '', '{"provider":"phone","providers":["phone"]}', '{}', clock_timestamp(), clock_timestamp()),
  ('30000000-0000-4000-8000-000000000005', 'authenticated', 'authenticated', '+12025550105', clock_timestamp(), '', '{"provider":"phone","providers":["phone"]}', '{}', clock_timestamp(), clock_timestamp()),
  ('30000000-0000-4000-8000-000000000006', 'authenticated', 'authenticated', '+12025550106', clock_timestamp(), '', '{"provider":"phone","providers":["phone"]}', '{}', clock_timestamp(), clock_timestamp()),
  ('30000000-0000-4000-8000-000000000007', 'authenticated', 'authenticated', '+12025550107', clock_timestamp(), '', '{"provider":"phone","providers":["phone"]}', '{}', clock_timestamp(), clock_timestamp()),
  ('30000000-0000-4000-8000-000000000008', 'authenticated', 'authenticated', '+12025550108', clock_timestamp(), '', '{"provider":"phone","providers":["phone"]}', '{}', clock_timestamp(), clock_timestamp());

insert into catalog.user_roles (user_id, role, entity_id, is_active)
values
  ('30000000-0000-4000-8000-000000000001', 'comunidade', null, true),
  ('30000000-0000-4000-8000-000000000002', 'companheiro', null, true),
  ('30000000-0000-4000-8000-000000000003', 'responsavel', (select id from catalog.entities where code = 'SYN-RLS-A'), true),
  ('30000000-0000-4000-8000-000000000004', 'responsavel', (select id from catalog.entities where code = 'SYN-RLS-B'), true),
  ('30000000-0000-4000-8000-000000000005', 'responsavel', (select id from catalog.entities where code = 'SYN-RLS-C'), true),
  ('30000000-0000-4000-8000-000000000006', 'substituto', (select id from catalog.entities where code = 'SYN-RLS-C'), true),
  ('30000000-0000-4000-8000-000000000007', 'responsavel', (select id from catalog.entities where code = 'SYN-RLS-D'), true),
  ('30000000-0000-4000-8000-000000000008', 'comunidade', null, false);

insert into catalog.entity_contact_settings (entity_id, substitute_mode)
select id, code = 'SYN-RLS-C'
from catalog.entities
where code in ('SYN-RLS-A', 'SYN-RLS-B', 'SYN-RLS-C', 'SYN-RLS-D');

insert into catalog.contact_destinations (
  entity_id,
  recipient_role,
  recipient_user_id,
  whatsapp_phone,
  call_phone,
  is_active
)
values
  ((select id from catalog.entities where code = 'SYN-RLS-A'), 'responsavel', '30000000-0000-4000-8000-000000000003', '+12025550131', null, true),
  ((select id from catalog.entities where code = 'SYN-RLS-B'), 'responsavel', '30000000-0000-4000-8000-000000000004', null, '+12025550132', true),
  ((select id from catalog.entities where code = 'SYN-RLS-C'), 'responsavel', '30000000-0000-4000-8000-000000000005', '+12025550133', null, true),
  ((select id from catalog.entities where code = 'SYN-RLS-C'), 'substituto', '30000000-0000-4000-8000-000000000006', '+12025550134', null, true),
  ((select id from catalog.entities where code = 'SYN-RLS-D'), 'responsavel', '30000000-0000-4000-8000-000000000007', null, null, true);

select ok(
  (select relrowsecurity from pg_class where oid = 'catalog.community_contacts'::regclass),
  'C14 contact table enables RLS'
);
select ok(
  (select relforcerowsecurity from pg_class where oid = 'catalog.community_contacts'::regclass),
  'C14 contact table forces RLS'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'catalog.contact_destinations'::regclass),
  'C14 destination table enables RLS'
);
select ok(
  (select relforcerowsecurity from pg_class where oid = 'catalog.contact_destinations'::regclass),
  'C14 destination table forces RLS'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'catalog.entity_contact_settings'::regclass),
  'C14 entity contact settings enable RLS'
);
select ok(
  (select relforcerowsecurity from pg_class where oid = 'catalog.entity_contact_settings'::regclass),
  'C14 entity contact settings force RLS'
);
select ok(
  (
    select not rolsuper and not rolbypassrls and not rolcanlogin
    from pg_roles
    where rolname = 'community_contact_processor'
  ),
  'C14 contact function owner cannot bypass RLS or log in'
);

select ok(
  not has_table_privilege('anon', 'catalog.community_contacts', 'SELECT'),
  'C14 anon cannot select contacts directly'
);
select ok(
  not has_table_privilege('authenticated', 'catalog.community_contacts', 'SELECT'),
  'C14 authenticated users cannot select contacts directly'
);
select ok(
  not has_table_privilege('service_role', 'catalog.community_contacts', 'SELECT'),
  'C14 service_role cannot read contact rows outside the restricted function'
);
select ok(
  not has_table_privilege('anon', 'catalog.contact_destinations', 'SELECT'),
  'C14 anon cannot select recipient phones directly'
);
select ok(
  not has_table_privilege('authenticated', 'catalog.contact_destinations', 'SELECT'),
  'C14 authenticated users cannot select recipient phones directly'
);
select ok(
  not has_table_privilege('service_role', 'catalog.contact_destinations', 'SELECT'),
  'C14 service_role cannot read recipient phones outside the restricted function'
);
select ok(
  not has_table_privilege('anon', 'catalog.entity_contact_settings', 'SELECT')
    and not has_table_privilege('authenticated', 'catalog.entity_contact_settings', 'SELECT')
    and not has_table_privilege('service_role', 'catalog.entity_contact_settings', 'SELECT'),
  'C14 only the restricted database function can read substitute settings'
);

select ok(
  not has_function_privilege('anon', 'public.community_contact_method(text,text)', 'EXECUTE'),
  'C14 anon cannot resolve a contact method'
);
select ok(
  not has_function_privilege('anon', 'public.start_community_contact(text,text)', 'EXECUTE'),
  'C14 anon cannot start a contact'
);
select is(
  (
    select array_to_string(proargnames[3:5], ',')
    from pg_proc
    where oid = 'public.start_community_contact(text,text)'::regprocedure
  ),
  'contact_code,method,href',
  'C11 contact RPC returns only a code, method, and external link, never a raw phone column'
);
select is(
  (
    select array_to_string(proargnames[2:3], ',')
    from pg_proc
    where oid = 'public.equipment_availability(text)'::regprocedure
  ),
  'bank_name,available_quantity',
  'C14 anonymous availability contract remains bank name and quantity only'
);

set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claim.role', 'anon', true);

select throws_ok(
  $$select * from catalog.community_profiles$$,
  '42501',
  null,
  'C14 anon cannot read profile/CPF rows'
);
select throws_ok(
  $$select * from catalog.community_contacts$$,
  '42501',
  null,
  'C14 anon cannot read contact rows'
);
select throws_ok(
  $$select * from catalog.contact_destinations$$,
  '42501',
  null,
  'C14 anon cannot read recipient or phone rows'
);
select throws_ok(
  $$select public.community_contact_method('Entidade Sintetica RLS A', 'SYN-RLS-C14')$$,
  '42501',
  null,
  'C14 anon cannot resolve a destination through RPC'
);
select throws_ok(
  $$select * from public.start_community_contact('Entidade Sintetica RLS A', 'SYN-RLS-C14')$$,
  '42501',
  null,
  'C14 anon cannot initiate a contact through RPC'
);

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', '30000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(public.has_community_role(), false, 'C14 Companion without Community is not authorized');
select is(
  public.community_contact_method('Entidade Sintetica RLS A', 'SYN-RLS-C14'),
  'unavailable',
  'C14 Companion receives no contact method or destination'
);
select throws_ok(
  $$select * from public.start_community_contact('Entidade Sintetica RLS A', 'SYN-RLS-C14')$$,
  '42501',
  null,
  'C14 Companion cannot initiate a contact'
);
select throws_ok(
  $$select * from catalog.community_profiles$$,
  '42501',
  null,
  'C14 Companion cannot read CPF profiles'
);
select throws_ok(
  $$select * from catalog.community_contacts$$,
  '42501',
  null,
  'C14 Companion cannot read contacts'
);
select throws_ok(
  $$select * from catalog.contact_destinations$$,
  '42501',
  null,
  'C14 Companion cannot read recipient phones'
);
select throws_ok(
  $$select * from catalog.entity_contact_settings$$,
  '42501',
  null,
  'C14 Companion cannot read substitute settings'
);

select set_config('request.jwt.claim.sub', '30000000-0000-4000-8000-000000000008', true);
select is(public.has_community_role(), false, 'C14 an inactive Community role grants no permission');
select is(
  public.community_contact_method('Entidade Sintetica RLS A', 'SYN-RLS-C14'),
  'unavailable',
  'C14 an inactive Community role receives no contact method'
);
select throws_ok(
  $$select * from public.start_community_contact('Entidade Sintetica RLS A', 'SYN-RLS-C14')$$,
  '42501',
  null,
  'C14 an inactive Community role cannot initiate a contact'
);

select set_config('request.jwt.claim.sub', '30000000-0000-4000-8000-000000000001', true);
select is(public.has_community_role(), true, 'C14 active Community role is derived from auth.uid()');
select is(
  public.community_contact_method('Entidade Sintetica RLS A', 'SYN-RLS-C14'),
  'whatsapp',
  'C14 Community sees only the authorized WhatsApp method for entity A'
);
select is(
  public.community_contact_method('Entidade Sintetica RLS B', 'SYN-RLS-C14'),
  'telephone',
  'C12 Community gets the call fallback for entity B'
);
select is(
  public.community_contact_method('Entidade Sintetica RLS C', 'SYN-RLS-C14'),
  'whatsapp',
  'C9 Community resolves the active substitute method for entity C'
);
select is(
  public.community_contact_method('Entidade Sintetica RLS D', 'SYN-RLS-C14'),
  'unavailable',
  'C12 Community receives no method when the effective recipient has no phone'
);

select ok(
  (
    with requests as (
      select * from public.start_community_contact('Entidade Sintetica RLS A', 'SYN-RLS-C14')
      union all
      select * from public.start_community_contact('Entidade Sintetica RLS A', 'SYN-RLS-C14')
    )
    select count(*) = 2
      and count(distinct contact_code) = 1
      and bool_and(contact_code ~ '^[A-F0-9]{12}$')
      and bool_and(method = 'whatsapp')
      and bool_and(
        href = 'https://wa.me/12025550131?text=Ola.%20Quero%20conversar%20sobre%20um%20emprestimo%20de%20equipamento.%20Codigo%20do%20contato:%20'
          || contact_code
          || '.'
      )
    from requests
  ),
  'C9/C10 Community reuses one code and only the message tag varies for entity A'
);
select ok(
  (
    select contact_code ~ '^[A-F0-9]{12}$'
      and method = 'telephone'
      and href = 'tel:+12025550132'
    from public.start_community_contact('Entidade Sintetica RLS B', 'SYN-RLS-C14')
  ),
  'C12 fallback link contains only the configured tel destination'
);
select ok(
  (
    select contact_code ~ '^[A-F0-9]{12}$'
      and method = 'whatsapp'
      and href = 'https://wa.me/12025550134?text=Ola.%20Quero%20conversar%20sobre%20um%20emprestimo%20de%20equipamento.%20Codigo%20do%20contato:%20'
        || contact_code
        || '.'
    from public.start_community_contact('Entidade Sintetica RLS C', 'SYN-RLS-C14')
  ),
  'C9 contact uses the active substitute destination when substitute mode is on'
);
select ok(
  (
    select contact_code is null and method = 'unavailable' and href is null
    from public.start_community_contact('Entidade Sintetica RLS D', 'SYN-RLS-C14')
  ),
  'C12 no authorized phone creates no contact and returns no number or link'
);

select throws_ok(
  $$select * from catalog.community_profiles$$,
  '42501',
  null,
  'C14 Community cannot select CPF profiles directly'
);
select throws_ok(
  $$select * from catalog.community_contacts$$,
  '42501',
  null,
  'C14 Community cannot read contact rows directly'
);
select throws_ok(
  $$select * from catalog.contact_destinations$$,
  '42501',
  null,
  'C14 Community cannot read recipient phones directly'
);
select throws_ok(
  $$select * from catalog.entity_contact_settings$$,
  '42501',
  null,
  'C14 Community cannot read entity routing settings directly'
);

reset role;
select is(
  (
    select count(*)::integer
    from catalog.community_contacts
    where user_id = '30000000-0000-4000-8000-000000000001'
  ),
  3,
  'C9/C10 exactly three authorized contacts exist; duplicate A reuses one and D creates none'
);
select is(
  (
    select count(*)::integer
    from catalog.community_contacts
    where user_id = '30000000-0000-4000-8000-000000000001'
      and situacao = 'novo'::catalog.contact_situation
  ),
  3,
  'C9 newly created contacts use the normalized situation novo'
);

select * from finish();
rollback;
