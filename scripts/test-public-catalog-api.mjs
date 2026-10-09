import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';

const expectedNames = [
  'Cadeira de rodas',
  'Cama hospitalar',
  'Cadeira de banho',
  'Andador',
  'Muletas',
  'Colchão para cama hospitalar',
  'Cadeira infantil ou adaptada',
  'Bota ortopédica',
  'Tipoia de braço',
  'Suporte para soro',
  'Assento sanitário elevado',
  'Banheira ou apoio para banho',
  'Outros',
];

const priorityNames = [
  'Cadeira de rodas',
  'Cama hospitalar',
  'Cadeira de banho',
  'Andador',
  'Muletas',
];

function readLocalSupabaseStatus() {
  const output = execFileSync('supabase', ['status', '--output', 'env'], {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  return Object.fromEntries(
    output
      .split(/\r?\n/)
      .flatMap((line) => {
        const separator = line.indexOf('=');
        if (separator < 0) return [];

        const name = line.slice(0, separator);
        const value = line.slice(separator + 1).replace(/^"(.*)"$/, '$1');
        return [[name, value]];
      }),
  );
}

const localStatus = readLocalSupabaseStatus();
const apiUrl = process.env.SUPABASE_URL ?? localStatus.API_URL;
const anonKey = process.env.SUPABASE_ANON_KEY ?? localStatus.ANON_KEY;

assert.ok(apiUrl, 'Supabase local status must provide API_URL');
assert.ok(anonKey, 'SUPABASE_ANON_KEY or local Supabase ANON_KEY is required');

const apiHost = new URL(apiUrl).hostname;
assert.ok(
  ['127.0.0.1', 'localhost', '::1', '[::1]'].includes(apiHost),
  'This integration test only targets a local Supabase URL',
);

const catalogUrl = new URL('/rest/v1/equipment_types', apiUrl);

async function readCatalog(token) {
  const response = await fetch(catalogUrl, {
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${token}`,
    },
  });

  assert.ok(response.ok, `Catalog GET returned HTTP ${response.status}`);
  return response.json();
}

function assertCatalog(rows) {
  assert.ok(Array.isArray(rows), 'Catalog response must be an array');
  assert.equal(rows.length, expectedNames.length, 'Catalog must contain exactly 13 rows');
  assert.deepEqual(
    rows.map(({ name }) => name).sort(),
    [...expectedNames].sort(),
    'Catalog must contain exactly the approved active names',
  );
  assert.equal(
    rows.some(({ code }) => code === 'PE'),
    false,
    'Inactive PE must not be returned',
  );
  assert.ok(
    rows.every(
      (row) =>
        Object.keys(row).sort().join(',') === 'code,display_order,name' &&
        Number.isInteger(row.display_order),
    ),
    'Catalog response must contain only code, name, and display_order',
  );
  assert.deepEqual(
    rows.slice(0, priorityNames.length).map(({ name }) => name),
    priorityNames,
    'The five required priorities must appear first in order',
  );
  assert.ok(
    rows.every(
      (row, index) => index === 0 || rows[index - 1].display_order < row.display_order,
    ),
    'Catalog rows must follow their strictly increasing configured display_order',
  );
}

async function createAuthenticatedToken() {
  const credentials = {
    email: 'catalog-api-test@example.invalid',
    password: 'Catalog-Test-Only-2026!',
  };

  async function authenticate(path) {
    const response = await fetch(new URL(path, apiUrl), {
      method: 'POST',
      headers: {
        apikey: anonKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(credentials),
    });

    let body = {};
    try {
      body = await response.json();
    } catch {}

    return { response, body };
  }

  let result = await authenticate('/auth/v1/token?grant_type=password');
  if (!result.response.ok) {
    result = await authenticate('/auth/v1/signup');
  }

  assert.ok(
    result.response.ok && typeof result.body.access_token === 'string',
    `Local synthetic account could not obtain an access token (HTTP ${result.response.status})`,
  );
  return result.body.access_token;
}

async function attemptWrite(token, method, search, body) {
  const url = new URL(catalogUrl);
  url.search = search;

  return fetch(url, {
    method,
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
}

const anonymousRows = await readCatalog(anonKey);
assertCatalog(anonymousRows);
console.log('PASS C1: anonymous Data API read returns the 13 active types and omits PE');
console.log('PASS C2: the priority prefix and configured response order are correct');

const authenticatedToken = await createAuthenticatedToken();
const authenticatedRows = await readCatalog(authenticatedToken);
assertCatalog(authenticatedRows);
assert.deepEqual(
  authenticatedRows,
  anonymousRows,
  'Authenticated and anonymous readers must receive the same public catalog',
);
console.log('PASS C3: both roles receive only the active catalog fields through the view');

const writeAttempts = [
  {
    method: 'POST',
    search: '',
    body: { code: 'ZZ', name: 'Tipo sintetico de teste', display_order: 99 },
  },
  {
    method: 'PATCH',
    search: '?code=eq.CR',
    body: { name: 'Nome sintetico alterado pelo teste' },
  },
  { method: 'DELETE', search: '?code=eq.CR' },
];

for (const [role, token] of [
  ['anon', anonKey],
  ['authenticated', authenticatedToken],
]) {
  for (const { method, search, body } of writeAttempts) {
    const response = await attemptWrite(token, method, search, body);
    const rowsAfterAttempt = await readCatalog(anonKey);

    assert.ok(
      response.status >= 400 && response.status < 500,
      `${role} ${method} must be rejected with a client error, received HTTP ${response.status}`,
    );
    assert.deepEqual(
      rowsAfterAttempt,
      anonymousRows,
      `${role} ${method} must leave the public catalog unchanged`,
    );
  }
}

console.log('PASS C4: POST, PATCH, and DELETE are rejected for both roles without catalog changes');
