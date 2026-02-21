import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../services/mock_data_service.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final bool isInitialized;
  final bool isFirebaseAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isInitialized = false,
    this.isFirebaseAuthenticated = false,
  });

  bool get isProfileComplete => user != null && user!.name.isNotEmpty;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isInitialized,
    bool? isFirebaseAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      isFirebaseAuthenticated:
          isFirebaseAuthenticated ?? this.isFirebaseAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirestoreService _firestoreService;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  StreamSubscription<Map<String, dynamic>?>? _userSubscription;

  AuthNotifier(this._firestoreService)
    : super(const AuthState(isLoading: true)) {
    _initialize();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      try {
        final data = await _firestoreService.getDocument(
          collection: 'users',
          docId: firebaseUser.uid,
        );

        if (data != null) {
          final user = User.fromMap(data);
          state = AuthState(
            user: user,
            isInitialized: true,
            isFirebaseAuthenticated: true,
          );
          MockDataService.currentUser = user;
          _subscribeToUserUpdates(user.id);
        } else {
          // Authenticated but no profile yet
          state = const AuthState(
            isInitialized: true,
            isFirebaseAuthenticated: true,
          );
        }
      } catch (e) {
        print('AuthNotifier: Error during initialization: $e');
        state = const AuthState(
          isInitialized: true,
          isFirebaseAuthenticated: true,
        );
      }
    } else {
      state = const AuthState(
        isInitialized: true,
        isFirebaseAuthenticated: false,
      );
    }
  }

  /// Refresh auth state (useful after Google Sign-In)
  Future<void> refreshAuthState() async {
    print('🔄 AuthNotifier: Refreshing auth state...');
    await _initialize();
  }

  void login(User user) {
    state = AuthState(
      user: user,
      isInitialized: true,
      isFirebaseAuthenticated: true,
    );
    MockDataService.currentUser = user;
    _subscribeToUserUpdates(user.id);
  }

  void logout() {
    _userSubscription?.cancel();
    _userSubscription = null;
    state = const AuthState(
      isInitialized: true,
      isFirebaseAuthenticated: false,
    );
  }

  void updateUser(User user) {
    if (state.user?.id != user.id) {
      _subscribeToUserUpdates(user.id);
    }
    state = state.copyWith(user: user);
    MockDataService.currentUser = user;
  }

  void _subscribeToUserUpdates(String userId) {
    _userSubscription?.cancel();
    _userSubscription = _firestoreService
        .listenToDocument(collection: 'users', docId: userId)
        .listen(
          (data) {
            if (data != null) {
              try {
                final updatedUser = User.fromMap(data);
                state = state.copyWith(user: updatedUser);
                MockDataService.currentUser = updatedUser;
              } catch (e) {
                print('AuthNotifier: Error parsing user update: $e');
              }
            }
          },
          onError: (e) {
            print('AuthNotifier: Error in user stream: $e');
          },
        );
  }

  /// Update user's avatar URL
  Future<bool> updateAvatarUrl(String avatarUrl) async {
    if (state.user == null) {
      print('AuthNotifier: No user in state');
      return false;
    }

    try {
      print('AuthNotifier: Updating avatar URL for user ${state.user!.id}');

      await _firestoreService.updateUserAvatar(
        userId: state.user!.id,
        avatarUrl: avatarUrl,
      );

      final updatedUser = state.user!.copyWith(avatarUrl: avatarUrl);
      state = state.copyWith(user: updatedUser);
      MockDataService.currentUser = updatedUser;

      print('AuthNotifier: Avatar URL updated successfully');
      return true;
    } catch (e) {
      print('AuthNotifier: Error updating avatar URL: $e');
      return false;
    }
  }

  /// Remove user's avatar
  Future<bool> removeAvatar() async {
    if (state.user == null) {
      print('AuthNotifier: No user in state');
      return false;
    }

    try {
      print('AuthNotifier: Removing avatar for user ${state.user!.id}');

      await _firestoreService.removeUserAvatar(userId: state.user!.id);

      final updatedUser = state.user!.copyWith(avatarUrl: null);
      state = state.copyWith(user: updatedUser);
      MockDataService.currentUser = updatedUser;

      print('AuthNotifier: Avatar removed successfully');
      return true;
    } catch (e) {
      print('AuthNotifier: Error removing avatar: $e');
      return false;
    }
  }
}

// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return AuthNotifier(firestoreService);
});

// Current user provider (convenience)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});
