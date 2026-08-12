import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../models/customer_model.dart';
import '../../services/booking_service.dart';
import '../../services/google_calendar_service.dart';
import '../../config/theme.dart';

/// Create/Edit Booking form (spec section 3) — customer, wedding info,
/// package, payment. Checks for date conflicts before saving (section 19).
class BookingFormScreen extends StatefulWidget {
  final DateTime? initialDate;
  final BookingModel? existing;
  const BookingFormScreen({super.key, this.initialDate, this.existing});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = BookingService();
  late DateTime _date;
  String _eventType = 'nikah';
  String _bookingStatus = 'new_inquiry';
  String _paymentStatus = 'unpaid';

  final _customerName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _venue = TextEditingController();
  final _guests = TextEditingController();
  final _bride = TextEditingController();
  final _groom = TextEditingController();
  final _theme = TextEditingController();
  final _color = TextEditingController();
  final _packagePrice = TextEditingController();
  final _additional = TextEditingController(text: '0');
  final _discount = TextEditingController(text: '0');
  final _depositRequired = TextEditingController(text: '0');
  final _notes = TextEditingController();
  bool _saving = false;
  bool _checkingConflict = false;
  String? _conflictWarning;
  bool _syncToGoogle = false;
  bool _syncToPhoneCalendar = false;
  final _googleCalendar = GoogleCalendarService();

  static const _eventTypes = ['tunang', 'nikah', 'sanding', 'aqiqah', 'majlis_lain'];
  static const _bookingStatuses = [
    'new_inquiry', 'quotation_sent', 'booking_confirmed', 'deposit_paid',
    'preparation', 'wedding_completed', 'completed', 'cancelled',
  ];
  static const _paymentStatuses = ['unpaid', 'deposit_paid', 'partially_paid', 'fully_paid', 'overdue'];

  bool get _supportsPhoneCalendar {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  }

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.weddingDate ?? widget.initialDate ?? DateTime.now();
    _syncToPhoneCalendar = _supportsPhoneCalendar;
    final e = widget.existing;
    if (e != null) {
      _customerName.text = e.customerName;
      _phone.text = e.customerPhone ?? '';
      _venue.text = e.venueText ?? '';
      _guests.text = e.expectedGuests?.toString() ?? '';
      _bride.text = e.brideName ?? '';
      _groom.text = e.groomName ?? '';
      _theme.text = e.weddingTheme ?? '';
      _color.text = e.weddingColor ?? '';
      _packagePrice.text = e.packagePrice?.toString() ?? '';
      _additional.text = e.additionalCharges.toString();
      _discount.text = e.discount.toString();
      _depositRequired.text = e.depositRequired.toString();
      _notes.text = e.notes ?? '';
      _eventType = e.eventType;
      _bookingStatus = e.bookingStatus;
      _paymentStatus = e.paymentStatus;
    }
    _checkConflict();
  }

  Future<void> _checkConflict() async {
    setState(() => _checkingConflict = true);
    try {
      final conflict = await _service.hasDateConflict(_date, excludeBookingId: widget.existing?.id);
      setState(() => _conflictWarning =
          conflict ? '⚠️ This date already has a booking. Double-check the venue before confirming.' : null);
    } catch (_) {
      setState(() => _conflictWarning = null);
    } finally {
      setState(() => _checkingConflict = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _checkConflict();
    }
  }

  Future<String?> _resolveCustomerId() async {
    if (_customerName.text.trim().isEmpty) return null;
    final created = await _service.createCustomer(CustomerModel(
      fullName: _customerName.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
    ));
    return created.id;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final customerId = widget.existing?.customerId ?? await _resolveCustomerId();
      final booking = BookingModel(
        customerId: customerId,
        weddingDate: _date,
        eventType: _eventType,
        venueText: _venue.text.trim(),
        expectedGuests: int.tryParse(_guests.text.trim()),
        brideName: _bride.text.trim(),
        groomName: _groom.text.trim(),
        weddingTheme: _theme.text.trim(),
        weddingColor: _color.text.trim(),
        packagePrice: double.tryParse(_packagePrice.text.trim()),
        additionalCharges: double.tryParse(_additional.text.trim()) ?? 0,
        discount: double.tryParse(_discount.text.trim()) ?? 0,
        depositRequired: double.tryParse(_depositRequired.text.trim()) ?? 0,
        depositPaid: widget.existing?.depositPaid ?? 0,
        paymentStatus: _paymentStatus,
        bookingStatus: _bookingStatus,
        notes: _notes.text.trim(),
        googleEventId: widget.existing?.googleEventId,
      );
      final BookingModel saved;
      if (widget.existing?.id != null) {
        saved = await _service.update(widget.existing!.id!, booking);
      } else {
        saved = await _service.create(booking);
      }

      if (_syncToGoogle && saved.id != null) {
        try {
          final connected = _googleCalendar.isConnected || await _googleCalendar.connect();
          if (connected) {
            final eventId = await _googleCalendar.upsertBookingEvent(
              existingEventId: saved.googleEventId,
              title: '${saved.eventType.toUpperCase()} — ${_customerName.text.trim()}',
              date: _date,
              description: 'Venue: ${_venue.text.trim()}\nGuests: ${_guests.text.trim()}\nNotes: ${_notes.text.trim()}',
              location: _venue.text.trim(),
            );
            if (eventId != null) await _service.setGoogleEventId(saved.id!, eventId);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Booking saved, but Google Calendar sync failed: $e')),
            );
          }
        }
      }

      if (_syncToPhoneCalendar && saved.id != null) {
        try {
          await _saveToPhoneCalendar(
            title: '${saved.eventType.toUpperCase()} — ${_customerName.text.trim()}',
            date: _date,
            description: 'Venue: ${_venue.text.trim()}\nGuests: ${_guests.text.trim()}\nNotes: ${_notes.text.trim()}',
            location: _venue.text.trim(),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Booking saved, but phone calendar sync failed: $e')),
            );
          }
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveToPhoneCalendar({
    required String title,
    required DateTime date,
    required String description,
    String? location,
  }) async {
    final event = Event(
      title: title,
      description: description,
      location: location,
      startDate: DateTime(date.year, date.month, date.day),
      endDate: DateTime(date.year, date.month, date.day + 1),
      allDay: true,
    );
    await Add2Calendar.addEvent2Cal(event);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'New Booking' : 'Edit Booking')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_conflictWarning != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_conflictWarning!, style: const TextStyle(color: Colors.deepOrange)),
                  ),
                const _SectionLabel('Customer Information'),
                TextFormField(
                  controller: _customerName,
                  decoration: const InputDecoration(labelText: 'Customer name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone number'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'))),
                ]),
                const SizedBox(height: 24),
                const _SectionLabel('Wedding Information'),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text('${_date.toLocal()}'.split(' ').first),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _eventType,
                      decoration: const InputDecoration(labelText: 'Event type'),
                      items: [for (final t in _eventTypes) DropdownMenuItem(value: t, child: Text(t))],
                      onChanged: (v) => setState(() => _eventType = v!),
                    ),
                  ),
                ]),
                if (_checkingConflict) const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 12),
                TextFormField(controller: _venue, decoration: const InputDecoration(labelText: 'Venue')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(controller: _bride, decoration: const InputDecoration(labelText: 'Bride name'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _groom, decoration: const InputDecoration(labelText: 'Groom name'))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(controller: _guests, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Expected guests'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _theme, decoration: const InputDecoration(labelText: 'Wedding theme'))),
                ]),
                const SizedBox(height: 12),
                TextFormField(controller: _color, decoration: const InputDecoration(labelText: 'Wedding color')),
                const SizedBox(height: 24),
                const _SectionLabel('Package & Payment'),
                Row(children: [
                  Expanded(child: TextFormField(controller: _packagePrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Package price (RM)'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _additional, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Additional charges (RM)'))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(controller: _discount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount (RM)'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _depositRequired, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Deposit required (RM)'))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _paymentStatus,
                      decoration: const InputDecoration(labelText: 'Payment status'),
                      items: [for (final s in _paymentStatuses) DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' ')))],
                      onChanged: (v) => setState(() => _paymentStatus = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _bookingStatus,
                      decoration: const InputDecoration(labelText: 'Booking status'),
                      items: [for (final s in _bookingStatuses) DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' ')))],
                      onChanged: (v) => setState(() => _bookingStatus = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                const _SectionLabel('Notes'),
                TextFormField(controller: _notes, maxLines: 4, decoration: const InputDecoration(labelText: 'Detailed notes')),
                const SizedBox(height: 12),
                if (_supportsPhoneCalendar)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _syncToPhoneCalendar,
                    onChanged: (v) => setState(() => _syncToPhoneCalendar = v ?? false),
                    title: const Text('Save booking to phone calendar'),
                    subtitle: const Text('No Google sign-in required'),
                  ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _syncToGoogle,
                  onChanged: (v) => setState(() => _syncToGoogle = v ?? false),
                  title: const Text('Sync this booking to Google Calendar'),
                  subtitle: const Text('You may be asked to sign in to Google when saving'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldLight))
                      : Text(widget.existing == null ? 'Create Booking' : 'Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold, fontSize: 15)),
      );
}
