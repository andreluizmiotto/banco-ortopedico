-- A bank with no draft still needs its name back. The page turns the
-- placeholder row into an empty list instead of the failure message, the same
-- shape public.admin_bank_contacts and public.admin_bank_equipment_units use.

grant admin_loan_manager to current_user with set true;
grant usage, create on schema public to admin_loan_manager;
set role admin_loan_manager;

create or replace function public.admin_bank_loans()
returns table (
  bank_name text,
  public_code text,
  borrower_name text,
  unit_count integer,
  created_at timestamptz,
  status text
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
    raise exception 'Empréstimo indisponível' using errcode = '42501';
  end if;

  return query
  select
    entity.public_name,
    loan.public_code,
    profile.name,
    count(line.unit_id)::integer,
    loan.created_at,
    loan.status::text
  from catalog.entities as entity
  left join catalog.loans as loan
    on loan.entity_id = entity.id
    and loan.status = 'draft'
  left join catalog.community_profiles as profile
    on profile.id = loan.borrower_user_id
  left join catalog.loan_lines as line
    on line.loan_id = loan.id
    and line.released_at is null
  where entity.id = v_entity_id
  group by loan.id, entity.public_name, profile.name
  order by loan.created_at desc nulls last, loan.id nulls last;
end
$function$;

reset role;

alter function public.admin_bank_loans() owner to admin_loan_manager;
revoke all privileges on function public.admin_bank_loans()
  from public, anon, authenticated, service_role;
grant execute on function public.admin_bank_loans() to authenticated;

revoke create on schema public from admin_loan_manager;
revoke admin_loan_manager from current_user;