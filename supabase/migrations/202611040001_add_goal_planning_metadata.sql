-- Extensible goal-specific assumptions and source evidence live with the existing goal row.
-- Older clients omit this nullable column and remain compatible.
alter table public.goals
    add column if not exists "planningData" jsonb;
