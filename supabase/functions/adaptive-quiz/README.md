# adaptive-quiz

Edge Function 'adaptive-quiz' — Gemini-based adaptive quiz generator.

Environment:
- GEMINI_API_KEY must be set as Supabase secret.

Request (POST JSON):
{
  "level": "A1.1",
  "topic": "Artikel"
}

Response: JSON quiz matching the schema in `docs/EDGE_FUNCTIONS_REDESIGN.md`.

Local testing:
- `supabase functions serve adaptive-quiz` (ensure `GEMINI_API_KEY` available in env)

Deploy:
- `supabase functions deploy adaptive-quiz`