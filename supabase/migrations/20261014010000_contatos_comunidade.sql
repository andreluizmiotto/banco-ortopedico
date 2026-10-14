create type catalog.contact_situation as enum (
  'novo',
  'atendido',
  'virou_emprestimo',
  'sem_retorno'
);

create table catalog.entity_contact_settings (
  entity_id uuid primary key references catalog.entities (id) on delete cascade,
  substitute_mode boolean not null default false,
  updated_at timestamptz not null default clock_timestamp()
);

create table catalog.contact_destinations (
  entity_id uuid not null references catalog.entities (id) on delete cascade,
  recipient_role catalog.user_role not null
    check (recipient_role in ('responsavel', 'substituto')),
  recipient_user_id uuid not null references auth.users (id) on delete restrict,
  whatsapp_phone text,
  call_phone text,
  is_active boolean not null default true,
  updated_at timestamptz not null default clock_timestamp(),
  primary key (entity_id, recipient_role),
  constraint contact_destinations_whatsapp_e164_check check (
    whatsapp_phone is null or (
      whatsapp_phone like '+%'
      and substring(whatsapp_phone from 2) ~ '^[1-9][0-9]{7,14}$'
    )
  ),
  constraint contact_destinations_call_e164_check check (
    call_phone is null or (
      call_phone like '+%'
      and substring(call_phone from 2) ~ '^[1-9][0-9]{7,14}$'
    )
  )
);

create table catalog.community_contacts (
  id uuid primary key default gen_random_uuid(),
  codigo text not null unique
    default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12))
    check (codigo ~ '^[A-F0-9]{12}$'),
  user_id uuid not null references auth.users (id) on delete restrict,
  entity_id uuid not null references catalog.entities (id) on delete restrict,
  equipment_type_code text not null
    references catalog.equipment_types (code) on delete restrict,
  recipient_user_id uuid not null references auth.users (id) on delete restrict,
  recipient_role catalog.user_role not null
    check (recipient_role in ('responsavel', 'substituto')),
  origem text not null default 'detalhe_equipamento'
    check (origem = 'detalhe_equipamento'),
  situacao catalog.contact_situation not null default 'novo',
  created_at timestamptz not null default clock_timestamp()
);

create index community_contacts_owner_entity_type_created_idx
  on catalog.community_contacts (
    user_id,
    entity_id,
    equipment_type_code,
    created_at desc
  );

alter table catalog.entity_contact_settings enable row level security;
alter table catalog.entity_contact_settings force row level security;
alter table catalog.contact_destinations enable row level security;
alter table catalog.contact_destinations force row level security;
alter table catalog.community_contacts enable row level security;
alter table catalog.community_contacts force row level security;

revoke all privileges on table catalog.entity_contact_settings
  from public, anon, authenticated, service_role;
revoke all privileges on table catalog.contact_destinations
  from public, anon, authenticated, service_role;
revoke all privileges on table catalog.community_contacts
  from public, anon, authenticated, service_role;

create role community_contact_processor nologin noinherit nobypassrls;

create policy "Contact processor reads active banks"
  on catalog.entities
  for select
  to community_contact_processor
  using (is_bank and is_active);

create policy "Contact processor reads active equipment types"
  on catalog.equipment_types
  for select
  to community_contact_processor
  using (is_active);

create policy "Contact processor checks type ownership"
  on catalog.equipment_units
  for select
  to community_contact_processor
  using (true);

create policy "Contact processor checks active community and recipients"
  on catalog.user_roles
  for select
  to community_contact_processor
  using (
    (
      user_id = catalog.current_auth_uid()
      and role = 'comunidade'
      and is_active
    )
    or (
      role in ('responsavel', 'substituto')
      and is_active
    )
  );

create policy "Contact processor reads entity contact settings"
  on catalog.entity_contact_settings
  for select
  to community_contact_processor
  using (true);

create policy "Contact processor reads active destinations"
  on catalog.contact_destinations
  for select
  to community_contact_processor
  using (is_active);

create policy "Community contact processor reads own contacts"
  on catalog.community_contacts
  for select
  to community_contact_processor
  using (user_id = catalog.current_auth_uid());

create policy "Community contact processor inserts own contacts"
  on catalog.community_contacts
  for insert
  to community_contact_processor
  with check (
    user_id = catalog.current_auth_uid()
    and exists (
      select 1
      from catalog.user_roles as user_role
      where user_role.user_id = catalog.current_auth_uid()
        and user_role.role = 'comunidade'
        and user_role.is_active
    )
  );

create policy "Community contact processor refreshes own effective recipient"
  on catalog.community_contacts
  for update
  to community_contact_processor
  using (user_id = catalog.current_auth_uid())
  with check (
    user_id = catalog.current_auth_uid()
    and recipient_role in ('responsavel', 'substituto')
    and exists (
      select 1
      from catalog.user_roles as user_role
      where user_role.user_id = catalog.current_auth_uid()
        and user_role.role = 'comunidade'
        and user_role.is_active
    )
  );

grant usage on schema catalog to community_contact_processor;
grant select (id, public_name, is_bank, is_active) on catalog.entities
  to community_contact_processor;
grant select (code, is_active) on catalog.equipment_types
  to community_contact_processor;
grant select (owner_entity_id, equipment_type_code) on catalog.equipment_units
  to community_contact_processor;
grant select (user_id, role, entity_id, is_active) on catalog.user_roles
  to community_contact_processor;
grant select (entity_id, substitute_mode) on catalog.entity_contact_settings
  to community_contact_processor;
grant select (
  entity_id,
  recipient_role,
  recipient_user_id,
  whatsapp_phone,
  call_phone,
  is_active
) on catalog.contact_destinations to community_contact_processor;
grant select, insert on catalog.community_contacts
  to community_contact_processor;
grant update (recipient_user_id, recipient_role) on catalog.community_contacts
  to community_contact_processor;
grant execute on function catalog.current_auth_uid()
  to community_contact_processor;

grant usage, create on schema public to community_contact_processor;
grant community_contact_processor to current_user;

create function public.community_contact_method(
  p_public_bank_name text,
  p_equipment_type_code text
)
returns text
language plpgsql
stable
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_user_id uuid := catalog.current_auth_uid();
  v_entity_id uuid;
  v_substitute_mode boolean := false;
  v_recipient_role catalog.user_role;
  v_whatsapp_phone text;
  v_call_phone text;
begin
  if v_user_id is null or not exists (
    select 1
    from catalog.user_roles as user_role
    where user_role.user_id = v_user_id
      and user_role.role = 'comunidade'
      and user_role.is_active
  ) then
    return 'unavailable';
  end if;

  select entity.id
  into v_entity_id
  from catalog.entities as entity
  where entity.public_name = p_public_bank_name
    and entity.is_bank
    and entity.is_active;

  if not found or not exists (
    select 1
    from catalog.equipment_types as equipment_type
    join catalog.equipment_units as equipment_unit
      on equipment_unit.equipment_type_code = equipment_type.code
    where equipment_type.code = p_equipment_type_code
      and equipment_type.is_active
      and equipment_unit.owner_entity_id = v_entity_id
  ) then
    return 'unavailable';
  end if;

  select settings.substitute_mode
  into v_substitute_mode
  from catalog.entity_contact_settings as settings
  where settings.entity_id = v_entity_id;

  v_recipient_role := case
    when v_substitute_mode then 'substituto'::catalog.user_role
    else 'responsavel'::catalog.user_role
  end;

  select destination.whatsapp_phone, destination.call_phone
  into v_whatsapp_phone, v_call_phone
  from catalog.contact_destinations as destination
  join catalog.user_roles as user_role
    on user_role.user_id = destination.recipient_user_id
    and user_role.role = destination.recipient_role
    and user_role.entity_id = destination.entity_id
    and user_role.is_active
  where destination.entity_id = v_entity_id
    and destination.recipient_role = v_recipient_role
    and destination.is_active
  limit 1;

  if not found then
    return 'unavailable';
  end if;

  if v_whatsapp_phone is not null then
    return 'whatsapp';
  end if;

  if v_call_phone is not null then
    return 'telephone';
  end if;

  return 'unavailable';
end
$function$;

create function public.start_community_contact(
  p_public_bank_name text,
  p_equipment_type_code text
)
returns table (contact_code text, method text, href text)
language plpgsql
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_user_id uuid := catalog.current_auth_uid();
  v_entity_id uuid;
  v_substitute_mode boolean := false;
  v_recipient_role catalog.user_role;
  v_recipient_user_id uuid;
  v_whatsapp_phone text;
  v_call_phone text;
  v_method text;
  v_contact_code text;
  v_href text;
  v_now timestamptz;
begin
  if v_user_id is null or not exists (
    select 1
    from catalog.user_roles as user_role
    where user_role.user_id = v_user_id
      and user_role.role = 'comunidade'
      and user_role.is_active
  ) then
    raise exception 'Contato indisponivel' using errcode = '42501';
  end if;

  select entity.id
  into v_entity_id
  from catalog.entities as entity
  where entity.public_name = p_public_bank_name
    and entity.is_bank
    and entity.is_active;

  if not found or not exists (
    select 1
    from catalog.equipment_types as equipment_type
    join catalog.equipment_units as equipment_unit
      on equipment_unit.equipment_type_code = equipment_type.code
    where equipment_type.code = p_equipment_type_code
      and equipment_type.is_active
      and equipment_unit.owner_entity_id = v_entity_id
  ) then
    return query select null::text, 'unavailable'::text, null::text;
    return;
  end if;

  select settings.substitute_mode
  into v_substitute_mode
  from catalog.entity_contact_settings as settings
  where settings.entity_id = v_entity_id;

  v_recipient_role := case
    when v_substitute_mode then 'substituto'::catalog.user_role
    else 'responsavel'::catalog.user_role
  end;

  select
    destination.recipient_user_id,
    destination.whatsapp_phone,
    destination.call_phone
  into
    v_recipient_user_id,
    v_whatsapp_phone,
    v_call_phone
  from catalog.contact_destinations as destination
  join catalog.user_roles as user_role
    on user_role.user_id = destination.recipient_user_id
    and user_role.role = destination.recipient_role
    and user_role.entity_id = destination.entity_id
    and user_role.is_active
  where destination.entity_id = v_entity_id
    and destination.recipient_role = v_recipient_role
    and destination.is_active
  limit 1;

  if not found then
    return query select null::text, 'unavailable'::text, null::text;
    return;
  end if;

  if v_whatsapp_phone is not null then
    v_method := 'whatsapp';
  elsif v_call_phone is not null then
    v_method := 'telephone';
  else
    return query select null::text, 'unavailable'::text, null::text;
    return;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      v_user_id::text || ':' || v_entity_id::text || ':' || p_equipment_type_code,
      0
    )
  );

  v_now := clock_timestamp();

  select contact.codigo
  into v_contact_code
  from catalog.community_contacts as contact
  where contact.user_id = v_user_id
    and contact.entity_id = v_entity_id
    and contact.equipment_type_code = p_equipment_type_code
    and contact.created_at >= v_now - interval '30 minutes'
  order by contact.created_at desc, contact.id desc
  limit 1;

  if not found then
    insert into catalog.community_contacts (
      user_id,
      entity_id,
      equipment_type_code,
      recipient_user_id,
      recipient_role,
      origem,
      situacao,
      created_at
    )
    values (
      v_user_id,
      v_entity_id,
      p_equipment_type_code,
      v_recipient_user_id,
      v_recipient_role,
      'detalhe_equipamento',
      'novo',
      v_now
    )
    returning codigo into v_contact_code;
  else
    update catalog.community_contacts as contact
    set
      recipient_user_id = v_recipient_user_id,
      recipient_role = v_recipient_role
    where contact.codigo = v_contact_code
      and contact.user_id = v_user_id;
  end if;

  if v_method = 'whatsapp' then
    v_href := 'https://wa.me/'
      || regexp_replace(v_whatsapp_phone, '[^0-9]', '', 'g')
      || '?text=Ola.%20Quero%20conversar%20sobre%20um%20emprestimo%20de%20equipamento.%20Codigo%20do%20contato:%20'
      || v_contact_code
      || '.';
  else
    v_href := 'tel:' || v_call_phone;
  end if;

  return query select v_contact_code, v_method, v_href;
end
$function$;

alter function public.community_contact_method(text, text)
  owner to community_contact_processor;
alter function public.start_community_contact(text, text)
  owner to community_contact_processor;

revoke all privileges on function public.community_contact_method(text, text)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.start_community_contact(text, text)
  from public, anon, authenticated, service_role;

grant execute on function public.community_contact_method(text, text)
  to authenticated;
grant execute on function public.start_community_contact(text, text)
  to authenticated;

revoke create on schema public from community_contact_processor;
revoke community_contact_processor from current_user;
