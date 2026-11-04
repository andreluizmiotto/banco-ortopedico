-- Loans: person lookup, draft that holds units, versioned term model, generated file
-- and the four audit events FR-019/FR-020/FR-021/FR-031/FR-034/FR-042 owe.

alter table catalog.entities
  add column loan_suggested_days integer not null default 90;

alter table catalog.entities
  add constraint entities_loan_suggested_days_shape check (
    loan_suggested_days between 1 and 365
  );

create type catalog.document_type as enum ('loan_term');

create type catalog.document_review_status as enum (
  'pending_legal_review',
  'approved'
);

create type catalog.loan_status as enum ('draft', 'active', 'cancelled');

create table catalog.document_models (
  id uuid primary key default gen_random_uuid(),
  entity_id uuid not null references catalog.entities (id) on delete restrict,
  document_type catalog.document_type not null,
  version integer not null check (version >= 1),
  body text not null check (char_length(btrim(body)) between 1 and 20000),
  review_status catalog.document_review_status not null
    default 'pending_legal_review',
  is_active boolean not null default true,
  created_at timestamptz not null default clock_timestamp(),
  unique (entity_id, document_type, version)
);

create unique index document_models_one_active_key
  on catalog.document_models (entity_id, document_type)
  where is_active;

create table catalog.loans (
  id uuid primary key default gen_random_uuid(),
  public_code text not null unique
    default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12)),
  entity_id uuid not null references catalog.entities (id) on delete restrict,
  borrower_user_id uuid not null references auth.users (id) on delete restrict,
  patient_name text,
  condition_note text,
  delivery_date date not null,
  due_date date,
  review_date date,
  status catalog.loan_status not null default 'draft',
  created_by_user_id uuid not null references auth.users (id) on delete restrict,
  created_at timestamptz not null default clock_timestamp(),
  completed_at timestamptz,
  cancelled_at timestamptz,
  constraint loans_public_code_shape check (public_code ~ '^[A-F0-9]{12}$'),
  constraint loans_patient_name_shape check (
    patient_name is null
    or char_length(btrim(patient_name)) between 2 and 120
  ),
  constraint loans_condition_note_shape check (
    condition_note is null
    or char_length(btrim(condition_note)) between 1 and 200
  ),
  constraint loans_term_shape check (
    (due_date is not null and review_date is null)
    or (due_date is null and review_date is not null)
  ),
  constraint loans_closed_shape check (
    (status = 'draft' and completed_at is null and cancelled_at is null)
    or (status = 'active' and completed_at is not null and cancelled_at is null)
    or (status = 'cancelled' and completed_at is null and cancelled_at is not null)
  )
);

create index loans_entity_status_created_idx
  on catalog.loans (entity_id, status, created_at desc);

create index loans_borrower_entity_idx
  on catalog.loans (borrower_user_id, entity_id);

create table catalog.loan_lines (
  loan_id uuid not null references catalog.loans (id) on delete restrict,
  unit_id uuid not null references catalog.equipment_units (id) on delete restrict,
  released_at timestamptz,
  primary key (loan_id, unit_id)
);

create unique index loan_lines_open_unit_key
  on catalog.loan_lines (unit_id)
  where released_at is null;

create table catalog.loan_documents (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references catalog.loans (id) on delete restrict,
  document_model_id uuid not null
    references catalog.document_models (id) on delete restrict,
  version integer not null check (version >= 1),
  storage_path text not null unique check (
    storage_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9]{1,4}\.pdf$'
  ),
  content_hash text not null check (content_hash ~ '^[0-9a-f]{64}$'),
  is_current boolean not null default true,
  created_by_user_id uuid not null references auth.users (id) on delete restrict,
  created_at timestamptz not null default clock_timestamp(),
  unique (loan_id, version)
);

create unique index loan_documents_one_current_key
  on catalog.loan_documents (loan_id)
  where is_current;

create table catalog.loan_event_audit (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid not null references auth.users (id) on delete restrict,
  entity_id uuid not null references catalog.entities (id) on delete restrict,
  loan_id uuid not null references catalog.loans (id) on delete restrict,
  action text not null check (
    action in (
      'loan_draft_created',
      'loan_term_generated',
      'loan_completed',
      'loan_draft_cancelled'
    )
  ),
  previous_status catalog.loan_status,
  new_status catalog.loan_status not null,
  unit_ids uuid[] not null default '{}',
  document_model_version integer,
  content_hash text,
  due_date date,
  review_date date,
  created_at timestamptz not null default clock_timestamp(),
  constraint loan_event_audit_term_shape check (
    action <> 'loan_term_generated'
    or (document_model_version is not null and content_hash is not null)
  ),
  constraint loan_event_audit_cancel_shape check (
    action <> 'loan_draft_cancelled'
    or (previous_status = 'draft' and new_status = 'cancelled')
  )
);

create index loan_event_audit_loan_created_idx
  on catalog.loan_event_audit (loan_id, created_at);

alter table catalog.entities enable row level security;
alter table catalog.document_models enable row level security;
alter table catalog.document_models force row level security;
alter table catalog.loans enable row level security;
alter table catalog.loans force row level security;
alter table catalog.loan_lines enable row level security;
alter table catalog.loan_lines force row level security;
alter table catalog.loan_documents enable row level security;
alter table catalog.loan_documents force row level security;
alter table catalog.loan_event_audit enable row level security;
alter table catalog.loan_event_audit force row level security;

revoke all privileges on table catalog.document_models
  from public, anon, authenticated, service_role;
revoke all privileges on table catalog.loans
  from public, anon, authenticated, service_role;
revoke all privileges on table catalog.loan_lines
  from public, anon, authenticated, service_role;
revoke all privileges on table catalog.loan_documents
  from public, anon, authenticated, service_role;
revoke all privileges on table catalog.loan_event_audit
  from public, anon, authenticated, service_role;

create function catalog.normalize_person_name(p_value text)
returns text
language sql
immutable
set search_path = ''
as $function$
  select translate(
    lower(btrim(coalesce(p_value, ''))),
    'áàâãäéèêëíìîïóòôõöúùûüçñýÿ',
    'aaaaaeeeeiiiiooooouuuucnyy'
  )
$function$;

revoke all privileges on function catalog.normalize_person_name(text)
  from public, anon, authenticated, service_role;

create role admin_loan_manager nologin noinherit nobypassrls;
alter role admin_loan_manager inherit;
grant admin_bank_authorization_checker to admin_loan_manager;

grant usage on schema catalog to admin_loan_manager;
grant execute on function catalog.normalize_person_name(text)
  to admin_loan_manager;
grant execute on function catalog.current_auth_uid()
  to admin_loan_manager;
grant execute on function public.current_admin_bank_entity_id()
  to admin_loan_manager;

grant select (id, public_name, is_active, loan_suggested_days)
  on catalog.entities to admin_loan_manager;
grant select (code, name, is_active, display_order)
  on catalog.equipment_types to admin_loan_manager;
grant select (id, code, name)
  on catalog.storage_locations to admin_loan_manager;
grant select (
  id,
  equipment_type_code,
  owner_entity_id,
  storage_location_id,
  status,
  visible_code
) on catalog.equipment_units to admin_loan_manager;
grant update (status) on catalog.equipment_units to admin_loan_manager;
grant select (id, name, cpf, phone)
  on catalog.community_profiles to admin_loan_manager;
grant select (user_id, role, is_active)
  on catalog.user_roles to admin_loan_manager;
grant select (id, entity_id, document_type, version, body, review_status, is_active)
  on catalog.document_models to admin_loan_manager;
grant select, insert, update on catalog.loans to admin_loan_manager;
grant select, insert, update on catalog.loan_lines to admin_loan_manager;
grant select, insert, update on catalog.loan_documents to admin_loan_manager;
grant insert on catalog.loan_event_audit to admin_loan_manager;
grant insert (
  actor_user_id,
  entity_id,
  unit_id,
  action,
  previous_status,
  new_status,
  previous_storage_location_id,
  new_storage_location_id,
  previous_visible_code,
  new_visible_code,
  entry_origin
) on catalog.equipment_unit_change_audit to admin_loan_manager;

create policy "Loan manager reads its own bank entity"
  on catalog.entities
  for select
  to admin_loan_manager
  using (id = public.current_admin_bank_entity_id());

create policy "Loan manager reads equipment types"
  on catalog.equipment_types
  for select
  to admin_loan_manager
  using (true);

create policy "Loan manager reads storage locations"
  on catalog.storage_locations
  for select
  to admin_loan_manager
  using (true);

create policy "Loan manager reads units in its own bank"
  on catalog.equipment_units
  for select
  to admin_loan_manager
  using (owner_entity_id = public.current_admin_bank_entity_id());

create policy "Loan manager updates units in its own bank"
  on catalog.equipment_units
  for update
  to admin_loan_manager
  using (owner_entity_id = public.current_admin_bank_entity_id())
  with check (owner_entity_id = public.current_admin_bank_entity_id());

create policy "Loan manager reads active community profiles"
  on catalog.community_profiles
  for select
  to admin_loan_manager
  using (
    exists (
      select 1
      from catalog.user_roles as user_role
      where user_role.user_id = community_profiles.id
        and user_role.role = 'community'
        and user_role.is_active
    )
  );

create policy "Loan manager reads profiles of its own loans"
  on catalog.community_profiles
  for select
  to admin_loan_manager
  using (
    exists (
      select 1
      from catalog.loans as loan
      where loan.borrower_user_id = community_profiles.id
        and loan.entity_id = public.current_admin_bank_entity_id()
    )
  );

create policy "Loan manager reads community roles"
  on catalog.user_roles
  for select
  to admin_loan_manager
  using (role = 'community');

create policy "Loan manager reads its own bank models"
  on catalog.document_models
  for select
  to admin_loan_manager
  using (entity_id = public.current_admin_bank_entity_id());

create policy "Loan manager reads its own bank loans"
  on catalog.loans
  for select
  to admin_loan_manager
  using (entity_id = public.current_admin_bank_entity_id());

create policy "Loan manager inserts its own bank loans"
  on catalog.loans
  for insert
  to admin_loan_manager
  with check (entity_id = public.current_admin_bank_entity_id());

create policy "Loan manager updates its own bank loans"
  on catalog.loans
  for update
  to admin_loan_manager
  using (entity_id = public.current_admin_bank_entity_id())
  with check (entity_id = public.current_admin_bank_entity_id());

create policy "Loan manager reads its own bank loan lines"
  on catalog.loan_lines
  for select
  to admin_loan_manager
  using (
    exists (
      select 1
      from catalog.loans as loan
      where loan.id = loan_lines.loan_id
        and loan.entity_id = public.current_admin_bank_entity_id()
    )
  );

create policy "Loan manager inserts its own bank loan lines"
  on catalog.loan_lines
  for insert
  to admin_loan_manager
  with check (
    exists (
      select 1
      from catalog.loans as loan
      where loan.id = loan_lines.loan_id
        and loan.entity_id = public.current_admin_bank_entity_id()
    )
    and exists (
      select 1
      from catalog.equipment_units as unit
      where unit.id = loan_lines.unit_id
        and unit.owner_entity_id = public.current_admin_bank_entity_id()
    )
  );

create policy "Loan manager updates its own bank loan lines"
  on catalog.loan_lines
  for update
  to admin_loan_manager
  using (
    exists (
      select 1
      from catalog.loans as loan
      where loan.id = loan_lines.loan_id
        and loan.entity_id = public.current_admin_bank_entity_id()
    )
  )
  with check (
    exists (
      select 1
      from catalog.loans as loan
      where loan.id = loan_lines.loan_id
        and loan.entity_id = public.current_admin_bank_entity_id()
    )
  );

create policy "Loan manager reads its own bank loan documents"
  on catalog.loan_documents
  for select
  to admin_loan_manager
  using (
    exists (
      select 1
      from catalog.loans as loan
      where loan.id = loan_documents.loan_id
        and loan.entity_id = public.current_admin_bank_entity_id()
    )
  );

create policy "Loan manager inserts its own bank loan documents"
  on catalog.loan_documents
  for insert
  to admin_loan_manager
  with check (
    exists (
      select 1
      from catalog.loans as loan
      where loan.id = loan_documents.loan_id
        and loan.entity_id = public.current_admin_bank_entity_id()
    )
    and exists (
      select 1
      from catalog.document_models as model
      where model.id = loan_documents.document_model_id
        and model.entity_id = public.current_admin_bank_entity_id()
    )
  );

create policy "Loan manager updates its own bank loan documents"
  on catalog.loan_documents
  for update
  to admin_loan_manager
  using (
    exists (
      select 1
      from catalog.loans as loan
      where loan.id = loan_documents.loan_id
        and loan.entity_id = public.current_admin_bank_entity_id()
    )
  )
  with check (
    exists (
      select 1
      from catalog.loans as loan
      where loan.id = loan_documents.loan_id
        and loan.entity_id = public.current_admin_bank_entity_id()
    )
  );

create policy "Loan manager inserts its own bank loan audit"
  on catalog.loan_event_audit
  for insert
  to admin_loan_manager
  with check (
    actor_user_id = catalog.current_auth_uid()
    and entity_id = public.current_admin_bank_entity_id()
    and exists (
      select 1
      from catalog.loans as loan
      where loan.id = loan_event_audit.loan_id
        and loan.entity_id = loan_event_audit.entity_id
    )
  );

create policy "Loan manager inserts its own unit audit"
  on catalog.equipment_unit_change_audit
  for insert
  to admin_loan_manager
  with check (
    actor_user_id = catalog.current_auth_uid()
    and entity_id = public.current_admin_bank_entity_id()
    and action = 'unit_updated'
    and exists (
      select 1
      from catalog.equipment_units as unit
      where unit.id = equipment_unit_change_audit.unit_id
        and unit.owner_entity_id = equipment_unit_change_audit.entity_id
    )
  );

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('loan-terms', 'loan-terms', false, 5242880, array['application/pdf'])
on conflict (id) do nothing;

insert into catalog.document_models (
  entity_id,
  document_type,
  version,
  body,
  review_status,
  is_active
)
select
  entity.id,
  'loan_term',
  1,
  $body$TERMO DE EMPRÉSTIMO DE EQUIPAMENTO

{bank_name}, neste ato cedente, entrega em empréstimo ao responsável abaixo identificado os equipamentos relacionados neste termo, para uso próprio ou de paciente informado, comprometendo-se o responsável a devolvê-los nas condições recebidas e nas datas aqui registradas.

RESPONSÁVEL
Nome: {borrower_name}
CPF: {borrower_cpf}

PACIENTE
{patient_name}

DATAS
Entrega: {delivery_date}
Devolução prevista: {due_date}
Revisão: {review_date}

EQUIPAMENTOS E ESTADO NA ENTREGA
{equipment_list}

ANOTAÇÃO DE ESTADO
{condition_note}

Código do empréstimo: {public_code}

O responsável declara ter recebido os equipamentos em bom estado de conservação e assume a responsabilidade pela guarda e devolução. Este texto é um modelo provisório do banco e está pendente de revisão jurídica.

Assinatura do responsável: ______________________________

Assinatura do representante do banco: ______________________________$body$,
  'pending_legal_review',
  true
from catalog.entities as entity
on conflict (entity_id, document_type, version) do nothing;

grant admin_loan_manager to current_user with set true;
grant usage, create on schema public to admin_loan_manager;
set role admin_loan_manager;

create function public.admin_search_people(p_query text)
returns table (
  user_id uuid,
  full_name text,
  masked_cpf text,
  masked_phone text,
  open_loan_count integer,
  has_more boolean
)
language plpgsql
stable
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_entity_id uuid := public.current_admin_bank_entity_id();
  v_text text := btrim(coalesce(p_query, ''));
  v_digits text;
  v_digits_only boolean;
begin
  if v_entity_id is null then
    raise exception 'Empréstimo indisponível' using errcode = '42501';
  end if;

  v_digits := regexp_replace(v_text, '[^0-9]', '', 'g');
  v_digits_only := v_text <> ''
    and v_text ~ '^[0-9()./ -]+$';

  if v_text = '' then
    raise exception 'Busca inválida' using errcode = 'P0002';
  end if;

  if v_digits_only then
    if char_length(v_digits) <> 11 then
      raise exception 'Busca inválida' using errcode = 'P0002';
    end if;
  elsif char_length(v_text) < 3 then
    raise exception 'Busca inválida' using errcode = 'P0002';
  end if;

  return query
  with matches as (
    select
      profile.id,
      profile.name,
      profile.cpf,
      profile.phone
    from catalog.community_profiles as profile
    join catalog.user_roles as user_role
      on user_role.user_id = profile.id
      and user_role.role = 'community'
      and user_role.is_active
    where case
      when v_digits_only then profile.cpf = v_digits
      else catalog.normalize_person_name(profile.name)
        like '%' || catalog.normalize_person_name(v_text) || '%'
    end
  ),
  ordered as (
    select matches.*
    from matches
    order by matches.name, matches.id
    limit 11
  )
  select
    ordered.id,
    ordered.name,
    '***.***.***-' || right(ordered.cpf, 2),
    '(' || substring(ordered.phone from 4 for 2) || ') *****-'
      || right(ordered.phone, 4),
    (
      select count(*)::integer
      from catalog.loans as loan
      where loan.borrower_user_id = ordered.id
        and loan.entity_id = v_entity_id
        and loan.status in ('draft', 'active')
    ),
    (select count(*) from ordered) > 10
  from ordered
  order by ordered.name, ordered.id
  limit 10;
end
$function$;

create function public.admin_loan_available_units()
returns table (
  bank_name text,
  suggested_days integer,
  unit_id uuid,
  equipment_type_code text,
  equipment_type_name text,
  visible_code text,
  storage_location_name text
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
    entity.loan_suggested_days,
    unit.id,
    unit.equipment_type_code,
    equipment_type.name,
    unit.visible_code,
    location.name
  from catalog.entities as entity
  join catalog.equipment_units as unit
    on unit.owner_entity_id = entity.id
    and unit.status = 'available'
  join catalog.equipment_types as equipment_type
    on equipment_type.code = unit.equipment_type_code
  left join catalog.storage_locations as location
    on location.id = unit.storage_location_id
  where entity.id = v_entity_id
  order by
    equipment_type.display_order nulls last,
    unit.visible_code nulls last,
    unit.visible_code,
    unit.id;
end
$function$;

create function public.admin_create_loan_draft(
  p_borrower_user_id uuid,
  p_unit_ids uuid[],
  p_patient_name text,
  p_condition_note text,
  p_due_kind text,
  p_custom_days integer,
  p_review_days integer
)
returns table (
  public_code text,
  delivery_date date,
  due_date date,
  review_date date
)
language plpgsql
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_actor_id uuid := catalog.current_auth_uid();
  v_entity_id uuid := public.current_admin_bank_entity_id();
  v_entity_active boolean;
  v_suggested_days integer;
  v_delivery_date date;
  v_due_date date;
  v_review_date date;
  v_patient_name text;
  v_condition_note text;
  v_unit_ids uuid[];
  v_requested integer;
  v_found integer;
  v_unavailable integer;
  v_type_name text;
  v_visible_code text;
  v_loan_id uuid;
  v_public_code text;
  v_existing_id uuid;
begin
  if v_actor_id is null or v_entity_id is null then
    raise exception 'Empréstimo indisponível' using errcode = '42501';
  end if;

  select entity.is_active, entity.loan_suggested_days
  into v_entity_active, v_suggested_days
  from catalog.entities as entity
  where entity.id = v_entity_id;

  if v_entity_active is distinct from true then
    raise exception 'Este banco não está recebendo novos empréstimos.'
      using errcode = '42501';
  end if;

  if p_borrower_user_id is null or not exists (
    select 1
    from catalog.community_profiles as profile
    join catalog.user_roles as user_role
      on user_role.user_id = profile.id
      and user_role.role = 'community'
      and user_role.is_active
    where profile.id = p_borrower_user_id
  ) then
    raise exception 'Pessoa inválida' using errcode = 'P0002';
  end if;

  if p_due_kind is null or p_due_kind not in ('suggested', 'custom', 'no_due_date') then
    raise exception 'Prazo inválido' using errcode = 'P0002';
  end if;

  v_patient_name := nullif(btrim(coalesce(p_patient_name, '')), '');
  v_condition_note := nullif(btrim(coalesce(p_condition_note, '')), '');

  if v_patient_name is not null
    and char_length(v_patient_name) not between 2 and 120
  then
    raise exception 'Paciente inválido' using errcode = 'P0002';
  end if;

  if v_condition_note is not null and char_length(v_condition_note) > 200 then
    raise exception 'Anotação inválida' using errcode = 'P0002';
  end if;

  if p_unit_ids is null or array_position(p_unit_ids, null) is not null then
    raise exception 'Equipamentos inválidos' using errcode = 'P0002';
  end if;

  v_unit_ids := array(
    select distinct unit_value
    from unnest(p_unit_ids) as unit_value
    order by unit_value
  );
  v_requested := coalesce(array_length(p_unit_ids, 1), 0);

  if v_requested < 1
    or v_requested > 50
    or array_length(v_unit_ids, 1) <> v_requested
  then
    raise exception 'Equipamentos inválidos' using errcode = 'P0002';
  end if;

  v_delivery_date := (now() at time zone 'America/Sao_Paulo')::date;

  if p_due_kind = 'custom' then
    if p_custom_days is null or p_custom_days not between 1 and 365 then
      raise exception 'Prazo inválido' using errcode = 'P0002';
    end if;
    v_due_date := v_delivery_date + p_custom_days;
    v_review_date := null;
  elsif p_due_kind = 'suggested' then
    v_due_date := v_delivery_date + v_suggested_days;
    v_review_date := null;
  else
    if p_review_days is null or p_review_days not between 1 and 365 then
      raise exception 'Revisão inválida' using errcode = 'P0002';
    end if;
    v_due_date := null;
    v_review_date := v_delivery_date + p_review_days;
  end if;

  select loan.id
  into v_existing_id
  from catalog.loans as loan
  where loan.entity_id = v_entity_id
    and loan.status = 'draft'
    and loan.borrower_user_id = p_borrower_user_id
    and loan.due_date is not distinct from v_due_date
    and loan.review_date is not distinct from v_review_date
    and loan.patient_name is not distinct from v_patient_name
    and loan.condition_note is not distinct from v_condition_note
    and (
      select array_agg(line.unit_id order by line.unit_id)
      from catalog.loan_lines as line
      where line.loan_id = loan.id
        and line.released_at is null
    ) = v_unit_ids
  order by loan.created_at desc
  limit 1;

  if v_existing_id is not null then
    return query
    select loan.public_code, loan.delivery_date, loan.due_date, loan.review_date
    from catalog.loans as loan
    where loan.id = v_existing_id;
    return;
  end if;

  perform unit.id
  from catalog.equipment_units as unit
  where unit.owner_entity_id = v_entity_id
    and unit.id = any(v_unit_ids)
  order by unit.id
  for update;

  select count(*)
  into v_found
  from catalog.equipment_units as unit
  where unit.owner_entity_id = v_entity_id
    and unit.id = any(v_unit_ids);

  if v_found <> v_requested then
    raise exception 'Equipamentos inválidos' using errcode = 'P0002';
  end if;

  select count(*)
  into v_unavailable
  from catalog.equipment_units as unit
  where unit.owner_entity_id = v_entity_id
    and unit.id = any(v_unit_ids)
    and unit.status <> 'available';

  if v_unavailable > 0 then
    select equipment_type.name, unit.visible_code
    into v_type_name, v_visible_code
    from catalog.equipment_units as unit
    join catalog.equipment_types as equipment_type
      on equipment_type.code = unit.equipment_type_code
    where unit.owner_entity_id = v_entity_id
      and unit.id = any(v_unit_ids)
      and unit.status <> 'available'
    order by unit.id
    limit 1;

    raise exception
      'O equipamento % % não está mais disponível. Atualize a lista e escolha outro.',
      v_type_name,
      coalesce(v_visible_code, 'sem número')
      using errcode = 'P0003';
  end if;

  select equipment_type.name, unit.visible_code
  into v_type_name, v_visible_code
  from catalog.loan_lines as line
  join catalog.equipment_units as unit on unit.id = line.unit_id
  join catalog.equipment_types as equipment_type
    on equipment_type.code = unit.equipment_type_code
  where line.unit_id = any(v_unit_ids)
    and line.released_at is null
  order by unit.id
  limit 1;

  if found then
    raise exception
      'O equipamento % % não está mais disponível. Atualize a lista e escolha outro.',
      v_type_name,
      coalesce(v_visible_code, 'sem número')
      using errcode = 'P0003';
  end if;

  v_public_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));

  insert into catalog.loans (
    id,
    public_code,
    entity_id,
    borrower_user_id,
    patient_name,
    condition_note,
    delivery_date,
    due_date,
    review_date,
    status,
    created_by_user_id
  )
  values (
    gen_random_uuid(),
    v_public_code,
    v_entity_id,
    p_borrower_user_id,
    v_patient_name,
    v_condition_note,
    v_delivery_date,
    v_due_date,
    v_review_date,
    'draft',
    v_actor_id
  )
  returning id into v_loan_id;

  insert into catalog.loan_lines (loan_id, unit_id)
  select v_loan_id, unit_value
  from unnest(v_unit_ids) as unit_value;

  update catalog.equipment_units as unit
  set status = 'reserved'
  where unit.owner_entity_id = v_entity_id
    and unit.id = any(v_unit_ids)
    and unit.status = 'available';

  insert into catalog.loan_event_audit (
    actor_user_id,
    entity_id,
    loan_id,
    action,
    previous_status,
    new_status,
    unit_ids,
    due_date,
    review_date
  )
  values (
    v_actor_id,
    v_entity_id,
    v_loan_id,
    'loan_draft_created',
    null,
    'draft',
    v_unit_ids,
    v_due_date,
    v_review_date
  );

  return query
  select v_public_code, v_delivery_date, v_due_date, v_review_date;
exception
  when unique_violation then
    raise exception
      'Um dos equipamentos escolhidos não está mais disponível. Atualize a lista e escolha outro.'
      using errcode = 'P0003';
end
$function$;

create function public.admin_bank_loans()
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
  from catalog.loans as loan
  join catalog.entities as entity on entity.id = loan.entity_id
  join catalog.community_profiles as profile
    on profile.id = loan.borrower_user_id
  left join catalog.loan_lines as line
    on line.loan_id = loan.id
    and line.released_at is null
  where loan.entity_id = v_entity_id
    and loan.status = 'draft'
  group by loan.id, entity.public_name, profile.name
  order by loan.created_at desc, loan.id;
end
$function$;

create function public.admin_loan_detail(p_public_code text)
returns table (
  bank_name text,
  public_code text,
  status text,
  borrower_name text,
  masked_cpf text,
  masked_phone text,
  patient_name text,
  condition_note text,
  delivery_date date,
  due_date date,
  review_date date,
  created_at timestamptz,
  completed_at timestamptz,
  term_version integer,
  term_generated_at timestamptz,
  units jsonb
)
language plpgsql
stable
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_entity_id uuid := public.current_admin_bank_entity_id();
  v_loan_id uuid;
begin
  if v_entity_id is null then
    raise exception 'Empréstimo indisponível' using errcode = '42501';
  end if;

  if p_public_code is null or p_public_code !~ '^[A-F0-9]{12}$' then
    raise exception 'Empréstimo não encontrado' using errcode = 'P0005';
  end if;

  select loan.id
  into v_loan_id
  from catalog.loans as loan
  where loan.entity_id = v_entity_id
    and loan.public_code = p_public_code;

  if v_loan_id is null then
    raise exception 'Empréstimo não encontrado' using errcode = 'P0005';
  end if;

  return query
  select
    entity.public_name,
    loan.public_code,
    loan.status::text,
    profile.name,
    '***.***.***-' || right(profile.cpf, 2),
    '(' || substring(profile.phone from 4 for 2) || ') *****-'
      || right(profile.phone, 4),
    loan.patient_name,
    loan.condition_note,
    loan.delivery_date,
    loan.due_date,
    loan.review_date,
    loan.created_at,
    loan.completed_at,
    document.version,
    document.created_at,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'unit_id', unit.id,
            'type_name', equipment_type.name,
            'visible_code', unit.visible_code,
            'storage_location_name', location.name
          )
          order by equipment_type.display_order nulls last, unit.visible_code, unit.id
        )
        from catalog.loan_lines as line
        join catalog.equipment_units as unit on unit.id = line.unit_id
        join catalog.equipment_types as equipment_type
          on equipment_type.code = unit.equipment_type_code
        left join catalog.storage_locations as location
          on location.id = unit.storage_location_id
        where line.loan_id = loan.id
      ),
      '[]'::jsonb
    )
  from catalog.loans as loan
  join catalog.entities as entity on entity.id = loan.entity_id
  join catalog.community_profiles as profile
    on profile.id = loan.borrower_user_id
  left join catalog.loan_documents as document
    on document.loan_id = loan.id
    and document.is_current
  where loan.id = v_loan_id;
end
$function$;

create function public.admin_loan_term_data(p_public_code text)
returns table (
  bank_name text,
  public_code text,
  borrower_name text,
  borrower_cpf text,
  patient_name text,
  condition_note text,
  delivery_date date,
  due_date date,
  review_date date,
  units jsonb,
  model_version integer,
  model_body text,
  model_review_status text,
  next_version integer,
  next_storage_path text
)
language plpgsql
stable
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_entity_id uuid := public.current_admin_bank_entity_id();
  v_loan_id uuid;
  v_next_version integer;
begin
  if v_entity_id is null then
    raise exception 'Empréstimo indisponível' using errcode = '42501';
  end if;

  if p_public_code is null or p_public_code !~ '^[A-F0-9]{12}$' then
    raise exception 'Empréstimo não encontrado' using errcode = 'P0005';
  end if;

  select loan.id
  into v_loan_id
  from catalog.loans as loan
  where loan.entity_id = v_entity_id
    and loan.public_code = p_public_code;

  if v_loan_id is null then
    raise exception 'Empréstimo não encontrado' using errcode = 'P0005';
  end if;

  if not exists (
    select 1
    from catalog.loans as loan
    where loan.id = v_loan_id
      and loan.status = 'draft'
  ) then
    raise exception 'Empréstimo já concluído' using errcode = 'P0003';
  end if;

  if not exists (
    select 1
    from catalog.document_models as model
    where model.entity_id = v_entity_id
      and model.document_type = 'loan_term'
      and model.is_active
  ) then
    raise exception 'Este banco ainda não tem um modelo de termo ativo.'
      using errcode = 'P0003';
  end if;

  select coalesce(max(document.version), 0) + 1
  into v_next_version
  from catalog.loan_documents as document
  where document.loan_id = v_loan_id;

  return query
  select
    entity.public_name,
    loan.public_code,
    profile.name,
    profile.cpf,
    loan.patient_name,
    loan.condition_note,
    loan.delivery_date,
    loan.due_date,
    loan.review_date,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'unit_id', unit.id,
            'type_name', equipment_type.name,
            'visible_code', unit.visible_code,
            'storage_location_name', location.name
          )
          order by equipment_type.display_order nulls last, unit.visible_code, unit.id
        )
        from catalog.loan_lines as line
        join catalog.equipment_units as unit on unit.id = line.unit_id
        join catalog.equipment_types as equipment_type
          on equipment_type.code = unit.equipment_type_code
        left join catalog.storage_locations as location
          on location.id = unit.storage_location_id
        where line.loan_id = loan.id
          and line.released_at is null
      ),
      '[]'::jsonb
    ),
    model.version,
    model.body,
    model.review_status::text,
    v_next_version,
    v_entity_id::text || '/' || v_loan_id::text || '/'
      || v_next_version::text || '.pdf'
  from catalog.loans as loan
  join catalog.entities as entity on entity.id = loan.entity_id
  join catalog.community_profiles as profile
    on profile.id = loan.borrower_user_id
  join catalog.document_models as model
    on model.entity_id = loan.entity_id
    and model.document_type = 'loan_term'
    and model.is_active
  where loan.id = v_loan_id;
end
$function$;

create function public.admin_record_loan_term(
  p_public_code text,
  p_model_version integer,
  p_storage_path text,
  p_content_hash text
)
returns integer
language plpgsql
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_actor_id uuid := catalog.current_auth_uid();
  v_entity_id uuid := public.current_admin_bank_entity_id();
  v_loan catalog.loans;
  v_model_id uuid;
  v_next_version integer;
  v_current_id uuid;
  v_current_hash text;
  v_expected_path text;
begin
  if v_actor_id is null or v_entity_id is null then
    raise exception 'Empréstimo indisponível' using errcode = '42501';
  end if;

  if p_public_code is null or p_public_code !~ '^[A-F0-9]{12}$' then
    raise exception 'Empréstimo não encontrado' using errcode = 'P0005';
  end if;

  if p_content_hash is null or p_content_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'Arquivo inválido' using errcode = 'P0002';
  end if;

  select *
  into v_loan
  from catalog.loans as loan
  where loan.entity_id = v_entity_id
    and loan.public_code = p_public_code
  for update;

  if not found then
    raise exception 'Empréstimo não encontrado' using errcode = 'P0005';
  end if;

  if v_loan.status <> 'draft' then
    raise exception 'Empréstimo já concluído' using errcode = 'P0003';
  end if;

  select model.id
  into v_model_id
  from catalog.document_models as model
  where model.entity_id = v_entity_id
    and model.document_type = 'loan_term'
    and model.is_active
    and model.version = p_model_version;

  if v_model_id is null then
    raise exception 'Modelo de termo inválido' using errcode = 'P0002';
  end if;

  select document.id, document.content_hash
  into v_current_id, v_current_hash
  from catalog.loan_documents as document
  where document.loan_id = v_loan.id
    and document.is_current;

  if v_current_id is not null
    and v_current_hash = p_content_hash
    and exists (
      select 1
      from catalog.loan_documents as document
      where document.id = v_current_id
        and document.document_model_id = v_model_id
    )
  then
    select document.version
    into v_next_version
    from catalog.loan_documents as document
    where document.id = v_current_id;
    return v_next_version;
  end if;

  select coalesce(max(document.version), 0) + 1
  into v_next_version
  from catalog.loan_documents as document
  where document.loan_id = v_loan.id;

  v_expected_path := v_entity_id::text || '/' || v_loan.id::text || '/'
    || v_next_version::text || '.pdf';

  if p_storage_path is distinct from v_expected_path then
    raise exception 'Arquivo inválido' using errcode = 'P0002';
  end if;

  update catalog.loan_documents as document
  set is_current = false
  where document.loan_id = v_loan.id
    and document.is_current;

  insert into catalog.loan_documents (
    loan_id,
    document_model_id,
    version,
    storage_path,
    content_hash,
    is_current,
    created_by_user_id
  )
  values (
    v_loan.id,
    v_model_id,
    v_next_version,
    p_storage_path,
    p_content_hash,
    true,
    v_actor_id
  );

  insert into catalog.loan_event_audit (
    actor_user_id,
    entity_id,
    loan_id,
    action,
    previous_status,
    new_status,
    unit_ids,
    document_model_version,
    content_hash,
    due_date,
    review_date
  )
  values (
    v_actor_id,
    v_entity_id,
    v_loan.id,
    'loan_term_generated',
    'draft',
    'draft',
    coalesce(
      (
        select array_agg(line.unit_id order by line.unit_id)
        from catalog.loan_lines as line
        where line.loan_id = v_loan.id
          and line.released_at is null
      ),
      '{}'::uuid[]
    ),
    p_model_version,
    p_content_hash,
    v_loan.due_date,
    v_loan.review_date
  );

  return v_next_version;
end
$function$;

create function public.admin_loan_term_file(p_public_code text)
returns text
language plpgsql
stable
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_entity_id uuid := public.current_admin_bank_entity_id();
  v_storage_path text;
begin
  if v_entity_id is null then
    raise exception 'Empréstimo indisponível' using errcode = '42501';
  end if;

  if p_public_code is null or p_public_code !~ '^[A-F0-9]{12}$' then
    raise exception 'Empréstimo não encontrado' using errcode = 'P0005';
  end if;

  select document.storage_path
  into v_storage_path
  from catalog.loans as loan
  join catalog.loan_documents as document
    on document.loan_id = loan.id
    and document.is_current
  where loan.entity_id = v_entity_id
    and loan.public_code = p_public_code;

  if v_storage_path is null then
    raise exception 'Empréstimo não encontrado' using errcode = 'P0005';
  end if;

  return v_storage_path;
end
$function$;

create function public.admin_complete_loan(p_public_code text)
returns table (status text, completed_at timestamptz)
language plpgsql
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_actor_id uuid := catalog.current_auth_uid();
  v_entity_id uuid := public.current_admin_bank_entity_id();
  v_loan catalog.loans;
  v_unit_ids uuid[];
  v_held integer;
  v_reserved integer;
  v_completed_at timestamptz := clock_timestamp();
begin
  if v_actor_id is null or v_entity_id is null then
    raise exception 'Empréstimo indisponível' using errcode = '42501';
  end if;

  if p_public_code is null or p_public_code !~ '^[A-F0-9]{12}$' then
    raise exception 'Empréstimo não encontrado' using errcode = 'P0005';
  end if;

  select *
  into v_loan
  from catalog.loans as loan
  where loan.entity_id = v_entity_id
    and loan.public_code = p_public_code
  for update;

  if not found then
    raise exception 'Empréstimo não encontrado' using errcode = 'P0005';
  end if;

  if v_loan.status <> 'draft' then
    raise exception 'Empréstimo já concluído' using errcode = 'P0003';
  end if;

  if not exists (
    select 1
    from catalog.loan_documents as document
    where document.loan_id = v_loan.id
      and document.is_current
  ) then
    raise exception 'Gere o termo antes de concluir a saída.'
      using errcode = 'P0002';
  end if;

  select array_agg(line.unit_id order by line.unit_id)
  into v_unit_ids
  from catalog.loan_lines as line
  where line.loan_id = v_loan.id
    and line.released_at is null;

  if v_unit_ids is null then
    raise exception 'Empréstimo sem equipamentos' using errcode = 'P0002';
  end if;

  perform unit.id
  from catalog.equipment_units as unit
  where unit.owner_entity_id = v_entity_id
    and unit.id = any(v_unit_ids)
  order by unit.id
  for update;

  select count(*), count(*) filter (where unit.status = 'reserved')
  into v_held, v_reserved
  from catalog.equipment_units as unit
  where unit.owner_entity_id = v_entity_id
    and unit.id = any(v_unit_ids);

  if v_held <> array_length(v_unit_ids, 1)
    or v_reserved <> array_length(v_unit_ids, 1)
  then
    raise exception
      'A situação de um equipamento mudou. Confira o acervo antes de concluir.'
      using errcode = 'P0003';
  end if;

  update catalog.loans as loan
  set status = 'active', completed_at = v_completed_at
  where loan.id = v_loan.id;

  update catalog.equipment_units as unit
  set status = 'on_loan'
  where unit.owner_entity_id = v_entity_id
    and unit.id = any(v_unit_ids)
    and unit.status = 'reserved';

  insert into catalog.equipment_unit_change_audit (
    actor_user_id,
    entity_id,
    unit_id,
    action,
    previous_status,
    new_status,
    previous_storage_location_id,
    new_storage_location_id,
    previous_visible_code,
    new_visible_code,
    entry_origin
  )
  select
    v_actor_id,
    v_entity_id,
    unit.id,
    'unit_updated',
    'reserved',
    'on_loan',
    unit.storage_location_id,
    unit.storage_location_id,
    unit.visible_code,
    unit.visible_code,
    null
  from catalog.equipment_units as unit
  where unit.owner_entity_id = v_entity_id
    and unit.id = any(v_unit_ids);

  insert into catalog.loan_event_audit (
    actor_user_id,
    entity_id,
    loan_id,
    action,
    previous_status,
    new_status,
    unit_ids,
    due_date,
    review_date
  )
  values (
    v_actor_id,
    v_entity_id,
    v_loan.id,
    'loan_completed',
    'draft',
    'active',
    v_unit_ids,
    v_loan.due_date,
    v_loan.review_date
  );

  return query select 'active'::text, v_completed_at;
end
$function$;

create function public.admin_cancel_loan_draft(p_public_code text)
returns text
language plpgsql
security definer
set search_path = ''
set row_security = on
as $function$
declare
  v_actor_id uuid := catalog.current_auth_uid();
  v_entity_id uuid := public.current_admin_bank_entity_id();
  v_loan catalog.loans;
  v_unit_ids uuid[];
  v_cancelled_at timestamptz := clock_timestamp();
begin
  if v_actor_id is null or v_entity_id is null then
    raise exception 'Empréstimo indisponível' using errcode = '42501';
  end if;

  if p_public_code is null or p_public_code !~ '^[A-F0-9]{12}$' then
    raise exception 'Empréstimo não encontrado' using errcode = 'P0005';
  end if;

  select *
  into v_loan
  from catalog.loans as loan
  where loan.entity_id = v_entity_id
    and loan.public_code = p_public_code
  for update;

  if not found then
    raise exception 'Empréstimo não encontrado' using errcode = 'P0005';
  end if;

  if v_loan.status <> 'draft' then
    raise exception 'Empréstimo já concluído' using errcode = 'P0003';
  end if;

  with released as (
    update catalog.loan_lines as line
    set released_at = v_cancelled_at
    where line.loan_id = v_loan.id
      and line.released_at is null
    returning line.unit_id
  )
  select array_agg(released.unit_id order by released.unit_id)
  into v_unit_ids
  from released;

  update catalog.equipment_units as unit
  set status = 'available'
  where unit.owner_entity_id = v_entity_id
    and unit.id = any(coalesce(v_unit_ids, '{}'::uuid[]))
    and unit.status = 'reserved';

  update catalog.loans as loan
  set status = 'cancelled', cancelled_at = v_cancelled_at
  where loan.id = v_loan.id;

  insert into catalog.loan_event_audit (
    actor_user_id,
    entity_id,
    loan_id,
    action,
    previous_status,
    new_status,
    unit_ids,
    due_date,
    review_date
  )
  values (
    v_actor_id,
    v_entity_id,
    v_loan.id,
    'loan_draft_cancelled',
    'draft',
    'cancelled',
    coalesce(v_unit_ids, '{}'::uuid[]),
    v_loan.due_date,
    v_loan.review_date
  );

  return 'cancelled';
end
$function$;

reset role;

alter function public.admin_search_people(text) owner to admin_loan_manager;
alter function public.admin_loan_available_units() owner to admin_loan_manager;
alter function public.admin_create_loan_draft(uuid, uuid[], text, text, text, integer, integer)
  owner to admin_loan_manager;
alter function public.admin_bank_loans() owner to admin_loan_manager;
alter function public.admin_loan_detail(text) owner to admin_loan_manager;
alter function public.admin_loan_term_data(text) owner to admin_loan_manager;
alter function public.admin_record_loan_term(text, integer, text, text)
  owner to admin_loan_manager;
alter function public.admin_loan_term_file(text) owner to admin_loan_manager;
alter function public.admin_complete_loan(text) owner to admin_loan_manager;
alter function public.admin_cancel_loan_draft(text) owner to admin_loan_manager;

revoke all privileges on function public.admin_search_people(text)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.admin_loan_available_units()
  from public, anon, authenticated, service_role;
revoke all privileges on function public.admin_create_loan_draft(uuid, uuid[], text, text, text, integer, integer)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.admin_bank_loans()
  from public, anon, authenticated, service_role;
revoke all privileges on function public.admin_loan_detail(text)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.admin_loan_term_data(text)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.admin_record_loan_term(text, integer, text, text)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.admin_loan_term_file(text)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.admin_complete_loan(text)
  from public, anon, authenticated, service_role;
revoke all privileges on function public.admin_cancel_loan_draft(text)
  from public, anon, authenticated, service_role;

grant execute on function public.admin_search_people(text) to authenticated;
grant execute on function public.admin_loan_available_units() to authenticated;
grant execute on function public.admin_create_loan_draft(uuid, uuid[], text, text, text, integer, integer)
  to authenticated;
grant execute on function public.admin_bank_loans() to authenticated;
grant execute on function public.admin_loan_detail(text) to authenticated;
grant execute on function public.admin_loan_term_data(text) to authenticated;
grant execute on function public.admin_record_loan_term(text, integer, text, text)
  to authenticated;
grant execute on function public.admin_loan_term_file(text) to authenticated;
grant execute on function public.admin_complete_loan(text) to authenticated;
grant execute on function public.admin_cancel_loan_draft(text) to authenticated;

revoke create on schema public from admin_loan_manager;
revoke admin_loan_manager from current_user;
