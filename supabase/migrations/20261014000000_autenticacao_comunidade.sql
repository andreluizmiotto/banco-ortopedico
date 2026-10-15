create type catalog.user_role as enum (
  'comunidade',
  'companheiro',
  'responsavel',
  'substituto',
  'admin_banco',
  'admin_geral'
);

create table catalog.community_profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null check (length(btrim(name)) between 2 and 150),
  cpf text not null,
  phone text not null,
  privacy_notice_version text not null
    check (length(btrim(privacy_notice_version)) between 1 and 128),
  privacy_notice_accepted_at timestamptz not null default clock_timestamp(),
  created_at timestamptz not null default clock_timestamp(),
  constraint community_profiles_cpf_unique unique (cpf),
  constraint community_profiles_cpf_format check (cpf ~ '^[0-9]{11}$'),
  constraint community_profiles_phone_e164_check check (
    phone like '+%'
    and substring(phone from 2) ~ '^[1-9][0-9]{7,14}$'
  )
);

create table catalog.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  role catalog.user_role not null,
  entity_id uuid references catalog.entities (id) on delete cascade,
  is_active boolean not null default true,
  created_at timestamptz not null default clock_timestamp(),
  constraint user_roles_entity_scope_check check (
    (
      role in ('responsavel', 'substituto', 'admin_banco')
      and entity_id is not null
    )
    or (
      role in ('comunidade', 'companheiro', 'admin_geral')
      and entity_id is null
    )
  )
);

create unique index user_roles_global_unique_idx
  on catalog.user_roles (user_id, role)
  where entity_id is null;

create unique index user_roles_entity_unique_idx
  on catalog.user_roles (user_id, role, entity_id)
  where entity_id is not null;

create table catalog.community_login_limits (
  origin_hash text primary key
    check (origin_hash ~ '^[0-9a-f]{64}$'),
  failed_attempts smallint not null default 1
    check (failed_attempts between 1 and 5),
  locked_until timestamptz,
  updated_at timestamptz not null default clock_timestamp(),
  constraint community_login_limits_lock_count_check check (
    locked_until is null or failed_attempts = 5
  )
);

alter table catalog.community_profiles enable row level security;
alter table catalog.community_profiles force row level security;
alter table catalog.user_roles enable row level security;
alter table catalog.user_roles force row level security;
alter table catalog.community_login_limits enable row level security;
alter table catalog.community_login_limits force row level security;

revoke all privileges on table catalog.community_profiles
  from public, anon, authenticated, service_role;
revoke all privileges on table catalog.user_roles
  from public, anon, authenticated, service_role;
revoke all privileges on table catalog.community_login_limits
  from public, anon, authenticated, service_role;

create role community_identity_lookup nologin noinherit nobypassrls;
create role community_profile_provisioner nologin noinherit nobypassrls;
create role community_login_limiter nologin noinherit nobypassrls;
create role community_authorization_checker nologin noinherit nobypassrls;

-- Auth's schema is managed; custom function roles cannot receive its schema usage grant.
-- This fixed-path wrapper returns only the subject from auth.uid() for RLS predicates.
create function catalog.current_auth_uid()
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
  to community_authorization_checker;

create policy "Identity lookup reads private profile rows"
  on catalog.community_profiles
  for select
  to community_identity_lookup
  using (true);

create policy "Profile provisioner reads existing profile rows"
  on catalog.community_profiles
  for select
  to community_profile_provisioner
  using (true);

create policy "Profile provisioner inserts confirmed users"
  on catalog.community_profiles
  for insert
  to community_profile_provisioner
  with check (
    phone like '+%'
    and substring(phone from 2) ~ '^[1-9][0-9]{7,14}$'
  );

create policy "Identity lookup sees active community roles"
  on catalog.user_roles
  for select
  to community_identity_lookup
  using (role = 'comunidade' and is_active);

create policy "Profile provisioner reads community roles"
  on catalog.user_roles
  for select
  to community_profile_provisioner
  using (role = 'comunidade' and entity_id is null);

create policy "Profile provisioner inserts confirmed community roles"
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
        and profile.phone like '+%'
        and substring(profile.phone from 2) ~ '^[1-9][0-9]{7,14}$'
    )
  );

create policy "Authorization checker sees its own active community role"
  on catalog.user_roles
  for select
  to community_authorization_checker
  using (
    user_id = catalog.current_auth_uid()
    and role = 'comunidade'
    and is_active
  );

create policy "Login limiter manages hashed origin rows"
  on catalog.community_login_limits
  for all
  to community_login_limiter
  using (true)
  with check (true);

grant usage on schema catalog to community_identity_lookup;
grant usage on schema catalog to community_profile_provisioner;
grant usage on schema catalog to community_login_limiter;
grant usage on schema catalog to community_authorization_checker;

grant select (id, cpf, phone) on catalog.community_profiles
  to community_identity_lookup;
grant select (user_id, role, is_active) on catalog.user_roles
  to community_identity_lookup;

grant select (id, cpf, phone) on catalog.community_profiles
  to community_profile_provisioner;
grant insert (
  id,
  name,
  cpf,
  phone,
  privacy_notice_version,
  privacy_notice_accepted_at
) on catalog.community_profiles to community_profile_provisioner;
grant select (user_id, role, entity_id, is_active) on catalog.user_roles
  to community_profile_provisioner;
grant insert (user_id, role, entity_id, is_active) on catalog.user_roles
  to community_profile_provisioner;

grant select, insert, update, delete on catalog.community_login_limits
  to community_login_limiter;

grant select (user_id, role, is_active) on catalog.user_roles
  to community_authorization_checker;

grant usage, create on schema public
  to community_identity_lookup,
     community_profile_provisioner,
     community_login_limiter,
     community_authorization_checker;
grant community_identity_lookup,
      community_profile_provisioner,
      community_login_limiter,
      community_authorization_checker
  to current_user;

create function public.community_phone_for_cpf(p_cpf text)
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

create function public.complete_community_signup(
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

create function public.is_community_login_locked(p_origin_hash text)
returns boolean
language plpgsql
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_locked_until timestamptz;
begin
  if p_origin_hash is null or p_origin_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'Origem invalida' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_origin_hash, 0));

  select login_limit.locked_until
  into v_locked_until
  from catalog.community_login_limits as login_limit
  where login_limit.origin_hash = p_origin_hash
  for update;

  if not found then
    return false;
  end if;

  if v_locked_until is not null and v_locked_until > clock_timestamp() then
    return true;
  end if;

  if v_locked_until is not null then
    delete from catalog.community_login_limits as login_limit
    where login_limit.origin_hash = p_origin_hash;
  end if;

  return false;
end
$function$;

create function public.record_community_login_failure(p_origin_hash text)
returns void
language plpgsql
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_now timestamptz := clock_timestamp();
  v_failed_attempts smallint;
  v_locked_until timestamptz;
  v_next_attempts smallint;
begin
  if p_origin_hash is null or p_origin_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'Origem invalida' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_origin_hash, 0));

  select login_limit.failed_attempts, login_limit.locked_until
  into v_failed_attempts, v_locked_until
  from catalog.community_login_limits as login_limit
  where login_limit.origin_hash = p_origin_hash
  for update;

  if not found then
    insert into catalog.community_login_limits (
      origin_hash,
      failed_attempts,
      locked_until,
      updated_at
    )
    values (p_origin_hash, 1, null, v_now);
    return;
  end if;

  if v_locked_until is not null and v_locked_until > v_now then
    return;
  end if;

  if v_locked_until is not null then
    v_next_attempts := 1;
  else
    v_next_attempts := least(v_failed_attempts + 1, 5);
  end if;

  update catalog.community_login_limits as login_limit
  set
    failed_attempts = v_next_attempts,
    locked_until = case
      when v_next_attempts = 5 then v_now + interval '15 minutes'
      else null
    end,
    updated_at = v_now
  where login_limit.origin_hash = p_origin_hash;
end
$function$;

create function public.clear_community_login_failures(p_origin_hash text)
returns void
language plpgsql
security definer
set search_path = ''
set row_security = on
as $function$
begin
  if p_origin_hash is null or p_origin_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'Origem invalida' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_origin_hash, 0));

  delete from catalog.community_login_limits as login_limit
  where login_limit.origin_hash = p_origin_hash;
end
$function$;

create function public.has_community_role()
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

alter function public.community_phone_for_cpf(text)
  owner to community_identity_lookup;
alter function public.complete_community_signup(uuid, text, text, text, text, boolean)
  owner to community_profile_provisioner;
alter function public.is_community_login_locked(text)
  owner to community_login_limiter;
alter function public.record_community_login_failure(text)
  owner to community_login_limiter;
alter function public.clear_community_login_failures(text)
  owner to community_login_limiter;
alter function public.has_community_role()
  owner to community_authorization_checker;

revoke all privileges on function public.community_phone_for_cpf(text)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.complete_community_signup(uuid, text, text, text, text, boolean)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.is_community_login_locked(text)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.record_community_login_failure(text)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.clear_community_login_failures(text)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.has_community_role()
  from public, anon, authenticated, service_role;

grant execute on function public.community_phone_for_cpf(text) to service_role;
grant execute on function public.complete_community_signup(uuid, text, text, text, text, boolean)
  to service_role;
grant execute on function public.is_community_login_locked(text) to service_role;
grant execute on function public.record_community_login_failure(text) to service_role;
grant execute on function public.clear_community_login_failures(text) to service_role;
grant execute on function public.has_community_role() to authenticated;

revoke create on schema public
  from community_identity_lookup,
       community_profile_provisioner,
       community_login_limiter,
       community_authorization_checker;
revoke community_identity_lookup,
       community_profile_provisioner,
       community_login_limiter,
       community_authorization_checker
  from current_user;
