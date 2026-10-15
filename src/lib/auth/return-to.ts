export function sanitizeReturnTo(value: unknown): string {
  if (typeof value !== "string") return "/";

  const destination = value.trim();
  return /^\/equipamentos\/[A-Za-z0-9_-]+$/.test(destination)
    ? destination
    : "/";
}
