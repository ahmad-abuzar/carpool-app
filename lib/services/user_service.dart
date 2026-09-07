import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'firestore_service.dart';
// import 'storage_service.dart';  // Deprecated: Using Cloudinary instead

/// User Management Service
/// Handles all user-related operations
class UserService {
  final FirestoreService _firestoreService = FirestoreService();
  // final StorageService _storageService = StorageService();  // Deprecated: Using Cloudinary
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'users';

  /// Create user profile in Firestore
  Future<void> createUserProfile(User user) async {
    await _firestoreService.createDocument(
      collection: _collection,
      docId: user.id,
      data: user.toMap(),
    );
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    final data = await _firestoreService.getDocument(
      collection: _collection,
      docId: userId,
    );

    if (data == null) return null;
    return User.fromMap(data);
  }

  /// Update user profile
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: userId,
      data: updates,
    );
  }

  /// Update full user object
  Future<void> updateUser(User user) async {
    await _firestoreService.setDocument(
      collection: _collection,
      docId: user.id,
      data: user.toMap(),
      merge: true,
    );
  }

  // DEPRECATED: Use ImageUploadService.uploadProfileImage + updateProfileImageUrl instead
  /*
  /// Upload and update profile picture
  Future<String> uploadProfilePicture({
    required String userId,
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    // Upload image to storage
    final imageUrl = await _storageService.uploadProfilePicture(
      userId: userId,
      imageFile: imageFile,
      onProgress: onProgress,
    );

    // Update user profile with new image URL
    await updateUserProfile(userId, {'avatarUrl': imageUrl});

    return imageUrl;
  }
  */

  /// Update profile image URL (Cloudinary)
  Future<void> updateProfileImageUrl(String userId, String url) async {
    await updateUserProfile(userId, {'profileImageUrl': url});
  }

  /// Update verification images (Cloudinary URLs)
  Future<void> updateVerificationImages(
    String userId,
    VerificationImages images,
  ) async {
    await updateUserProfile(userId, {'verificationImages': images.toMap()});
  }

  /// Update specific verification image URL
  Future<void> updateVerificationImageUrl({
    required String userId,
    String? cnicUrl,
    String? faceUrl,
    String? leftFingerprintUrl,
    String? rightFingerprintUrl,
  }) async {
    // Get current verification images
    final user = await getUserById(userId);
    final currentImages =
        user?.verificationImages ?? const VerificationImages();

    // Update with new URLs
    final updatedImages = VerificationImages(
      cnicImageUrl: cnicUrl ?? currentImages.cnicImageUrl,
      faceImageUrl: faceUrl ?? currentImages.faceImageUrl,
      fingerprintImages:
          (leftFingerprintUrl != null || rightFingerprintUrl != null)
          ? FingerprintImages(
              leftHandUrl:
                  leftFingerprintUrl ??
                  currentImages.fingerprintImages?.leftHandUrl,
              rightHandUrl:
                  rightFingerprintUrl ??
                  currentImages.fingerprintImages?.rightHandUrl,
            )
          : currentImages.fingerprintImages,
    );

    await updateVerificationImages(userId, updatedImages);
  }

  /// Update verification status
  Future<void> updateVerificationStatus({
    required String userId,
    bool? phoneVerified,
    bool? emailVerified,
    bool? idVerified,
    bool? faceVerified,
    bool? fingerprintsVerified,
    bool? vehicleVerified,
  }) async {
    final updates = <String, dynamic>{};

    if (phoneVerified != null) updates['phoneVerified'] = phoneVerified;
    if (emailVerified != null) updates['emailVerified'] = emailVerified;
    if (idVerified != null) updates['idVerified'] = idVerified;
    if (faceVerified != null) updates['faceVerified'] = faceVerified;
    if (fingerprintsVerified != null) {
      updates['fingerprintsVerified'] = fingerprintsVerified;
    }
    if (vehicleVerified != null) updates['vehicleVerified'] = vehicleVerified;

    if (updates.isNotEmpty) {
      await updateUserProfile(userId, updates);
      await _updateVerificationLevel(userId);
    }
  }

  /// Update verification level based on completed verifications
  Future<void> _updateVerificationLevel(String userId) async {
    final user = await getUserById(userId);
    if (user == null) return;

    VerificationLevel level;
    if (user.idVerified && user.faceVerified && user.fingerprintsVerified) {
      level = VerificationLevel.full;
    } else if (user.idVerified ||
        user.faceVerified ||
        user.fingerprintsVerified) {
      level = VerificationLevel.partial;
    } else {
      level = VerificationLevel.none;
    }

    await updateUserProfile(userId, {'verificationLevel': level.name});
  }

  /// Add emergency contact
  Future<void> addEmergencyContact(String userId, String contact) async {
    await _firestore.collection(_collection).doc(userId).update({
      'emergencyContacts': FieldValue.arrayUnion([contact]),
    });
  }

  /// Remove emergency contact
  Future<void> removeEmergencyContact(String userId, String contact) async {
    await _firestore.collection(_collection).doc(userId).update({
      'emergencyContacts': FieldValue.arrayRemove([contact]),
    });
  }

  /// Update user rating
  Future<void> updateUserRating(String userId, double newRating) async {
    await updateUserProfile(userId, {'rating': newRating});
  }

  /// Increment total rides
  Future<void> incrementTotalRides(
    String userId, {
    bool asDriver = false,
  }) async {
    final updates = <String, dynamic>{'totalRides': FieldValue.increment(1)};

    if (asDriver) {
      updates['totalRidesAsDriver'] = FieldValue.increment(1);
    }

    await _firestore.collection(_collection).doc(userId).update(updates);
  }

  /// Search users by name or email
  Future<List<User>> searchUsers(String query) async {
    // Note: This is a basic search. For production, consider using Algolia or similar
    final snapshot = await _firestore
        .collection(_collection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => User.fromMap(doc.data())).toList();
  }

  /// Get users by role
  Future<List<User>> getUsersByRole(UserRole role) async {
    final docs = await _firestoreService.queryDocuments(
      collection: _collection,
      field: 'role',
      value: role.name,
    );

    return docs.map((doc) => User.fromMap(doc)).toList();
  }

  /// Get verified users
  Future<List<User>> getVerifiedUsers() async {
    final docs = await _firestoreService.queryDocuments(
      collection: _collection,
      field: 'verificationLevel',
      value: VerificationLevel.full.name,
    );

    return docs.map((doc) => User.fromMap(doc)).toList();
  }

  /// Listen to user changes
  Stream<User?> listenToUser(String userId) {
    return _firestoreService
        .listenToDocument(collection: _collection, docId: userId)
        .map((data) => data != null ? User.fromMap(data) : null);
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    await _firestoreService.deleteDocument(
      collection: _collection,
      docId: userId,
    );
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    final user = await getUserById(userId);
    if (user == null) return {};

    return {
      'totalRides': user.totalRides,
      'totalRidesAsDriver': user.totalRidesAsDriver,
      'rating': user.rating,
      'verificationLevel': user.verificationLevel.name,
      'isFullyVerified': user.verificationLevel == VerificationLevel.full,
    };
  }

  /// Update user preferences
  Future<void> updatePreferences({
    required String userId,
    String? homeAddress,
    String? workAddress,
    bool? preferFemaleOnlyRides,
    bool? notificationsEnabled,
    bool? locationSharingEnabled,
  }) async {
    final updates = <String, dynamic>{};

    if (homeAddress != null) updates['homeAddress'] = homeAddress;
    if (workAddress != null) updates['workAddress'] = workAddress;
    if (preferFemaleOnlyRides != null) {
      updates['preferFemaleOnlyRides'] = preferFemaleOnlyRides;
    }
    if (notificationsEnabled != null) {
      updates['notificationsEnabled'] = notificationsEnabled;
    }
    if (locationSharingEnabled != null) {
      updates['locationSharingEnabled'] = locationSharingEnabled;
    }

    if (updates.isNotEmpty) {
      await updateUserProfile(userId, updates);
    }
  }
}
