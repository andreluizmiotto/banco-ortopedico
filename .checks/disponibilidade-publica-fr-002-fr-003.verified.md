# Disponibilidade publica e cartoes por banco Verification

**Verdict**: PASS
**Profile**: light (explicitly required for this verification)
**Diff range**: `574c730ded58061a1ee821fdb73b18f2984c82a8 + current worktree` (uncommitted; tracked changes reviewed with `git diff HEAD`, untracked feature files opened directly; no commit authorized)
**Round**: 2 - scoped
**Verifier**: independent verifier (author != verifier)

## Worktree

- **Round 2 scope, verified at current worktree `574c730ded58061a1ee821fdb73b18f2984c82a8` plus uncommitted changes:** reread the checklist, task, full tracked `git diff HEAD`, and all untracked feature files. The only Round 2 clarification is in `.checks/disponibilidade-publica-fr-002-fr-003.md:11,33,35-37`; no implementation file or C1-C10 criterion changed.
- `.opencode/` and `.tasks/` user-owned changes were left untouched. No code, test, task, or checklist files were edited by the verifier; only this verification report is being updated.
- A `Testing Strategy (Lean MVP)` addition in `AGENTS.md` conflicted with this task's Playwright proof. The user explicitly reconfirmed Playwright as a task-specific exception for Round 2; this conflict is resolved and is not a finding. The verifier did not edit `AGENTS.md`.
- No commit, push, or PR was created. Supabase commands used `--local`; the direct API script enforces loopback at `scripts/test-public-availability-api.mjs:36-40`, and Playwright uses synthetic local settings and intercepted API responses at `playwright.config.ts:15-25`.

## Binding sources (verified at current worktree `574c730ded58061a1ee821fdb73b18f2984c82a8` plus checklist clarification)

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.tasks/disponibilidade-publica-fr-002-fr-003.md` and `.checks/disponibilidade-publica-fr-002-fr-003.md` | yes | C1-C10's assertions retain the written values; the user's clarification changes no criterion | Round 1 G1 is resolved: the checklist now explicitly sets the task entry to the public list at `/` and defers the separate initial screen, FAQ and privacy flow (`.checks/disponibilidade-publica-fr-002-fr-003.md:11,33,35-37`). |
| `docs/ux/acessibilidade-e-fluxos.md` (binding public flow) | yes | List/detail sections 3.2-3.9 remain binding and the implemented zero card, visitor CTA, loading and recoverable error assertions agree with `:31-38,83-90` | Section 3.1's broader initial screen at `:30` is explicitly outside this task by the user's clarification recorded in the checklist at `:11,33,37`; G1 is resolved, not a finding. |
| `docs/produto/requisitos.md`, `docs/produto/regras-de-negocio.md`, `docs/produto/criterios-de-aceite.md`, `docs/arquitetura/modelo-conceitual.md` | yes | The tested aggregate, ownership-vs-location rule, zero card and minimal public response align with FR-002/003, AC-001/002/018 and the data model | none for the enumerated C1-C10 claims |
| `docs/arquitetura/autenticacao-e-autorizacao.md`, `docs/privacidade/requisitos-de-dados.md`, `AGENTS.md` | yes | Direct operational-table reads are denied and the public function exposes the aggregate only, matching the public/authenticated privacy boundary | none for C1-C10; the Testing Strategy conflict was resolved by the explicit task authorization above |
| `.tasks/catalogo-publico-tipos-ativos.md`, `.checks/catalogo-publico-tipos-ativos.verified.md`, both catalog SQL files, `scripts/test-public-catalog-api.mjs`, `supabase/config.toml`, `package.json`, current migration/seed and `src/app/page.tsx` | yes | Existing public catalog schema and seed are preserved; the availability migration adds a separate aggregate contract | none for C1-C10 |
| Local Next 16.4 docs named in the checklist, `node_modules/@supabase/ssr/README.md`, `next.config.ts`, and the Playwright CLI/web-server docs | yes | The current async route params, Suspense boundary, client-only interactivity, local web server and Cache Components configuration are consistent with the opened version-specific docs | none |

## Checks (all proofs verified at current worktree `574c730ded58061a1ee821fdb73b18f2984c82a8`; full rerun)

| Check | Claim | Proof run and result | Evidence | Result |
|---|---|---|---|---|
| C1 | A=3 and B=2, counting only `disponivel` (the chosen DB equivalent of product `em_casa`) despite the other five situations | Round 2 `npm exec --yes --package=supabase@2.120.0 -- supabase test db supabase/tests/disponibilidade-publica.test.sql --local` - exit 0, 27/27; full SQL regression rerun - exit 0, 54/54 | `supabase/tests/disponibilidade-publica.test.sql:38-67` - `is(array_agg(status::text order by ordinal), array['disponivel','reservado','emprestado','manutencao','doado','baixado']::text[], ...)` and `results_eq(... values ('Entidade Sintética A'::text, 3), ('Entidade Sintética B'::text, 2) ...)`; `supabase/migrations/20261013000000_disponibilidade_publica.sql:88-90` - `count(*) filter (where equipment_unit.situacao = 'disponivel'::catalog.equipment_situation)::integer` | PASS |
| C2 | Moving only an A unit's shared storage location leaves ownership and aggregate quantities unchanged | Round 2 targeted SQL proof - exit 0, 27/27; full SQL regression rerun - exit 0, 54/54 | `supabase/tests/disponibilidade-publica.test.sql:83-117` - the update sets only `storage_location_id` and `is(..., 'SYN-A:SYN-SHARED', ...)`; `:119-130` - `results_eq(... values ('Entidade Sintética A'::text, 3), ('Entidade Sintética B'::text, 2) ...)` after the update | PASS |
| C3 | Anonymous RPC rows contain exactly public bank name and integer quantity, with no type/unit/situation/contact fields | Round 2 `npm exec --yes --package=supabase@2.120.0 -- node scripts/test-public-availability-api.mjs` - exit 0; printed `PASS C3` | `scripts/test-public-availability-api.mjs:63-88` - `Object.keys(row).sort().join(',') === 'available_quantity,bank_name'`, `typeof row.bank_name === 'string'`, `Number.isInteger(row.available_quantity)`, and `assert.deepEqual(..., {'Entidade Sintética A': 3, 'Entidade Sintética B': 2, 'Entidade Sintética C': 0}, ...)`; `:151-155` calls it with `anonToken` | PASS |
| C4 | `anon` and synthetic `authenticated` cannot read operational/personal resources directly; both can execute only the authorized aggregate contract | Round 2 targeted SQL proof - exit 0, 27/27; API script rerun - exit 0 and printed `PASS C4`; full SQL regression - exit 0, 54/54 | `supabase/tests/disponibilidade-publica.test.sql:181-199` - `not has_table_privilege(..., 'SELECT')` for both roles and `has_function_privilege(..., 'EXECUTE')`; `:237-274` uses `throws_ok(..., '42501', ...)` on direct reads as anon/authenticated; `scripts/test-public-availability-api.mjs:128-149,157-182` asserts every private-resource request is 4xx, rejects personal/contact text in its body, and loops over anon and authenticated tokens | PASS |
| C5 | Zero-quantity bank remains visible with exact empty text and quantity 0 | Round 2 Playwright invocation - named C5 test passed; overall 6/6 passed | `tests/disponibilidade-publica.spec.ts:125-134` - `getByText('Entidade Sintética C', { exact: true }).toBeVisible()`, `getByText('Todos emprestados no momento', { exact: true }).toBeVisible()`, and `getByLabel('Quantidade disponível: 0').toBeVisible()` | PASS |
| C6 | Two controlled random values produce different positive-bank permutations, with zero bank last | Round 2 Playwright invocation - named C6 test passed; overall 6/6 passed | `tests/disponibilidade-publica.spec.ts:137-150` - `expect(reversed.map(...)).toEqual(['Entidade Sintética B','Entidade Sintética A','Entidade Sintética C'])` and `expect(unchanged.map(...)).toEqual(['Entidade Sintética A','Entidade Sintética B','Entidade Sintética C'])` | PASS |
| C7 | Zero card keeps `Entrar para conversar` at `/entrar`, without direct contact URL/phone; `/entrar` route is absent | Round 2 Playwright invocation - named C7 test passed; `Glob src/app/entrar/**` returned no files; build route table also has no `/entrar` | `tests/disponibilidade-publica.spec.ts:160-168` - link `.toBeVisible()`, `.toHaveAttribute('href', '/entrar')`, `locator('a[href*="wa.me"], a[href^="tel:"]').toHaveCount(0)`, and `getByText(/\+?\d{8,}/).toHaveCount(0)` | PASS |
| C8 | At 360px list/detail meet width, text, title, CTA and palette thresholds; availability is textual | Round 2 Playwright invocation - named C8 test passed; overall 6/6 passed | `tests/disponibilidade-publica.spec.ts:68-113` - `documentWidth <= 360`, minimum copy `>=18`, heading `>=26`, action height `>=56`, font size `>=20`, weight `>=700`, and exact five-color array; `:179-187` asserts `Disponível no depósito` in both routes; `src/app/globals.css:7-11` defines the tested Rotary tokens | PASS |
| C9 | Pending RPC shows status role, loading text and indicator on list/detail | Round 2 Playwright invocation - named C9 test passed; overall 6/6 passed | `tests/disponibilidade-publica.spec.ts:190-210` - for both paths, `getByRole('status').toHaveText('Carregando a disponibilidade...')` and `locator('[data-loading-indicator]').toBeVisible()` | PASS |
| C10 | HTTP 503 shows recoverable exact error, never zero, then retry loads data | Round 2 Playwright invocation - named C10 test passed; overall 6/6 passed | `tests/disponibilidade-publica.spec.ts:225-256` returns `status: 503`, asserts exact alert text, `getByText('Todos emprestados no momento').toHaveCount(0)`, clicks `Tentar novamente`, asserts `Disponível no depósito`, and `expect(attempts).toBeGreaterThan(attemptsBeforeRetry)` | PASS |

## Commands and results (verified at current worktree `574c730ded58061a1ee821fdb73b18f2984c82a8`)

- `npm exec --yes --package=supabase@2.120.0 -- supabase db reset --local` - Round 2 PASS; both migrations and the configured seed applied locally.
- `npm exec --yes --package=supabase@2.120.0 -- supabase test db supabase/tests/disponibilidade-publica.test.sql --local` - Round 2 PASS; 1 file, 27 tests.
- `npm exec --yes --package=supabase@2.120.0 -- supabase test db --local` - Round 2 PASS; 2 files, 54 tests.
- `npm exec --yes --package=supabase@2.120.0 -- node scripts/test-public-availability-api.mjs` - Round 2 PASS C3 and PASS C4.
- `npm run test:e2e -- --grep "C5|C6|C7|C8|C9|C10" tests/disponibilidade-publica.spec.ts` - Round 2 PASS; output individually showed C5, C6, C7, C8, C9 and C10; 6 passed.
- `npm run build` - Round 2 PASS; TypeScript and production build succeeded. Route table lists `/`, `/_not-found`, and `/equipamentos/[code]`, not `/entrar`.
- `npm run lint` - Round 2 exit 0, 0 errors and the same 3 warnings in pre-existing `.opencode/skills/mermaid-studio/scripts/render.mjs:206` and `validate.mjs:103,279`; these files were not altered.
- `git diff --check HEAD --` - carried from Round 1 at worktree `574c730ded58061a1ee821fdb73b18f2984c82a8`; Round 2 introduced no tracked source changes.

## Boundary and synthetic data (carried from Round 1 at worktree `574c730ded58061a1ee821fdb73b18f2984c82a8`; files reopened and unchanged)

- Route absence: `Glob src/app/entrar/**` returned no files; the successful production build route table also excludes `/entrar`. The visitor link is nevertheless asserted as `href="/entrar"` in C7.
- Role boundary: `supabase/migrations/20261013000000_disponibilidade_publica.sql:48-58` revokes direct operational table grants and grants SELECT only to the restricted aggregate reader; `:78-80` declares exactly `(bank_name text, available_quantity integer)`; `:111-114` grants function execution to `anon` and `authenticated`. SQL and direct API assertions for both roles passed in C4.
- Contact/PII: content scans for `wa.me`, `tel:`, CPF/phone terms and phone-number patterns returned no hits in runtime `src` or migration/seed SQL; the no-phone and no-contact-link expressions in the C7 E2E assertion are cited above. API error-body checks reject CPF, phone, residential address and `wa.me` text (`scripts/test-public-availability-api.mjs:144-148`). Test source mentions these strings only as negative matchers.
- Synthetic data: the current availability migration is DDL only; search for `INSERT INTO`/`COPY` in it returned no matches. `supabase/seed.sql:1-21` retains the approved public catalog reference values; all added entities, shared point and unit rows are marked `SYN-*`/`SYN-SHARED` with fixed synthetic UUIDs at `:23-74`. The focused SQL test inserts `SYN-AVAIL-C1` and synthetic locations/entities at `supabase/tests/disponibilidade-publica.test.sql:5-36`. No real inventory, phone or personal record is used.

## Profile steps (carried from Round 1 at worktree `574c730ded58061a1ee821fdb73b18f2984c82a8`; profile unchanged)

- Coverage join: not applicable under `light`; the checklist has no Coverage section or set rows.
- Test policy: not applicable under `light`; the checklist has no Test policy section.
- Fault injection: not applicable under `light`; no faults were injected.
- Full UI-profile screen/arrangement enumeration: not required under `light`. The task clarification at `.checks/disponibilidade-publica-fr-002-fr-003.md:11,33,37` resolves the prior G1 scope question; no C1-C10 criterion changed.

## Swept (verified at current worktree `574c730ded58061a1ee821fdb73b18f2984c82a8`; proofs rerun)

| Row | Verification | Result |
|---|---|---|
| validation | C1 checks the six DB situations and A=3/B=2; C2 checks that changing only storage location preserves owner counts (`supabase/tests/disponibilidade-publica.test.sql:38-67,83-130`). | PASS |
| failure modes | C10 intercepts HTTP 503, displays a retry path and does not show a zero-availability card (`tests/disponibilidade-publica.spec.ts:225-256`). | PASS |
| idempotency and retry | Reads do not mutate inventory; C10 retries the RPC and asserts a later successful request, with no write path. | PASS |
| authorization | C3/C4 assert the minimal aggregate, deny direct operational reads for anon/authenticated, and constrain table grants/RLS (`scripts/test-public-availability-api.mjs:63-88,128-182`; SQL test `:133-232`). | PASS |
| concurrency | No writes or concurrent state changes are in this slice. | N/A - out of scope |
| ordering | C6 asserts two exact permutations and places the zero bank last (`tests/disponibilidade-publica.spec.ts:137-150`). | PASS |
| data lifecycle | Added entities, locations and units are synthetic; the real Phase 1 load remains outside this change. | PASS |
| external-dependency failure | C9 holds RPC requests pending and C10 returns a synthetic 503; both recoverable states pass. | PASS |
| state transitions | The aggregate is read-only and does not change equipment situations. | N/A - out of scope |
| observability | API proof prints only criterion-level PASS messages; no personal/contact payload is logged (`scripts/test-public-availability-api.mjs:151-182`). | PASS |

## Go-live gate (verified at current worktree `574c730ded58061a1ee821fdb73b18f2984c82a8`)

The Phase 1 authorized load/reconciliation gate remains open, as required: `.checks/disponibilidade-publica-fr-002-fr-003.md:88-90` is unchecked and `.tasks/disponibilidade-publica-fr-002-fr-003.md:127-131` leaves the N-versus-physical-count rule unresolved. Synthetic proofs do not close this production gate.

## Gaps (Round 1 disposition verified at current worktree `574c730ded58061a1ee821fdb73b18f2984c82a8`)

- **G1 from Round 1 - resolved by explicit user clarification, not a finding.** `.checks/disponibilidade-publica-fr-002-fr-003.md:11,33,35-37` declares the list at `/` as this task's entry and explicitly defers the separate initial screen, FAQ and privacy flow. The clarification leaves C1-C10 unchanged and keeps authentication/cadastro outside the slice; `/entrar` remains only the C7 CTA destination. No other concrete gaps were found in Round 2.

## Gate (verified at current worktree `574c730ded58061a1ee821fdb73b18f2984c82a8`)

Round 2 targeted SQL - 27 passed, 0 failed; complete SQL harness - 54 passed, 0 failed; direct API - C3/C4 passed; Playwright - 6 passed, 0 failed; build - passed; lint - 0 errors, 3 warnings. C1-C10: 10/10 proven. Overall PASS; G1 resolved by user clarification. The Phase 1 go-live gate remains open.
