-- Code Atlas: profiles and learning progress with row-level security.
-- Run in the Supabase SQL editor, or with the Supabase CLI: supabase db push

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text check (display_name is null or char_length(display_name) <= 80),
  last_language text check (last_language is null or char_length(last_language) <= 30),
  last_concept integer check (last_concept is null or last_concept between 0 and 99),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.completed_lessons (
  user_id uuid not null references auth.users (id) on delete cascade,
  language text not null check (char_length(language) between 1 and 30),
  concept integer not null check (concept between 0 and 99),
  completed_at timestamptz not null default now(),
  primary key (user_id, language, concept)
);

create table public.quiz_results (
  user_id uuid not null references auth.users (id) on delete cascade,
  language text not null check (char_length(language) between 1 and 30),
  concept integer not null check (concept between 0 and 99),
  passed boolean not null default false,
  tries integer not null default 0 check (tries >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, language, concept)
);

create table public.bookmarks (
  user_id uuid not null references auth.users (id) on delete cascade,
  language text not null check (char_length(language) between 1 and 30),
  concept integer not null check (concept between 0 and 99),
  created_at timestamptz not null default now(),
  primary key (user_id, language, concept)
);

create table public.test_results (
  user_id uuid not null references auth.users (id) on delete cascade,
  language text not null check (char_length(language) between 1 and 30),
  best integer not null default 0 check (best >= 0),
  attempts integer not null default 0 check (attempts >= 0),
  last_score integer not null default 0 check (last_score >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, language)
);

-- Keep updated_at fresh.
create function public.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end; $$;

create trigger profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger quiz_results_updated before update on public.quiz_results
  for each row execute function public.set_updated_at();
create trigger test_results_updated before update on public.test_results
  for each row execute function public.set_updated_at();

-- Create a profile row automatically when someone signs up.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, nullif(left(coalesce(new.raw_user_meta_data ->> 'display_name', ''), 80), ''))
  on conflict (id) do nothing;
  return new;
end; $$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Row-level security: each signed-in user can reach only their own rows.
alter table public.profiles enable row level security;
alter table public.completed_lessons enable row level security;
alter table public.quiz_results enable row level security;
alter table public.bookmarks enable row level security;
alter table public.test_results enable row level security;

revoke all on public.profiles, public.completed_lessons, public.quiz_results,
  public.bookmarks, public.test_results from anon;
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.completed_lessons, public.quiz_results,
  public.bookmarks, public.test_results to authenticated;

create policy profiles_select_own on public.profiles for select to authenticated
  using ((select auth.uid()) = id);
create policy profiles_update_own on public.profiles for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy completed_lessons_own on public.completed_lessons for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy quiz_results_own on public.quiz_results for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy bookmarks_own on public.bookmarks for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy test_results_own on public.test_results for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
