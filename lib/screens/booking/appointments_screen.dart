import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../../services/booking_service.dart';
import '../../config/theme.dart';

/// Appointment management (spec section 5). Types: fitting, pickup,
/// return, pelamin setup/discussion, wedding day, meeting, reminder,
/// other. New appointments show up immediately on the Booking Calendar
/// screen since it reads straight from the same `appointments` table.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _service = BookingService();
  List<AppointmentModel> _appointments = [];
  bool _loading = true;

  static const _types = [
    'fitting_baju', 'pickup_baju', 'return_baju', 'pelamin_setup',
    'pelamin_discussion', 'wedding_day', 'meeting_customer', 'payment_reminder', 'other',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _service.fetchAppointments(from: DateTime.now().subtract(const Duration(days: 1)));
      setState(() => _appointments = rows);
    } catch (_) {
      setState(() => _appointments = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    String type = _types.first;
    DateTime date = DateTime.now();
    TimeOfDay time = TimeOfDay.now();
    final notesCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSB) => AlertDialog(
          title: const Text('New Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [for (final t in _types) DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))],
                  onChanged: (v) => setSB(() => type = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('${date.toLocal()}'.split(' ').first),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) setSB(() => date = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(time.format(context)),
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: time);
                          if (picked != null) setSB(() => time = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
                const SizedBox(height: 12),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (ok == true) {
      final hh = time.hour.toString().padLeft(2, '0');
      final mm = time.minute.toString().padLeft(2, '0');
      await _service.createAppointment(AppointmentModel(
        appointmentType: type,
        appointmentDate: date,
        appointmentTime: '$hh:$mm',
        location: locationCtrl.text.trim(),
        notes: notesCtrl.text.trim(),
      ));
      _load(); // reload here; the Booking Calendar screen re-fetches on its own next visit
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
              const Text('Appointments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('New Appointment')),
            ],
          ),
          const SizedBox(height: 4),
          Text('New appointments appear on the Booking Calendar automatically.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_appointments.isEmpty)
            Padding(padding: const EdgeInsets.all(40), child: Text('No upcoming appointments.', style: TextStyle(color: Colors.grey[600])))
          else
            Card(
              child: Column(
                children: [
                  for (final a in _appointments)
                    ListTile(
                      leading: const Icon(Icons.schedule, color: AppColors.gold),
                      title: Text(a.appointmentType.replaceAll('_', ' ')),
                      subtitle: Text('${a.appointmentDate.toLocal().toString().split(' ').first} at ${a.appointmentTime}${a.location != null && a.location!.isNotEmpty ? ' · ${a.location}' : ''}'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
