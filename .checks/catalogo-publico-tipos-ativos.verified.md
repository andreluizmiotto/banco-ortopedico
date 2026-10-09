# Catalogo publico de tipos ativos Verification

**Verdict**: PASS
**Profile**: light (no explicit TLC profile in `AGENTS.md`; light is the default)
**Diff range**: 16c9976..ecc8ca1 (HEAD: ecc8ca103caa04c95d57d1224b67d81922d7ac3b)
**Round**: 1 - full
**Verifier**: independent verifier (author != verifier)

## Binding sources

Interface binding-source comparison is not applicable under `light`: this is database/API-only work with no interface binding source.

## Checks

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | Anonymous read returns exactly the 13 approved active names and omits `PE`. | `supabase db reset` -> `supabase test db` -> `node scripts/test-public-catalog-api.mjs`; all completed successfully in the batched invocation. | `scripts/test-public-catalog-api.mjs:4-18,77-86` - `assert.equal(rows.length, expectedNames.length, ...)`; `assert.deepEqual(rows.map(({ name }) => name).sort(), [...expectedNames].sort(), ...)`; `assert.equal(rows.some(({ code }) => code === 'PE'), false, ...)`. `supabase/tests/catalogo-publico.test.sql:5-33` - pgTAP `is` compares `array_agg(code \|\| '=' \|\| name ...)` for `is_active` rows with the literal 13-item code/name array; the following `is((select is_active ... code = 'PE'), false, ...)` asserts `PE` is inactive. | PASS |
| C2 | Data API response has the required first five names and strictly follows increasing `display_order`. | `supabase test db` and `node scripts/test-public-catalog-api.mjs`; both completed successfully in the batched invocation. | `scripts/test-public-catalog-api.mjs:20-26,96-105` - `assert.deepEqual(rows.slice(0, priorityNames.length).map(({ name }) => name), priorityNames, ...)`; `assert.ok(rows.every((row, index) => index === 0 \|\| rows[index - 1].display_order < row.display_order), ...)`. `supabase/tests/catalogo-publico.test.sql:35-54` - pgTAP `is` compares the first five active names ordered by `display_order, code` with the five required literals. | PASS |
| C3 | RLS limits both API roles to active rows; only `SELECT` is granted on table/view; both roles receive only public fields. | `supabase test db` and `node scripts/test-public-catalog-api.mjs`; both completed successfully in the batched invocation. | `supabase/tests/catalogo-publico.test.sql:56-95` - `ok(relrowsecurity)`; `ok(reloptions @> array['security_invoker=true'])`; for anon/authenticated on both relations, `ok(has_table_privilege(..., 'SELECT') and not has_table_privilege(..., 'INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'))`. Active-row counts are asserted for anon at `supabase/tests/catalogo-publico.test.sql:100-109` and authenticated at `supabase/tests/catalogo-publico.test.sql:164-173`. `supabase/config.toml:11-15` exposes only `public` and `graphql_public`. `scripts/test-public-catalog-api.mjs:88-95,161-174` - `rows.every(row => Object.keys(row).sort().join(',') === 'code,display_order,name' && Number.isInteger(row.display_order))`; `assertCatalog` runs for both responses and `assert.deepEqual(authenticatedRows, anonymousRows, ...)`. | PASS |
| C4 | Data API `POST`, `PATCH`, and `DELETE` are rejected for both roles and leave the catalog unchanged. | `supabase test db` and `node scripts/test-public-catalog-api.mjs`; both completed successfully in the batched invocation. | `scripts/test-public-catalog-api.mjs:176-207` - `writeAttempts` enumerates `POST`, `PATCH`, `DELETE`; nested loops cover `anon` and `authenticated`; `assert.ok(response.status >= 400 && response.status < 500, ...)`; `assert.deepEqual(rowsAfterAttempt, anonymousRows, ...)`. The SQL suite also asserts no write grants for either role on either relation at `supabase/tests/catalogo-publico.test.sql:74-95` and rejected write statements under both roles at `supabase/tests/catalogo-publico.test.sql:112-159,176-224`. | PASS |

## Test execution

The following single chained invocation ran at `HEAD` and exited 0:

```sh
npm exec --yes --package=supabase@2.120.0 -- supabase db reset && npm exec --yes --package=supabase@2.120.0 -- supabase test db && npm exec --yes --package=supabase@2.120.0 -- node scripts/test-public-catalog-api.mjs
```

- Reset applied migration `20261009000000_catalogo_publico_tipos.sql` and `supabase/seed.sql` successfully.
- `supabase/tests/catalogo-publico.test.sql` exists and ran: `.. ok`; runner reported `Files=1, Tests=27`, `Result: PASS`. Its `plan(27)` is at `supabase/tests/catalogo-publico.test.sql:3`.
- The API proof exists and emitted `PASS C1`, `PASS C2`, `PASS C3`, and `PASS C4`; corresponding assertions and calls are cited above.

## Profile steps

- Coverage join: not applicable under `light`; the checklist has no `Coverage` section or set rows.
- Test policy: not applicable under `light`; the checklist has no `Test policy` section.
- Fault injection: not performed; it is not required under `light`.

## Swept

| Row | Verification | Result |
|---|---|---|
| validation | C1 checks the exact active-name set and excludes `PE` (`scripts/test-public-catalog-api.mjs:77-86`; `supabase/tests/catalogo-publico.test.sql:5-33`). | PASS |
| failure modes | The diff adds no application client or custom error handler; native Data API behavior remains outside this read-only database boundary. | PASS |
| idempotency and retry | No product write or retry path is introduced; public reads are read-only and C4 rejects writes. | PASS |
| authorization | Migration enables RLS and defines `using (is_active)` for both roles (`supabase/migrations/20261009000000_catalogo_publico_tipos.sql:13-23`); tests verify role visibility and minimum grants. | PASS |
| concurrency and ordering | The fixed priority prefix and increasing returned `display_order` are asserted for C2; concurrent writes remain out of scope. | PASS |
| data lifecycle | Seed contains the 13 active types and inactive `PE` (`supabase/seed.sql:3-16`); no personal, inventory, or loan data is added. | PASS |
| external-dependency failure | No application client or offline fallback is added; no offline behavior is specified. | PASS |
| state transitions | No activation/deactivation administration is added; the seed establishes initial states only. | PASS |
| observability | No analytics or personal-data logging is added; the API script logs only proof pass messages (`scripts/test-public-catalog-api.mjs:163-210`). | PASS |

## Gaps

None found. All four checks have located assertions, all requested proofs passed, and no level or sampling gaps were identified.

## Gate

`supabase db reset` - passed; `supabase test db` - 27 passed, 0 failed; API proof - C1-C4 passed; chained command exit 0.
