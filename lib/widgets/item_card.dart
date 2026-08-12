import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/item_model.dart';
import '../config/theme.dart';

/// One card renders every category's item — image, title, and whichever
/// of price / size / description / availability that category declares
/// (see CategoriesConfig). [editable] shows edit/delete affordances only
/// for staff — public visitors get a clean read-only card (view-only,
/// per spec: "user cannot edit, add or delete").
class ItemCard extends StatelessWidget {
  final ItemModel item;
  final bool editable;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final bool showAvailability;
  final bool? isAvailable; // for baju pengantin boolean availability

  const ItemCard({
    super.key,
    required this.item,
    this.editable = false,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.showAvailability = false,
    this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (c, _) => const ColoredBox(
                            color: AppColors.softGrey,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (c, _, __) => const ColoredBox(
                            color: AppColors.softGrey,
                            child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                          ),
                        )
                      : const ColoredBox(
                          color: AppColors.softGrey,
                          child: Icon(Icons.photo_camera_back_outlined, size: 40, color: Colors.grey),
                        ),
                  if (editable)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Row(
                        children: [
                          _iconBtn(Icons.edit, onEdit),
                          const SizedBox(width: 6),
                          _iconBtn(Icons.delete, onDelete, danger: true),
                        ],
                      ),
                    ),
                  if (showAvailability && isAvailable != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _AvailabilityChip(available: isAvailable!),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (item.subcategory != null)
                    Text(item.subcategory!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (item.price != null)
                        Text('RM ${item.price!.toStringAsFixed(0)}',
                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                      if (item.sizeFeet != null) Text('${item.sizeFeet!.toStringAsFixed(0)} kaki'),
                      if (item.sizeInch != null) Text('${item.sizeInch!.toStringAsFixed(0)} inci'),
                    ],
                  ),
                  if (item.description != null && item.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  if (item.quantityAvailable != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Available: ${item.quantityAvailable}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.quantityAvailable! > 0 ? Colors.green[700] : Colors.red,
                        ),
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

  Widget _iconBtn(IconData icon, VoidCallback? onTap, {bool danger = false}) => InkWell(
        onTap: onTap,
        child: CircleAvatar(
          radius: 15,
          backgroundColor: Colors.white,
          child: Icon(icon, size: 15, color: danger ? Colors.red : AppColors.black),
        ),
      );
}

class _AvailabilityChip extends StatelessWidget {
  final bool available;
  const _AvailabilityChip({required this.available});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: available ? Colors.green[600] : Colors.red[600],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        available ? 'Available' : 'Not Available',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
