# Sankosh

Sankosh is a mobile-first Indian personal-finance PWA for AI-assisted entry, EMIs, credit-card cycles, subscriptions, shared expenses, budgets, holdings, and source-backed IPO research.

## Stack

Next.js App Router, TypeScript, Tailwind CSS, Shadcn-style UI primitives, Framer Motion, Recharts, `next-pwa`, Supabase Auth/PostgreSQL, Zod, and the OpenAI Responses API.

## Start locally

```bash
npx create-next-app@latest sankosh --typescript --tailwind --eslint --app --src-dir=false --import-alias="@/*"
cd sankosh
npx shadcn@latest init
npm install framer-motion recharts next-pwa @supabase/ssr @supabase/supabase-js zod lucide-react
cp .env.example .env.local
npm run dev
```

For this delivered project, dependencies are already declared; use `pnpm install && pnpm dev`.

## Configure Supabase

1. Create a Supabase project in an Indian or nearby region suitable for your data-residency needs.
2. Run `supabase/schema.sql` in the SQL editor.
3. Add your Site URL and `http://localhost:3000/auth/callback` to Auth redirect URLs.
4. Copy the project URL and anonymous key into `.env.local`. Never expose the service-role key.
5. Add `OPENAI_API_KEY` only to the server environment. Without it, the app uses a clearly marked local demo parser.

## Core flow

`POST /api/ai/parse` validates the note, verifies the session, requests strict structured JSON, and validates the model result again. After user review, `POST /api/entries` performs the database write. RLS remains the final authorization boundary.

## PWA

`next-pwa` is configured for a standard Next.js deployment. A small compatible service-worker registration is also included for the hosted preview runtime. The manifest uses standalone mode and a dark system-bar theme.

## WhatsApp reminders

The current UI opens a pre-filled, user-reviewed WhatsApp message. For automatic sends, use approved Meta WhatsApp templates from a scheduled server or Supabase Edge Function, and send only where `consent_confirmed = true`.

## Financial data policy

Do not store card numbers, CVVs, banking passwords, Aadhaar, PAN scans, or broker credentials. Portfolio prices are manual until a licensed market-data provider is integrated. IPO summaries must retain their source and timestamp and must never promise allotment or returns.
