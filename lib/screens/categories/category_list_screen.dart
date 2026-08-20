import 'package:flutter/material.dart';
import '../../config/categories_config.dart';
import '../../models/item_model.dart';
import '../../services/item_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/item_card.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../config/theme.dart';
import 'item_form_screen.dart';

/// ONE screen implementation drives every public display-card page:
/// Pakej Perkahwinan, Koleksi Pelamin, Koleksi Baju Pengantin,
/// Barang Pelamin, Laman Dahlia. Which categories/fields/filters it
/// shows comes entirely from [PageConfig] (see categories_config.dart).
///
/// Public visitors: view-only, no login needed.
/// Staff: same screen gains Add/Edit/Delete affordances automatically.
class CategoryListScreen extends StatefulWidget {
  final String pageKey;
  const CategoryListScreen({super.key, required this.pageKey});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final _service = ItemService();
  late PageConfig _config;
  List<ItemModel> _allItems = [];
  ItemFilters _filters = ItemFilters();
  AppRole _role = AppRole.guest;
  bool _loading = true;
  String? _activeCategory;

  @override
  void initState() {
    super.initState();
    _config = CategoriesConfig.byKey(widget.pageKey);
    _activeCategory = _config.sections.first.category;
    AuthService().currentRole().then((r) => setState(() => _role = r));
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.fetchByPage(widget.pageKey);
      setState(() => _allItems = items);
    } catch (e) {
      // Supabase likely not configured yet — show empty state gracefully.
      setState(() => _allItems = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  List<ItemModel> get _filtered {
    var list = _allItems.where((i) => i.category == _activeCategory).toList();
    if (_filters.query.isNotEmpty) {
      final q = _filters.query.toLowerCase();
      list = list.where((i) {
        return i.title.toLowerCase().contains(q) ||
            (i.description ?? '').toLowerCase().contains(q) ||
            (i.subcategory ?? '').toLowerCase().contains(q) ||
            i.category.toLowerCase().contains(q);
      }).toList();
    }
    if (_filters.price != null) {
      list = list.where((i) => (i.price ?? 0) == _filters.price!).toList();
    }
    if (_filters.sizeMin != null || _filters.sizeMax != null) {
      final min = _filters.sizeMin;
      final max = _filters.sizeMax;
      list = list.where((i) {
        bool matchesRange(double v) {
          if (min != null && v < min) return false;
          if (max != null && v > max) return false;
          return true;
        }

        // Prefer explicit feet value when present (pages with sizeFeet).
        if (i.sizeFeet != null) {
          return matchesRange(i.sizeFeet!);
        }

        switch (_filters.sizeTarget) {
          case SizeFilterTarget.male:
            return i.sizeMaleInch != null && matchesRange(i.sizeMaleInch!);
          case SizeFilterTarget.female:
            return i.sizeFemaleInch != null && matchesRange(i.sizeFemaleInch!);
          case SizeFilterTarget.both:
            final maleOk =
                i.sizeMaleInch != null && matchesRange(i.sizeMaleInch!);
            final femaleOk =
                i.sizeFemaleInch != null && matchesRange(i.sizeFemaleInch!);
            return maleOk || femaleOk;
        }
      }).toList();
    }
    return list;
  }

  bool get _isStaff => _role == AppRole.staff || _role == AppRole.admin;

  Future<void> _openForm({ItemModel? existing}) async {
    final section =
        _config.sections.firstWhere((s) => s.category == _activeCategory);
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ItemFormDialog(
          pageKey: widget.pageKey, section: section, existing: existing),
    );
    if (result == true) _load();
  }

  Future<void> _delete(ItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.title}" permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true && item.id != null) {
      await _service.delete(item.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final section =
        _config.sections.firstWhere((s) => s.category == _activeCategory);
    return Scaffold(
      appBar: KKKKTopBar(isStaffLoggedIn: _role != AppRole.guest),
      floatingActionButton: _isStaff
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: ContentBounds(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_config.title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${_filtered.length} items',
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                // Category chips (subsections within the page)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _config.sections)
                      ChoiceChip(
                        label: Text(s.category),
                        selected: _activeCategory == s.category,
                        selectedColor: AppColors.gold,
                        onSelected: (_) =>
                            setState(() => _activeCategory = s.category),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_config.hasSearch)
                  SearchFilterBar(
                    showSizeFilter: _config.hasFilter &&
                        (section.hasSizeFeet || section.hasSizeMaleFemaleInch),
                    showSizeTarget: section.hasSizeMaleFemaleInch,
                    sizeLabel:
                        section.hasSizeFeet ? 'Size (feet)' : 'Size (inch)',
                    onChanged: (f) => setState(() => _filters = f),
                  ),
                const SizedBox(height: 20),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('No items yet',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  )
                else
                  ResponsiveGrid(
                    children: [
                      for (final item in _filtered)
                        ItemCard(
                          item: item,
                          editable: _isStaff,
                          showAvailability: section.hasAvailabilityCount,
                          onEdit: () => _openForm(existing: item),
                          onDelete: () => _delete(item),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
