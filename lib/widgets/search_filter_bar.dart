import 'package:flutter/material.dart';

class ItemFilters {
  final String query;
  final double? minPrice;
  final double? minSize; // "From Size" — items with size >= this value
  ItemFilters({this.query = '', this.minPrice, this.minSize});
}

/// Search bar + "From Size" / "From Price" filter used by Koleksi Pelamin
/// and Koleksi Baju Pengantin, per spec: filters must support a
/// "from size" style (>=) rather than an exact match.
class SearchFilterBar extends StatefulWidget {
  final bool showSizeFilter;
  final String sizeLabel;
  final ValueChanged<ItemFilters> onChanged;
  const SearchFilterBar({
    super.key,
    required this.onChanged,
    this.showSizeFilter = false,
    this.sizeLabel = 'Size',
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final _queryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();

  void _emit() {
    widget.onChanged(ItemFilters(
      query: _queryCtrl.text.trim(),
      minPrice: double.tryParse(_priceCtrl.text.trim()),
      minSize: double.tryParse(_sizeCtrl.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _queryCtrl,
            onChanged: (_) => _emit(),
            decoration: const InputDecoration(
              hintText: 'Search...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          width: 170,
          child: TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _emit(),
            decoration: const InputDecoration(
              hintText: 'From price (RM)',
              prefixIcon: Icon(Icons.attach_money),
              isDense: true,
            ),
          ),
        ),
        if (widget.showSizeFilter)
          SizedBox(
            width: 170,
            child: TextField(
              controller: _sizeCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => _emit(),
              decoration: InputDecoration(
                hintText: 'From ${widget.sizeLabel}',
                prefixIcon: const Icon(Icons.straighten),
                isDense: true,
              ),
            ),
          ),
      ],
    );
  }
}
