-- supabase/schema.sql
-- AI Electronics Learning Engine (v1)
-- Postgres schema designed for: curriculum -> planning -> practice -> grading -> mastery


create extension if not exists pgcrypto;

create table if not exists topics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  prereq_topic_ids uuid[] not null default '{}'::uuid[],
  created_at timestamptz not null default now()
);

create table if not exists objectives (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references topics(id) on delete cascade,
  code text not null,
  statement text not null,
  rubric jsonb not null default '{}'::jsonb,
  common_errors jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  unique(topic_id, code)
);

create table if not exists problem_templates (
  id uuid primary key default gen_random_uuid(),
  objective_id uuid not null references objectives(id) on delete cascade,
  title text not null,
  difficulty int not null default 1,
  params_schema jsonb not null,
  generator_spec jsonb not null,
  solution_spec jsonb not null,
  created_at timestamptz not null default now(),
  check (difficulty between 1 and 5)
);

create table if not exists problems (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references problem_templates(id) on delete cascade,
  objective_id uuid not null references objectives(id) on delete cascade,
  params jsonb not null,
  rendered jsonb not null,
  answer_key jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists student_objective_state (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  objective_id uuid not null references objectives(id) on delete cascade,
  mastery numeric not null default 0.0,
  confidence numeric not null default 0.5,
  last_seen timestamptz,
  error_tags jsonb not null default '[]'::jsonb,
  unique(user_id, objective_id),
  check (mastery >= 0.0 and mastery <= 1.0),
  check (confidence >= 0.0 and confidence <= 1.0)
);

create table if not exists sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  session_date date not null default current_date,
  plan jsonb not null,
  created_at timestamptz not null default now()
);

create unique index if not exists idx_sessions_user_date
  on sessions(user_id, session_date);

create table if not exists attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  session_id uuid references sessions(id) on delete set null,
  problem_id uuid not null references problems(id) on delete cascade,
  answer jsonb not null,
  work_shown text,
  is_correct boolean not null,
  score numeric not null default 0.0,
  error_tags jsonb not null default '[]'::jsonb,
  feedback text,
  created_at timestamptz not null default now(),
  check (score >= 0.0 and score <= 1.0)
);

create index if not exists idx_objectives_topic_id on objectives(topic_id);
create index if not exists idx_problem_templates_objective_id on problem_templates(objective_id);
create index if not exists idx_problems_objective_id on problems(objective_id);

create index if not exists idx_state_user_id on student_objective_state(user_id);
create index if not exists idx_state_objective_id on student_objective_state(objective_id);

create index if not exists idx_attempts_user_id on attempts(user_id);
create index if not exists idx_attempts_problem_id on attempts(problem_id);
create index if not exists idx_attempts_created_at on attempts(created_at);


-- Convention: error_tags values should come from a controlled set, e.g.:
-- ["units_error","sign_error","wrong_reference_node","algebra_error","model_error","arithmetic_error"]
