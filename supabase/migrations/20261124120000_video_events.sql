-- Demo-video viewing log, written by the video-events edge function (service role only).
-- One row per event: video_start, video_progress (10/25/50/75/90), video_complete, video_summary.
-- No raw IP is stored: country comes from the edge network's country header and ip_hash is a salted
-- hash, used only to rate-limit and to count distinct networks.
create table if not exists public.video_events (
  id                   bigint generated always as identity primary key,
  created_at           timestamptz not null default now(),
  event                text not null check (event in ('video_start','video_progress','video_complete','video_summary')),
  video_id             text not null,
  visitor_id           text not null,   -- random id kept in the browser (localStorage bi_vid)
  session_id           text not null,   -- one per page view
  video_duration       integer,
  video_percent        smallint,        -- progress milestone (video_progress only)
  watched_seconds      integer,         -- seconds actually played, replays included
  percent_watched      smallint,        -- share of the film played at least once
  max_position_seconds integer,
  play_count           smallint,
  completed            boolean,         -- reached the end
  engagement           text,            -- glance, partial, most, complete, skipped_to_end
  captions_on          boolean,
  muted                boolean,
  page                 text,
  referrer             text,
  utm                  jsonb,
  screen               text,
  device               text,            -- mobile, tablet, desktop
  country              text,
  ip_hash              text,
  user_agent           text
);

create index if not exists video_events_visitor_idx  on public.video_events (visitor_id, created_at desc);
create index if not exists video_events_session_idx  on public.video_events (session_id);
create index if not exists video_events_created_idx  on public.video_events (created_at desc);
create index if not exists video_events_iphash_idx   on public.video_events (ip_hash, created_at desc);

alter table public.video_events enable row level security;   -- no policies: only the service role reads or writes

-- Contact and scan forms carry the same visitor id, so a lead can be matched to what they watched.
alter table public.contact_submissions add column if not exists visitor_id text;
create index if not exists contact_submissions_visitor_idx on public.contact_submissions (visitor_id);

-- One row per page view that started the film.
create or replace view public.video_sessions as
select
  session_id,
  visitor_id,
  video_id,
  min(created_at)                                   as started_at,
  max(watched_seconds)                              as watched_seconds,
  max(percent_watched)                              as percent_watched,
  max(max_position_seconds)                         as max_position_seconds,
  bool_or(coalesce(completed, false))               as completed,
  (array_agg(engagement order by created_at desc) filter (where engagement is not null))[1] as engagement,
  (array_agg(country order by created_at desc) filter (where country is not null))[1]       as country,
  (array_agg(device order by created_at desc) filter (where device is not null))[1]         as device,
  (array_agg(referrer order by created_at asc) filter (where coalesce(referrer, '') <> ''))[1] as referrer,
  (array_agg(utm order by created_at asc) filter (where utm is not null and utm <> '{}'::jsonb))[1] as utm
from public.video_events
group by session_id, visitor_id, video_id;

-- One row per visitor and film.
create or replace view public.video_viewers as
select
  visitor_id,
  video_id,
  count(*)                       as sessions,
  min(started_at)                as first_seen,
  max(started_at)                as last_seen,
  sum(watched_seconds)           as total_seconds_watched,
  max(percent_watched)           as best_percent_watched,
  bool_or(completed)             as ever_completed,
  max(country)                   as country,
  max(device)                    as device
from public.video_sessions
group by visitor_id, video_id;

-- Leads (accepted contact and scan submissions) with what they watched.
create or replace view public.leads_who_watched as
select
  c.created_at, c.form, c.name, c.email, c.company, c.platform, c.interest,
  v.video_id, v.sessions, v.total_seconds_watched, v.best_percent_watched, v.ever_completed, v.country
from public.contact_submissions c
join public.video_viewers v on v.visitor_id = c.visitor_id
where c.status = 'accepted'
order by c.created_at desc;

-- Supabase exposes the public schema to anon by default. Nothing here is for the public.
revoke all on public.video_events, public.video_sessions, public.video_viewers, public.leads_who_watched from anon, authenticated;
