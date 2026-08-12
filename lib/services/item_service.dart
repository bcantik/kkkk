import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item_model.dart';

/// Generic CRUD service for the `items` table — backs every public
/// display-card page (Pakej Perkahwinan, Pelamin, Baju Pengantin,
/// Barang Pelamin, Laman Dahlia). One service, driven by page_key.
class ItemService {
  final _client = Supabase.instance.client;

  Future<List<ItemModel>> fetchByPage(String pageKey, {String? category}) async {
    var query = _client.from('items').select().eq('page_key', pageKey);
    if (category != null) query = query.eq('category', category);
    final rows = await query.order('created_at');
    return (rows as List).map((r) => ItemModel.fromMap(r)).toList();
  }

  Stream<List<ItemModel>> watchByPage(String pageKey) {
    return _client
        .from('items')
        .stream(primaryKey: ['id'])
        .eq('page_key', pageKey)
        .order('created_at')
        .map((rows) => rows.map((r) => ItemModel.fromMap(r)).toList());
  }

  Future<ItemModel> create(ItemModel item) async {
    final row = await _client.from('items').insert(item.toMap()).select().single();
    return ItemModel.fromMap(row);
  }

  Future<ItemModel> update(String id, ItemModel item) async {
    final row = await _client.from('items').update(item.toMap()).eq('id', id).select().single();
    return ItemModel.fromMap(row);
  }

  Future<void> delete(String id) async {
    await _client.from('items').delete().eq('id', id);
  }

  /// Used for Baju Pengantin availability: item is unavailable if it has a
  /// dress_rental whose booking wedding_date is within ±2 weeks of [date].
  Future<bool> isBajuAvailable(String itemId, DateTime date) async {
    final from = date.subtract(const Duration(days: 14)).toIso8601String().split('T').first;
    final to = date.add(const Duration(days: 14)).toIso8601String().split('T').first;
    final rows = await _client
        .from('dress_rentals')
        .select('id, bookings!inner(wedding_date)')
        .eq('item_id', itemId)
        .gte('bookings.wedding_date', from)
        .lte('bookings.wedding_date', to);
    return (rows as List).isEmpty;
  }
}
