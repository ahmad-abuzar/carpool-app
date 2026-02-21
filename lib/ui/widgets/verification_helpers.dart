import 'package:flutter/material.dart';
import '../models/user.dart';

// Helper function to determine verification button label
String getVerificationButtonLabel(VerificationStatus status, User user) {
  switch (status) {
    case VerificationStatus.none:
      return 'Verify Now';
    case VerificationStatus.inProgress:
      if (!user.idVerified) return 'Continue Verification';
      if (!user.faceVerified) return 'Continue Verification';
      if (!user.fingerprintsVerified) return 'Continue Verification';
      return 'Continue Verification';
    case VerificationStatus.pending:
      return 'Under Review';
    case VerificationStatus.verified:
      return 'View Verification';
  }
}
