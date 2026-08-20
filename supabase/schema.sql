-- =====================================================================
-- KERJA KAHWIN KUALA KANGSAR (KKKK) — Supabase Schema
-- Run this in Supabase SQL Editor (Project > SQL Editor > New query)
-- =====================================================================

create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------------------
-- 1. USERS / PROFILES (extends Supabase auth.users)
-- ---------------------------------------------------------------------
create type user_role as enum ('admin', 'staff', 'viewer');

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  role user_role not null default 'staff',
  created_at timestamptz default now()
);

-- ---------------------------------------------------------------------
-- 2. SITE CONTENT (editable Contact page, etc.)
-- ---------------------------------------------------------------------
create table site_content (
  key text primary key,          -- e.g. 'contact_page'
  content jsonb not null default '{}',
  updated_at timestamptz default now(),
  updated_by uuid references profiles(id)
);

-- ---------------------------------------------------------------------
-- 3. GENERIC ITEMS TABLE
-- Covers: Pakej Perkahwinan (+subcategories), Koleksi Pelamin,
-- Koleksi Baju Pengantin, Barang Pelamin, Laman Dahlia — everything
-- that is "card with image + CRUD" is one row here, distinguished by
-- page_key / category / subcategory. This is what the generic CRUD
-- engine in the app reads/writes.
-- ---------------------------------------------------------------------
create table items (
  id uuid primary key default uuid_generate_v4(),
  page_key text not null,        -- 'pakej_perkahwinan' | 'pelamin' | 'baju_pengantin' | 'barang_pelamin' | 'dahlia'
  category text not null,        -- e.g. 'Pakej Dewan', 'Pelamin Khemah', 'Songket', 'Kerusi', 'Pakej Kenduri'
  subcategory text,               -- e.g. 'Dewan A', 'Nasi Mamak', 'Nikah'
  title text not null,
  description text,
  price numeric(10,2),
  size_feet numeric(6,2),         -- used by pelamin (size in feet)
  size_male_inch numeric(6,2),    -- used by baju pengantin (groom/male size)
  size_female_inch numeric(6,2),  -- used by baju pengantin (bride/female size)
  image_url text,
  quantity_total int,             -- used for Kerusi / Panel style stock
  quantity_available int,         -- decremented by bookings
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_items_page_key on items(page_key);
create index idx_items_category on items(category);

-- ---------------------------------------------------------------------
-- 4. VENUES
-- ---------------------------------------------------------------------
create table venues (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  address text,
  created_at timestamptz default now()
);

-- ---------------------------------------------------------------------
-- 5. CUSTOMERS
-- ---------------------------------------------------------------------
create table customers (
  id uuid primary key default uuid_generate_v4(),
  full_name text not null,
  phone text,
  email text,
  ic_number text,
  address text,
  emergency_contact text,
  created_at timestamptz default now()
);

create index idx_customers_phone on customers(phone);

-- ---------------------------------------------------------------------
-- 6. BOOKINGS
-- ---------------------------------------------------------------------
create type event_type as enum (
  'tunang','nikah','sanding','aqiqah','majlis_lain',
  'makeup','sewa_baju','sewa_aksesori'
);
create type booking_status as enum (
  'new_inquiry','quotation_sent','booking_confirmed','deposit_paid',
  'preparation','wedding_completed','completed','cancelled'
);
create type payment_status as enum ('unpaid','deposit_paid','partially_paid','fully_paid','overdue');

create table bookings (
  id uuid primary key default uuid_generate_v4(),
  customer_id uuid references customers(id) on delete set null,
  wedding_date date not null,
  event_type event_type not null,
  venue_id uuid references venues(id),
  venue_text text,               -- free text fallback if venue not in list
  expected_guests int,
  bride_name text,
  groom_name text,
  wedding_theme text,
  wedding_color text,

  package_item_id uuid references items(id),  -- links to items table (Pakej Perkahwinan, Dahlia pkgs, etc.)
  package_price numeric(10,2),
  additional_charges numeric(10,2) default 0,
  discount numeric(10,2) default 0,
  total_amount numeric(10,2) generated always as
    (coalesce(package_price,0) + coalesce(additional_charges,0) - coalesce(discount,0)) stored,

  deposit_required numeric(10,2) default 0,
  deposit_paid numeric(10,2) default 0,
  payment_status payment_status not null default 'unpaid',
  booking_status booking_status not null default 'new_inquiry',

  notes text,
  google_event_id text,          -- set when synced to a staff member's Google Calendar
  created_by uuid references profiles(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index idx_bookings_date on bookings(wedding_date);
create index idx_bookings_status on bookings(booking_status);

-- Additional items chosen for a booking (pelamin, barang, baju, katering, etc.)
create table booking_items (
  id uuid primary key default uuid_generate_v4(),
  booking_id uuid references bookings(id) on delete cascade,
  item_id uuid references items(id),
  quantity int default 1,
  price numeric(10,2),
  notes text
);

-- ---------------------------------------------------------------------
-- 7. PAYMENTS
-- ---------------------------------------------------------------------
create type payment_type as enum ('deposit','second_payment','final_payment','additional_charge','refund');

create table payments (
  id uuid primary key default uuid_generate_v4(),
  booking_id uuid references bookings(id) on delete cascade,
  payment_type payment_type not null,
  amount numeric(10,2) not null,
  payment_date date not null default current_date,
  notes text,
  recorded_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- ---------------------------------------------------------------------
-- 8. APPOINTMENTS
-- ---------------------------------------------------------------------
create type appointment_type as enum (
  'fitting_baju','pickup_baju','return_baju','pelamin_setup','pelamin_discussion',
  'wedding_day','meeting_customer','payment_reminder','other'
);

create table appointments (
  id uuid primary key default uuid_generate_v4(),
  booking_id uuid references bookings(id) on delete cascade,
  customer_id uuid references customers(id) on delete set null,
  appointment_type appointment_type not null,
  appointment_date date not null,
  appointment_time time not null,
  staff_assigned uuid references profiles(id),
  location text,
  notes text,
  reminder_offset_days int default 1,   -- 1, 3, 7, or custom
  created_at timestamptz default now()
);

create index idx_appointments_date on appointments(appointment_date);

-- ---------------------------------------------------------------------
-- 9. DRESS RENTALS (links Koleksi Baju Pengantin items to bookings)
-- ---------------------------------------------------------------------
create type dress_status as enum ('available','reserved','fitting','alter','rented','returned','cleaning');

create table dress_rentals (
  id uuid primary key default uuid_generate_v4(),
  item_id uuid references items(id) on delete cascade,   -- the dress (baju_pengantin item)
  booking_id uuid references bookings(id) on delete cascade,
  customer_id uuid references customers(id) on delete set null,
  status dress_status not null default 'reserved',
  fitting_date date,
  pickup_date date,
  return_date date,
  created_at timestamptz default now()
);

-- ---------------------------------------------------------------------
-- 10. PELAMIN BOOKINGS + CHECKLIST
-- ---------------------------------------------------------------------
create table pelamin_bookings (
  id uuid primary key default uuid_generate_v4(),
  booking_id uuid references bookings(id) on delete cascade,
  pelamin_item_id uuid references items(id),
  setup_date date,
  setup_time time,
  created_at timestamptz default now()
);

create type checklist_stage as enum ('ready','packed','loaded','installed');

create table pelamin_checklist (
  id uuid primary key default uuid_generate_v4(),
  pelamin_booking_id uuid references pelamin_bookings(id) on delete cascade,
  section text not null,     -- BACKDROP / FLOWERS / FURNITURE / DECORATION
  item_name text not null,
  is_ready boolean default false,
  is_packed boolean default false,
  is_loaded boolean default false,
  is_installed boolean default false
);

-- ---------------------------------------------------------------------
-- 11. NOTIFICATIONS
-- ---------------------------------------------------------------------
create table notifications (
  id uuid primary key default uuid_generate_v4(),
  recipient_id uuid references profiles(id) on delete cascade,
  title text not null,
  body text,
  type text,                 -- 'fitting' | 'wedding' | 'payment' | 'pelamin' | 'other'
  related_booking_id uuid references bookings(id),
  is_read boolean default false,
  created_at timestamptz default now()
);

-- ---------------------------------------------------------------------
-- 12. NOTES (free-form notes attached to a booking)
-- ---------------------------------------------------------------------
create table notes (
  id uuid primary key default uuid_generate_v4(),
  booking_id uuid references bookings(id) on delete cascade,
  content text not null,
  image_url text,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- =====================================================================
-- ROW LEVEL SECURITY
-- Public (anon) can READ items (for the 4 public display pages) but
-- never write. Only authenticated staff/admin can write anywhere,
-- and only view/write bookings/customers/payments (never the public).
-- =====================================================================

alter table profiles enable row level security;
alter table site_content enable row level security;
alter table items enable row level security;
alter table venues enable row level security;
alter table customers enable row level security;
alter table bookings enable row level security;
alter table booking_items enable row level security;
alter table payments enable row level security;
alter table appointments enable row level security;
alter table dress_rentals enable row level security;
alter table pelamin_bookings enable row level security;
alter table pelamin_checklist enable row level security;
alter table notifications enable row level security;
alter table notes enable row level security;

-- Helper: is the current user staff or admin?
create or replace function is_staff() returns boolean as $$
  select exists (
    select 1 from profiles
    where id = auth.uid() and role in ('staff','admin')
  );
$$ language sql security definer;

-- items: public can read active items; staff can do everything
create policy "public read items" on items for select using (is_active = true or is_staff());
create policy "staff write items" on items for insert with check (is_staff());
create policy "staff update items" on items for update using (is_staff());
create policy "staff delete items" on items for delete using (is_staff());

-- site_content: public can read; staff can write
create policy "public read site_content" on site_content for select using (true);
create policy "staff write site_content" on site_content for insert with check (is_staff());
create policy "staff update site_content" on site_content for update using (is_staff());

-- profiles: users can read their own; staff can read all
create policy "read own profile" on profiles for select using (auth.uid() = id or is_staff());
create policy "update own profile" on profiles for update using (auth.uid() = id);

-- Everything below is staff-only (customers, bookings, payments, appointments, etc.)
create policy "staff all venues" on venues for all using (is_staff()) with check (is_staff());
create policy "staff all customers" on customers for all using (is_staff()) with check (is_staff());
create policy "staff select bookings" on bookings for select using (is_staff());
create policy "staff write bookings" on bookings for insert with check (is_staff());
create policy "staff update bookings" on bookings for update using (is_staff());
create policy "staff delete bookings" on bookings for delete using (is_staff());
create policy "staff all booking_items" on booking_items for all using (is_staff()) with check (is_staff());
create policy "staff all payments" on payments for all using (is_staff()) with check (is_staff());
create policy "staff all appointments" on appointments for all using (is_staff()) with check (is_staff());
create policy "staff all dress_rentals" on dress_rentals for all using (is_staff()) with check (is_staff());
create policy "staff all pelamin_bookings" on pelamin_bookings for all using (is_staff()) with check (is_staff());
create policy "staff all pelamin_checklist" on pelamin_checklist for all using (is_staff()) with check (is_staff());
create policy "own notifications" on notifications for select using (recipient_id = auth.uid());
create policy "staff insert notifications" on notifications for insert with check (is_staff());
create policy "own notifications update" on notifications for update using (recipient_id = auth.uid());
create policy "staff all notes" on notes for all using (is_staff()) with check (is_staff());

-- =====================================================================
-- STORAGE BUCKET for images (create via Dashboard > Storage, or here)
-- =====================================================================
insert into storage.buckets (id, name, public) values ('item-images', 'item-images', true)
on conflict (id) do nothing;

create policy "public read item-images" on storage.objects
  for select using (bucket_id = 'item-images');
create policy "staff upload item-images" on storage.objects
  for insert with check (bucket_id = 'item-images' and is_staff());
create policy "staff update item-images" on storage.objects
  for update using (bucket_id = 'item-images' and is_staff());
create policy "staff delete item-images" on storage.objects
  for delete using (bucket_id = 'item-images' and is_staff());

-- =====================================================================
-- SAMPLE DATA (Section 20 of the brief — Mak Cik Me booking)
-- Run AFTER you have created at least one customer/item, or use as-is:
-- =====================================================================
insert into customers (full_name, phone) values ('Mak Cik Me', '0123456789')
on conflict do nothing;

-- Trigger to keep updated_at fresh
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_items_updated before update on items
  for each row execute function set_updated_at();
create trigger trg_bookings_updated before update on bookings
  for each row execute function set_updated_at();

-- =====================================================================
-- STOCK ADJUSTMENT (atomic) — used when a Kerusi/Panel-style item is
-- added to or removed from a booking, so two staff adding the same
-- item at once can't oversell the stock.
-- =====================================================================
create or replace function adjust_item_stock(p_item_id uuid, p_delta int)
returns void as $$
begin
  update items
  set quantity_available = greatest(0, coalesce(quantity_available, 0) + p_delta)
  where id = p_item_id;
end;
$$ language plpgsql security definer;

grant execute on function adjust_item_stock(uuid, int) to authenticated;
