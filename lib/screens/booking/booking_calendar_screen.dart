import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/booking_service.dart';
import '../../models/booking_model.dart';
import '../../models/appointment_model.dart';
import '../../config/theme.dart';
import 'booking_form_screen.dart';
import 'booking_details_screen.dart';

/// One calendar entry — wraps either a booking or an appointment so both
/// can share the same day-marker logic and color rules.
class _CalEntry {
  final bool isAppointment;
  final BookingModel? booking;
  final AppointmentModel? appointment;
  _CalEntry.booking(this.booking)
      : isAppointment = false,
        appointment = null;
  _CalEntry.appointment(this.appointment)
      : isAppointment = true,
        booking = null;

  DateTime get date => isAppointment ? appointment!.appointmentDate : booking!.weddingDate;

  Color get color {
    if (isAppointment) {
      switch (appointment!.appointmentType) {
        case 'fitting_baju':
        case 'pickup_baju':
        case 'return_baju':
          return AppColors.eventFitting;
        case 'pelamin_setup':
        case 'pelamin_discussion':
          return AppColors.eventPelamin;
        case 'wedding_day':
          return AppColors.eventWedding;
        case 'payment_reminder':
          return AppColors.eventPayment;
        case 'meeting_customer':
          return AppColors.eventMeeting;
        default:
          return AppColors.eventOther;
      }
    }
    switch (booking!.eventType) {
      case 'tunang':
        return AppColors.eventTunang;
      case 'nikah':
        return AppColors.eventNikah;
      case 'sanding':
        return AppColors.eventSanding;
      case 'aqiqah':
        return AppColors.eventAqiqah;
      default:
        return AppColors.eventMajlisLain;
    }
  }

  String get title => isAppointment
      ? '${appointment!.appointmentTime} · ${appointment!.appointmentType.replaceAll('_', ' ')}'
      : (booking!.customerName.isEmpty ? 'Booking' : booking!.customerName);

  String get subtitle => isAppointment
      ? appointment!.customerName
      : '${booking!.eventType} · ${booking!.venueText ?? ''}';
}

/// Google-Calendar-style booking calendar (spec section 2 & 14).
/// Month / 2-Weeks / Week toggle, a "Today" jump, a full date/month/year
/// picker, and both bookings (colored by event type) and appointments
/// (colored by appointment type) plotted together.
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
  Map<DateTime, List<_CalEntry>> _events = {};
  bool _loading = true;
  bool _todayOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _load();
  }

  DateTime _d(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final from = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final to = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);
      final bookings = await _service.fetchAll(from: from, to: to);
      final appointments = await _service.fetchAppointments(from: from, to: to);
      final map = <DateTime, List<_CalEntry>>{};
      for (final b in bookings) {
        map.putIfAbsent(_d(b.weddingDate), () => []).add(_CalEntry.booking(b));
      }
      for (final a in appointments) {
        map.putIfAbsent(_d(a.appointmentDate), () => []).add(_CalEntry.appointment(a));
      }
      setState(() => _events = map);
    } catch (_) {
      setState(() => _events = {});
    } finally {
      setState(() => _loading = false);
    }
  }

  List<_CalEntry> _entriesFor(DateTime day) => _events[_d(day)] ?? [];

  Future<void> _jumpToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Jump to date',
    );
    if (picked != null) {
      setState(() {
        _focusedDay = picked;
        _selectedDay = picked;
        _todayOnly = false;
      });
      _load();
    }
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _focusedDay = now;
      _selectedDay = now;
      _todayOnly = !_todayOnly;
    });
  }

  void _openDaySheet(DateTime selected) {
    if (widget.viewOnly) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DaySheet(
        day: selected,
        entries: _entriesFor(selected),
        onCreate: () async {
          Navigator.pop(context);
          final saved = await Navigator.of(context)
              .push<bool>(MaterialPageRoute(builder: (_) => BookingFormScreen(initialDate: selected)));
          if (saved == true) _load();
        },
        onOpen: (entry) {
          Navigator.pop(context);
          if (!entry.isAppointment) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => BookingDetailsScreen(bookingId: entry.booking!.id!)))
                .then((_) => _load());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final visibleDay = _todayOnly ? now : (_selectedDay ?? now);
    final visibleEntries = _entriesFor(visibleDay);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Booking Calendar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _jumpToDate,
                    icon: const Icon(Icons.event, size: 16),
                    label: const Text('Jump to Date'),
                  ),
                  FilterChip(
                    label: const Text("Today's Bookings"),
                    selected: _todayOnly,
                    onSelected: (_) => _goToday(),
                    selectedColor: AppColors.gold,
                  ),
                ],
              ),
            ],
          ),
          if (widget.viewOnly)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('View only', style: TextStyle(color: Colors.grey[600])),
            ),
          const SizedBox(height: 12),
          // Explicit, reliably-wired Month / 2 Weeks / Week toggle.
          SegmentedButton<CalendarFormat>(
            segments: const [
              ButtonSegment(value: CalendarFormat.month, label: Text('Month')),
              ButtonSegment(value: CalendarFormat.twoWeeks, label: Text('2 Weeks')),
              ButtonSegment(value: CalendarFormat.week, label: Text('Week')),
            ],
            selected: {_format},
            onSelectionChanged: (s) => setState(() => _format = s.first),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TableCalendar<_CalEntry>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _format,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                  CalendarFormat.twoWeeks: '2 Weeks',
                  CalendarFormat.week: 'Week',
                },
                headerStyle: const HeaderStyle(formatButtonVisible: false),
                selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                eventLoader: _entriesFor,
                onFormatChanged: (f) => setState(() => _format = f),
                onPageChanged: (d) {
                  _focusedDay = d;
                  _load();
                },
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                    _todayOnly = false;
                  });
                  _openDaySheet(selected);
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
                          for (final e in events.take(4))
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: e.color, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendDot(color: AppColors.eventTunang, label: 'Tunang'),
              _LegendDot(color: AppColors.eventNikah, label: 'Nikah'),
              _LegendDot(color: AppColors.eventSanding, label: 'Sanding'),
              _LegendDot(color: AppColors.eventAqiqah, label: 'Aqiqah'),
              _LegendDot(color: AppColors.eventMajlisLain, label: 'Majlis Lain'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _todayOnly
                ? "Today's Bookings & Appointments"
                : 'On ${visibleDay.toLocal().toString().split(' ').first}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (visibleEntries.isEmpty)
            Text('Nothing scheduled.', style: TextStyle(color: Colors.grey[600]))
          else
            for (final e in visibleEntries)
              Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: e.color),
                  title: Text(e.title),
                  subtitle: Text(e.subtitle),
                  onTap: e.isAppointment
                      ? null
                      : () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => BookingDetailsScreen(bookingId: e.booking!.id!)))
                          .then((_) => _load()),
                ),
              ),
        ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}

class _DaySheet extends StatelessWidget {
  final DateTime day;
  final List<_CalEntry> entries;
  final VoidCallback onCreate;
  final void Function(_CalEntry) onOpen;
  const _DaySheet({required this.day, required this.entries, required this.onCreate, required this.onOpen});

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
            for (final e in entries)
              ListTile(
                leading: CircleAvatar(backgroundColor: e.color),
                title: Text(e.title),
                subtitle: Text(e.subtitle),
                onTap: () => onOpen(e),
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
