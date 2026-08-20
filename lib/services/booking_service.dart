import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';
import '../models/customer_model.dart';
import '../models/appointment_model.dart';

class BookingService {
  final _client = Supabase.instance.client;

  static const _bookingSelect =
      '*, customers(full_name, phone), items:package_item_id(title)';

  Future<List<BookingModel>> fetchAll({
    DateTime? from,
    DateTime? to,
    String? statusFilter,
  }) async {
    var query = _client.from('bookings').select(_bookingSelect);
    if (from != null) {
      query = query.gte('wedding_date', from.toIso8601String().split('T').first);
    }
    if (to != null) {
      query = query.lte('wedding_date', to.toIso8601String().split('T').first);
    }
    if (statusFilter != null) query = query.eq('booking_status', statusFilter);
    final rows = await query.order('wedding_date');
    return (rows as List).map((r) => BookingModel.fromMap(r)).toList();
  }

  Stream<List<Map<String, dynamic>>> watchAllRaw() {
    return _client.from('bookings').stream(primaryKey: ['id']).order('wedding_date');
  }

  /// Checks for a date conflict on the same venue before creating.
  Future<bool> hasDateConflict(DateTime date, {String? excludeBookingId, String? venueId}) async {
    var query = _client
        .from('bookings')
        .select('id')
        .eq('wedding_date', date.toIso8601String().split('T').first)
        .neq('booking_status', 'cancelled');
    if (venueId != null) query = query.eq('venue_id', venueId);
    final rows = await query;
    final list = (rows as List).where((r) => r['id'] != excludeBookingId);
    return list.isNotEmpty;
  }

  Future<BookingModel> create(BookingModel booking) async {
    final row = await _client.from('bookings').insert(booking.toMap()).select(_bookingSelect).single();
    return BookingModel.fromMap(row);
  }

  Future<BookingModel> update(String id, BookingModel booking) async {
    final row = await _client
        .from('bookings')
        .update(booking.toMap())
        .eq('id', id)
        .select(_bookingSelect)
        .single();
    return BookingModel.fromMap(row);
  }

  Future<void> delete(String id) async => _client.from('bookings').delete().eq('id', id);

  Future<void> updateDate(String id, DateTime newDate) async {
    await _client
        .from('bookings')
        .update({'wedding_date': newDate.toIso8601String().split('T').first}).eq('id', id);
  }

  // ---- Customers ----
  Future<List<CustomerModel>> fetchCustomers({String? search}) async {
    var query = _client.from('customers').select();
    if (search != null && search.isNotEmpty) {
      query = query.or('full_name.ilike.%$search%,phone.ilike.%$search%');
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List).map((r) => CustomerModel.fromMap(r)).toList();
  }

  Future<CustomerModel> createCustomer(CustomerModel c) async {
    final row = await _client.from('customers').insert(c.toMap()).select().single();
    return CustomerModel.fromMap(row);
  }

  Future<CustomerModel> updateCustomer(String id, CustomerModel customer) async {
    final row = await _client
        .from('customers')
        .update(customer.toMap())
        .eq('id', id)
        .select()
        .single();
    return CustomerModel.fromMap(row);
  }

  Future<void> deleteCustomer(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }

  // ---- Payments ----
  Future<void> recordPayment({
    required String bookingId,
    required String paymentType,
    required double amount,
    String? notes,
  }) async {
    await _client.from('payments').insert({
      'booking_id': bookingId,
      'payment_type': paymentType,
      'amount': amount,
      'notes': notes,
    });
    // bump deposit_paid on the booking
    final booking = await _client.from('bookings').select('deposit_paid').eq('id', bookingId).single();
    final newPaid = (booking['deposit_paid'] as num).toDouble() + amount;
    await _client.from('bookings').update({'deposit_paid': newPaid}).eq('id', bookingId);
  }

  Future<List<Map<String, dynamic>>> paymentHistory(String bookingId) async {
    final rows = await _client
        .from('payments')
        .select()
        .eq('booking_id', bookingId)
        .order('payment_date');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  // ---- Appointments ----
  Future<List<AppointmentModel>> fetchAppointments({DateTime? from, DateTime? to}) async {
    var query = _client.from('appointments').select('*, customers(full_name)');
    if (from != null) {
      query = query.gte('appointment_date', from.toIso8601String().split('T').first);
    }
    if (to != null) {
      query = query.lte('appointment_date', to.toIso8601String().split('T').first);
    }
    final rows = await query.order('appointment_date').order('appointment_time');
    return (rows as List).map((r) => AppointmentModel.fromMap(r)).toList();
  }

  Future<void> createAppointment(AppointmentModel a) async {
    await _client.from('appointments').insert(a.toMap());
  }

  Future<void> updateAppointment(String id, AppointmentModel appointment) async {
    await _client.from('appointments').update(appointment.toMap()).eq('id', id);
  }

  Future<void> deleteAppointment(String id) async {
    await _client.from('appointments').delete().eq('id', id);
  }

  // ---- Booking Add-ons (booking_items) ----
  // Links a chosen catalogue item (pelamin, barang, baju, katering...) to
  // a booking. For Kerusi/Panel-style items with tracked stock, this
  // atomically decrements availability via the `adjust_item_stock` RPC
  // so concurrent staff can't oversell the same stock.
  Future<List<Map<String, dynamic>>> fetchBookingItems(String bookingId) async {
    final rows = await _client
        .from('booking_items')
        .select('*, items(title, category, quantity_available)')
        .eq('booking_id', bookingId);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> addBookingItem({
    required String bookingId,
    required String itemId,
    required bool tracksStock,
    int quantity = 1,
    double? price,
    String? notes,
  }) async {
    await _client.from('booking_items').insert({
      'booking_id': bookingId,
      'item_id': itemId,
      'quantity': quantity,
      'price': price,
      'notes': notes,
    });
    if (tracksStock) {
      await _client.rpc('adjust_item_stock', params: {'p_item_id': itemId, 'p_delta': -quantity});
    }
  }

  Future<void> removeBookingItem({
    required String bookingItemId,
    required String itemId,
    required bool tracksStock,
    required int quantity,
  }) async {
    await _client.from('booking_items').delete().eq('id', bookingItemId);
    if (tracksStock) {
      await _client.rpc('adjust_item_stock', params: {'p_item_id': itemId, 'p_delta': quantity});
    }
  }

  Future<void> setGoogleEventId(String bookingId, String eventId) async {
    await _client.from('bookings').update({'google_event_id': eventId}).eq('id', bookingId);
  }

  // ---- Notes (with optional attached photo) ----
  Future<List<Map<String, dynamic>>> fetchNotes(String bookingId) async {
    final rows = await _client
        .from('notes')
        .select()
        .eq('booking_id', bookingId)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> addNote({required String bookingId, required String content, String? imageUrl}) async {
    await _client.from('notes').insert({
      'booking_id': bookingId,
      'content': content,
      'image_url': imageUrl,
    });
  }

  Future<void> deleteNote(String noteId) async {
    await _client.from('notes').delete().eq('id', noteId);
  }

  // ---- Dashboard drill-down ----
  // Powers the clickable dashboard stat cards — same underlying query
  // the KPI counts are based on, so clicking a number shows exactly the
  // bookings behind it.
  Future<List<BookingModel>> fetchByDashboardFilter(String filter) async {
    final now = DateTime.now();
    switch (filter) {
      case 'today':
        return fetchAll(from: DateTime(now.year, now.month, now.day), to: DateTime(now.year, now.month, now.day));
      case 'month':
        return fetchAll(from: DateTime(now.year, now.month, 1), to: DateTime(now.year, now.month + 1, 0));
      case 'pending':
        final rows = await _client
            .from('bookings')
            .select(_bookingSelect)
            .inFilter('booking_status', ['new_inquiry', 'quotation_sent']).order('wedding_date');
        return (rows as List).map((r) => BookingModel.fromMap(r)).toList();
      case 'completed':
        return fetchAll(statusFilter: 'completed');
      case 'outstanding':
        final all = await fetchAll();
        return all.where((b) => b.outstanding > 0).toList();
      default:
        return fetchAll();
    }
  }

  // ---- Dashboard aggregates ----
  Future<Map<String, dynamic>> dashboardStats() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1)
        .toIso8601String()
        .split('T')
        .first;

    final todays = await _client.from('bookings').select('id').eq('wedding_date', today);
    final thisMonth = await _client
        .from('bookings')
        .select('id')
        .gte('wedding_date', monthStart);
    final pending = await _client
        .from('bookings')
        .select('id')
        .inFilter('booking_status', ['new_inquiry', 'quotation_sent']);
    final completed = await _client
        .from('bookings')
        .select('id')
        .eq('booking_status', 'completed');
    final outstanding = await _client
        .from('bookings')
        .select('total_amount, deposit_paid')
        .neq('booking_status', 'cancelled');

    double outstandingTotal = 0;
    for (final r in (outstanding as List)) {
      final total = (r['total_amount'] as num?)?.toDouble() ?? 0;
      final paid = (r['deposit_paid'] as num?)?.toDouble() ?? 0;
      outstandingTotal += (total - paid).clamp(0, double.infinity);
    }

    return {
      'todayCount': (todays as List).length,
      'monthCount': (thisMonth as List).length,
      'pendingCount': (pending as List).length,
      'completedCount': (completed as List).length,
      'outstandingTotal': outstandingTotal,
    };
  }
}
