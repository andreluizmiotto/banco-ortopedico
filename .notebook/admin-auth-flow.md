# Administrative Auth Flow
> Supabase email/password entry, scoped by one active `admin_banco` entity

Entry: `src/app/admin/entrar/actions.ts:signInAdminAction()` → `signInWithPassword()` → `getAdminBankContext()` → fixed redirect `/admin/contatos`.

Authorization: `src/lib/auth/admin-bank.ts:getAdminBankContext()` calls `auth.getUser()` then `public.current_admin_bank_entity_id()`; returns only the linked entity UUID. `requireAdminBankContext()` is called by the protected destination per request.

Database: `supabase/migrations/20261015000000_autenticacao_administrativa.sql` — partial unique index for active `admin_banco`; no-argument RPC owned by `admin_bank_authorization_checker` (`NOLOGIN NOBYPASSRLS`), using `catalog.current_auth_uid()` and RLS.

Session refresh: `src/proxy.ts` includes `/admin/:path*`; Proxy refreshes cookies only and does not grant authorization. The contacts screen revalidates through the same trusted bank context; see [admin-contact-management-flow](admin-contact-management-flow.md).

Fixture: `supabase/seed.sql` — local-only synthetic Auth identity and one role linked to `SYN-ROTARY-BOA-VISTA`; set `auth.users.instance_id` to the zero UUID explicitly. GoTrue's `FindUserByEmailAndAudience()` filters by `instance_id = uuid.Nil`; omitting it leaves `NULL`, so Auth reports generic invalid credentials. Seed `confirmation_token`, `recovery_token`, `email_change_token_new`, and `email_change` as empty strings, not `NULL`, or GoTrue can fail scanning the user. Reapplying the seed via local database reset is destructive to local data; use a targeted repair when preserving local state.

Updated: 2026-10-22
