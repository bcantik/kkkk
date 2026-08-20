-- Migration 003: booking event types added in the app.
-- Run this once in the Supabase SQL Editor after migration_002.sql.

alter type event_type add value if not exists 'makeup';
alter type event_type add value if not exists 'sewa_baju';
alter type event_type add value if not exists 'sewa_aksesori';

-- Deleting a customer keeps their historical booking/rental/appointment
-- records while removing the customer link.
alter table appointments
  drop constraint if exists appointments_customer_id_fkey,
  add constraint appointments_customer_id_fkey
    foreign key (customer_id) references customers(id) on delete set null;

alter table dress_rentals
  drop constraint if exists dress_rentals_customer_id_fkey,
  add constraint dress_rentals_customer_id_fkey
    foreign key (customer_id) references customers(id) on delete set null;
