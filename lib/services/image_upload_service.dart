import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../config/cloudinary_config.dart';

/// Centralized service for uploading images to Cloudinary
class ImageUploadService {
  /// Upload profile image to Cloudinary
  /// Returns the secure URL or null on failure
  Future<String?> uploadProfileImage(File image, String uid) async {
    try {
      print('📤 Uploading profile image for user: $uid');

      final cloudinary = CloudinaryPublic(
        CloudinaryConfig.cloudName,
        CloudinaryConfig.uploadPreset,
        cache: false,
      );

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          folder: CloudinaryConfig.profilePicturesFolder,
          publicId: uid,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      print('✅ Profile image uploaded: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e, stackTrace) {
      print('❌ Error uploading profile image: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Upload CNIC image to Cloudinary
  /// Returns the secure URL or null on failure
  Future<String?> uploadCNIC(File image, String uid) async {
    try {
      print('📤 Uploading CNIC image for user: $uid');

      final cloudinary = CloudinaryPublic(
        CloudinaryConfig.cloudName,
        CloudinaryConfig.uploadPreset,
        cache: false,
      );

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          folder: CloudinaryConfig.verificationIdsFolder,
          publicId: uid,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      print('✅ CNIC image uploaded: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e, stackTrace) {
      print('❌ Error uploading CNIC: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Upload face image to Cloudinary
  /// Returns the secure URL or null on failure
  Future<String?> uploadFaceImage(File image, String uid) async {
    try {
      print('📤 Uploading face image for user: $uid');

      final cloudinary = CloudinaryPublic(
        CloudinaryConfig.cloudName,
        CloudinaryConfig.uploadPreset,
        cache: false,
      );

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          folder: CloudinaryConfig.verificationFacesFolder,
          publicId: uid,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      print('✅ Face image uploaded: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e, stackTrace) {
      print('❌ Error uploading face image: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Upload fingerprint images (both hands) to Cloudinary
  /// Returns map with 'leftHand' and 'rightHand' URLs
  Future<Map<String, String?>> uploadFingerprints({
    required File leftHand,
    required File rightHand,
    required String uid,
  }) async {
    final Map<String, String?> urls = {};

    try {
      print('📤 Uploading fingerprint images for user: $uid');

      final cloudinary = CloudinaryPublic(
        CloudinaryConfig.cloudName,
        CloudinaryConfig.uploadPreset,
        cache: false,
      );

      // Upload left hand
      print('📸 Uploading left hand...');
      final leftResponse = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          leftHand.path,
          folder: CloudinaryConfig.verificationFingerprintsFolder,
          publicId: '${uid}_left',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      urls['leftHand'] = leftResponse.secureUrl;
      print('✅ Left hand uploaded: ${leftResponse.secureUrl}');

      // Upload right hand
      print('📸 Uploading right hand...');
      final rightResponse = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          rightHand.path,
          folder: CloudinaryConfig.verificationFingerprintsFolder,
          publicId: '${uid}_right',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      urls['rightHand'] = rightResponse.secureUrl;
      print('✅ Right hand uploaded: ${rightResponse.secureUrl}');

      return urls;
    } catch (e, stackTrace) {
      print('❌ Error uploading fingerprints: $e');
      print('Stack trace: $stackTrace');
      return urls; // Return partial results if any
    }
  }

  /// Generic upload method for any image type
  Future<String?> uploadImage({
    required File image,
    required String folder,
    required String publicId,
  }) async {
    try {
      print('📤 Uploading image to folder: $folder, publicId: $publicId');

      final cloudinary = CloudinaryPublic(
        CloudinaryConfig.cloudName,
        CloudinaryConfig.uploadPreset,
        cache: false,
      );

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          folder: folder,
          publicId: publicId,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      print('✅ Image uploaded: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e, stackTrace) {
      print('❌ Error uploading image: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}
