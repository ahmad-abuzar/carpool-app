import 'package:cloud_firestore/cloud_firestore.dart';
import 'id_data.dart';

class VerificationData {
  final String userId;
  final IdData? idData;
  final bool idScanned;
  final bool faceVerified;
  final bool fingerprintsVerified;
  final DateTime? idScanTimestamp;
  final DateTime? faceVerificationTimestamp;
  final DateTime? fingerprintCaptureTimestamp;
  final String? faceImageUrl;
  final String? rightHandImageUrl;
  final String? leftHandImageUrl;

  const VerificationData({
    required this.userId,
    this.idData,
    this.idScanned = false,
    this.faceVerified = false,
    this.fingerprintsVerified = false,
    this.idScanTimestamp,
    this.faceVerificationTimestamp,
    this.fingerprintCaptureTimestamp,
    this.faceImageUrl,
    this.rightHandImageUrl,
    this.leftHandImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'idData': idData?.toMap(),
      'idScanned': idScanned,
      'faceVerified': faceVerified,
      'fingerprintsVerified': fingerprintsVerified,
      'idScanTimestamp': idScanTimestamp != null
          ? Timestamp.fromDate(idScanTimestamp!)
          : null,
      'faceVerificationTimestamp': faceVerificationTimestamp != null
          ? Timestamp.fromDate(faceVerificationTimestamp!)
          : null,
      'fingerprintCaptureTimestamp': fingerprintCaptureTimestamp != null
          ? Timestamp.fromDate(fingerprintCaptureTimestamp!)
          : null,
      'faceImageUrl': faceImageUrl,
      'rightHandImageUrl': rightHandImageUrl,
      'leftHandImageUrl': leftHandImageUrl,
    };
  }

  factory VerificationData.fromMap(Map<String, dynamic> map) {
    return VerificationData(
      userId: map['userId'] ?? '',
      idData: map['idData'] != null ? IdData.fromMap(map['idData']) : null,
      idScanned: map['idScanned'] ?? false,
      faceVerified: map['faceVerified'] ?? false,
      fingerprintsVerified: map['fingerprintsVerified'] ?? false,
      idScanTimestamp: map['idScanTimestamp'] != null
          ? (map['idScanTimestamp'] as Timestamp).toDate()
          : null,
      faceVerificationTimestamp: map['faceVerificationTimestamp'] != null
          ? (map['faceVerificationTimestamp'] as Timestamp).toDate()
          : null,
      fingerprintCaptureTimestamp: map['fingerprintCaptureTimestamp'] != null
          ? (map['fingerprintCaptureTimestamp'] as Timestamp).toDate()
          : null,
      faceImageUrl: map['faceImageUrl'],
      rightHandImageUrl: map['rightHandImageUrl'],
      leftHandImageUrl: map['leftHandImageUrl'],
    );
  }

  VerificationData copyWith({
    IdData? idData,
    bool? idScanned,
    bool? faceVerified,
    bool? fingerprintsVerified,
    DateTime? idScanTimestamp,
    DateTime? faceVerificationTimestamp,
    DateTime? fingerprintCaptureTimestamp,
    String? faceImageUrl,
    String? rightHandImageUrl,
    String? leftHandImageUrl,
  }) {
    return VerificationData(
      userId: userId,
      idData: idData ?? this.idData,
      idScanned: idScanned ?? this.idScanned,
      faceVerified: faceVerified ?? this.faceVerified,
      fingerprintsVerified: fingerprintsVerified ?? this.fingerprintsVerified,
      idScanTimestamp: idScanTimestamp ?? this.idScanTimestamp,
      faceVerificationTimestamp:
          faceVerificationTimestamp ?? this.faceVerificationTimestamp,
      fingerprintCaptureTimestamp:
          fingerprintCaptureTimestamp ?? this.fingerprintCaptureTimestamp,
      faceImageUrl: faceImageUrl ?? this.faceImageUrl,
      rightHandImageUrl: rightHandImageUrl ?? this.rightHandImageUrl,
      leftHandImageUrl: leftHandImageUrl ?? this.leftHandImageUrl,
    );
  }
}
