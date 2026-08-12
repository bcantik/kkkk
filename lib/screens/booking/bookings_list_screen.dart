import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../config/theme.dart';
import 'booking_form_screen.dart';
import 'booking_details_screen.dart';

/// Booking list with search/filter (spec section 12).
class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});
  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  final _service = BookingService();
  List<BookingModel> _all = [];
  String _query = '';
  String? _statusFilter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _service.fetchAll(statusFilter: _statusFilter);
      setState(() => _all = rows);
    } catch (_) {
      setState(() => _all = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  List<BookingModel> get _filtered => _query.isEmpty
      ? _all
      : _all.where((b) =>
          b.customerName.toLowerCase().contains(_query.toLowerCase()) ||
          (b.venueText ?? '').toLowerCase().contains(_query.toLowerCase())).toList();

  static const _statuses = [
    'new_inquiry', 'quotation_sent', 'booking_confirmed', 'deposit_paid',
    'preparation', 'wedding_completed', 'completed', 'cancelled',
  ];

  Future<void> _quickDelete(BookingModel b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete booking?'),
        content: Text('Remove the booking for "${b.customerName}" permanently? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && b.id != null) {
      await _service.delete(b.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bookings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () async {
                  final saved = await Navigator.of(context)
                      .push<bool>(MaterialPageRoute(builder: (_) => const BookingFormScreen()));
                  if (saved == true) _load();
                },
                icon: const Icon(Icons.add),
                label: const Text('New Booking'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Search customer or venue', prefixIcon: Icon(Icons.search), isDense: true),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(labelText: 'Status', isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All statuses')),
                    for (final s in _statuses) DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '))),
                  ],
                  onChanged: (v) {
                    setState(() => _statusFilter = v);
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_filtered.isEmpty)
            Padding(padding: const EdgeInsets.all(40), child: Text('No bookings found.', style: TextStyle(color: Colors.grey[600])))
          else
            Card(
              child: Column(
                children: [
                  for (final b in _filtered)
                    ListTile(
                      title: Text(b.customerName.isEmpty ? 'Booking' : b.customerName),
                      subtitle: Text('${b.weddingDate.toLocal().toString().split(' ').first} · ${b.eventType} · ${b.venueText ?? ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(b.bookingStatus.replaceAll('_', ' '), style: const TextStyle(fontSize: 11)),
                            backgroundColor: AppColors.softGrey,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _quickDelete(b),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => BookingDetailsScreen(bookingId: b.id!)))
                          .then((_) => _load()),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
