drop function public.admin_bank_contacts(text);

grant admin_contact_manager to current_user with set true;
grant usage, create on schema public to admin_contact_manager;
set role admin_contact_manager;

create function public.admin_bank_contacts(p_public_code text)
returns table (
  bank_name text,
  public_code text,
  status text,
  overdue_48h boolean
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
    coalesce(
      contact.status = 'new'::catalog.contact_status
        and contact.created_at <= statement_timestamp() - interval '48 hours',
      false
    )
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

reset role;

alter function public.admin_bank_contacts(text)
  owner to admin_contact_manager;
revoke all privileges on function public.admin_bank_contacts(text)
  from public, anon, authenticated, service_role;
grant execute on function public.admin_bank_contacts(text) to authenticated;

revoke create on schema public from admin_contact_manager;
revoke admin_contact_manager from current_user;
