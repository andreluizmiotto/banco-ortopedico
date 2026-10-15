# Community Auth and Contact Flow
> Supabase phone/password identity, private CPF profile and role-gated contact links

Entry: `src/app/entrar/actions.ts:signInCommunityAction()`

Sign in: `src/lib/auth/identity.ts:normalizeCpf()` → service-only `public.community_phone_for_cpf(text)` → Supabase Auth `phone/password` → `public.has_community_role()` → sanitized detail redirect. Origin lock: `catalog.community_login_limits`, HMAC key from server-only service role secret.

Sign up: `startCommunitySignupAction()` creates phone/password user without metadata; `finishCommunitySignupAction()` verifies OTP, then service-only `public.complete_community_signup(...)` stores CPF, name, verified phone, role and notice acceptance in the private profile/domain tables.

Session: `src/lib/supabase/server.ts` writes HttpOnly SSR cookies; `src/proxy.ts` refreshes only `/entrar` and `/equipamentos/:path*`. Client props contain authorization/method only, never user or phone objects.

Contact: `src/app/_components/equipment-detail.tsx` resolves a method without a number; `src/lib/contacts/server.ts` calls `public.start_community_contact(...)`. The DB function binds `catalog.current_auth_uid()`, locks `(user, entity, type)`, reuses a 30-minute contact, and returns only the code/method/external URL.

RLS: private tables remain in unexposed `catalog`; restricted function roles are `NOBYPASSRLS`. `catalog.current_auth_uid()` wraps `auth.uid()` because the managed `auth` schema does not grant usage to custom function roles.

Updated: 2026-10-14
