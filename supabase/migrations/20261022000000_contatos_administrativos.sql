create role admin_contact_manager nologin noinherit nobypassrls;

create table catalog.community_contact_situation_audit (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid not null references auth.users (id) on delete restrict,
  action text not null check (action = 'contact_situation_changed'),
  entity_id uuid not null references catalog.entities (id) on delete restrict,
  contact_id uuid not null unique
    references catalog.community_contacts (id) on delete restrict,
  previous_situation catalog.contact_situation not null
    check (previous_situation = 'novo'),
  new_situation catalog.contact_situation not null check (
    new_situation in ('atendido', 'sem_retorno', 'virou_emprestimo')
  ),
  created_at timestamptz not null default clock_timestamp()
);

alter table catalog.community_contact_situation_audit
  enable row level security;
alter table catalog.community_contact_situation_audit
  force row level security;

revoke all privileges on table catalog.community_contact_situation_audit
  from public, anon, authenticated, service_role;

grant usage on schema catalog to admin_contact_manager;
grant select (id, public_name) on catalog.entities to admin_contact_manager;
grant select (id, codigo, entity_id, situacao, created_at)
  on catalog.community_contacts to admin_contact_manager;
grant update (situacao) on catalog.community_contacts
  to admin_contact_manager;
grant insert (
  actor_user_id,
  action,
  entity_id,
  contact_id,
  previous_situation,
  new_situation
) on catalog.community_contact_situation_audit to admin_contact_manager;
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
    and situacao in ('atendido', 'sem_retorno', 'virou_emprestimo')
  );

create policy "Admin contact manager inserts its own situation audit"
  on catalog.community_contact_situation_audit
  for insert
  to admin_contact_manager
  with check (
    actor_user_id = catalog.current_auth_uid()
    and entity_id = public.current_admin_bank_entity_id()
    and action = 'contact_situation_changed'
    and previous_situation = 'novo'
    and new_situation in ('atendido', 'sem_retorno', 'virou_emprestimo')
    and exists (
      select 1
      from catalog.community_contacts as contact
      where contact.id = community_contact_situation_audit.contact_id
        and contact.entity_id = community_contact_situation_audit.entity_id
        and contact.situacao = community_contact_situation_audit.new_situation
    )
  );

grant admin_contact_manager to current_user with set true;
grant usage, create on schema public to admin_contact_manager;
set role admin_contact_manager;

create function public.admin_bank_contacts(p_codigo text)
returns table (
  bank_name text,
  codigo text,
  situacao text,
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
    contact.codigo,
    contact.situacao::text,
    contact.created_at
  from catalog.entities as entity
  left join catalog.community_contacts as contact
    on contact.entity_id = entity.id
    and (
      p_codigo is null
      or (
        p_codigo ~ '^[A-F0-9]{12}$'
        and contact.codigo = p_codigo
      )
    )
  where entity.id = v_entity_id;
end
$function$;

create function public.admin_set_contact_situation(
  p_codigo text,
  p_new_situation text
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
  v_previous_situation catalog.contact_situation;
  v_target_situation catalog.contact_situation;
begin
  if v_actor_id is null or v_entity_id is null then
    raise exception 'Contato indisponível' using errcode = 'P0001';
  end if;

  if p_codigo is null or p_codigo !~ '^[A-F0-9]{12}$'
    or p_new_situation is null
    or p_new_situation not in ('atendido', 'sem_retorno', 'virou_emprestimo')
  then
    raise exception 'Contato indisponível' using errcode = 'P0001';
  end if;

  v_target_situation := p_new_situation::catalog.contact_situation;

  select contact.id, contact.situacao
  into v_contact_id, v_previous_situation
  from catalog.community_contacts as contact
  where contact.entity_id = v_entity_id
    and contact.codigo = p_codigo
  for update;

  if not found then
    raise exception 'Contato indisponível' using errcode = 'P0001';
  end if;

  if v_previous_situation = v_target_situation then
    return v_previous_situation::text;
  end if;

  if v_previous_situation <> 'novo' then
    raise exception 'Situação já registrada' using errcode = 'P0002';
  end if;

  update catalog.community_contacts as contact
  set situacao = v_target_situation
  where contact.id = v_contact_id
    and contact.entity_id = v_entity_id
    and contact.situacao = 'novo';

  if not found then
    raise exception 'Contato indisponível' using errcode = 'P0001';
  end if;

  insert into catalog.community_contact_situation_audit (
    actor_user_id,
    action,
    entity_id,
    contact_id,
    previous_situation,
    new_situation
  )
  values (
    v_actor_id,
    'contact_situation_changed',
    v_entity_id,
    v_contact_id,
    v_previous_situation,
    v_target_situation
  );

  return v_target_situation::text;
end
$function$;

reset role;

alter function public.admin_bank_contacts(text)
  owner to admin_contact_manager;
alter function public.admin_set_contact_situation(text, text)
  owner to admin_contact_manager;

revoke all privileges on function public.admin_bank_contacts(text)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.admin_set_contact_situation(text, text)
  from public, anon, authenticated, service_role;
grant execute on function public.admin_bank_contacts(text) to authenticated;
grant execute on function public.admin_set_contact_situation(text, text)
  to authenticated;

revoke create on schema public from admin_contact_manager;
revoke admin_contact_manager from current_user;
