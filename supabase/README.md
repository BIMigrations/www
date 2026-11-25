# Supabase backend

The Supabase functions and schema for this site now live in the **BIMDash** repo
(`BIMigrations/BIMDash`, `supabase/`), which owns the project:

- `contact`: the contact and estate-scan form handler (moved there unchanged on 2026-11-25).
- `video-events`: the demo-video viewing log; this site posts to it only when `video_endpoint` in
  `_config.yml` is set.
- Migrations, including `contact_submissions` and `video_events`.

Change and deploy them from BIMDash (`npx supabase functions deploy <name> --no-verify-jwt`).
