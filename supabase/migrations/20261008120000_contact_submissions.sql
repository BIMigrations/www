-- Log of website contact submissions. Backs the per-IP rate limit and gives us
-- a record to review when tuning the spam rules.
create table if not exists public.contact_submissions (
  id           bigint generated always as identity primary key,
  created_at   timestamptz not null default now(),
  ip           text,
  status       text not null check (status in ('accepted', 'rejected')),
  reasons      text[] not null default '{}',
  form         text,
  name         text,
  email        text,
  domain       text,
  company      text,
  platform     text,
  interest     text,
  message      text,
  page         text,
  user_agent   text
);

-- the rate limiter counts rows per IP inside a short window
create index if not exists contact_submissions_ip_created_at_idx
  on public.contact_submissions (ip, created_at desc);
create index if not exists contact_submissions_created_at_idx
  on public.contact_submissions (created_at desc);

-- No client should read or write this table; the edge function uses the
-- service role, which bypasses RLS. Enabling RLS with no policies means
-- anon and authenticated get nothing.
alter table public.contact_submissions enable row level security;
