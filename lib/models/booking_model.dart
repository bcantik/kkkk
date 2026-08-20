class BookingModel {
  final String? id;
  final String? customerId;
  final String customerName; // joined display field
  final String? customerPhone;
  final DateTime weddingDate;
  final String eventType; // tunang | nikah | sanding | aqiqah | majlis_lain | makeup | sewa_baju | sewa_aksesori
  final String? venueId;
  final String? venueText;
  final int? expectedGuests;
  final String? brideName;
  final String? groomName;
  final String? weddingTheme;
  final String? weddingColor;
  final String? packageItemId;
  final String? packageName;
  final double? packagePrice;
  final double additionalCharges;
  final double discount;
  final double totalAmount;
  final double depositRequired;
  final double depositPaid;
  final String paymentStatus;
  final String bookingStatus;
  final String? notes;
  final String? googleEventId;

  BookingModel({
    this.id,
    this.customerId,
    this.customerName = '',
    this.customerPhone,
    required this.weddingDate,
    required this.eventType,
    this.venueId,
    this.venueText,
    this.expectedGuests,
    this.brideName,
    this.groomName,
    this.weddingTheme,
    this.weddingColor,
    this.packageItemId,
    this.packageName,
    this.packagePrice,
    this.additionalCharges = 0,
    this.discount = 0,
    this.totalAmount = 0,
    this.depositRequired = 0,
    this.depositPaid = 0,
    this.paymentStatus = 'unpaid',
    this.bookingStatus = 'new_inquiry',
    this.notes,
    this.googleEventId,
  });

  double get outstanding => totalAmount - depositPaid;
  double get paymentProgress =>
      totalAmount <= 0 ? 0 : (depositPaid / totalAmount).clamp(0, 1);

  factory BookingModel.fromMap(Map<String, dynamic> map) => BookingModel(
        id: map['id'] as String?,
        customerId: map['customer_id'] as String?,
        customerName: (map['customers']?['full_name']) ?? map['customer_name'] ?? '',
        customerPhone: (map['customers']?['phone']) ?? map['customer_phone'],
        weddingDate: DateTime.parse(map['wedding_date']),
        eventType: map['event_type'] as String,
        venueId: map['venue_id'] as String?,
        venueText: map['venue_text'] as String?,
        expectedGuests: map['expected_guests'] as int?,
        brideName: map['bride_name'] as String?,
        groomName: map['groom_name'] as String?,
        weddingTheme: map['wedding_theme'] as String?,
        weddingColor: map['wedding_color'] as String?,
        packageItemId: map['package_item_id'] as String?,
        packageName: map['items']?['title'],
        packagePrice: (map['package_price'] as num?)?.toDouble(),
        additionalCharges: (map['additional_charges'] as num?)?.toDouble() ?? 0,
        discount: (map['discount'] as num?)?.toDouble() ?? 0,
        totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
        depositRequired: (map['deposit_required'] as num?)?.toDouble() ?? 0,
        depositPaid: (map['deposit_paid'] as num?)?.toDouble() ?? 0,
        paymentStatus: map['payment_status'] as String? ?? 'unpaid',
        bookingStatus: map['booking_status'] as String? ?? 'new_inquiry',
        notes: map['notes'] as String?,
        googleEventId: map['google_event_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'customer_id': customerId,
        'wedding_date': weddingDate.toIso8601String().split('T').first,
        'event_type': eventType,
        'venue_id': venueId,
        'venue_text': venueText,
        'expected_guests': expectedGuests,
        'bride_name': brideName,
        'groom_name': groomName,
        'wedding_theme': weddingTheme,
        'wedding_color': weddingColor,
        'package_item_id': packageItemId,
        'package_price': packagePrice,
        'additional_charges': additionalCharges,
        'discount': discount,
        'deposit_required': depositRequired,
        'deposit_paid': depositPaid,
        'payment_status': paymentStatus,
        'booking_status': bookingStatus,
        'notes': notes,
        if (googleEventId != null) 'google_event_id': googleEventId,
      };
}
