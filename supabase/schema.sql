create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null default '',
  reason text not null default '계산실수',
  review_count integer not null default 0,
  image_data text,
  source_type text not null default 'text',
  created_at timestamptz not null default now()
);

alter table public.notes add column if not exists reason text not null default '계산실수';
alter table public.notes add column if not exists review_count integer not null default 0;
alter table public.notes add column if not exists image_data text;

alter table public.notes enable row level security;
drop policy if exists "Users can read their notes" on public.notes;
drop policy if exists "Users can create their notes" on public.notes;
drop policy if exists "Users can update their notes" on public.notes;
create policy "Users can read their notes" on public.notes for select using (auth.uid() = user_id);
create policy "Users can create their notes" on public.notes for insert with check (auth.uid() = user_id);
create policy "Users can update their notes" on public.notes for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
