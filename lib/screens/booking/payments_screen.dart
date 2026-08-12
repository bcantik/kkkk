import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import 'booking_details_screen.dart';

/// Payment overview across all bookings (spec section 10) — shows
/// overdue/outstanding balances clearly for staff follow-up. Bookings
/// with nothing left owing drop off this list automatically (they still
/// live in Bookings / Reports, just not here — this view is for
/// "what still needs collecting").
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _service = BookingService();
  List<BookingModel> _all = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _service.fetchAll();
      // Auto-remove fully paid / no-outstanding bookings from this view.
      final withBalance = rows.where((b) => b.outstanding > 0.005).toList();
      withBalance.sort((a, b) => b.outstanding.compareTo(a.outstanding));
      setState(() => _all = withBalance);
    } catch (_) {
      setState(() => _all = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  List<BookingModel> get _filtered => _query.isEmpty
      ? _all
      : _all.where((b) => b.customerName.toLowerCase().contains(_query.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Bookings with an outstanding balance. Fully paid bookings are hidden automatically.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            width: 300,
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search customer', prefixIcon: Icon(Icons.search), isDense: true),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_filtered.isEmpty)
            Padding(padding: const EdgeInsets.all(40), child: Text('No outstanding payments 🎉', style: TextStyle(color: Colors.grey[600])))
          else
            Card(
              child: Column(
                children: [
                  for (final b in _filtered)
                    ListTile(
                      title: Text(b.customerName.isEmpty ? 'Booking' : b.customerName),
                      subtitle: Text('Total RM ${b.totalAmount.toStringAsFixed(0)} · Paid RM ${b.depositPaid.toStringAsFixed(0)}'),
                      trailing: Text(
                        'RM ${b.outstanding.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
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
