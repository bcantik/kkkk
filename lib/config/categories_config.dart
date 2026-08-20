/// =====================================================================
/// CATEGORY CONFIGURATION
/// This file is what makes the generic CRUD engine cover every single
/// category from the spec without hand-writing 50 near-identical screens.
/// Each `ItemSection` maps 1:1 to an `items.category` value in Supabase,
/// and declares which fields that category needs (price / size / desc /
/// availability) plus its subcategories (used as filter chips + a
/// dropdown when adding/editing an item).
/// =====================================================================
library;

class ItemSection {
  final String category; // matches items.category in DB
  final List<String> subcategories; // optional preset subcategory choices
  final bool hasPrice;
  final bool hasSizeFeet;
  final bool hasSizeMaleFemaleInch; // separate Size Male (inch) / Size Female (inch)
  final bool hasDescription;
  final bool hasAvailabilityCount; // e.g. Kerusi / Panel: "available: 3"
  final bool hasBooleanAvailability; // e.g. Baju: available / not available (date-based)

  const ItemSection({
    required this.category,
    this.subcategories = const [],
    this.hasPrice = false,
    this.hasSizeFeet = false,
    this.hasSizeMaleFemaleInch = false,
    this.hasDescription = false,
    this.hasAvailabilityCount = false,
    this.hasBooleanAvailability = false,
  });
}

class PageConfig {
  final String pageKey;
  final String title;
  final List<ItemSection> sections;
  final bool hasSearch;
  final bool hasFilter;
  const PageConfig({
    required this.pageKey,
    required this.title,
    required this.sections,
    // Search + "from price / from size" filtering is now standard on
    // every catalogue page.
    this.hasSearch = true,
    this.hasFilter = true,
  });
}

class CategoriesConfig {
  // ---------------------------------------------------------------
  // 1. PAKEJ PERKAHWINAN
  // ---------------------------------------------------------------
  static const pakejPerkahwinan = PageConfig(
    pageKey: 'pakej_perkahwinan',
    title: 'Pakej Perkahwinan',
    sections: [
      ItemSection(category: 'Pakej Dewan', subcategories: ['Lengkap', 'Dewan A', 'Dewan B', 'Dewan C'], hasPrice: true, hasDescription: true),
      ItemSection(category: 'Pakej Rumah', subcategories: ['Lengkap', 'Rumah A', 'Rumah B'], hasPrice: true, hasDescription: true),
      ItemSection(category: 'Pakej Tunang', hasPrice: true, hasDescription: true),
      ItemSection(category: 'Pakej Khemah', hasPrice: true, hasDescription: true),
      ItemSection(category: 'Pakej Katering', subcategories: ['Basic (RM11)', 'Premium (RM13)', 'Nasi Mamak'], hasPrice: true, hasDescription: true),
      ItemSection(category: 'Set Khemah', subcategories: ['Khemah Pengantin', 'Khemah Piramid'], hasPrice: true, hasDescription: true),
      ItemSection(category: 'Set Meja Nikah', subcategories: ['Meja dan Kerusi', 'Meja dan Alas Nikah'], hasPrice: true, hasDescription: true),
      ItemSection(category: 'Set Candy Wall', subcategories: ['Sweet Basic', 'Sweet Classic', 'Sweet Deluxe'], hasPrice: true, hasDescription: true),
      ItemSection(category: 'Set Dewan IPD', hasPrice: true, hasDescription: true),
      ItemSection(category: 'MUA', subcategories: ['Tunang', 'Nikah', 'Sanding'], hasPrice: true, hasDescription: true),
      ItemSection(category: 'Cake', hasPrice: true, hasDescription: true),
      ItemSection(category: 'Henna', hasPrice: true, hasDescription: true),
    ],
  );

  // ---------------------------------------------------------------
  // 2. KOLEKSI PELAMIN  (search + filter: title, price, size feet — "From Size")
  // ---------------------------------------------------------------
  static const koleksiPelamin = PageConfig(
    pageKey: 'pelamin',
    title: 'Koleksi Pelamin',
    sections: [
      ItemSection(category: 'Pelamin Dewan', hasPrice: true, hasSizeFeet: true),
      ItemSection(category: 'Pelamin Khemah', hasPrice: true, hasSizeFeet: true),
      ItemSection(category: 'Pelamin Rumah', hasPrice: true, hasSizeFeet: true),
      ItemSection(category: 'Pelamin Bajet', hasPrice: true, hasSizeFeet: true),
    ],
  );

  // ---------------------------------------------------------------
  // 3. KOLEKSI BAJU PENGANTIN (search + filter: title, price, size (male
  // & female, inch) — "From Size". Availability is boolean, computed
  // from bookings ±2 weeks)
  // ---------------------------------------------------------------
  static const koleksiBaju = PageConfig(
    pageKey: 'baju_pengantin',
    title: 'Koleksi Baju Pengantin',
    sections: [
      ItemSection(category: 'Songket', hasPrice: true, hasSizeMaleFemaleInch: true, hasDescription: true, hasBooleanAvailability: true),
      ItemSection(category: 'Dress/Gaun', hasPrice: true, hasSizeMaleFemaleInch: true, hasDescription: true, hasBooleanAvailability: true),
      ItemSection(category: 'Baju Nikah', hasPrice: true, hasSizeMaleFemaleInch: true, hasDescription: true, hasBooleanAvailability: true),
      ItemSection(category: 'Suit', hasPrice: true, hasSizeMaleFemaleInch: true, hasDescription: true, hasBooleanAvailability: true),
      ItemSection(category: 'Lengha', hasPrice: true, hasSizeMaleFemaleInch: true, hasDescription: true, hasBooleanAvailability: true),
      ItemSection(category: 'Aksesori', hasPrice: true, hasDescription: true, hasBooleanAvailability: true),
    ],
  );

  // ---------------------------------------------------------------
  // 4. BARANG PELAMIN (search only. Kerusi + Panel have numeric
  // availability tied to bookings; everything else always available)
  // ---------------------------------------------------------------
  static const barangPelamin = PageConfig(
    pageKey: 'barang_pelamin',
    title: 'Barang Pelamin',
    hasFilter: false, // no price/size on these — search only
    sections: [
      ItemSection(category: 'Kerusi', hasDescription: true, hasAvailabilityCount: true),
      ItemSection(category: 'Besi/Jet', hasDescription: true),
      ItemSection(category: 'Kain', hasDescription: true),
      ItemSection(category: 'Stage', hasDescription: true),
      ItemSection(category: 'Panel', hasDescription: true, hasAvailabilityCount: true),
      ItemSection(category: 'Bunga', hasDescription: true),
      ItemSection(category: 'Daun', hasDescription: true),
      ItemSection(category: 'Carpet', hasDescription: true),
      ItemSection(category: 'Pintu Gerbang', hasDescription: true),
      ItemSection(category: 'Walkaway', hasDescription: true),
      ItemSection(category: 'Lampu', hasDescription: true),
      ItemSection(category: 'Aksesori', hasDescription: true),
    ],
  );

  // ---------------------------------------------------------------
  // 5. LAMAN DAHLIA
  // ---------------------------------------------------------------
  static const lamanDahlia = PageConfig(
    pageKey: 'dahlia',
    title: 'Laman Dahlia',
    sections: [
      ItemSection(category: 'Pakej Kenduri', hasPrice: true, hasDescription: true),
      ItemSection(category: 'Pakej Lengkap', hasPrice: true, hasDescription: true),
      ItemSection(category: 'Pakej Lengkap Eksklusif', hasPrice: true, hasDescription: true),
      ItemSection(category: 'Additional', subcategories: ['Tetamu', 'Makanan Luar', 'Bermalam Homestay', 'Baju Custom', 'Show', 'Menu'], hasPrice: true, hasDescription: true),
    ],
  );

  static const List<PageConfig> allPages = [
    pakejPerkahwinan,
    koleksiPelamin,
    koleksiBaju,
    barangPelamin,
    lamanDahlia,
  ];

  static PageConfig byKey(String key) =>
      allPages.firstWhere((p) => p.pageKey == key);
}
