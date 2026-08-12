import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/booking_service.dart';
import '../../models/booking_model.dart';
import '../../config/theme.dart';
import 'booking_form_screen.dart';
import 'booking_details_screen.dart';

/// Google-Calendar-style booking calendar (spec section 2 & 14).
/// Month view with colored event dots; tap a date to create a booking,
/// tap an event to open its full details. Public "view" of this same
/// data (view-only, no create/edit) is reachable from the staff top bar
/// per spec ("calendar will show all booking, view only").
class BookingCalendarScreen extends StatefulWidget {
  final bool viewOnly;
  const BookingCalendarScreen({super.key, this.viewOnly = false});

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  final _service = BookingService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _format = CalendarFormat.month;
  Map<DateTime, List<BookingModel>> _events = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final bookings = await _service.fetchAll(
        from: DateTime(_focusedDay.year, _focusedDay.month - 1, 1),
        to: DateTime(_focusedDay.year, _focusedDay.month + 2, 0),
      );
      final map = <DateTime, List<BookingModel>>{};
      for (final b in bookings) {
        final key = DateTime(b.weddingDate.year, b.weddingDate.month, b.weddingDate.day);
        map.putIfAbsent(key, () => []).add(b);
      }
      setState(() => _events = map);
    } catch (_) {
      setState(() => _events = {});
    } finally {
      setState(() => _loading = false);
    }
  }

  List<BookingModel> _eventsFor(DateTime day) =>
      _events[DateTime(day.year, day.month, day.day)] ?? [];

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
      case 'wedding_completed':
        return AppColors.eventWedding;
      case 'deposit_paid':
      case 'booking_confirmed':
        return AppColors.eventFitting;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppColors.eventPayment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selectedDay != null ? _eventsFor(_selectedDay!) : <BookingModel>[];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking Calendar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          if (widget.viewOnly)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('View only', style: TextStyle(color: Colors.grey[600])),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TableCalendar<BookingModel>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _format,
                selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                eventLoader: _eventsFor,
                onFormatChanged: (f) => setState(() => _format = f),
                onPageChanged: (d) {
                  _focusedDay = d;
                  _load();
                },
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                  if (!widget.viewOnly) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _DaySheet(
                        day: selected,
                        bookings: _eventsFor(selected),
                        onCreate: () async {
                          Navigator.pop(context);
                          final saved = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => BookingFormScreen(initialDate: selected)),
                          );
                          if (saved == true) _load();
                        },
                        onOpen: (b) {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => BookingDetailsScreen(bookingId: b.id!)),
                          );
                        },
                      ),
                    );
                  }
                },
                calendarStyle: const CalendarStyle(
                  markerDecoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: AppColors.softGrey, shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: AppColors.black, shape: BoxShape.circle),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    return Positioned(
                      bottom: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final e in events.take(3))
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: _statusColor(e.bookingStatus), shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedDay != null) ...[
            Text(
              'Bookings on ${_selectedDay!.toLocal().toString().split(' ').first}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final b in selectedEvents)
              Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: _statusColor(b.bookingStatus)),
                  title: Text(b.customerName.isEmpty ? 'Booking' : b.customerName),
                  subtitle: Text('${b.eventType} · ${b.venueText ?? ''} · ${b.paymentStatus}'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BookingDetailsScreen(bookingId: b.id!)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DaySheet extends StatelessWidget {
  final DateTime day;
  final List<BookingModel> bookings;
  final VoidCallback onCreate;
  final void Function(BookingModel) onOpen;
  const _DaySheet({required this.day, required this.bookings, required this.onCreate, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(day.toLocal().toString().split(' ').first,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final b in bookings)
              ListTile(
                title: Text(b.customerName.isEmpty ? 'Booking' : b.customerName),
                subtitle: Text(b.eventType),
                onTap: () => onOpen(b),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('New Booking on this date'),
            ),
          ],
        ),
      ),
    );
  }
}
