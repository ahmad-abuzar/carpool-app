import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../state/auth_provider.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.multiply,
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: Spacing.md),

              Text('Welcome to EzRide', style: AppTypography.headline(context)),

              const SizedBox(height: Spacing.xs),

              Text(
                'Smart Ride Sharing Application',
                style: AppTypography.bodySmall(context),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Phone auth button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/phone-auth'),
                  icon: const Icon(Icons.phone),
                  label: const Text('Continue with Phone'),
                ),
              ),

              const SizedBox(height: Spacing.lg),

              // Social login buttons
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      print('🔵 Google Sign-In button pressed');
                      final authService = FirebaseAuthService();
                      final userCredential = await authService
                          .signInWithGoogle();

                      print('🔵 UserCredential: ${userCredential != null}');
                      print('🔵 Context mounted: ${context.mounted}');

                      if (userCredential != null && context.mounted) {
                        print('🔵 Refreshing auth state...');
                        // Refresh auth state to update router
                        await ref
                            .read(authProvider.notifier)
                            .refreshAuthState();

                        print('🔵 Checking user profile...');
                        // Check if user has completed profile setup
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userCredential.user!.uid)
                            .get();

                        print('🔵 User doc exists: ${userDoc.exists}');
                        print('🔵 User data: ${userDoc.data()}');

                        final hasCompleteProfile =
                            userDoc.exists && userDoc.data()?['role'] != null;

                        print(
                          '🔵 Has complete profile (role exists): $hasCompleteProfile',
                        );

                        if (hasCompleteProfile) {
                          print('✅ EXISTING USER - Navigating to /home');
                          context.go('/home');
                        } else {
                          print('🆕 NEW USER - Navigating to /profile-setup');
                          context.go('/profile-setup');
                        }
                      } else {
                        print(
                          '⚠️ Navigation blocked - credential: ${userCredential != null}, mounted: ${context.mounted}',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Google Sign-In failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('Continue with Google'),
                ),
              ),

              const SizedBox(height: Spacing.md),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Stub: would implement Apple Sign-In
                    context.push('/profile-setup');
                  },
                  icon: const Icon(Icons.apple),
                  label: const Text('Continue with Apple'),
                ),
              ),

              const SizedBox(height: Spacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
