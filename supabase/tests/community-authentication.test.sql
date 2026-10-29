begin;

select plan(33);

select ok(
  (select relrowsecurity from pg_class where oid = 'catalog.community_profiles'::regclass),
  'C14 profile table enables RLS'
);
select ok(
  (select relforcerowsecurity from pg_class where oid = 'catalog.community_profiles'::regclass),
  'C14 profile table forces RLS'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'catalog.user_roles'::regclass),
  'C14 role table enables RLS'
);
select ok(
  (select relforcerowsecurity from pg_class where oid = 'catalog.user_roles'::regclass),
  'C14 role table forces RLS'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'catalog.community_login_limits'::regclass),
  'C14 login-limit table enables RLS'
);
select ok(
  (select relforcerowsecurity from pg_class where oid = 'catalog.community_login_limits'::regclass),
  'C14 login-limit table forces RLS'
);

select ok(
  not has_table_privilege('anon', 'catalog.community_profiles', 'SELECT'),
  'C14 anon cannot select CPF profiles directly'
);
select ok(
  not has_table_privilege('authenticated', 'catalog.community_profiles', 'SELECT'),
  'C14 authenticated users cannot select CPF profiles directly'
);
select ok(
  not has_table_privilege('service_role', 'catalog.community_profiles', 'SELECT'),
  'C14 service_role cannot read profile rows outside the restricted function'
);
select ok(
  not has_table_privilege('anon', 'catalog.user_roles', 'SELECT'),
  'C14 anon cannot select role assignments directly'
);
select ok(
  not has_table_privilege('authenticated', 'catalog.user_roles', 'SELECT'),
  'C14 authenticated users cannot select role assignments directly'
);
select ok(
  not has_table_privilege('anon', 'catalog.community_login_limits', 'SELECT')
    and not has_table_privilege('anon', 'catalog.community_login_limits', 'INSERT')
    and not has_table_privilege('anon', 'catalog.community_login_limits', 'UPDATE'),
  'C14 anon cannot read or modify login-limit records'
);
select ok(
  not has_table_privilege('authenticated', 'catalog.community_login_limits', 'SELECT')
    and not has_table_privilege('authenticated', 'catalog.community_login_limits', 'INSERT')
    and not has_table_privilege('authenticated', 'catalog.community_login_limits', 'UPDATE'),
  'C14 authenticated users cannot read or modify login-limit records'
);
select ok(
  not has_table_privilege('service_role', 'catalog.community_login_limits', 'SELECT'),
  'C14 service_role cannot read login-limit records directly'
);

select ok(
  exists (
    select 1
    from pg_constraint
    where conrelid = 'catalog.community_profiles'::regclass
      and conname = 'community_profiles_cpf_unique'
      and contype = 'u'
  ),
  'C3 normalized CPF has a unique database constraint'
);
select ok(
  exists (
    select 1
    from pg_constraint
    where conrelid = 'catalog.community_profiles'::regclass
      and confrelid = 'auth.users'::regclass
      and contype = 'f'
  ),
  'C3 community profile is linked to auth.users'
);
select ok(
  (
    select count(*) = 3
    from information_schema.columns
    where table_schema = 'catalog'
      and table_name = 'community_profiles'
      and column_name in ('phone', 'privacy_notice_version', 'privacy_notice_accepted_at')
  )
    and not exists (
      select 1
      from information_schema.columns
      where table_schema = 'catalog'
        and table_name = 'community_profiles'
        and column_name in ('password', 'password_hash')
    ),
  'C3 profile records its verified phone and accepted notice without storing credentials'
);

select ok(
  (
    select not rolsuper and not rolbypassrls and not rolcanlogin
    from pg_roles
    where rolname = 'community_identity_lookup'
  ),
  'C14 CPF lookup function owner cannot bypass RLS or log in'
);
select ok(
  (
    select not rolsuper and not rolbypassrls and not rolcanlogin
    from pg_roles
    where rolname = 'community_profile_provisioner'
  ),
  'C14 profile provisioner cannot bypass RLS or log in'
);
select ok(
  (
    select not rolsuper and not rolbypassrls and not rolcanlogin
    from pg_roles
    where rolname = 'community_login_limiter'
  ),
  'C14 login limiter cannot bypass RLS or log in'
);
select ok(
  (
    select not rolsuper and not rolbypassrls and not rolcanlogin
    from pg_roles
    where rolname = 'community_authorization_checker'
  ),
  'C14 role checker cannot bypass RLS or log in'
);

select ok(
  not has_function_privilege('anon', 'public.community_phone_for_cpf(text)', 'EXECUTE'),
  'C14 anon cannot use CPF-to-phone lookup'
);
select ok(
  not has_function_privilege('authenticated', 'public.community_phone_for_cpf(text)', 'EXECUTE'),
  'C14 authenticated users cannot use CPF-to-phone lookup'
);
select ok(
  has_function_privilege('service_role', 'public.community_phone_for_cpf(text)', 'EXECUTE'),
  'C2 server service role can resolve the confirmed Auth phone'
);
select ok(
  has_function_privilege('service_role', 'public.complete_community_signup(uuid,text,text,text,text,boolean)', 'EXECUTE'),
  'C3 server service role can provision a confirmed community profile'
);
select ok(
  not has_function_privilege('anon', 'public.complete_community_signup(uuid,text,text,text,text,boolean)', 'EXECUTE')
    and not has_function_privilege('authenticated', 'public.complete_community_signup(uuid,text,text,text,text,boolean)', 'EXECUTE'),
  'C14 browsers cannot invoke profile provisioning directly'
);

select ok(
  has_function_privilege('service_role', 'public.is_community_login_locked(text)', 'EXECUTE')
    and has_function_privilege('service_role', 'public.record_community_login_failure(text)', 'EXECUTE')
    and has_function_privilege('service_role', 'public.clear_community_login_failures(text)', 'EXECUTE'),
  'C5 server can check, record, and clear the origin lock'
);
select ok(
  not has_function_privilege('anon', 'public.is_community_login_locked(text)', 'EXECUTE')
    and not has_function_privilege('anon', 'public.record_community_login_failure(text)', 'EXECUTE')
    and not has_function_privilege('anon', 'public.clear_community_login_failures(text)', 'EXECUTE'),
  'C14 anon cannot inspect or alter origin lock state'
);
select ok(
  not has_function_privilege('authenticated', 'public.is_community_login_locked(text)', 'EXECUTE')
    and not has_function_privilege('authenticated', 'public.record_community_login_failure(text)', 'EXECUTE')
    and not has_function_privilege('authenticated', 'public.clear_community_login_failures(text)', 'EXECUTE'),
  'C14 authenticated users cannot inspect or alter origin lock state'
);

select ok(
  has_function_privilege('authenticated', 'public.has_community_role()', 'EXECUTE'),
  'C8 authenticated server session can check its own community role'
);
select ok(
  (
    select prosecdef
      and pg_get_userbyid(proowner) = 'postgres'
      and proconfig @> array['search_path=""']::text[]
    from pg_proc
    where oid = 'catalog.current_auth_uid()'::regprocedure
  )
    and has_function_privilege(
      'community_authorization_checker',
      'catalog.current_auth_uid()',
      'EXECUTE'
    )
    and has_function_privilege(
      'community_contact_processor',
      'catalog.current_auth_uid()',
      'EXECUTE'
    )
    and not has_function_privilege(
      'anon',
      'catalog.current_auth_uid()',
      'EXECUTE'
    )
    and not has_function_privilege(
      'authenticated',
      'catalog.current_auth_uid()',
      'EXECUTE'
    )
    and not has_function_privilege(
      'service_role',
      'catalog.current_auth_uid()',
      'EXECUTE'
    ),
  'C14 subject wrapper is fixed-path and available only to restricted function roles'
);
select ok(
  not has_function_privilege('anon', 'public.has_community_role()', 'EXECUTE'),
  'C14 anon cannot query community authorization'
);
select is(
  pg_get_function_result('public.community_phone_for_cpf(text)'::regprocedure),
  'text',
  'C2 private CPF lookup returns one confirmed-phone value, not a profile row'
);

select * from finish();
rollback;
