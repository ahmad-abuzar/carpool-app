import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/verification_data.dart';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current verification status for a user
  Future<VerificationStatus> getVerificationStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return VerificationStatus.none;

      final data = doc.data();
      final statusString = data?['verificationStatus'] as String?;

      switch (statusString) {
        case 'inProgress':
          return VerificationStatus.inProgress;
        case 'pending':
          return VerificationStatus.pending;
        case 'verified':
          return VerificationStatus.verified;
        default:
          return VerificationStatus.none;
      }
    } catch (e) {
      print('Error getting verification status: $e');
      return VerificationStatus.none;
    }
  }

  // Set verification status
  Future<void> setVerificationStatus(
    String uid,
    VerificationStatus status,
  ) async {
    try {
      String statusString;
      switch (status) {
        case VerificationStatus.none:
          statusString = 'none';
          break;
        case VerificationStatus.inProgress:
          statusString = 'inProgress';
          break;
        case VerificationStatus.pending:
          statusString = 'pending';
          break;
        case VerificationStatus.verified:
          statusString = 'verified';
          break;
      }

      await _firestore.collection('users').doc(uid).update({
        'verificationStatus': statusString,
      });
    } catch (e) {
      print('Error setting verification status: $e');
    }
  }

  // Mark ID as verified
  Future<void> markIdVerified(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'idVerified': true,
      });
      await _updateVerificationLevel(uid);
    } catch (e) {
      print('Error marking ID verified: $e');
    }
  }

  // Mark face as verified
  Future<void> markFaceVerified(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'faceVerified': true,
      });
      await _updateVerificationLevel(uid);
    } catch (e) {
      print('Error marking face verified: $e');
    }
  }

  // Mark fingerprints as verified
  Future<void> markFingerprintsVerified(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fingerprintsVerified': true,
      });
      await _updateVerificationLevel(uid);
    } catch (e) {
      print('Error marking fingerprints verified: $e');
    }
  }

  // Get verification data
  Future<VerificationData?> getVerificationData(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('verificationData')
          .doc('current')
          .get();

      if (!doc.exists) return null;
      return VerificationData.fromMap(doc.data()!);
    } catch (e) {
      print('Error getting verification data: $e');
      return null;
    }
  }

  // Save verification data
  Future<void> saveVerificationData(VerificationData data) async {
    try {
      await _firestore
          .collection('users')
          .doc(data.userId)
          .collection('verificationData')
          .doc('current')
          .set(data.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving verification data: $e');
    }
  }

  // Complete verification
  Future<void> completeVerification(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'verificationStatus': 'verified',
        'verificationLevel': 'full',
        'verificationDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error completing verification: $e');
    }
  }

  // Update verification level based on completed steps
  Future<void> _updateVerificationLevel(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return;

      final data = doc.data();
      final idVerified = data?['idVerified'] ?? false;
      final faceVerified = data?['faceVerified'] ?? false;
      final fingerprintsVerified = data?['fingerprintsVerified'] ?? false;

      String level;
      if (idVerified && faceVerified && fingerprintsVerified) {
        level = 'full';
      } else if (idVerified || faceVerified || fingerprintsVerified) {
        level = 'partial';
      } else {
        level = 'none';
      }

      await _firestore.collection('users').doc(uid).update({
        'verificationLevel': level,
      });
    } catch (e) {
      print('Error updating verification level: $e');
    }
  }

  // Reset verification (For debugging/testing)
  Future<void> resetVerification(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'verificationStatus': 'none',
        'verificationLevel': 'none',
        'idVerified': false,
        'faceVerified': false,
        'fingerprintsVerified': false,
        'verificationDate': FieldValue.delete(),
      });
    } catch (e) {
      print('Error resetting verification: $e');
    }
  }
}
