grant usage on schema public to admin_contact_manager;
grant execute on function public.current_admin_bank_entity_id()
  to admin_contact_manager;
grant execute on function catalog.current_auth_uid()
  to admin_contact_manager;
