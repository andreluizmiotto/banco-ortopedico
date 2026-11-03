create schema catalog;

revoke all on schema catalog from public, anon, authenticated, service_role;
grant usage on schema catalog to anon, authenticated;

create table catalog.equipment_types (
  code text primary key,
  name text not null unique,
  is_active boolean not null default true,
  display_order integer not null unique
);

alter table catalog.equipment_types enable row level security;

revoke all privileges on table catalog.equipment_types
  from public, anon, authenticated, service_role;
grant select on table catalog.equipment_types to anon, authenticated;

create policy "Read active equipment types"
  on catalog.equipment_types
  for select
  to anon, authenticated
  using (is_active);

create view public.equipment_types
with (security_invoker = true)
as
select code, name, display_order
from catalog.equipment_types
where is_active
order by display_order, code;

revoke all privileges on table public.equipment_types
  from public, anon, authenticated, service_role;
grant select on table public.equipment_types to anon, authenticated;
