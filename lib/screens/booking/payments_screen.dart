import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../config/theme.dart';

/// Payment overview across all bookings (spec section 10) — shows
/// overdue/outstanding balances clearly for staff follow-up.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _service = BookingService();
  List<BookingModel> _bookings = [];
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
      rows.sort((a, b) => b.outstanding.compareTo(a.outstanding));
      setState(() => _bookings = rows);
    } catch (_) {
      setState(() => _bookings = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_bookings.isEmpty)
            Padding(padding: const EdgeInsets.all(40), child: Text('No bookings yet.', style: TextStyle(color: Colors.grey[600])))
          else
            Card(
              child: Column(
                children: [
                  for (final b in _bookings)
                    ListTile(
                      title: Text(b.customerName.isEmpty ? 'Booking' : b.customerName),
                      subtitle: Text('Total RM ${b.totalAmount.toStringAsFixed(0)} · Paid RM ${b.depositPaid.toStringAsFixed(0)}'),
                      trailing: Text(
                        'RM ${b.outstanding.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: b.outstanding > 0 ? Colors.red : AppColors.eventWedding,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
