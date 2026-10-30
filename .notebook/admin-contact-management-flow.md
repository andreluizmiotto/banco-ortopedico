# Administrative Contact Management Flow
> Entity-scoped contact lookup and a single auditable situation change

Entry: `src/app/admin/contatos/page.tsx:AdminContactsData()` →
`src/lib/contacts/admin-server.ts:getAdminContactsPageData()` →
`src/lib/auth/admin-bank.ts:resolveAdminBankAccess()`.

Read: `public.admin_bank_contacts(text)` derives the bank from the active
`bank_admin` session and returns its canonical public name, contact code,
situation, and the `overdue_48h` boolean. PostgreSQL computes the 48-hour
threshold from `created_at`; neither the timestamp nor another contact field
reaches the browser. Search accepts only `^[A-F0-9]{12}$`.

Change: `src/app/admin/contatos/actions.ts:setAdminContactSituationAction()` →
`src/lib/contacts/admin-server.ts:changeAdminContactSituation()` →
`public.admin_set_contact_status(text,text)`. The database locks the contact,
allows one transition from `new`, updates only `status`, and writes one audit
row in the same transaction. Repeating the same target is idempotent;
`converted_to_loan` does not create a loan.

Database: `supabase/migrations/20261022000000_admin_contacts.sql`,
`20261025000000_admin_contact_manager_checker_membership.sql`, and
`20261026000000_admin_contact_highlight_dto.sql` and
`20261027000000_admin_contact_highlight_boundary.sql` —
`admin_contact_manager` is `NOLOGIN NOBYPASSRLS` and inherits the existing
`admin_bank_authorization_checker` for the session-derived entity resolver;
policies still scope rows to that active link. The audit table stores actor,
action, entity, internal contact id, previous/new situation, and timestamp
without personal fields. `catalog` remains outside exposed API schemas.

Updated: 2026-10-22
