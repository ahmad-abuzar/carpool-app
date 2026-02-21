import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

/// User state notifier for managing user data and avatar
class UserNotifier extends StateNotifier<User?> {
  final FirestoreService _firestoreService;

  UserNotifier(this._firestoreService, User? initialUser) : super(initialUser);

  /// Update user's avatar URL
  Future<bool> updateAvatarUrl(String avatarUrl) async {
    if (state == null) {
      print('UserNotifier: No user in state');
      return false;
    }

    try {
      print('UserNotifier: Updating avatar URL for user ${state!.id}');

      // Update Firestore
      await _firestoreService.updateUserAvatar(
        userId: state!.id,
        avatarUrl: avatarUrl,
      );

      // Update local state
      state = state!.copyWith(avatarUrl: avatarUrl);

      print('UserNotifier: Avatar URL updated successfully');
      return true;
    } catch (e) {
      print('UserNotifier: Error updating avatar URL: $e');
      return false;
    }
  }

  /// Remove user's avatar
  Future<bool> removeAvatar() async {
    if (state == null) {
      print('UserNotifier: No user in state');
      return false;
    }

    try {
      print('UserNotifier: Removing avatar for user ${state!.id}');

      // Update Firestore
      await _firestoreService.removeUserAvatar(userId: state!.id);

      // Update local state (set avatarUrl to null)
      state = state!.copyWith(avatarUrl: null);

      print('UserNotifier: Avatar removed successfully');
      return true;
    } catch (e) {
      print('UserNotifier: Error removing avatar: $e');
      return false;
    }
  }

  /// Refresh user data from Firestore
  Future<void> refreshUser() async {
    if (state == null) {
      print('UserNotifier: No user to refresh');
      return;
    }

    try {
      print('UserNotifier: Refreshing user data for ${state!.id}');

      final userData = await _firestoreService.getDocument(
        collection: 'users',
        docId: state!.id,
      );

      if (userData != null) {
        // Create updated user from Firestore data
        state = state!.copyWith(
          avatarUrl: userData['avatarUrl'] as String?,
          name: userData['name'] as String? ?? state!.name,
          email: userData['email'] as String? ?? state!.email,
          // Add other fields as needed
        );

        print('UserNotifier: User data refreshed successfully');
      }
    } catch (e) {
      print('UserNotifier: Error refreshing user: $e');
    }
  }

  /// Update full user data
  void updateUser(User user) {
    state = user;
  }

  /// Clear user state (logout)
  void clearUser() {
    state = null;
  }
}
