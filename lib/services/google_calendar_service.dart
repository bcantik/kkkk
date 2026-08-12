import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

/// Syncs KKKK bookings into a real Google Calendar so staff get the event
/// on their phone's native calendar app too, with Google's own reminders.
///
/// SETUP REQUIRED (one-time, by whoever owns the Google Cloud project):
/// 1. console.cloud.google.com -> create/select a project
/// 2. APIs & Services > Library -> enable "Google Calendar API"
/// 3. APIs & Services > Credentials -> Create OAuth client ID
///    - Type: Web application (or the platform you target)
///    - Add your app's redirect / bundle ID as needed
/// 4. Paste the client ID into lib/config/supabase_config.dart -> GoogleCalendarConfig
class GoogleCalendarService {
  final _googleSignIn = GoogleSignIn(
    clientId: GoogleCalendarConfig.clientId,
    scopes: GoogleCalendarConfig.scopes,
  );

  GoogleSignInAccount? _account;

  Future<bool> connect() async {
    _account = await _googleSignIn.signIn();
    return _account != null;
  }

  Future<void> disconnect() => _googleSignIn.signOut();

  bool get isConnected => _account != null;

  Future<gcal.CalendarApi?> _apiClient() async {
    if (_account == null) return null;
    final authHeaders = await _account!.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    return gcal.CalendarApi(client);
  }

  /// Push a booking into Google Calendar as an event. Call this right
  /// after creating/editing a booking in Supabase so both stay in sync.
  Future<String?> upsertBookingEvent({
    String? existingEventId,
    required String title,
    required DateTime date,
    required String description,
    String? location,
  }) async {
    final api = await _apiClient();
    if (api == null) return null;

    final event = gcal.Event(
      summary: title,
      description: description,
      location: location,
      start: gcal.EventDateTime(date: DateTime(date.year, date.month, date.day)),
      end: gcal.EventDateTime(date: DateTime(date.year, date.month, date.day + 1)),
      reminders: gcal.EventReminders(
        useDefault: false,
        overrides: [
          gcal.EventReminder(method: 'popup', minutes: 24 * 60),
          gcal.EventReminder(method: 'popup', minutes: 3 * 24 * 60),
        ],
      ),
    );

    if (existingEventId != null) {
      final updated = await api.events.update(
        event,
        GoogleCalendarConfig.calendarId,
        existingEventId,
      );
      return updated.id;
    } else {
      final created = await api.events.insert(event, GoogleCalendarConfig.calendarId);
      return created.id;
    }
  }

  Future<void> deleteBookingEvent(String eventId) async {
    final api = await _apiClient();
    if (api == null) return;
    await api.events.delete(GoogleCalendarConfig.calendarId, eventId);
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
