# Sankosh security baseline

- Supabase Auth is the only identity authority. Server routes call `auth.getUser()`; they never trust a user ID supplied by the browser.
- Every financial table has RLS enabled, with separate select, insert, update and delete policies bound to `auth.uid()`.
- Session cookies are refreshed server-side and forced to `HttpOnly`, `Secure` in production, `SameSite=Lax`, and `/` scope.
- Zod validates untrusted input before AI processing and again after model output. The AI never writes directly to the database; users review before a separate validated insert.
- The browser receives only the Supabase anonymous key. OpenAI and WhatsApp tokens remain server-side.
- WhatsApp sends require recorded consent. The default UX only generates a user-reviewed `wa.me` draft.
- IPO content is research summarisation, not personalized advice. Store source URL and generation time with each summary.
- Production hardening: enable MFA, leaked-password protection, PITR/backups, audit-log retention, rate limits, bot protection, and key rotation in Supabase.
