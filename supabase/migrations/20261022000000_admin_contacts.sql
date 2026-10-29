create role admin_contact_manager nologin noinherit nobypassrls;

create table catalog.community_contact_status_audit (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid not null references auth.users (id) on delete restrict,
  action text not null check (action = 'contact_status_changed'),
  entity_id uuid not null references catalog.entities (id) on delete restrict,
  contact_id uuid not null unique
    references catalog.community_contacts (id) on delete restrict,
  previous_status catalog.contact_status not null
    check (previous_status = 'new'),
  new_status catalog.contact_status not null check (
    new_status in ('answered', 'no_response', 'converted_to_loan')
  ),
  created_at timestamptz not null default clock_timestamp()
);

alter table catalog.community_contact_status_audit
  enable row level security;
alter table catalog.community_contact_status_audit
  force row level security;

revoke all privileges on table catalog.community_contact_status_audit
  from public, anon, authenticated, service_role;

grant usage on schema catalog to admin_contact_manager;
grant select (id, public_name) on catalog.entities to admin_contact_manager;
grant select (id, public_code, entity_id, status, created_at)
  on catalog.community_contacts to admin_contact_manager;
grant update (status) on catalog.community_contacts
  to admin_contact_manager;
grant insert (
  actor_user_id,
  action,
  entity_id,
  contact_id,
  previous_status,
  new_status
) on catalog.community_contact_status_audit to admin_contact_manager;
grant execute on function catalog.current_auth_uid()
  to admin_contact_manager;
grant execute on function public.current_admin_bank_entity_id()
  to admin_contact_manager;

create policy "Admin contact manager reads its own bank entity"
  on catalog.entities
  for select
  to admin_contact_manager
  using (id = public.current_admin_bank_entity_id());

create policy "Admin contact manager reads contacts in its own bank"
  on catalog.community_contacts
  for select
  to admin_contact_manager
  using (entity_id = public.current_admin_bank_entity_id());

create policy "Admin contact manager changes new contacts in its own bank"
  on catalog.community_contacts
  for update
  to admin_contact_manager
  using (entity_id = public.current_admin_bank_entity_id())
  with check (
    entity_id = public.current_admin_bank_entity_id()
    and status in ('answered', 'no_response', 'converted_to_loan')
  );

create policy "Admin contact manager inserts its own status audit"
  on catalog.community_contact_status_audit
  for insert
  to admin_contact_manager
  with check (
    actor_user_id = catalog.current_auth_uid()
    and entity_id = public.current_admin_bank_entity_id()
    and action = 'contact_status_changed'
    and previous_status = 'new'
    and new_status in ('answered', 'no_response', 'converted_to_loan')
    and exists (
      select 1
      from catalog.community_contacts as contact
      where contact.id = community_contact_status_audit.contact_id
        and contact.entity_id = community_contact_status_audit.entity_id
        and contact.status = community_contact_status_audit.new_status
    )
  );

grant admin_contact_manager to current_user with set true;
grant usage, create on schema public to admin_contact_manager;
set role admin_contact_manager;

create function public.admin_bank_contacts(p_public_code text)
returns table (
  bank_name text,
  public_code text,
  status text,
  created_at timestamptz
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
    contact.public_code,
    contact.status::text,
    contact.created_at
  from catalog.entities as entity
  left join catalog.community_contacts as contact
    on contact.entity_id = entity.id
    and (
      p_public_code is null
      or (
        p_public_code ~ '^[A-F0-9]{12}$'
        and contact.public_code = p_public_code
      )
    )
  where entity.id = v_entity_id;
end
$function$;

create function public.admin_set_contact_status(
  p_public_code text,
  p_new_status text
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
  v_contact_id uuid;
  v_previous_status catalog.contact_status;
  v_target_status catalog.contact_status;
begin
  if v_actor_id is null or v_entity_id is null then
    raise exception 'Contact unavailable' using errcode = 'P0001';
  end if;

  if p_public_code is null or p_public_code !~ '^[A-F0-9]{12}$'
    or p_new_status is null
    or p_new_status not in ('answered', 'no_response', 'converted_to_loan')
  then
    raise exception 'Contact unavailable' using errcode = 'P0001';
  end if;

  v_target_status := p_new_status::catalog.contact_status;

  select contact.id, contact.status
  into v_contact_id, v_previous_status
  from catalog.community_contacts as contact
  where contact.entity_id = v_entity_id
    and contact.public_code = p_public_code
  for update;

  if not found then
    raise exception 'Contact unavailable' using errcode = 'P0001';
  end if;

  if v_previous_status = v_target_status then
    return v_previous_status::text;
  end if;

  if v_previous_status <> 'new' then
    raise exception 'Status already registered' using errcode = 'P0002';
  end if;

  update catalog.community_contacts as contact
  set status = v_target_status
  where contact.id = v_contact_id
    and contact.entity_id = v_entity_id
    and contact.status = 'new';

  if not found then
    raise exception 'Contact unavailable' using errcode = 'P0001';
  end if;

  insert into catalog.community_contact_status_audit (
    actor_user_id,
    action,
    entity_id,
    contact_id,
    previous_status,
    new_status
  )
  values (
    v_actor_id,
    'contact_status_changed',
    v_entity_id,
    v_contact_id,
    v_previous_status,
    v_target_status
  );

  return v_target_status::text;
end
$function$;

reset role;

alter function public.admin_bank_contacts(text)
  owner to admin_contact_manager;
alter function public.admin_set_contact_status(text, text)
  owner to admin_contact_manager;

revoke all privileges on function public.admin_bank_contacts(text)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.admin_set_contact_status(text, text)
  from public, anon, authenticated, service_role;
grant execute on function public.admin_bank_contacts(text) to authenticated;
grant execute on function public.admin_set_contact_status(text, text)
  to authenticated;

revoke create on schema public from admin_contact_manager;
revoke admin_contact_manager from current_user;
