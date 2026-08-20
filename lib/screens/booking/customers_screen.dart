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

  Future<void> _deleteCustomer(CustomerModel customer) async {
    if (customer.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text(
          'Delete ${customer.fullName}? Existing bookings and appointments will be kept, but unlinked from this customer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteCustomer(customer.id!);
      await _search('');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${customer.fullName} was deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete customer: $e')),
        );
      }
    }
  }

  Future<void> _editCustomer(CustomerModel customer) async {
    if (customer.id == null) return;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: customer.fullName);
    final phoneCtrl = TextEditingController(text: customer.phone ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Full name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'No. Tel'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Save changes'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    try {
      await _service.updateCustomer(
        customer.id!,
        CustomerModel(
          fullName: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          email: customer.email,
          icNumber: customer.icNumber,
          address: customer.address,
          emergencyContact: customer.emergencyContact,
        ),
      );
      await _search('');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${nameCtrl.text.trim()} was updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update customer: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
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
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Edit customer',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editCustomer(c),
                          ),
                          IconButton(
                            tooltip: 'Delete customer',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteCustomer(c),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
        ),
      ),
    );
  }
}
