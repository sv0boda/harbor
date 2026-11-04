// pin-client.mjs — dependency-free browser ES module for Harbor ship-backend PIN handling.
// No fetch, no PIN storage/logging. All amounts synthetic micro-integer strings.

const enc = new TextEncoder();

function toHex(bytes) {
  return Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
}

function fromHex(hex) {
  if (!/^[0-9a-f]*$/.test(hex) || hex.length % 2 !== 0) throw new Error('bad hex');
  const out = new Uint8Array(hex.length / 2);
  for (let i = 0; i < out.length; i++) out[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  return out;
}

function assertCrypto() {
  const c = globalThis.crypto;
  if (!c || !c.subtle) throw new Error('WebCrypto (crypto.subtle) unavailable');
  return c;
}

// Enforce: pin is 4-6 ASCII digits (leading zeros allowed); salt is exactly 64 lowercase hex.
export async function derivePin(pin, salt, ship = '~zod') {
  if (typeof pin !== 'string' || !/^[0-9]{4,6}$/.test(pin)) throw new Error('pin must be 4-6 ASCII digits');
  if (typeof salt !== 'string' || !/^[0-9a-f]{64}$/.test(salt)) throw new Error('salt must be 64 lowercase hex chars');
  const c = assertCrypto();
  const key = await c.subtle.importKey('raw', enc.encode(pin), 'PBKDF2', false, ['deriveBits']);
  const saltBytes = enc.encode(`harbor-pin-v1|${ship}|${salt}`);
  return c.subtle
    .deriveBits({ name: 'PBKDF2', hash: 'SHA-256', salt: saltBytes, iterations: 600000 }, key, 256)
    .then((bits) => toHex(new Uint8Array(bits)));
}

// 32 random bytes -> 64 lowercase hex chars.
export function newSalt() {
  const c = assertCrypto();
  const bytes = new Uint8Array(32);
  c.getRandomValues(bytes);
  return toHex(bytes);
}

// Validate 64 lowercase hex, return '0x' + groups of 4 hex chars joined by '.' (zeros preserved).
export function hoonHex(hex) {
  if (typeof hex !== 'string' || !/^[0-9a-f]{64}$/.test(hex)) throw new Error('hoonHex expects 64 lowercase hex chars');
  const groups = [];
  for (let i = 0; i < 64; i += 4) groups.push(hex.slice(i, i + 4));
  return '0x' + groups.join('.');
}

// Derive PIN key, then HMAC-SHA256 over UTF-8 message; return 64-character lowercase hexadecimal signature.
export function prove(pin, salt, message, ship = '~zod') {
  if (typeof message !== 'string') throw new Error('message must be a string');
  return derivePin(pin, salt, ship).then(async (hex) => {
    const c = assertCrypto();
    const key = await c.subtle.importKey('raw', fromHex(hex), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
    return c.subtle.sign('HMAC', key, enc.encode(message)).then((sig) => toHex(new Uint8Array(sig)));
  });
}

// Decimal string with at most 6 fraction digits -> BigInt micro-integer string.
// Value must be in [1, 1000000000000] micros.
export function parseAmount(value) {
  if (typeof value !== 'string' || !/^[0-9]+(\.[0-9]{1,6})?$/.test(value)) {
    throw new Error('amount must be a decimal string with at most 6 fraction digits');
  }
  const [whole, frac = ''] = value.split('.');
  const micros = BigInt(whole) * 1000000n + BigInt(frac.padEnd(6, '0') || '0');
  if (micros < 1n || micros > 1000000000000n) throw new Error('amount out of range 1..1000000000000');
  return micros.toString();
}

// BigInt micro-integer string -> trimmed decimal OCT string (no trailing zeros, no leading zeros).
export function formatAmount(value) {
  let micros;
  if (typeof value === 'bigint') micros = value;
  else if (typeof value === 'string' && /^[0-9]+$/.test(value)) micros = BigInt(value);
  else throw new Error('formatAmount expects a BigInt or non-negative integer string');
  if (micros < 0n) throw new Error('micros must be non-negative');
  const whole = micros / 1000000n;
  const frac = micros % 1000000n;
  if (frac === 0n) return whole.toString();
  return whole.toString() + '.' + frac.toString().padStart(6, '0').replace(/0+$/, '');
}
