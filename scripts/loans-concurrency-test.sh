#!/usr/bin/env bash
# C23: two concurrent drafts for the same unit. Exactly one must succeed and the
# other must be refused with the 409 conflict, leaving one loan and one line.
#
# pgTAP runs as a non-superuser role, so dblink cannot open a second session from
# inside the test. This script drives two real psql sessions against the local
# database instead, and the exit code is the proof.
set -euo pipefail

if [[ "${1:-}" == "--only" && "${2:-}" != "C23" ]]; then
  echo "this script only proves C23" >&2
  exit 2
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

project_id="$(sed -n 's/^project_id *= *"\(.*\)"/\1/p' supabase/config.toml)"
container="supabase_db_${project_id}"

psql_run() {
  docker exec -i "$container" psql "postgresql://postgres:postgres@127.0.0.1:5432/postgres" "$@"
}

entity_id="c9000000-0000-4000-8000-000000000001"
location_id="c9000000-0000-4000-8000-000000000002"
admin_id="c9000000-0000-4000-8000-000000000003"
person_id="c9000000-0000-4000-8000-000000000004"
unit_id="c9000000-0000-4000-8000-000000000005"

cleanup() {
  psql_run -v ON_ERROR_STOP=0 -q <<SQL >/dev/null 2>&1
delete from catalog.loan_event_audit where entity_id = '$entity_id';
delete from catalog.loan_documents where loan_id in (
  select id from catalog.loans where entity_id = '$entity_id'
);
delete from catalog.loan_lines where loan_id in (
  select id from catalog.loans where entity_id = '$entity_id'
);
delete from catalog.loans where entity_id = '$entity_id';
delete from catalog.equipment_unit_change_audit where entity_id = '$entity_id';
delete from catalog.equipment_units where owner_entity_id = '$entity_id';
delete from catalog.document_models where entity_id = '$entity_id';
delete from catalog.user_roles where entity_id = '$entity_id';
delete from catalog.storage_locations where id = '$location_id';
delete from catalog.community_profiles where id = '$person_id';
delete from auth.users where id in ('$admin_id', '$person_id');
delete from catalog.entities where id = '$entity_id';
SQL
}

trap cleanup EXIT

cleanup

psql_run -v ON_ERROR_STOP=1 -q <<SQL
insert into catalog.equipment_types (code, name, is_active, display_order)
values ('CR', 'Cadeira de rodas', true, 1)
on conflict (code) do nothing;

insert into catalog.entities (id, code, public_name, is_bank, is_active, loan_suggested_days)
values ('$entity_id', 'RACE', 'Banco Corrida Sintetica', true, true, 90);

insert into catalog.storage_locations (id, code, name)
values ('$location_id', 'RACE-L1', 'Sede do banco');

insert into auth.users (
  id, aud, role, email, email_confirmed_at, encrypted_password,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  ('$admin_id', 'authenticated', 'authenticated', 'corrida.admin@example.test',
   clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb,
   '{}'::jsonb, clock_timestamp(), clock_timestamp()),
  ('$person_id', 'authenticated', 'authenticated', 'corrida.pessoa@example.test',
   clock_timestamp(), '', '{"provider":"email","providers":["email"]}'::jsonb,
   '{}'::jsonb, clock_timestamp(), clock_timestamp());

insert into catalog.community_profiles (id, name, cpf, phone, privacy_notice_version)
values ('$person_id', 'Nadia Correa', '13579246800', '+5554999990123', 'v1');

insert into catalog.user_roles (user_id, role, entity_id, is_active)
values ('$admin_id', 'bank_admin', '$entity_id', true);

insert into catalog.user_roles (user_id, role, entity_id, is_active)
values ('$person_id', 'community', null, true);

insert into catalog.equipment_units (
  id, equipment_type_code, owner_entity_id, storage_location_id, status, visible_code
)
values ('$unit_id', 'CR', '$entity_id', '$location_id', 'available', 'RACE-0001');
SQL

call_rpc="begin;
set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claim.sub', '$admin_id', true);
select public_code from public.admin_create_loan_draft(
  '$person_id'::uuid,
  array['$unit_id']::uuid[],
  null,
  null,
  'custom',
  30,
  null
);"

workdir="$(mktemp -d)"
first_out="$workdir/first.out"
first_err="$workdir/first.err"
second_out="$workdir/second.out"
second_err="$workdir/second.err"

printf '%s\n\\! sleep 3\ncommit;\n' "$call_rpc" > "$workdir/first.sql"
printf '\\set VERBOSITY verbose\n%s\ncommit;\n' "$call_rpc" > "$workdir/second.sql"

docker exec -i "$container" psql "postgresql://postgres:postgres@127.0.0.1:5432/postgres" \
  -v ON_ERROR_STOP=1 -At -f - < "$workdir/first.sql" > "$first_out" 2> "$first_err" &
first_pid=$!

sleep 1

docker exec -i "$container" psql "postgresql://postgres:postgres@127.0.0.1:5432/postgres" \
  -v ON_ERROR_STOP=1 -At -f - < "$workdir/second.sql" > "$second_out" 2> "$second_err" &
second_pid=$!

set +e
wait "$first_pid"
first_status=$?
wait "$second_pid"
second_status=$?
set -e

fail() {
  echo "C23 FAIL: $1" >&2
  echo "--- first session ---" >&2
  cat "$first_out" "$first_err" >&2
  echo "--- second session ---" >&2
  cat "$second_out" "$second_err" >&2
  exit 1
}

[[ $first_status -eq 0 ]] || fail "the first draft did not succeed"
grep -Eq '^[A-F0-9]{12}$' "$first_out" || fail "the first draft returned no public code"
[[ $second_status -ne 0 ]] || fail "the second draft was accepted"
grep -q 'P0003' "$second_err" || fail "the second draft failed without the conflict code"

loans="$(psql_run -tAc "select count(*) from catalog.loans where entity_id = '$entity_id'")"
lines="$(psql_run -tAc "select count(*) from catalog.loan_lines line join catalog.loans loan on loan.id = line.loan_id where loan.entity_id = '$entity_id'")"
reserved="$(psql_run -tAc "select count(*) from catalog.equipment_units where id = '$unit_id' and status = 'reserved'")"

[[ "$loans" == "1" ]] || fail "expected one loan, found $loans"
[[ "$lines" == "1" ]] || fail "expected one line, found $lines"
[[ "$reserved" == "1" ]] || fail "expected the unit reserved, found $reserved"

echo "C23 ok: one draft accepted, the concurrent one refused with 409"
