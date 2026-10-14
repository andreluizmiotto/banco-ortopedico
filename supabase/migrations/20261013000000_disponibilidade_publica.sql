create type catalog.equipment_situation as enum (
  'disponivel',
  'reservado',
  'emprestado',
  'manutencao',
  'doado',
  'baixado'
);

create role availability_reader nologin noinherit;

create table catalog.entities (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  public_name text not null unique,
  is_bank boolean not null default true,
  is_active boolean not null default true
);

create table catalog.pontos_atendimento (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  address text
);

create table catalog.equipment_units (
  id uuid primary key default gen_random_uuid(),
  equipment_type_code text not null
    references catalog.equipment_types (code) on delete restrict,
  owner_entity_id uuid not null
    references catalog.entities (id) on delete restrict,
  storage_location_id uuid
    references catalog.pontos_atendimento (id) on delete restrict,
  situacao catalog.equipment_situation not null
);

create index equipment_units_owner_type_situation_idx
  on catalog.equipment_units (owner_entity_id, equipment_type_code, situacao);

alter table catalog.entities enable row level security;
alter table catalog.entities force row level security;
alter table catalog.pontos_atendimento enable row level security;
alter table catalog.pontos_atendimento force row level security;
alter table catalog.equipment_units enable row level security;
alter table catalog.equipment_units force row level security;

revoke all privileges on table catalog.entities
  from public, anon, authenticated, service_role;
revoke all privileges on table catalog.pontos_atendimento
  from public, anon, authenticated, service_role;
revoke all privileges on table catalog.equipment_units
  from public, anon, authenticated, service_role;

grant usage on schema catalog to availability_reader;
grant select on table catalog.entities, catalog.equipment_units
  to availability_reader;
grant select on table catalog.equipment_types to availability_reader;

create policy "Availability reader sees active banks"
  on catalog.entities
  for select
  to availability_reader
  using (is_bank and is_active);

create policy "Availability reader aggregates equipment units"
  on catalog.equipment_units
  for select
  to availability_reader
  using (true);

create policy "Availability reader sees active equipment types"
  on catalog.equipment_types
  for select
  to availability_reader
  using (is_active);

create function public.equipment_availability(p_equipment_type_code text)
returns table (bank_name text, available_quantity integer)
language sql
stable
security definer
set search_path = ''
set row_security = on
as $function$
  select
    entity.public_name,
    count(*) filter (
      where equipment_unit.situacao = 'disponivel'::catalog.equipment_situation
    )::integer
  from catalog.entities as entity
  join catalog.equipment_units as equipment_unit
    on equipment_unit.owner_entity_id = entity.id
    and equipment_unit.equipment_type_code = p_equipment_type_code
  where exists (
      select 1
      from catalog.equipment_types as equipment_type
      where equipment_type.code = p_equipment_type_code
        and equipment_type.is_active
    )
  group by entity.id, entity.public_name
$function$;

grant usage, create on schema public to availability_reader;
grant availability_reader to current_user;
alter function public.equipment_availability(text)
  owner to availability_reader;
revoke availability_reader from current_user;
revoke create on schema public from availability_reader;

revoke all privileges on function public.equipment_availability(text)
  from public, anon, authenticated, service_role;
grant execute on function public.equipment_availability(text)
  to anon, authenticated;
