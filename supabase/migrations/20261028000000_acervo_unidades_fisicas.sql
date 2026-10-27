create type catalog.equipment_entry_origin as enum (
  'doacao',
  'compra',
  'retorno_conserto',
  'devolucao_outro_banco'
);

alter table catalog.equipment_units
  add column visible_code text,
  add column entry_origin catalog.equipment_entry_origin;

alter table catalog.equipment_units
  add constraint equipment_units_visible_code_shape check (
    visible_code is null
    or (
      visible_code = btrim(visible_code)
      and char_length(visible_code) between 1 and 64
    )
  );

create unique index equipment_units_owner_visible_code_key
  on catalog.equipment_units (owner_entity_id, visible_code)
  where visible_code is not null;

create table catalog.equipment_unit_change_audit (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid not null references auth.users (id) on delete restrict,
  entity_id uuid not null references catalog.entities (id) on delete restrict,
  unit_id uuid not null references catalog.equipment_units (id) on delete restrict,
  action text not null check (action in ('unit_created', 'unit_updated')),
  previous_situation catalog.equipment_situation,
  new_situation catalog.equipment_situation not null,
  previous_storage_location_id uuid
    references catalog.pontos_atendimento (id) on delete restrict,
  new_storage_location_id uuid
    references catalog.pontos_atendimento (id) on delete restrict,
  previous_visible_code text,
  new_visible_code text,
  entry_origin catalog.equipment_entry_origin,
  created_at timestamptz not null default clock_timestamp(),
  constraint equipment_unit_change_audit_created_shape check (
    action <> 'unit_created'
    or (
      previous_situation is null
      and previous_storage_location_id is null
      and previous_visible_code is null
      and entry_origin is not null
    )
  ),
  constraint equipment_unit_change_audit_updated_shape check (
    action <> 'unit_updated'
    or (previous_situation is not null and entry_origin is null)
  )
);

create index equipment_unit_change_audit_unit_created_idx
  on catalog.equipment_unit_change_audit (unit_id, created_at);

alter table catalog.equipment_unit_change_audit enable row level security;
alter table catalog.equipment_unit_change_audit force row level security;

revoke all privileges on table catalog.equipment_unit_change_audit
  from public, anon, authenticated, service_role;

create role admin_equipment_manager nologin noinherit nobypassrls;
alter role admin_equipment_manager inherit;
grant admin_bank_authorization_checker to admin_equipment_manager;

grant usage on schema catalog to admin_equipment_manager;
grant select (
  id,
  equipment_type_code,
  owner_entity_id,
  storage_location_id,
  situacao,
  visible_code,
  entry_origin
) on catalog.equipment_units to admin_equipment_manager;
grant insert (
  equipment_type_code,
  owner_entity_id,
  storage_location_id,
  situacao,
  visible_code,
  entry_origin
) on catalog.equipment_units to admin_equipment_manager;
grant update (visible_code, storage_location_id, situacao)
  on catalog.equipment_units to admin_equipment_manager;
grant select (code, name, is_active, display_order)
  on catalog.equipment_types to admin_equipment_manager;
grant select (id, public_name) on catalog.entities to admin_equipment_manager;
grant select (id, code, name) on catalog.pontos_atendimento
  to admin_equipment_manager;
grant insert (
  actor_user_id,
  entity_id,
  unit_id,
  action,
  previous_situation,
  new_situation,
  previous_storage_location_id,
  new_storage_location_id,
  previous_visible_code,
  new_visible_code,
  entry_origin
) on catalog.equipment_unit_change_audit to admin_equipment_manager;
grant execute on function catalog.current_auth_uid()
  to admin_equipment_manager;
grant execute on function public.current_admin_bank_entity_id()
  to admin_equipment_manager;

create policy "Admin equipment manager reads units in its own bank"
  on catalog.equipment_units
  for select
  to admin_equipment_manager
  using (owner_entity_id = public.current_admin_bank_entity_id());

create policy "Admin equipment manager inserts units in its own bank"
  on catalog.equipment_units
  for insert
  to admin_equipment_manager
  with check (owner_entity_id = public.current_admin_bank_entity_id());

create policy "Admin equipment manager updates units in its own bank"
  on catalog.equipment_units
  for update
  to admin_equipment_manager
  using (owner_entity_id = public.current_admin_bank_entity_id())
  with check (owner_entity_id = public.current_admin_bank_entity_id());

create policy "Admin equipment manager reads equipment types"
  on catalog.equipment_types
  for select
  to admin_equipment_manager
  using (true);

create policy "Admin equipment manager reads its own bank entity"
  on catalog.entities
  for select
  to admin_equipment_manager
  using (id = public.current_admin_bank_entity_id());

create policy "Admin equipment manager reads storage locations"
  on catalog.pontos_atendimento
  for select
  to admin_equipment_manager
  using (true);

create policy "Admin equipment manager inserts its own unit audit"
  on catalog.equipment_unit_change_audit
  for insert
  to admin_equipment_manager
  with check (
    actor_user_id = catalog.current_auth_uid()
    and entity_id = public.current_admin_bank_entity_id()
    and action in ('unit_created', 'unit_updated')
    and exists (
      select 1
      from catalog.equipment_units as unit
      where unit.id = equipment_unit_change_audit.unit_id
        and unit.owner_entity_id = equipment_unit_change_audit.entity_id
    )
  );

grant admin_equipment_manager to current_user with set true;
grant usage, create on schema public to admin_equipment_manager;
set role admin_equipment_manager;

create function public.admin_bank_equipment_units()
returns table (
  bank_name text,
  unit_id uuid,
  equipment_type_code text,
  equipment_type_name text,
  visible_code text,
  storage_location_id uuid,
  storage_location_name text,
  entry_origin text,
  situacao text
)
language plpgsql
stable
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_entity_id uuid := public.current_admin_bank_entity_id();
begin
  if v_entity_id is null then
    return;
  end if;

  return query
  select
    entity.public_name,
    unit.id,
    unit.equipment_type_code,
    equipment_type.name,
    unit.visible_code,
    unit.storage_location_id,
    location.name,
    unit.entry_origin::text,
    unit.situacao::text
  from catalog.entities as entity
  left join catalog.equipment_units as unit
    on unit.owner_entity_id = entity.id
  left join catalog.equipment_types as equipment_type
    on equipment_type.code = unit.equipment_type_code
  left join catalog.pontos_atendimento as location
    on location.id = unit.storage_location_id
  where entity.id = v_entity_id
  order by
    equipment_type.display_order nulls last,
    unit.visible_code nulls last,
    unit.visible_code,
    unit.id;
end
$function$;

create function public.admin_bank_equipment_options()
returns table (
  option_kind text,
  option_code text,
  option_label text
)
language plpgsql
stable
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_entity_id uuid := public.current_admin_bank_entity_id();
begin
  if v_entity_id is null then
    return;
  end if;

  return query
  select 'equipment_type'::text, equipment_type.code, equipment_type.name
  from catalog.equipment_types as equipment_type
  where equipment_type.is_active
  union all
  select 'storage_location'::text, location.id::text, location.name
  from catalog.pontos_atendimento as location
  order by 1, 2;
end
$function$;

create function public.admin_create_equipment_unit(
  p_equipment_type_code text,
  p_visible_code text,
  p_storage_location_id uuid,
  p_situation text,
  p_entry_origin text
)
returns uuid
language plpgsql
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_actor_id uuid := catalog.current_auth_uid();
  v_entity_id uuid := public.current_admin_bank_entity_id();
  v_visible_code text;
  v_unit_id uuid;
begin
  if v_actor_id is null or v_entity_id is null then
    raise exception 'Acervo indisponível' using errcode = 'P0001';
  end if;

  if p_situation is null
    or p_situation not in (
      'disponivel',
      'reservado',
      'emprestado',
      'manutencao',
      'doado',
      'baixado'
    )
    or p_entry_origin is null
    or p_entry_origin not in (
      'doacao',
      'compra',
      'retorno_conserto',
      'devolucao_outro_banco'
    )
    or not exists (
      select 1
      from catalog.equipment_types as equipment_type
      where equipment_type.code = p_equipment_type_code
        and equipment_type.is_active
    )
    or (
      p_storage_location_id is not null
      and not exists (
        select 1
        from catalog.pontos_atendimento as location
        where location.id = p_storage_location_id
      )
    )
  then
    raise exception 'Dados da unidade inválidos' using errcode = 'P0002';
  end if;

  v_visible_code := nullif(btrim(coalesce(p_visible_code, '')), '');

  if v_visible_code is not null and char_length(v_visible_code) > 64 then
    raise exception 'Dados da unidade inválidos' using errcode = 'P0002';
  end if;

  insert into catalog.equipment_units (
    equipment_type_code,
    owner_entity_id,
    storage_location_id,
    situacao,
    visible_code,
    entry_origin
  )
  values (
    p_equipment_type_code,
    v_entity_id,
    p_storage_location_id,
    p_situation::catalog.equipment_situation,
    v_visible_code,
    p_entry_origin::catalog.equipment_entry_origin
  )
  returning id into v_unit_id;

  insert into catalog.equipment_unit_change_audit (
    actor_user_id,
    entity_id,
    unit_id,
    action,
    previous_situation,
    new_situation,
    previous_storage_location_id,
    new_storage_location_id,
    previous_visible_code,
    new_visible_code,
    entry_origin
  )
  values (
    v_actor_id,
    v_entity_id,
    v_unit_id,
    'unit_created',
    null,
    p_situation::catalog.equipment_situation,
    null,
    p_storage_location_id,
    null,
    v_visible_code,
    p_entry_origin::catalog.equipment_entry_origin
  );

  return v_unit_id;
exception
  when unique_violation then
    raise exception 'Identificador já usado' using errcode = 'P0003';
end
$function$;

create function public.admin_update_equipment_unit(
  p_unit_id uuid,
  p_visible_code text,
  p_storage_location_id uuid,
  p_situation text
)
returns text
language plpgsql
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_actor_id uuid := catalog.current_auth_uid();
  v_entity_id uuid := public.current_admin_bank_entity_id();
  v_visible_code text;
  v_previous_visible_code text;
  v_previous_storage_location_id uuid;
  v_previous_situation catalog.equipment_situation;
begin
  if v_actor_id is null or v_entity_id is null then
    raise exception 'Acervo indisponível' using errcode = 'P0001';
  end if;

  if p_unit_id is null
    or p_situation is null
    or p_situation not in (
      'disponivel',
      'reservado',
      'emprestado',
      'manutencao',
      'doado',
      'baixado'
    )
    or (
      p_storage_location_id is not null
      and not exists (
        select 1
        from catalog.pontos_atendimento as location
        where location.id = p_storage_location_id
      )
    )
  then
    raise exception 'Dados da unidade inválidos' using errcode = 'P0002';
  end if;

  v_visible_code := nullif(btrim(coalesce(p_visible_code, '')), '');

  if v_visible_code is not null and char_length(v_visible_code) > 64 then
    raise exception 'Dados da unidade inválidos' using errcode = 'P0002';
  end if;

  select
    unit.visible_code,
    unit.storage_location_id,
    unit.situacao
  into
    v_previous_visible_code,
    v_previous_storage_location_id,
    v_previous_situation
  from catalog.equipment_units as unit
  where unit.id = p_unit_id
    and unit.owner_entity_id = v_entity_id
  for update;

  if not found then
    raise exception 'Unidade indisponível' using errcode = 'P0001';
  end if;

  if v_previous_visible_code is not distinct from v_visible_code
    and v_previous_storage_location_id is not distinct from p_storage_location_id
    and v_previous_situation = p_situation::catalog.equipment_situation
  then
    return v_previous_situation::text;
  end if;

  update catalog.equipment_units as unit
  set
    visible_code = v_visible_code,
    storage_location_id = p_storage_location_id,
    situacao = p_situation::catalog.equipment_situation
  where unit.id = p_unit_id
    and unit.owner_entity_id = v_entity_id;

  insert into catalog.equipment_unit_change_audit (
    actor_user_id,
    entity_id,
    unit_id,
    action,
    previous_situation,
    new_situation,
    previous_storage_location_id,
    new_storage_location_id,
    previous_visible_code,
    new_visible_code,
    entry_origin
  )
  values (
    v_actor_id,
    v_entity_id,
    p_unit_id,
    'unit_updated',
    v_previous_situation,
    p_situation::catalog.equipment_situation,
    v_previous_storage_location_id,
    p_storage_location_id,
    v_previous_visible_code,
    v_visible_code,
    null
  );

  return p_situation;
exception
  when unique_violation then
    raise exception 'Identificador já usado' using errcode = 'P0003';
end
$function$;

reset role;

alter function public.admin_bank_equipment_units()
  owner to admin_equipment_manager;
alter function public.admin_bank_equipment_options()
  owner to admin_equipment_manager;
alter function public.admin_create_equipment_unit(text, text, uuid, text, text)
  owner to admin_equipment_manager;
alter function public.admin_update_equipment_unit(uuid, text, uuid, text)
  owner to admin_equipment_manager;

revoke all privileges on function public.admin_bank_equipment_units()
  from public, anon, authenticated, service_role;
revoke all privileges on function public.admin_bank_equipment_options()
  from public, anon, authenticated, service_role;
revoke all privileges on function public.admin_create_equipment_unit(text, text, uuid, text, text)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.admin_update_equipment_unit(uuid, text, uuid, text)
  from public, anon, authenticated, service_role;

grant execute on function public.admin_bank_equipment_units()
  to authenticated;
grant execute on function public.admin_bank_equipment_options()
  to authenticated;
grant execute on function public.admin_create_equipment_unit(text, text, uuid, text, text)
  to authenticated;
grant execute on function public.admin_update_equipment_unit(uuid, text, uuid, text)
  to authenticated;

revoke create on schema public from admin_equipment_manager;
revoke admin_equipment_manager from current_user;
