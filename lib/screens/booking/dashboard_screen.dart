import 'package:flutter/material.dart';
import '../../services/booking_service.dart';
import '../../models/appointment_model.dart';
import '../../models/booking_model.dart';
import '../../config/theme.dart';
import '../../widgets/responsive_layout.dart';
import 'booking_details_screen.dart';

/// Staff dashboard — today's schedule, KPIs and notifications
/// (spec section 1). Every KPI card is clickable and opens the list of
/// bookings behind that number (today / this month / pending /
/// completed / outstanding).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = BookingService();
  Map<String, dynamic> _stats = {};
  List<AppointmentModel> _today = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final stats = await _service.dashboardStats();
      final today = await _service.fetchAppointments(
        from: DateTime(now.year, now.month, now.day),
        to: DateTime(now.year, now.month, now.day),
      );
      setState(() {
        _stats = stats;
        _today = today;
      });
    } catch (_) {
      setState(() {
        _stats = {};
        _today = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _colorFor(String type) {
    switch (type) {
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

  Future<void> _openFilter(String filter, String title) async {
    showDialog(
      context: context,
      builder: (_) => _FilteredBookingsDialog(filter: filter, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Tap any card to see the bookings behind it.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 16),
            ResponsiveGrid(
              maxTileWidth: 220,
              childAspectRatio: 1.3,
              children: [
                _StatCard(
                  label: "Today's Bookings",
                  value: '${_stats['todayCount'] ?? 0}',
                  icon: Icons.today,
                  onTap: () => _openFilter('today', "Today's Bookings"),
                ),
                _StatCard(
                  label: 'This Month',
                  value: '${_stats['monthCount'] ?? 0}',
                  icon: Icons.calendar_month,
                  onTap: () => _openFilter('month', "This Month's Bookings"),
                ),
                _StatCard(
                  label: 'Pending',
                  value: '${_stats['pendingCount'] ?? 0}',
                  icon: Icons.hourglass_empty,
                  onTap: () => _openFilter('pending', 'Pending Bookings'),
                ),
                _StatCard(
                  label: 'Completed',
                  value: '${_stats['completedCount'] ?? 0}',
                  icon: Icons.check_circle_outline,
                  onTap: () => _openFilter('completed', 'Completed Bookings'),
                ),
                _StatCard(
                  label: 'Outstanding Payments',
                  value: 'RM ${(_stats['outstandingTotal'] ?? 0).toStringAsFixed(0)}',
                  icon: Icons.payments_outlined,
                  highlight: true,
                  onTap: () => _openFilter('outstanding', 'Outstanding Payments'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text("Today's Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_today.isEmpty)
              Text('No appointments scheduled for today.', style: TextStyle(color: Colors.grey[600]))
            else
              Card(
                child: Column(
                  children: [
                    for (final a in _today)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _colorFor(a.appointmentType),
                          child: const Icon(Icons.event, color: Colors.white, size: 18),
                        ),
                        title: Text('${a.appointmentTime} — ${a.appointmentType.replaceAll('_', ' ')}'),
                        subtitle: Text(a.customerName.isEmpty ? '—' : a.customerName),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  final VoidCallback? onTap;
  const _StatCard({required this.label, required this.value, required this.icon, this.highlight = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight ? AppColors.black : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: highlight ? AppColors.gold : AppColors.black),
              const Spacer(),
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: highlight ? Colors.white : Colors.black)),
              Text(label,
                  style: TextStyle(fontSize: 12, color: highlight ? Colors.white70 : Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilteredBookingsDialog extends StatefulWidget {
  final String filter;
  final String title;
  const _FilteredBookingsDialog({required this.filter, required this.title});

  @override
  State<_FilteredBookingsDialog> createState() => _FilteredBookingsDialogState();
}

class _FilteredBookingsDialogState extends State<_FilteredBookingsDialog> {
  final _service = BookingService();
  List<BookingModel> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _service.fetchByDashboardFilter(widget.filter);
    if (mounted) {
      setState(() {
      _bookings = rows;
      _loading = false;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _bookings.isEmpty
                        ? Center(child: Text('No bookings match this filter.', style: TextStyle(color: Colors.grey[600])))
                        : ListView(
                            children: [
                              for (final b in _bookings)
                                ListTile(
                                  title: Text(b.customerName.isEmpty ? 'Booking' : b.customerName),
                                  subtitle: Text(
                                      '${b.weddingDate.toLocal().toString().split(' ').first} · ${b.eventType} · RM ${b.outstanding.toStringAsFixed(0)} outstanding'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => BookingDetailsScreen(bookingId: b.id!)),
                                    );
                                  },
                                ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
