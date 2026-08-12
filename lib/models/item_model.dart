class ItemModel {
  final String? id;
  final String pageKey;
  final String category;
  final String? subcategory;
  final String title;
  final String? description;
  final double? price;
  final double? sizeFeet;
  final double? sizeInch;
  final String? imageUrl;
  final int? quantityTotal;
  final int? quantityAvailable;
  final bool isActive;

  ItemModel({
    this.id,
    required this.pageKey,
    required this.category,
    this.subcategory,
    required this.title,
    this.description,
    this.price,
    this.sizeFeet,
    this.sizeInch,
    this.imageUrl,
    this.quantityTotal,
    this.quantityAvailable,
    this.isActive = true,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map) => ItemModel(
        id: map['id'] as String?,
        pageKey: map['page_key'] as String,
        category: map['category'] as String,
        subcategory: map['subcategory'] as String?,
        title: map['title'] as String,
        description: map['description'] as String?,
        price: (map['price'] as num?)?.toDouble(),
        sizeFeet: (map['size_feet'] as num?)?.toDouble(),
        sizeInch: (map['size_inch'] as num?)?.toDouble(),
        imageUrl: map['image_url'] as String?,
        quantityTotal: map['quantity_total'] as int?,
        quantityAvailable: map['quantity_available'] as int?,
        isActive: map['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'page_key': pageKey,
        'category': category,
        'subcategory': subcategory,
        'title': title,
        'description': description,
        'price': price,
        'size_feet': sizeFeet,
        'size_inch': sizeInch,
        'image_url': imageUrl,
        'quantity_total': quantityTotal,
        'quantity_available': quantityAvailable,
        'is_active': isActive,
      };

  ItemModel copyWith({String? imageUrl}) => ItemModel(
        id: id,
        pageKey: pageKey,
        category: category,
        subcategory: subcategory,
        title: title,
        description: description,
        price: price,
        sizeFeet: sizeFeet,
        sizeInch: sizeInch,
        imageUrl: imageUrl ?? this.imageUrl,
        quantityTotal: quantityTotal,
        quantityAvailable: quantityAvailable,
        isActive: isActive,
      );
}
