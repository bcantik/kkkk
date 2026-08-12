import 'package:flutter/material.dart';
import '../../services/booking_service.dart';
import '../../config/theme.dart';
import '../../widgets/responsive_layout.dart';

/// Reports (spec section 13). Shows the key monthly figures on-screen;
/// PDF/Excel/CSV export uses the `pdf`, `printing` and `csv` packages
/// already declared in pubspec.yaml — wire the export button to your
/// preferred report layout once real data is flowing.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _service = BookingService();
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await _service.dashboardStats();
      setState(() => _stats = stats);
    } catch (_) {
      setState(() => _stats = {});
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf_outlined, size: 16), label: const Text('PDF')),
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.table_chart_outlined, size: 16), label: const Text('Excel')),
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.description_outlined, size: 16), label: const Text('CSV')),
              ]),
            ],
          ),
          const SizedBox(height: 20),
          ResponsiveGrid(
            maxTileWidth: 220,
            childAspectRatio: 1.3,
            children: [
              _ReportCard('Bookings This Month', '${_stats['monthCount'] ?? 0}'),
              _ReportCard('Pending Bookings', '${_stats['pendingCount'] ?? 0}'),
              _ReportCard('Completed Bookings', '${_stats['completedCount'] ?? 0}'),
              _ReportCard('Outstanding Payments', 'RM ${(_stats['outstandingTotal'] ?? 0).toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label, value;
  const _ReportCard(this.label, this.value);
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.gold)),
              const Spacer(),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      );
}
