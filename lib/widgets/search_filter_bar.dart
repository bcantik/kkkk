import 'package:flutter/material.dart';

enum SizeFilterTarget { both, male, female }

class ItemFilters {
  final String query;
  final double? price;
  final double? sizeMin; // Minimum size for range filtering
  final double? sizeMax; // Maximum size for range filtering
  final SizeFilterTarget sizeTarget;
  ItemFilters(
      {this.query = '',
      this.price,
      this.sizeMin,
      this.sizeMax,
      this.sizeTarget = SizeFilterTarget.both});
}

/// Search bar + "Size" / "Price" filter used by Koleksi Pelamin
/// and Koleksi Baju Pengantin. Price and size filtering are exact matches.
class SearchFilterBar extends StatefulWidget {
  final bool showSizeFilter;
  final bool showSizeTarget;
  final String sizeLabel;
  final ValueChanged<ItemFilters> onChanged;
  const SearchFilterBar({
    super.key,
    required this.onChanged,
    this.showSizeFilter = false,
    this.showSizeTarget = false,
    this.sizeLabel = 'Size',
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final _queryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _sizeMinCtrl = TextEditingController();
  final _sizeMaxCtrl = TextEditingController();
  SizeFilterTarget _sizeTarget = SizeFilterTarget.both;

  void _emit() {
    widget.onChanged(ItemFilters(
      query: _queryCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()),
      sizeMin: double.tryParse(_sizeMinCtrl.text.trim()),
      sizeMax: double.tryParse(_sizeMaxCtrl.text.trim()),
      sizeTarget: _sizeTarget,
    ));
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _priceCtrl.dispose();
    _sizeMinCtrl.dispose();
    _sizeMaxCtrl.dispose();
    super.dispose();
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
              hintText: 'Price (RM)',
              prefixText: 'RM ',
              isDense: true,
            ),
          ),
        ),
        if (widget.showSizeFilter)
          SizedBox(
            width: 340,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sizeMinCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _emit(),
                    decoration: InputDecoration(
                      hintText: '${widget.sizeLabel} min',
                      prefixIcon: const Icon(Icons.minimize),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _sizeMaxCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _emit(),
                    decoration: InputDecoration(
                      hintText: '${widget.sizeLabel} max',
                      prefixIcon: const Icon(Icons.add),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (widget.showSizeFilter && widget.showSizeTarget)
          SizedBox(
            width: 260,
            child: ToggleButtons(
              isSelected: [
                _sizeTarget == SizeFilterTarget.male,
                _sizeTarget == SizeFilterTarget.female,
                _sizeTarget == SizeFilterTarget.both,
              ],
              onPressed: (index) {
                setState(() {
                  _sizeTarget = SizeFilterTarget.values[index];
                });
                _emit();
              },
              borderRadius: BorderRadius.circular(6),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('M&F',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('M',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('F',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
