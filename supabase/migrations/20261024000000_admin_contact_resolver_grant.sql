grant admin_bank_authorization_checker to current_user with set true;
set role admin_bank_authorization_checker;

grant execute on function public.current_admin_bank_entity_id()
  to admin_contact_manager;

reset role;
revoke admin_bank_authorization_checker from current_user;
