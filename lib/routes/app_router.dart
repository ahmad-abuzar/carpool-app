import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ui/screens/splash/splash_screen.dart';
import '../ui/screens/onboarding/onboarding_screen.dart';
import '../ui/screens/onboarding/role_selection_screen.dart';
import '../ui/screens/auth/welcome_screen.dart';
import '../ui/screens/auth/phone_auth_screen.dart';
import '../ui/screens/auth/otp_screen.dart';
import '../ui/screens/auth/profile_setup_screen.dart';
import '../ui/screens/home/home_screen.dart';
import '../ui/screens/home/ride_search_screen.dart';
import '../ui/screens/rides/ride_details_screen.dart';
import '../ui/screens/rides/upcoming_trip_screen.dart';
import '../ui/screens/rides/live_trip_screen.dart';
import '../ui/screens/rides/rating_screen.dart';
import '../ui/screens/rides/ride_completion_screen.dart';
import '../ui/screens/booking/booking_flow_screen.dart';
import '../ui/screens/booking/booking_confirmation_screen.dart';
import '../ui/screens/driver/driver_home_screen.dart';
import '../ui/screens/driver/post_ride_screen.dart';
import '../ui/screens/driver/manage_rides_screen.dart';
import '../ui/screens/messages/messages_screen.dart';
import '../ui/screens/messages/chat_screen.dart';
import '../ui/screens/profile/profile_screen.dart';
import '../ui/screens/profile/verification_screen.dart';
import '../ui/screens/verification/id_scan_screen.dart';
import '../ui/screens/verification/face_verification_screen.dart';
import '../ui/screens/verification/fingerprint_capture_screen.dart';
import '../ui/screens/verification/verification_complete_screen.dart';
import '../ui/screens/profile/payment_methods_screen.dart';
import '../ui/screens/profile/preferences_screen.dart';
import '../ui/screens/profile/appearance_screen.dart';
import '../ui/screens/profile/ride_history_screen.dart';
import '../ui/widgets/main_navigation.dart';
import '../models/ride.dart';
import '../models/booking.dart';
import '../state/auth_provider.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _RouterRefreshStream(
      ref.watch(authProvider.notifier).stream,
    ),
    redirect: (context, state) {
      final isInitialized = authState.isInitialized;
      final isAuthenticated = authState.isFirebaseAuthenticated;
      final isProfileComplete = authState.isProfileComplete;

      // Don't redirect if not initialized (let splash stay)
      if (!isInitialized) return null;

      final isGoingToSplash = state.matchedLocation == '/splash';
      final isGoingToAuth =
          state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/phone-auth' ||
          state.matchedLocation == '/otp' ||
          state.matchedLocation == '/onboarding';
      final isGoingToProfileSetup = state.matchedLocation == '/profile-setup';

      if (!isAuthenticated) {
        // Not logged in -> can only be on splash, onboarding, welcome, or phone auth
        if (isGoingToSplash) return '/onboarding';
        if (!isGoingToAuth) return '/welcome';
        return null;
      }

      // Logged in
      if (!isProfileComplete) {
        // Logged in but profile incomplete -> must go to profile setup
        if (!isGoingToProfileSetup) return '/profile-setup';
        return null;
      }

      // Logged in + Profile complete -> can't go to welcome, onboarding, or profile setup
      if (isGoingToAuth || isGoingToSplash || isGoingToProfileSetup)
        return '/home';

      return null;
    },
    routes: [
      // Splash and Onboarding
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // Authentication
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/phone-auth',
        name: 'phone-auth',
        builder: (context, state) => const PhoneAuthScreen(),
      ),
      // ... existing routes ...
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final phone = extra['phone'] as String;
          final verificationId = extra['verificationId'] as String;
          final resendToken = extra['resendToken'] as int?;

          return OtpScreen(
            phoneNumber: phone,
            verificationId: verificationId,
            resendToken: resendToken,
          );
        },
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // Main App with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigation(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/rides',
            name: 'rides',
            builder: (context, state) => const DriverHomeScreen(),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Ride Search and Details
      GoRoute(
        path: '/ride-search',
        name: 'ride-search',
        builder: (context, state) => const RideSearchScreen(),
      ),
      GoRoute(
        path: '/ride-details/:id',
        name: 'ride-details',
        builder: (context, state) {
          final ride = state.extra as Ride;
          return RideDetailsScreen(ride: ride);
        },
      ),

      // Booking Flow
      GoRoute(
        path: '/booking',
        name: 'booking',
        builder: (context, state) {
          final ride = state.extra as Ride;
          return BookingFlowScreen(ride: ride);
        },
      ),
      // ... rest of the file ...
      GoRoute(
        path: '/booking-confirmation',
        name: 'booking-confirmation',
        builder: (context, state) {
          final booking = state.extra as Booking;
          return BookingConfirmationScreen(booking: booking);
        },
      ),

      // Trip Tracking
      GoRoute(
        path: '/upcoming-trip/:id',
        name: 'upcoming-trip',
        builder: (context, state) {
          final ride = state.extra as Ride;
          return UpcomingTripScreen(ride: ride);
        },
      ),
      GoRoute(
        path: '/live-trip/:id',
        name: 'live-trip',
        builder: (context, state) {
          final ride = state.extra as Ride;
          return LiveTripScreen(ride: ride);
        },
      ),

      // Ride Completion
      GoRoute(
        path: '/ride-complete/:id',
        name: 'ride-complete',
        builder: (context, state) {
          final ride = state.extra as Ride;
          return RideCompletionScreen(ride: ride);
        },
      ),

      // Rating
      GoRoute(
        path: '/rating/:rideId',
        name: 'rating',
        builder: (context, state) {
          final rideId = state.pathParameters['rideId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final isDriver = extra['isDriver'] as bool? ?? false;
          final ratedUserId = extra['ratedUserId'] as String? ?? '';
          return RatingScreen(
            rideId: rideId,
            isDriver: isDriver,
            ratedUserId: ratedUserId,
          );
        },
      ),

      // Driver Features
      GoRoute(
        path: '/post-ride',
        name: 'post-ride',
        builder: (context, state) => const PostRideScreen(),
      ),
      GoRoute(
        path: '/manage-rides',
        name: 'manage-rides',
        builder: (context, state) => const ManageRidesScreen(),
      ),

      // Messaging
      GoRoute(
        path: '/chat/:userId',
        name: 'chat',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final rideId = state.extra as String?;
          return ChatScreen(userId: userId, rideId: rideId);
        },
      ),

      // Profile Settings
      GoRoute(
        path: '/verification',
        name: 'verification',
        builder: (context, state) => const VerificationIntroScreen(),
      ),
      GoRoute(
        path: '/verification/id-scan',
        name: 'verification-id-scan',
        builder: (context, state) => const IdScanScreen(),
      ),
      GoRoute(
        path: '/verification/face',
        name: 'verification-face',
        builder: (context, state) => const FaceVerificationScreen(),
      ),
      GoRoute(
        path: '/verification/fingerprint',
        name: 'verification-fingerprint',
        builder: (context, state) => const FingerprintCaptureScreen(),
      ),
      GoRoute(
        path: '/verification/complete',
        name: 'verification-complete',
        builder: (context, state) => const VerificationCompleteScreen(),
      ),
      GoRoute(
        path: '/payment-methods',
        name: 'payment-methods',
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/preferences',
        name: 'preferences',
        builder: (context, state) => const PreferencesScreen(),
      ),
      GoRoute(
        path: '/appearance',
        name: 'appearance',
        builder: (context, state) => const AppearanceScreen(),
      ),
      GoRoute(
        path: '/ride-history',
        name: 'ride-history',
        builder: (context, state) => const RideHistoryScreen(),
      ),
    ],
  );
});

// Helper class for refreshing the router
class _RouterRefreshStream extends ChangeNotifier {
  _RouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
