class IdData {
  final String name;
  final String idNumber;
  final String? dateOfBirth;
  final double confidence;
  final String rawText;

  const IdData({
    required this.name,
    required this.idNumber,
    this.dateOfBirth,
    this.confidence = 0.0,
    this.rawText = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'idNumber': idNumber,
      'dateOfBirth': dateOfBirth,
      'confidence': confidence,
      'rawText': rawText,
    };
  }

  factory IdData.fromMap(Map<String, dynamic> map) {
    return IdData(
      name: map['name'] ?? '',
      idNumber: map['idNumber'] ?? '',
      dateOfBirth: map['dateOfBirth'],
      confidence: map['confidence']?.toDouble() ?? 0.0,
      rawText: map['rawText'] ?? '',
    );
  }
}
