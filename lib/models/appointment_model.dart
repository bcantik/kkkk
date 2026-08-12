class AppointmentModel {
  final String? id;
  final String? bookingId;
  final String? customerId;
  final String customerName;
  final String appointmentType;
  final DateTime appointmentDate;
  final String appointmentTime; // HH:mm
  final String? staffAssigned;
  final String? location;
  final String? notes;
  final int reminderOffsetDays;

  AppointmentModel({
    this.id,
    this.bookingId,
    this.customerId,
    this.customerName = '',
    required this.appointmentType,
    required this.appointmentDate,
    required this.appointmentTime,
    this.staffAssigned,
    this.location,
    this.notes,
    this.reminderOffsetDays = 1,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) => AppointmentModel(
        id: map['id'] as String?,
        bookingId: map['booking_id'] as String?,
        customerId: map['customer_id'] as String?,
        customerName: map['customers']?['full_name'] ?? '',
        appointmentType: map['appointment_type'] as String,
        appointmentDate: DateTime.parse(map['appointment_date']),
        appointmentTime: (map['appointment_time'] as String).substring(0, 5),
        staffAssigned: map['staff_assigned'] as String?,
        location: map['location'] as String?,
        notes: map['notes'] as String?,
        reminderOffsetDays: map['reminder_offset_days'] as int? ?? 1,
      );

  Map<String, dynamic> toMap() => {
        'booking_id': bookingId,
        'customer_id': customerId,
        'appointment_type': appointmentType,
        'appointment_date': appointmentDate.toIso8601String().split('T').first,
        'appointment_time': appointmentTime,
        'staff_assigned': staffAssigned,
        'location': location,
        'notes': notes,
        'reminder_offset_days': reminderOffsetDays,
      };
}
