# KERJA KAHWIN KUALA KANGSAR (KKKK)

A Flutter + Supabase wedding-business platform: public catalogue pages
(Pakej Perkahwinan, Koleksi Pelamin, Koleksi Baju Pengantin, Barang
Pelamin, Laman Dahlia) plus a staff-only Booking Management System
(dashboard, Google-Calendar-style booking calendar, payments,
customers, appointments, reports).

## ⚠️ Read this first — honest scope note

This is a **real, working scaffold**, not a mockup — every screen talks
to a live Supabase backend, images actually upload, forms actually
save, and the booking calendar is driven by real data. But the original
brief describes a large production system (~50 CRUD categories, Google
Calendar sync, push notifications, PDF/Excel exports, drag-and-drop
calendar, etc.). Rather than hand-write 50 nearly-identical screens, I
built a **generic, config-driven CRUD engine** (see
`lib/config/categories_config.dart`) that already covers every category
in the spec — Pakej Dewan, Pelamin Khemah, Songket, Kerusi, Pakej
Kenduri, all of it — through one reusable screen + form.

What's fully wired: auth & roles, all 5 public catalogue pages with
CRUD + image upload + search/filter, the editable Contact page, the
staff sidebar, dashboard KPIs, the booking calendar (month view with
color-coded status dots, tap-to-create, tap-to-open), full booking
create/edit/details with live payment progress bar and conflict
warning, customers, appointments, payments overview, and a reports
screen with the four headline stats.

What's stubbed / needs a bit more work before "production ready":
- **Drag-and-drop** on the calendar (the calendar itself is real;
  dragging events to a new date needs a week/day view — `table_calendar`
  is month-view by default, see "Next steps" below).
- **Google Calendar sync** — the code in
  `lib/services/google_calendar_service.dart` is complete and correct,
  but needs *your* Google Cloud OAuth client ID (see Setup step 4).
- **Push notifications when the app is closed** — in-app notifications
  and foreground local notifications work now; background push needs
  your own Firebase project (`flutterfire configure`).
- **PDF/Excel/CSV export buttons** on the Reports screen are present
  but not yet wired to a specific report layout — the `pdf`, `printing`
  and `csv` packages are already in `pubspec.yaml`.
- **Dress ±2-week availability** and **Kerusi/Panel stock deduction on
  booking** — the SQL/service logic (`ItemService.isBajuAvailable`) is
  there; hooking it into the booking-item save flow is the next step.
- **Automatic reminder scheduling** — `NotificationService` can create
  and show reminders; a scheduled job (Supabase Edge Function + cron,
  or a periodic client check) to fire them 1/3/7 days out is not yet
  built.

None of this is hard — the architecture is built so each of these is
an incremental addition, not a rewrite.

## Project structure

```
lib/
  config/         Supabase keys, category definitions, theme
  models/         Item, Booking, Customer, Appointment
  services/       Supabase CRUD, auth, storage/upload, Google Calendar, notifications
  widgets/        Reusable top bar, item card, image upload, responsive grid
  screens/
    categories/   Generic CRUD engine — powers all 5 public pages
    booking/      Staff dashboard, calendar, bookings, customers, payments, etc.
supabase/
  schema.sql      Full database schema + Row Level Security policies
```

## Setup

### 1. Supabase project
1. Create a project at supabase.com.
2. Open **SQL Editor** → paste the contents of `supabase/schema.sql` → Run.
   This creates every table, enum, RLS policy, and the `item-images`
   storage bucket.
3. **Project Settings → API** → copy the Project URL and anon public key
   into `lib/config/supabase_config.dart`.

### 2. Create your first staff/admin account
1. **Authentication → Users → Add user** (set email + password).
2. In **Table Editor → profiles**, insert a row with that user's `id`,
   their name, and `role = 'admin'`. (Staff you add later can be
   `'staff'` or `'viewer'` per the spec's three roles.)

### 3. Install & run
```bash
flutter pub get
flutter run                 # pick a device: Chrome, Android, iOS, macOS, Windows, Linux
```
The app is responsive out of the box (see `lib/widgets/responsive_layout.dart`)
— the same build adapts to phone, tablet, and desktop widths.

### 4. Optional: Google Calendar sync
1. console.cloud.google.com → create/select a project.
2. **APIs & Services → Library** → enable "Google Calendar API".
3. **APIs & Services → Credentials** → Create OAuth client ID.
4. Paste the client ID into `lib/config/supabase_config.dart` →
   `GoogleCalendarConfig.clientId`.
5. Call `GoogleCalendarService().upsertBookingEvent(...)` right after
   saving a booking (see the TODO comment in `booking_form_screen.dart`)
   to push it into staff's Google Calendar.

### 5. Optional: Firebase push notifications (background)
Run `flutterfire configure` with your own Firebase project, add the
`firebase_messaging` package, and register a listener — the
`NotificationService` already has the in-app + foreground-local half
of this built.

## Design notes (HCI)

- **Consistency**: one top bar, one card style, one form pattern reused
  across every one of the ~50 categories — staff only ever learn the
  pattern once.
- **Recognition over recall**: the homepage is six large labeled
  buttons, not a menu the visitor has to remember.
- **Feedback**: every save/delete shows a loading state and a
  confirmation dialog before destructive actions; the payment progress
  bar gives an at-a-glance status.
- **Error prevention**: the booking form checks for date conflicts
  live as you pick a date, before you can accidentally double-book.
- **Responsive & accessible contrast**: black/gold/cream palette
  matching the logo, with a fixed sidebar on desktop and a drawer on
  mobile so the full staff menu is always reachable.

## Sample data

`supabase/schema.sql` inserts the sample customer ("Mak Cik Me") from
the brief. To fully replicate section 20's sample booking, create a
Pakej Dewan C item first (via the staff UI), then create a booking for
Mak Cik Me on 5 September 2026 referencing it — the booking form's
"Additional charges" and "Notes" fields cover the pelamin colors,
attire notes, and setup timing details from the brief.
