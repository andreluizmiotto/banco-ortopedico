# Catalogo publico de tipos ativos

Sources:

- `.tasks/catalogo-publico-tipos-ativos.md` - intent, four criteria, boundary and unresolved inventory-model decision
- `docs/README.md` - documentation index and executable migrations/tests as implementation
- `docs/produto/requisitos.md` - FR-001 public list of active equipment types
- `docs/produto/regras-de-negocio.md` - approved initial types, inactive `PE`, and priority order
- `docs/produto/criterios-de-aceite.md` - synthetic-data evidence and catalog ordering
- `docs/arquitetura/modelo-conceitual.md` - global type distinct from physical inventory
- `docs/arquitetura/autenticacao-e-autorizacao.md` - public role access and database authorization
- `docs/arquitetura/visao-geral.md` - Supabase boundaries and migration/test organization
- `docs/arquitetura/decisoes/0001-nextjs-supabase.md` - PostgreSQL/RLS as the authorization boundary
- `docs/privacidade/requisitos-de-dados.md` - public-data classification and prohibition on personal data in public responses
- `supabase/config.toml` - exposed schemas and enabled migration/seed paths
- `AGENTS.md`, `package.json`, `src/app/page.tsx` - stack constraints, installed dependencies, and unchanged scaffold
- [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security) - grants and RLS must be combined; safe invoker views and pgTAP
- [Supabase Securing your API](https://supabase.com/docs/guides/api/securing-your-api) - explicit grants for exposed Data API objects
- [Supabase Testing your database](https://supabase.com/docs/guides/database/testing) - `supabase test db` execution contract

## Out of scope

- Availability by entity, inventory, equipment units/lots, loans, contacts, locations, or personal data - depend on the unresolved physical inventory model or later tasks.
- Public UI, Next.js/Supabase client integration, search, photos, descriptions, and custom error handling - the scaffold and application remain unchanged.
- Authentication/profile setup, CRUD administration, new dependencies, Supabase config changes, product-document changes, telemetry, and offline fallback - none is needed for the read-only catalog boundary.
- Any decision about the unresolved count-versus-individual inventory representation - this change creates no inventory relation.

## Landing

Reuse the configured Supabase Data API, migration/seed flow, and PostgreSQL RLS; add no application client, route, or dependency. The only exposed catalog resource is a read-only view over a non-exposed backing schema.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Public catalog Data API contract | `catalog.equipment_types(code, name, is_active, display_order)` with active-row RLS for `anon` and `authenticated`; `public.equipment_types` is a `security_invoker` view returning only `code`, `name`, and `display_order`, ordered by `display_order, code`. Both relations grant those roles only `SELECT`; the backing `catalog` schema remains outside the configured exposed schemas. | A directly exposed table that relies on callers to supply `order` cannot guarantee the required priority when the query omits it; a default owner-privilege view bypasses base-table RLS. |

- Nothing else in this change is hard to reverse.

## Checks

### S1 - Consulta publica de tipos ativos - 4 arquivos - 13,600 bytes / 4 = 3,400 tokens

**C1 (task criterion 1)** - After local reset and seed, an unauthenticated Data API read returns exactly the 13 approved active names and never returns inactive `PE`.
Proof: `npm exec --yes --package=supabase@2.120.0 -- supabase db reset`, then `npm exec --yes --package=supabase@2.120.0 -- node scripts/test-public-catalog-api.mjs` (`PASS C1`); `npm exec --yes --package=supabase@2.120.0 -- supabase test db` runs the active catalog/`PE` assertions in `supabase/tests/catalogo-publico.test.sql`.

**C2 (task criterion 2)** - The Data API response starts with `Cadeira de rodas`, `Cama hospitalar`, `Cadeira de banho`, `Andador`, `Muletas`, in that order; all returned rows follow their configured `display_order`, without fixing the relative order of the remaining eight names.
Proof: `npm exec --yes --package=supabase@2.120.0 -- node scripts/test-public-catalog-api.mjs` (`PASS C2`) checks the response order and strictly increasing `display_order`; `npm exec --yes --package=supabase@2.120.0 -- supabase test db` runs the pgTAP assertion for the configured first five positions.

**C3 (task criterion 3)** - The backing table has RLS that limits both API roles to active rows, grants only `SELECT` on the table and view, and the direct Data API response contains only the public catalog fields for both roles.
Proof: `npm exec --yes --package=supabase@2.120.0 -- supabase test db` runs the named RLS, `security_invoker`, role-grant, and active-row assertions in `supabase/tests/catalogo-publico.test.sql`; `npm exec --yes --package=supabase@2.120.0 -- node scripts/test-public-catalog-api.mjs` (`PASS C3`) reads the view as `anon` and `authenticated` and checks its exact response fields.

**C4 (task criterion 4)** - Direct Data API `POST`, `PATCH`, and `DELETE` attempts are rejected for both `anon` and `authenticated`, and each attempt leaves the catalog unchanged.
Proof: `npm exec --yes --package=supabase@2.120.0 -- node scripts/test-public-catalog-api.mjs` (`PASS C4`) exercises all six role/method pairs and compares the catalog after each; `npm exec --yes --package=supabase@2.120.0 -- supabase test db` checks that both roles have no write grants.

## Swept

- validation: C1 fixes the exact 13 active names and excludes inactive `PE`.
- failure modes: native Data API errors remain unchanged; this recut adds no client or custom error handler.
- idempotency and retry: reads have no side effects; no write or retry mechanism is introduced.
- authorization: C3 and C4 prove database RLS and minimum grants, including direct Data API calls.
- concurrency and ordering: concurrent writes are out of scope; C2 proves the configured ordering and fixed priority prefix.
- data lifecycle: C1 keeps `PE` inactive and out of public reads; no personal, inventory, or loan data is created.
- external-dependency failure: no application client or offline fallback is built; no offline behavior is specified.
- state transitions: activation/deactivation administration is out of scope; the seed establishes initial states only.
- observability: tests are the evidence; no analytics or personal-data logging is added.

## Handoff

- Profile is `light`; handoff is `on`.
- S1 is the entire database/Data API slice. Its four files total 13,600 bytes; at 4 bytes/token that is 3,400 tokens, well below the 150k batch budget, so no build handoff is needed.
