import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Two layers of notifications:
/// 1. In-app: rows in the `notifications` table, shown as a bell icon +
///    list in the staff dashboard (works everywhere, no extra setup).
/// 2. Device push/local reminders via flutter_local_notifications, so
///    staff get a real phone notification even with the app backgrounded.
///
/// NOTE: for background push when the app is fully closed, wire this up
/// to Firebase Cloud Messaging with your own Firebase project — that
/// requires `flutterfire configure` which needs your own Firebase
/// credentials, so it's left as the next step rather than faked here.
class NotificationService {
  final _client = Supabase.instance.client;
  final _local = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
  }

  Future<void> showNow({required String title, required String body}) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'kkkk_reminders',
        'KKKK Reminders',
        channelDescription: 'Booking, fitting and payment reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _local.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  }

  /// Fetches unread in-app notifications for the bell icon.
  Future<List<Map<String, dynamic>>> unreadForCurrentUser() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('notifications')
        .select()
        .eq('recipient_id', uid)
        .eq('is_read', false)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> markRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> createReminder({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    String? relatedBookingId,
  }) async {
    await _client.from('notifications').insert({
      'recipient_id': recipientId,
      'title': title,
      'body': body,
      'type': type,
      'related_booking_id': relatedBookingId,
    });
  }
}
