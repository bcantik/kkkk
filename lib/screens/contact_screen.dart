import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/top_bar.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';

/// Public Contact page. Staff (logged in) see an Edit button so they can
/// update phone/address/hours/socials — content is stored as JSON in
/// `site_content` so no redeploy is needed to change contact details.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  Map<String, dynamic> _content = {
    'phone': '+60 12-345 6789',
    'whatsapp': '+60 12-345 6789',
    'email': 'info@kkkk.my',
    'address': 'Kuala Kangsar, Perak, Malaysia',
    'hours': 'Isnin - Ahad, 9:00 AM - 6:00 PM',
  };
  bool _editing = false;
  AppRole _role = AppRole.guest;
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {for (final k in _content.keys) k: TextEditingController(text: _content[k])};
    AuthService().currentRole().then((r) => setState(() => _role = r));
    _load();
  }

  Future<void> _load() async {
    try {
      final row = await Supabase.instance.client
          .from('site_content')
          .select()
          .eq('key', 'contact_page')
          .maybeSingle();
      if (row != null && row['content'] != null) {
        setState(() {
          _content = Map<String, dynamic>.from(row['content']);
          _controllers = {for (final k in _content.keys) k: TextEditingController(text: _content[k])};
        });
      }
    } catch (_) {
      // Supabase not configured yet — show default placeholder content.
    }
  }

  Future<void> _save() async {
    final updated = {for (final k in _controllers.keys) k: _controllers[k]!.text};
    await Supabase.instance.client.from('site_content').upsert({
      'key': 'contact_page',
      'content': updated,
    });
    setState(() {
      _content = updated;
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = _role == AppRole.staff || _role == AppRole.admin;
    return Scaffold(
      appBar: KKKKTopBar(isStaffLoggedIn: _role != AppRole.guest),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hubungi Kami', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        if (isStaff)
                          IconButton(
                            icon: Icon(_editing ? Icons.close : Icons.edit),
                            onPressed: () => setState(() => _editing = !_editing),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_editing)
                      ..._controllers.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              controller: e.value,
                              decoration: InputDecoration(labelText: e.key),
                            ),
                          ))
                    else
                      ..._content.entries.map((e) => _ContactRow(label: e.key, value: e.value.toString())),
                    if (_editing)
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(onPressed: _save, child: const Text('Save')),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String label;
  final String value;
  const _ContactRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label[0].toUpperCase() + label.substring(1),
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
