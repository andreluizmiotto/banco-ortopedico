import "server-only";

export function normalizeCpf(value: unknown): string | null {
  if (typeof value !== "string") return null;

  const input = value.trim();
  if (!/^[0-9.\-\s]+$/.test(input)) return null;

  const digits = input.replace(/\D/g, "");
  if (!/^\d{11}$/.test(digits) || /^(\d)\1{10}$/.test(digits)) {
    return null;
  }

  let sum = 0;
  for (let index = 0; index < 9; index += 1) {
    sum += Number(digits[index]) * (10 - index);
  }
  const firstCheckDigit = ((sum * 10) % 11) % 10;

  sum = 0;
  for (let index = 0; index < 9; index += 1) {
    sum += Number(digits[index]) * (11 - index);
  }
  sum += firstCheckDigit * 2;
  const secondCheckDigit = ((sum * 10) % 11) % 10;

  if (
    Number(digits[9]) !== firstCheckDigit ||
    Number(digits[10]) !== secondCheckDigit
  ) {
    return null;
  }

  return digits;
}

export function normalizeAuthPhone(value: unknown): string | null {
  if (typeof value !== "string") return null;

  const input = value.trim();
  if (!/^[+0-9().\-\s]+$/.test(input)) return null;

  const digits = input.replace(/\D/g, "");
  if (!/^[1-9]\d{7,14}$/.test(digits)) return null;

  return `+${digits}`;
}

export function normalizePersonName(value: unknown): string | null {
  if (typeof value !== "string") return null;

  const name = value.trim();
  if (name.length < 2 || name.length > 150) return null;

  return name;
}

export function isValidNewPassword(value: unknown): value is string {
  return typeof value === "string" && value.length >= 8;
}
