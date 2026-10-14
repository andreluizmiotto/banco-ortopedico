-- Auth is a managed schema. Keep its subject lookup behind one fixed-path helper,
-- and store the confirmed phone only in the private community profile.
alter table catalog.community_profiles
  add column if not exists phone text;

do $migration$
begin
  if exists (
    select 1
    from catalog.community_profiles
    where phone is null
  ) then
    raise exception 'Community profile phone migration requires verified source data';
  end if;
end
$migration$;

alter table catalog.community_profiles
  alter column phone set not null;
alter table catalog.community_profiles
  drop constraint if exists community_profiles_phone_e164_check;
alter table catalog.community_profiles
  add constraint community_profiles_phone_e164_check check (
    phone like '+%'
    and substring(phone from 2) ~ '^[1-9][0-9]{7,14}$'
  );

create or replace function catalog.current_auth_uid()
returns uuid
language sql
stable
security definer
set search_path = ''
as $function$
  select auth.uid()
$function$;

revoke all privileges on function catalog.current_auth_uid()
  from public, anon, authenticated, service_role;
grant execute on function catalog.current_auth_uid()
  to community_authorization_checker, community_contact_processor;

grant select (id, cpf, phone) on catalog.community_profiles
  to community_identity_lookup, community_profile_provisioner;
grant insert (
  id,
  name,
  cpf,
  phone,
  privacy_notice_version,
  privacy_notice_accepted_at
) on catalog.community_profiles to community_profile_provisioner;

drop policy if exists "Profile provisioner inserts confirmed users"
  on catalog.community_profiles;
create policy "Profile provisioner inserts verified phone profiles"
  on catalog.community_profiles
  for insert
  to community_profile_provisioner
  with check (
    phone like '+%'
    and substring(phone from 2) ~ '^[1-9][0-9]{7,14}$'
  );

drop policy if exists "Profile provisioner inserts confirmed community roles"
  on catalog.user_roles;
create policy "Profile provisioner inserts community profile roles"
  on catalog.user_roles
  for insert
  to community_profile_provisioner
  with check (
    role = 'comunidade'
    and entity_id is null
    and is_active
    and exists (
      select 1
      from catalog.community_profiles as profile
      where profile.id = user_roles.user_id
        and profile.phone is not null
    )
  );

drop policy if exists "Authorization checker sees its own active community role"
  on catalog.user_roles;
create policy "Authorization checker sees its own active community role"
  on catalog.user_roles
  for select
  to community_authorization_checker
  using (
    user_id = catalog.current_auth_uid()
    and role = 'comunidade'
    and is_active
  );

grant community_identity_lookup to current_user with set true;
grant create on schema public to community_identity_lookup;
set role community_identity_lookup;

create or replace function public.community_phone_for_cpf(p_cpf text)
returns text
language plpgsql
stable
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_phone text;
begin
  if p_cpf is null or p_cpf !~ '^[0-9]{11}$' then
    return null;
  end if;

  select profile.phone
  into v_phone
  from catalog.community_profiles as profile
  join catalog.user_roles as user_role
    on user_role.user_id = profile.id
    and user_role.role = 'comunidade'
    and user_role.is_active
  where profile.cpf = p_cpf
  limit 1;

  return v_phone;
end
$function$;

alter function public.community_phone_for_cpf(text)
  owner to community_identity_lookup;
revoke all privileges on function public.community_phone_for_cpf(text)
  from public, anon, authenticated, service_role;
grant execute on function public.community_phone_for_cpf(text) to service_role;

reset role;
revoke create on schema public from community_identity_lookup;
revoke community_identity_lookup from current_user;

grant community_profile_provisioner to current_user with set true;
grant create on schema public to community_profile_provisioner;
set role community_profile_provisioner;

drop function if exists public.complete_community_signup(
  uuid,
  text,
  text,
  text,
  boolean
);

create or replace function public.complete_community_signup(
  p_auth_user_id uuid,
  p_cpf text,
  p_name text,
  p_phone text,
  p_privacy_notice_version text,
  p_privacy_accepted boolean
)
returns void
language plpgsql
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_existing_cpf text;
  v_existing_phone text;
begin
  if p_auth_user_id is null
    or p_cpf is null
    or p_cpf !~ '^[0-9]{11}$'
    or p_name is null
    or length(btrim(p_name)) not between 2 and 150
    or p_phone is null
    or p_phone not like '+%'
    or substring(p_phone from 2) !~ '^[1-9][0-9]{7,14}$'
    or p_privacy_notice_version is null
    or length(btrim(p_privacy_notice_version)) not between 1 and 128
    or p_privacy_accepted is distinct from true
  then
    raise exception 'Cadastro indisponivel' using errcode = 'P0001';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(p_auth_user_id::text, 1)
  );

  select profile.cpf, profile.phone
  into v_existing_cpf, v_existing_phone
  from catalog.community_profiles as profile
  where profile.id = p_auth_user_id;

  if found then
    if v_existing_cpf <> p_cpf or v_existing_phone <> p_phone then
      raise exception 'Cadastro indisponivel' using errcode = 'P0001';
    end if;
  else
    begin
      insert into catalog.community_profiles (
        id,
        name,
        cpf,
        phone,
        privacy_notice_version,
        privacy_notice_accepted_at
      )
      values (
        p_auth_user_id,
        btrim(p_name),
        p_cpf,
        p_phone,
        btrim(p_privacy_notice_version),
        clock_timestamp()
      );
    exception
      when unique_violation then
        raise exception 'Cadastro indisponivel' using errcode = 'P0001';
    end;
  end if;

  if exists (
    select 1
    from catalog.user_roles as user_role
    where user_role.user_id = p_auth_user_id
      and user_role.role = 'comunidade'
      and user_role.entity_id is null
      and not user_role.is_active
  ) then
    raise exception 'Cadastro indisponivel' using errcode = 'P0001';
  end if;

  if not exists (
    select 1
    from catalog.user_roles as user_role
    where user_role.user_id = p_auth_user_id
      and user_role.role = 'comunidade'
      and user_role.entity_id is null
      and user_role.is_active
  ) then
    insert into catalog.user_roles (user_id, role, entity_id, is_active)
    values (p_auth_user_id, 'comunidade', null, true);
  end if;
end
$function$;

alter function public.complete_community_signup(uuid, text, text, text, text, boolean)
  owner to community_profile_provisioner;
revoke all privileges on function public.complete_community_signup(
  uuid,
  text,
  text,
  text,
  text,
  boolean
) from public, anon, authenticated, service_role;
grant execute on function public.complete_community_signup(
  uuid,
  text,
  text,
  text,
  text,
  boolean
) to service_role;

reset role;
revoke create on schema public from community_profile_provisioner;
revoke community_profile_provisioner from current_user;

grant community_authorization_checker to current_user with set true;
grant create on schema public to community_authorization_checker;
set role community_authorization_checker;

create or replace function public.has_community_role()
returns boolean
language sql
stable
security definer
set search_path = ''
set row_security = on
as $function$
  select catalog.current_auth_uid() is not null
    and exists (
      select 1
      from catalog.user_roles as user_role
      where user_role.user_id = catalog.current_auth_uid()
        and user_role.role = 'comunidade'
        and user_role.is_active
    )
$function$;

alter function public.has_community_role()
  owner to community_authorization_checker;
revoke all privileges on function public.has_community_role()
  from public, anon, authenticated, service_role;
grant execute on function public.has_community_role() to authenticated;

reset role;
revoke create on schema public from community_authorization_checker;
revoke community_authorization_checker from current_user;

drop policy if exists "Contact processor checks active community and recipients"
  on catalog.user_roles;
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

drop policy if exists "Community contact processor reads own contacts"
  on catalog.community_contacts;
create policy "Community contact processor reads own contacts"
  on catalog.community_contacts
  for select
  to community_contact_processor
  using (user_id = catalog.current_auth_uid());

drop policy if exists "Community contact processor inserts own contacts"
  on catalog.community_contacts;
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

drop policy if exists "Community contact processor refreshes own effective recipient"
  on catalog.community_contacts;
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

alter table catalog.contact_destinations
  drop constraint if exists contact_destinations_whatsapp_e164_check;
alter table catalog.contact_destinations
  add constraint contact_destinations_whatsapp_e164_check check (
    whatsapp_phone is null or (
      whatsapp_phone like '+%'
      and substring(whatsapp_phone from 2) ~ '^[1-9][0-9]{7,14}$'
    )
  );
alter table catalog.contact_destinations
  drop constraint if exists contact_destinations_call_e164_check;
alter table catalog.contact_destinations
  add constraint contact_destinations_call_e164_check check (
    call_phone is null or (
      call_phone like '+%'
      and substring(call_phone from 2) ~ '^[1-9][0-9]{7,14}$'
    )
  );

grant community_contact_processor to current_user with set true;
grant create on schema public to community_contact_processor;
set role community_contact_processor;

create or replace function public.community_contact_method(
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
  if v_whatsapp_phone is not null then return 'whatsapp'; end if;
  if v_call_phone is not null then return 'telephone'; end if;
  return 'unavailable';
end
$function$;

create or replace function public.start_community_contact(
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

  select destination.recipient_user_id, destination.whatsapp_phone, destination.call_phone
  into v_recipient_user_id, v_whatsapp_phone, v_call_phone
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

reset role;
revoke create on schema public from community_contact_processor;
revoke community_contact_processor from current_user;
