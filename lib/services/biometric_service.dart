import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

/// Biometric authentication service
/// Handles fingerprint authentication like banking apps
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on device
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  /// Authenticate user with biometric (fingerprint/face ID)
  /// Returns true if authentication successful
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
  }) async {
    try {
      final bool canAuthenticate = await isBiometricAvailable();

      if (!canAuthenticate) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.message}');
      return false;
    }
  }

  /// Enable biometric for app (called after first setup)
  Future<bool> enableBiometric() async {
    return await authenticate(reason: 'Secure your account with fingerprint');
  }

  /// Verify biometric before sensitive operations
  Future<bool> verifyBiometric() async {
    return await authenticate(reason: 'Verify your identity');
  }
}
