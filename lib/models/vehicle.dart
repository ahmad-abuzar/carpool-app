class Vehicle {
  final String id;
  final String model;
  final String color;
  final String plateNumber;
  final int seats;
  final bool verified;
  final String? imageUrl;

  const Vehicle({
    required this.id,
    required this.model,
    required this.color,
    required this.plateNumber,
    required this.seats,
    this.verified = false,
    this.imageUrl,
  });

  // Firebase serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model': model,
      'color': color,
      'plateNumber': plateNumber,
      'seats': seats,
      'verified': verified,
      'imageUrl': imageUrl,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as String,
      model: map['model'] as String,
      color: map['color'] as String,
      plateNumber: map['plateNumber'] as String,
      seats: map['seats'] as int,
      verified: map['verified'] as bool? ?? false,
      imageUrl: map['imageUrl'] as String?,
    );
  }
}
