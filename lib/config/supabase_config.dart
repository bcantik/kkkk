/// =====================================================================
/// FILL THESE IN before running the app.
/// Get them from: Supabase Dashboard > Project Settings > API
/// =====================================================================
class SupabaseConfig {
  static const String url = 'https://mckdrtxpzukgvgmkixgt.supabase.co';
  static const String publishableKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ja2RydHhwenVrZ3ZnbWtpeGd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0NzUyMTQsImV4cCI6MjEwMjA1MTIxNH0.gPZTriLLC3tGxipc_V9d3AKSAtJPYQW-_pQlY8qG7PU';

  static const String itemImagesBucket = 'item-images';
}

/// Google Calendar API (optional feature — dashboard/calendar sync).
/// Create OAuth 2.0 credentials in Google Cloud Console:
/// APIs & Services > Credentials > Create OAuth client ID (Web application)
/// Enable the "Google Calendar API" under APIs & Services > Library.
class GoogleCalendarConfig {
  static const String clientId = 'YOUR_GOOGLE_OAUTH_CLIENT_ID.apps.googleusercontent.com';
  static const List<String> scopes = [
    'https://www.googleapis.com/auth/calendar.events',
    'https://www.googleapis.com/auth/calendar.readonly',
  ];
  // The Google Calendar ID to sync bookings into (use 'primary' for the
  // signed-in staff account's default calendar, or a shared calendar ID).
  static const String calendarId = 'primary';
}
