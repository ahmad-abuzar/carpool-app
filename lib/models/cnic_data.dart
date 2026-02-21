/// Model for Pakistani CNIC (National ID Card) data
class CnicData {
  final String cnicNumber; // Format: XXXXX-XXXXXXX-X
  final String name;
  final String fatherName;
  final DateTime? dateOfBirth;
  final DateTime? dateOfIssue;
  final DateTime? dateOfExpiry;
  final String? address;
  final String gender;

  const CnicData({
    required this.cnicNumber,
    required this.name,
    required this.fatherName,
    this.dateOfBirth,
    this.dateOfIssue,
    this.dateOfExpiry,
    this.address,
    this.gender = 'Unknown',
  });

  /// Check if CNIC number is valid format
  bool get isValidFormat {
    // CNIC format: 12345-1234567-1 (13 digits with dashes)
    final regex = RegExp(r'^\d{5}-\d{7}-\d{1}$');
    return regex.hasMatch(cnicNumber);
  }

  /// Get CNIC without dashes
  String get cnicWithoutDashes {
    return cnicNumber.replaceAll('-', '');
  }

  /// Extract gender from CNIC (last digit determines gender)
  /// Odd = Male, Even = Female
  String get genderFromCnic {
    try {
      final lastDigit = int.parse(cnicNumber[cnicNumber.length - 1]);
      return lastDigit % 2 == 0 ? 'Female' : 'Male';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Copy with method
  CnicData copyWith({
    String? cnicNumber,
    String? name,
    String? fatherName,
    DateTime? dateOfBirth,
    DateTime? dateOfIssue,
    DateTime? dateOfExpiry,
    String? address,
    String? gender,
  }) {
    return CnicData(
      cnicNumber: cnicNumber ?? this.cnicNumber,
      name: name ?? this.name,
      fatherName: fatherName ?? this.fatherName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      dateOfIssue: dateOfIssue ?? this.dateOfIssue,
      dateOfExpiry: dateOfExpiry ?? this.dateOfExpiry,
      address: address ?? this.address,
      gender: gender ?? this.gender,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'cnicNumber': cnicNumber,
      'name': name,
      'fatherName': fatherName,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'dateOfIssue': dateOfIssue?.millisecondsSinceEpoch,
      'dateOfExpiry': dateOfExpiry?.millisecondsSinceEpoch,
      'address': address,
      'gender': gender,
    };
  }

  /// Create from map
  factory CnicData.fromMap(Map<String, dynamic> map) {
    return CnicData(
      cnicNumber: map['cnicNumber'] as String,
      name: map['name'] as String,
      fatherName: map['fatherName'] as String,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'] as int)
          : null,
      dateOfIssue: map['dateOfIssue'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfIssue'] as int)
          : null,
      dateOfExpiry: map['dateOfExpiry'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfExpiry'] as int)
          : null,
      address: map['address'] as String?,
      gender: map['gender'] as String? ?? 'Unknown',
    );
  }

  @override
  String toString() {
    return 'CnicData(cnicNumber: $cnicNumber, name: $name, fatherName: $fatherName, dob: $dateOfBirth)';
  }
}
