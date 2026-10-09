<!-- BEGIN:nextjs-agent-rules -->

## This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

# AI Agent Guidelines — Banco Ortopédico

## Inviolable UI/UX Rules (Elderly Accessibility)
1. **Accessibility for Elderly Users:** Buttons must have a MINIMUM height of `56px` (`min-h-[56px]`), button text `20px+` bold, body text `18px+`.
2. **Official Rotary Color Palette:**
   - Primary/Buttons (Azul Real): `#17458F`
   - Accent/Badges (Dourado): `#F7A81B`
   - Body Text (Cinza Carvão): `#54565A`
   - Success/Available (Verde): `#1E7B3C`
   - Error/Overdue (Vermelho): `#B3261E`
3. **User-Friendly Portuguese UI Terminology:** NEVER use technical jargon such as "login", "dashboard", "logout", or "status". ALWAYS use everyday Portuguese terms: "entrar", "painel", "sair", and "situação".
4. **Single Primary Action Per Screen:** Clean mobile-first design targeting a minimum screen width of 360px.

## Architecture & Security
- Stack: Next.js (App Router, TypeScript) + Supabase (`@supabase/ssr`).
- All Supabase database queries MUST enforce Row Level Security (RLS) policies to isolate data among the 4 entities (Boa Vista, Três Vendas, Casa da Amizade, and Erechim).
- NEVER expose CPFs, phone numbers, or personal data to the client/frontend for the "Companheiro" user role.