import 'package:flutter/material.dart';
import '../../config/categories_config.dart';
import '../../models/item_model.dart';
import '../../services/item_service.dart';
import '../../widgets/image_upload_widget.dart';

/// Generic Add/Edit dialog — one form implementation shows only the
/// fields a given [ItemSection] declares (price / size feet / size inch
/// / description / stock quantity), so every one of the ~50 categories
/// in the spec gets a correctly-shaped CRUD form for free.
class ItemFormDialog extends StatefulWidget {
  final String pageKey;
  final ItemSection section;
  final ItemModel? existing;
  const ItemFormDialog({super.key, required this.pageKey, required this.section, this.existing});

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = ItemService();
  late TextEditingController _title;
  late TextEditingController _description;
  late TextEditingController _price;
  late TextEditingController _size;
  late TextEditingController _quantity;
  String? _subcategory;
  String? _imageUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _price = TextEditingController(text: e?.price?.toString() ?? '');
    _size = TextEditingController(text: (e?.sizeFeet ?? e?.sizeInch)?.toString() ?? '');
    _quantity = TextEditingController(text: e?.quantityTotal?.toString() ?? '');
    _subcategory = e?.subcategory ?? widget.section.subcategories.firstOrNull;
    _imageUrl = e?.imageUrl;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final qty = int.tryParse(_quantity.text.trim());
    final item = ItemModel(
      id: widget.existing?.id,
      pageKey: widget.pageKey,
      category: widget.section.category,
      subcategory: _subcategory,
      title: _title.text.trim(),
      description: widget.section.hasDescription ? _description.text.trim() : null,
      price: widget.section.hasPrice ? double.tryParse(_price.text.trim()) : null,
      sizeFeet: widget.section.hasSizeFeet ? double.tryParse(_size.text.trim()) : null,
      sizeInch: widget.section.hasSizeInch ? double.tryParse(_size.text.trim()) : null,
      imageUrl: _imageUrl,
      quantityTotal: widget.section.hasAvailabilityCount ? qty : null,
      quantityAvailable: widget.section.hasAvailabilityCount ? qty : null,
    );
    try {
      if (widget.existing?.id != null) {
        await _service.update(widget.existing!.id!, item);
      } else {
        await _service.create(item);
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

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.existing == null ? 'Add ${section.category}' : 'Edit ${section.category}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ImageUploadWidget(
                    initialUrl: _imageUrl,
                    folder: widget.pageKey,
                    onUploaded: (url) => setState(() => _imageUrl = url),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  if (section.subcategories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _subcategory,
                      decoration: const InputDecoration(labelText: 'Subcategory'),
                      items: [
                        for (final s in section.subcategories) DropdownMenuItem(value: s, child: Text(s))
                      ],
                      onChanged: (v) => setState(() => _subcategory = v),
                    ),
                  ],
                  if (section.hasPrice) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (RM)'),
                    ),
                  ],
                  if (section.hasSizeFeet || section.hasSizeInch) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _size,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: section.hasSizeFeet ? 'Size (feet)' : 'Size (inch)',
                      ),
                    ),
                  ],
                  if (section.hasAvailabilityCount) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantity,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity available'),
                    ),
                  ],
                  if (section.hasDescription) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
