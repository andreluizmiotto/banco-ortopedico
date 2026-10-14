import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';

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
const selectedCheck = process.argv.find((argument) =>
  argument.startsWith('--check='),
);
const checks = selectedCheck ? [selectedCheck.slice('--check='.length)] : ['C3', 'C4'];

assert.ok(apiUrl, 'Supabase local status must provide API_URL');
assert.ok(anonKey, 'SUPABASE_ANON_KEY or local Supabase ANON_KEY is required');
assert.ok(['C3', 'C4'].includes(checks[0]), 'Select --check=C3 or --check=C4');

const apiHost = new URL(apiUrl).hostname;
assert.ok(
  ['127.0.0.1', 'localhost', '::1', '[::1]'].includes(apiHost),
  'This integration test only targets a local Supabase URL',
);

const availabilityUrl = new URL('/rest/v1/rpc/equipment_availability', apiUrl);
const anonToken = anonKey;

async function requestAvailability(token) {
  const response = await fetch(availabilityUrl, {
    method: 'POST',
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ p_equipment_type_code: 'CR' }),
  });

  assert.ok(
    response.ok,
    `Availability RPC returned HTTP ${response.status}`,
  );
  return response.json();
}

function assertPublicContract(rows, label) {
  assert.ok(Array.isArray(rows), `${label} response must be an array`);
  assert.ok(
    rows.every(
      (row) =>
        Object.keys(row).sort().join(',') ===
          'available_quantity,bank_name' &&
        typeof row.bank_name === 'string' &&
        Number.isInteger(row.available_quantity),
    ),
    `${label} response must contain only a public bank name and integer quantity`,
  );
  assert.deepEqual(
    Object.fromEntries(
      rows.map(({ bank_name, available_quantity }) => [
        bank_name,
        available_quantity,
      ]),
    ),
    {
      'Entidade Sintética A': 3,
      'Entidade Sintética B': 2,
      'Entidade Sintética C': 0,
    },
    `${label} response must aggregate only synthetic available units by owner`,
  );
}

async function createSyntheticCompanionToken() {
  const credentials = {
    email: 'availability-companion-test@example.invalid',
    password: 'Availability-Test-Only-2026!',
    data: { test_role: 'companheiro' },
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
    `Synthetic authenticated test account could not obtain a token (HTTP ${result.response.status})`,
  );
  return result.body.access_token;
}

async function assertPrivateResourceDenied(token, resource) {
  const url = new URL(resource.path, apiUrl);
  const headers = {
    apikey: anonKey,
    Authorization: `Bearer ${token}`,
  };

  if (resource.schema) headers['Accept-Profile'] = resource.schema;

  const response = await fetch(url, { headers });
  const body = await response.text();

  assert.ok(
    response.status >= 400 && response.status < 500,
    `${resource.path} must not return records to this role (HTTP ${response.status})`,
  );
  assert.doesNotMatch(
    body,
    /Entidade Sint[eé]tica|CPF|telefone|endereco residencial|wa\.me/i,
    `${resource.path} error response must not contain synthetic records or personal/contact data`,
  );
}

if (checks.includes('C3')) {
  const rows = await requestAvailability(anonToken);
  assertPublicContract(rows, 'anon');
  console.log('PASS C3: anonymous RPC returns only bank_name and integer quantity');
}

if (checks.includes('C4')) {
  const companionToken = await createSyntheticCompanionToken();
  const authenticatedRows = await requestAvailability(companionToken);
  assertPublicContract(authenticatedRows, 'authenticated');

  const privateResources = [
    { path: '/rest/v1/equipment_units', schema: 'catalog' },
    { path: '/rest/v1/entities', schema: 'catalog' },
    { path: '/rest/v1/pontos_atendimento', schema: 'catalog' },
    { path: '/rest/v1/equipment_movements' },
    { path: '/rest/v1/loans' },
    { path: '/rest/v1/loan_items' },
    { path: '/rest/v1/profiles' },
    { path: '/rest/v1/people' },
  ];

  for (const token of [anonToken, companionToken]) {
    for (const resource of privateResources) {
      await assertPrivateResourceDenied(token, resource);
    }
  }

  console.log(
    'PASS C4: anon and authenticated roles cannot read operational or personal resources',
  );
}
