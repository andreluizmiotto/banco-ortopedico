create unique index user_roles_admin_banco_one_active_entity_idx
  on catalog.user_roles (user_id)
  where role = 'admin_banco' and is_active;

create role admin_bank_authorization_checker nologin noinherit nobypassrls;

create policy "Admin bank checker reads its own active bank role"
  on catalog.user_roles
  for select
  to admin_bank_authorization_checker
  using (
    user_id = catalog.current_auth_uid()
    and role = 'admin_banco'
    and is_active
  );

grant usage on schema catalog to admin_bank_authorization_checker;
grant select (user_id, role, entity_id, is_active) on catalog.user_roles
  to admin_bank_authorization_checker;
grant execute on function catalog.current_auth_uid()
  to admin_bank_authorization_checker;

grant admin_bank_authorization_checker to current_user with set true;
grant usage, create on schema public to admin_bank_authorization_checker;
set role admin_bank_authorization_checker;

create function public.current_admin_bank_entity_id()
returns uuid
language sql
stable
security definer
set search_path = ''
set row_security = on
as $function$
  select (array_agg(user_role.entity_id))[1]
  from catalog.user_roles as user_role
  where user_role.user_id = catalog.current_auth_uid()
    and user_role.role = 'admin_banco'
    and user_role.is_active
  having count(*) = 1
$function$;

revoke all privileges on function public.current_admin_bank_entity_id()
  from public, anon, authenticated, service_role;
grant execute on function public.current_admin_bank_entity_id()
  to authenticated;

reset role;
revoke create on schema public from admin_bank_authorization_checker;
revoke admin_bank_authorization_checker from current_user;
