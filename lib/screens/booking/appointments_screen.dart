import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../../services/booking_service.dart';
import '../../config/theme.dart';

/// Appointment management (spec section 5). Types: fitting, pickup,
/// return, pelamin setup/discussion, wedding day, meeting, reminder, other.
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
    final dateCtrl = ValueNotifier<DateTime>(DateTime.now());
    final timeCtrl = TextEditingController(text: '09:00');
    final notesCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSB) => AlertDialog(
          title: const Text('New Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [for (final t in _types) DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))],
                  onChanged: (v) => setSB(() => type = v!),
                ),
                const SizedBox(height: 8),
                TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Time (HH:mm)')),
                const SizedBox(height: 8),
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
      await _service.createAppointment(AppointmentModel(
        appointmentType: type,
        appointmentDate: dateCtrl.value,
        appointmentTime: timeCtrl.text,
        notes: notesCtrl.text,
      ));
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
              const Text('Appointments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('New Appointment')),
            ],
          ),
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
                      subtitle: Text('${a.appointmentDate.toLocal().toString().split(' ').first} at ${a.appointmentTime}'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
