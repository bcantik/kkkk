import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xl;
import 'package:share_plus/share_plus.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../config/theme.dart';
import '../../widgets/responsive_layout.dart';
import 'booking_details_screen.dart';

/// Reports (spec section 13) — real, working PDF/Excel/CSV exports of
/// the current booking list, and every summary card is clickable to
/// drill into the underlying bookings.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _service = BookingService();
  Map<String, dynamic> _stats = {};
  List<BookingModel> _allBookings = [];
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await _service.dashboardStats();
      final bookings = await _service.fetchAll();
      setState(() {
        _stats = stats;
        _allBookings = bookings;
      });
    } catch (_) {
      setState(() {
        _stats = {};
        _allBookings = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  List<List<String>> _tableRows() {
    return [
      ['Customer', 'Wedding Date', 'Event Type', 'Venue', 'Booking Status', 'Payment Status', 'Total (RM)', 'Paid (RM)', 'Outstanding (RM)'],
      for (final b in _allBookings)
        [
          b.customerName,
          b.weddingDate.toLocal().toString().split(' ').first,
          b.eventType,
          b.venueText ?? '',
          b.bookingStatus,
          b.paymentStatus,
          b.totalAmount.toStringAsFixed(2),
          b.depositPaid.toStringAsFixed(2),
          b.outstanding.toStringAsFixed(2),
        ],
    ];
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final rows = _tableRows();
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.Text('KERJA KAHWIN KUALA KANGSAR — Booking Report',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Generated ${DateTime.now().toLocal().toString().split('.').first}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: rows.first,
              data: rows.skip(1).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8D48A)),
            ),
          ],
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => doc.save());
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final csv = const ListToCsvConverter().convert(_tableRows());
      final bytes = Uint8List.fromList(csv.codeUnits);
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: 'kkkk_booking_report.csv', mimeType: 'text/csv')],
        subject: 'KKKK Booking Report (CSV)',
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final workbook = xl.Excel.createExcel();
      final sheet = workbook['Bookings'];
      for (final row in _tableRows()) {
        sheet.appendRow(row.map((c) => xl.TextCellValue(c)).toList());
      }
      workbook.delete('Sheet1');
      final bytes = workbook.encode();
      if (bytes != null) {
        await Share.shareXFiles(
          [XFile.fromData(Uint8List.fromList(bytes), name: 'kkkk_booking_report.xlsx', mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          subject: 'KKKK Booking Report (Excel)',
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _openFilteredList(String title, List<BookingModel> bookings) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: bookings.isEmpty
                      ? Center(child: Text('No bookings.', style: TextStyle(color: Colors.grey[600])))
                      : ListView(
                          children: [
                            for (final b in bookings)
                              ListTile(
                                title: Text(b.customerName.isEmpty ? 'Booking' : b.customerName),
                                subtitle: Text('${b.weddingDate.toLocal().toString().split(' ').first} · ${b.eventType}'),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final now = DateTime.now();
    final monthBookings = _allBookings.where((b) => b.weddingDate.year == now.year && b.weddingDate.month == now.month).toList();
    final pendingBookings = _allBookings.where((b) => b.bookingStatus == 'new_inquiry' || b.bookingStatus == 'quotation_sent').toList();
    final completedBookings = _allBookings.where((b) => b.bookingStatus == 'completed').toList();
    final outstandingBookings = _allBookings.where((b) => b.outstanding > 0).toList();
    final upcomingBookings = _allBookings.where((b) => b.weddingDate.isAfter(now)).toList();

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
                OutlinedButton.icon(
                  onPressed: _exporting ? null : _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: _exporting ? null : _exportExcel,
                  icon: const Icon(Icons.table_chart_outlined, size: 16),
                  label: const Text('Excel'),
                ),
                OutlinedButton.icon(
                  onPressed: _exporting ? null : _exportCsv,
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text('CSV'),
                ),
              ]),
            ],
          ),
          if (_exporting) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
          const SizedBox(height: 4),
          Text('Exports include every booking currently in the system. Tap a card below to see its bookings.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 20),
          ResponsiveGrid(
            maxTileWidth: 220,
            childAspectRatio: 1.3,
            children: [
              _ReportCard('Bookings This Month', '${monthBookings.length}', onTap: () => _openFilteredList('Bookings This Month', monthBookings)),
              _ReportCard('Pending Bookings', '${pendingBookings.length}', onTap: () => _openFilteredList('Pending Bookings', pendingBookings)),
              _ReportCard('Completed Bookings', '${completedBookings.length}', onTap: () => _openFilteredList('Completed Bookings', completedBookings)),
              _ReportCard('Upcoming Weddings', '${upcomingBookings.length}', onTap: () => _openFilteredList('Upcoming Weddings', upcomingBookings)),
              _ReportCard('Outstanding Payments', 'RM ${(_stats['outstandingTotal'] ?? 0).toStringAsFixed(0)}', onTap: () => _openFilteredList('Outstanding Payments', outstandingBookings)),
              _ReportCard('Total Bookings', '${_allBookings.length}', onTap: () => _openFilteredList('All Bookings', _allBookings)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _ReportCard(this.label, this.value, {required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
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
        ),
      );
}
