import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/biometric_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';

/// Biometric setup screen - shown after OTP verification
/// Banking app style biometric enrollment
class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _isLoading = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _biometricService.isBiometricAvailable();
    setState(() {
      _biometricAvailable = available;
    });
  }

  Future<void> _setupBiometric() async {
    setState(() => _isLoading = true);

    final success = await _biometricService.enableBiometric();

    setState(() => _isLoading = false);

    if (success) {
      // Save biometric enabled status
      if (mounted) {
        _showSuccessDialog();
      }
    } else {
      if (mounted) {
        _showErrorDialog();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: ColorPalette.success,
          size: 64,
        ),
        title: Text(
          'Biometric Enabled!',
          style: AppTypography.headline(context),
        ),
        content: Text(
          'Your account is now secured with fingerprint authentication.',
          style: AppTypography.body(context),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // Close dialog
              context.go('/role-selection'); // Continue to next step
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.error_outline,
          color: ColorPalette.error,
          size: 64,
        ),
        title: Text('Setup Failed', style: AppTypography.headline(context)),
        content: Text(
          'Could not enable biometric authentication. Please try again.',
          style: AppTypography.body(context),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              context.go('/role-selection'); // Skip for now
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Fingerprint icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: ColorPalette.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 64,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: Spacing.xxxl),

              // Title
              Text(
                'Secure Your Account',
                style: AppTypography.headline(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.md),

              // Description
              Text(
                'Enable fingerprint authentication for quick and secure access to your account.',
                style: AppTypography.body(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.lg),

              // Features list
              _buildFeatureItem(
                icon: Icons.security,
                title: 'Banking-level security',
                description: 'Your fingerprint never leaves your device',
              ),

              const SizedBox(height: Spacing.md),

              _buildFeatureItem(
                icon: Icons.speed,
                title: 'Quick access',
                description: 'Login in seconds with just your fingerprint',
              ),

              const SizedBox(height: Spacing.md),

              _buildFeatureItem(
                icon: Icons.lock,
                title: 'Privacy protected',
                description: 'No fingerprint data is stored on our servers',
              ),

              const SizedBox(height: Spacing.xxxl),

              // Enable button
              if (_biometricAvailable)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _setupBiometric,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Enable Fingerprint'),
                  ),
                ),

              if (!_biometricAvailable)
                Text(
                  'Biometric authentication not available on this device',
                  style: AppTypography.bodySmall(
                    context,
                    color: ColorPalette.error,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: Spacing.md),

              // Skip button
              TextButton(
                onPressed: () => context.go('/role-selection'),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ColorPalette.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Spacing.sm),
          ),
          child: Icon(icon, color: ColorPalette.primary, size: 24),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body(context, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(description, style: AppTypography.bodySmall(context)),
            ],
          ),
        ),
      ],
    );
  }
}
