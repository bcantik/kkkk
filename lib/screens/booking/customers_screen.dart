import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../services/booking_service.dart';

/// Customer database (spec section 9).
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _service = BookingService();
  List<CustomerModel> _customers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final rows = await _service.fetchCustomers(search: q);
      setState(() => _customers = rows);
    } catch (_) {
      setState(() => _customers = []);
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
          const Text('Customers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            width: 320,
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search by name or phone', prefixIcon: Icon(Icons.search), isDense: true),
              onChanged: _search,
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_customers.isEmpty)
            Padding(padding: const EdgeInsets.all(40), child: Text('No customers yet.', style: TextStyle(color: Colors.grey[600])))
          else
            Card(
              child: Column(
                children: [
                  for (final c in _customers)
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(c.fullName),
                      subtitle: Text(c.phone ?? '—'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
