import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/booking_model.dart';
import '../../models/item_model.dart';
import '../../services/booking_service.dart';
import '../../services/item_service.dart';
import '../../config/categories_config.dart';
import '../../config/theme.dart';
import 'booking_form_screen.dart';

/// Full booking profile (spec section 4) — customer, wedding info,
/// package, payment summary with progress bar, notes, and payment history.
class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final _service = BookingService();
  BookingModel? _booking;
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _bookingItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final row = await Supabase.instance.client
        .from('bookings')
        .select('*, customers(full_name, phone), items:package_item_id(title)')
        .eq('id', widget.bookingId)
        .single();
    final payments = await _service.paymentHistory(widget.bookingId);
    final bookingItems = await _service.fetchBookingItems(widget.bookingId);
    setState(() {
      _booking = BookingModel.fromMap(row);
      _payments = payments;
      _bookingItems = bookingItems;
      _loading = false;
    });
  }

  Future<void> _openAddItemPicker() async {
    final b = _booking!;
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _AddOnPickerDialog(bookingId: b.id!, weddingDate: b.weddingDate),
    );
    if (added == true) _load();
  }

  Future<void> _removeBookingItem(Map<String, dynamic> bi) async {
    final item = bi['items'] as Map<String, dynamic>?;
    final category = item?['category'] as String?;
    final tracksStock = category == 'Kerusi' || category == 'Panel';
    await _service.removeBookingItem(
      bookingItemId: bi['id'],
      itemId: bi['item_id'],
      tracksStock: tracksStock,
      quantity: (bi['quantity'] as int?) ?? 1,
    );
    _load();
  }

  Future<void> _addPayment() async {
    final amountCtrl = TextEditingController();
    String type = 'second_payment';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSB) => AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'deposit', child: Text('Deposit')),
                  DropdownMenuItem(value: 'second_payment', child: Text('Second payment')),
                  DropdownMenuItem(value: 'final_payment', child: Text('Final payment')),
                  DropdownMenuItem(value: 'additional_charge', child: Text('Additional charge')),
                  DropdownMenuItem(value: 'refund', child: Text('Refund')),
                ],
                onChanged: (v) => setSB(() => type = v!),
              ),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (RM)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (result == true && amountCtrl.text.isNotEmpty) {
      await _service.recordPayment(
        bookingId: widget.bookingId,
        paymentType: type,
        amount: double.tryParse(amountCtrl.text) ?? 0,
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _booking == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final b = _booking!;
    return Scaffold(
      appBar: AppBar(
        title: Text(b.customerName.isEmpty ? 'Booking' : b.customerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final saved = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => BookingFormScreen(existing: b)),
              );
              if (saved == true) _load();
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Row('Customer', b.customerName),
                      _Row('Phone', b.customerPhone ?? '—'),
                      _Row('Wedding Date', b.weddingDate.toLocal().toString().split(' ').first),
                      _Row('Event Type', b.eventType),
                      _Row('Venue', b.venueText ?? '—'),
                      _Row('Bride / Groom', '${b.brideName ?? '—'} & ${b.groomName ?? '—'}'),
                      _Row('Theme / Color', '${b.weddingTheme ?? '—'} · ${b.weddingColor ?? '—'}'),
                      _Row('Booking Status', b.bookingStatus.replaceAll('_', ' ')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      _Row('Total Package', 'RM ${b.totalAmount.toStringAsFixed(2)}'),
                      _Row('Deposit Required', 'RM ${b.depositRequired.toStringAsFixed(2)}'),
                      _Row('Paid', 'RM ${b.depositPaid.toStringAsFixed(2)}'),
                      _Row('Outstanding', 'RM ${b.outstanding.toStringAsFixed(2)}',
                          color: b.outstanding > 0 ? Colors.red : Colors.green),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: b.paymentProgress,
                          minHeight: 10,
                          backgroundColor: AppColors.softGrey,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _addPayment,
                        icon: const Icon(Icons.add),
                        label: const Text('Record Payment'),
                      ),
                      if (_payments.isNotEmpty) ...[
                        const Divider(height: 28),
                        const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold)),
                        for (final p in _payments)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${p['payment_type']} — RM ${p['amount']}'),
                            subtitle: Text('${p['payment_date']}'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Add-ons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          OutlinedButton.icon(
                            onPressed: _openAddItemPicker,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Item'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_bookingItems.isEmpty)
                        Text('No add-ons linked yet.', style: TextStyle(color: Colors.grey[600]))
                      else
                        for (final bi in _bookingItems)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.inventory_2_outlined, color: AppColors.gold),
                            title: Text(bi['items']?['title'] ?? 'Item'),
                            subtitle: Text('${bi['items']?['category'] ?? ''} · Qty ${bi['quantity']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeBookingItem(bi),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (b.notes != null && b.notes!.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(b.notes!),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lets staff attach a catalogue item (pelamin, barang, baju pengantin,
/// katering...) to this booking. For Baju Pengantin it checks the
/// ±2-week availability rule before allowing the add; for Kerusi/Panel
/// it shows remaining stock and blocks adding past zero.
class _AddOnPickerDialog extends StatefulWidget {
  final String bookingId;
  final DateTime weddingDate;
  const _AddOnPickerDialog({required this.bookingId, required this.weddingDate});

  @override
  State<_AddOnPickerDialog> createState() => _AddOnPickerDialogState();
}

class _AddOnPickerDialogState extends State<_AddOnPickerDialog> {
  final _itemService = ItemService();
  final _bookingService = BookingService();
  String _pageKey = CategoriesConfig.barangPelamin.pageKey;
  List<ItemModel> _items = [];
  bool _loading = true;
  final Map<String, bool> _availabilityCache = {};

  static const _pages = [
    CategoriesConfig.barangPelamin,
    CategoriesConfig.koleksiPelamin,
    CategoriesConfig.koleksiBaju,
    CategoriesConfig.pakejPerkahwinan,
    CategoriesConfig.lamanDahlia,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _itemService.fetchByPage(_pageKey);
    setState(() {
      _items = items;
      _loading = false;
    });
    if (_pageKey == CategoriesConfig.koleksiBaju.pageKey) {
      for (final item in items) {
        if (item.id == null) continue;
        final available = await _itemService.isBajuAvailable(item.id!, widget.weddingDate);
        if (mounted) setState(() => _availabilityCache[item.id!] = available);
      }
    }
  }

  Future<void> _addItem(ItemModel item) async {
    final tracksStock = item.category == 'Kerusi' || item.category == 'Panel';
    if (tracksStock && (item.quantityAvailable ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Out of stock.')));
      return;
    }
    if (_pageKey == CategoriesConfig.koleksiBaju.pageKey && _availabilityCache[item.id] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This item is already booked within 2 weeks of this date.')),
      );
      return;
    }
    await _bookingService.addBookingItem(
      bookingId: widget.bookingId,
      itemId: item.id!,
      tracksStock: tracksStock,
      price: item.price,
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Item to Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _pageKey,
                decoration: const InputDecoration(labelText: 'Category page'),
                items: [for (final p in _pages) DropdownMenuItem(value: p.pageKey, child: Text(p.title))],
                onChanged: (v) {
                  setState(() => _pageKey = v!);
                  _load();
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          for (final item in _items)
                            ListTile(
                              title: Text(item.title),
                              subtitle: Text([
                                item.category,
                                if (item.price != null) 'RM ${item.price!.toStringAsFixed(0)}',
                                if (item.quantityAvailable != null) 'Stock: ${item.quantityAvailable}',
                              ].join(' · ')),
                              trailing: _pageKey == CategoriesConfig.koleksiBaju.pageKey &&
                                      _availabilityCache.containsKey(item.id)
                                  ? _AvailBadge(available: _availabilityCache[item.id]!)
                                  : IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: AppColors.gold),
                                      onPressed: () => _addItem(item),
                                    ),
                              onTap: _pageKey == CategoriesConfig.koleksiBaju.pageKey
                                  ? () => _addItem(item)
                                  : null,
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

class _AvailBadge extends StatelessWidget {
  final bool available;
  const _AvailBadge({required this.available});
  @override
  Widget build(BuildContext context) => Chip(
        label: Text(available ? 'Available' : 'Booked', style: const TextStyle(fontSize: 11, color: Colors.white)),
        backgroundColor: available ? Colors.green : Colors.red,
      );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Row(this.label, this.value, {this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 150, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
            Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color))),
          ],
        ),
      );
}
