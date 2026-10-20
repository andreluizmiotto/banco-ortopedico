# Administrative Auth Flow
> Supabase email/password entry, scoped by one active `admin_banco` entity

Entry: `src/app/admin/entrar/actions.ts:signInAdminAction()` → `signInWithPassword()` → `getAdminBankContext()` → fixed redirect `/admin/contatos`.

Authorization: `src/lib/auth/admin-bank.ts:getAdminBankContext()` calls `auth.getUser()` then `public.current_admin_bank_entity_id()`; returns only the linked entity UUID. `requireAdminBankContext()` is called by the protected destination per request.

Database: `supabase/migrations/20261015000000_autenticacao_administrativa.sql` — partial unique index for active `admin_banco`; no-argument RPC owned by `admin_bank_authorization_checker` (`NOLOGIN NOBYPASSRLS`), using `catalog.current_auth_uid()` and RLS.

Session refresh: `src/proxy.ts` includes `/admin/:path*`; Proxy refreshes cookies only and does not grant authorization. `/admin/contatos` remains an empty guarded route until FR-017/AC-007.

Fixture: `supabase/seed.sql` — local-only synthetic Auth identity and one role linked to `SYN-ROTARY-BOA-VISTA`.

Updated: 2026-10-20
