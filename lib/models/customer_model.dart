class CustomerModel {
  final String? id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? icNumber;
  final String? address;
  final String? emergencyContact;

  CustomerModel({
    this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.icNumber,
    this.address,
    this.emergencyContact,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) => CustomerModel(
        id: map['id'] as String?,
        fullName: map['full_name'] as String,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        icNumber: map['ic_number'] as String?,
        address: map['address'] as String?,
        emergencyContact: map['emergency_contact'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'ic_number': icNumber,
        'address': address,
        'emergency_contact': emergencyContact,
      };
}
