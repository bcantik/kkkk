-- =====================================================================
-- MIGRATION 002 — run this in Supabase SQL Editor on your EXISTING
-- project (the one you already ran schema.sql on). This only adds the
-- new columns/features from the latest round of changes — it will not
-- touch or delete any data you already have.
-- =====================================================================

-- 1. Split baju pengantin size into male / female (inch)
alter table items rename column size_inch to size_male_inch;
alter table items add column if not exists size_female_inch numeric(6,2);

-- 2. Notes can now carry an attached photo
alter table notes add column if not exists image_url text;

-- 3. (from the previous round — safe to re-run, no-ops if already applied)
alter table bookings add column if not exists google_event_id text;

create or replace function adjust_item_stock(p_item_id uuid, p_delta int)
returns void as $$
begin
  update items
  set quantity_available = greatest(0, coalesce(quantity_available, 0) + p_delta)
  where id = p_item_id;
end;
$$ language plpgsql security definer;

grant execute on function adjust_item_stock(uuid, int) to authenticated;
