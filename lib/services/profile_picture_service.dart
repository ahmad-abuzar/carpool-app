import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import '../config/cloudinary_config.dart';

/// Service for managing profile picture uploads
class ProfilePictureService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  /// Upload profile picture to Cloudinary
  Future<String?> uploadProfilePicture(File image, String userId) async {
    try {
      // Validate Cloudinary configuration
      if (CloudinaryConfig.cloudName.isEmpty) {
        print('ERROR: CLOUDINARY_CLOUD_NAME is not set in .env file');
        throw Exception('Cloudinary not configured: Cloud name is missing');
      }

      if (CloudinaryConfig.uploadPreset.isEmpty) {
        print('ERROR: Cloudinary upload preset is not set');
        print(
          'SOLUTION: Create an unsigned upload preset in Cloudinary dashboard',
        );
        throw Exception('Cloudinary not configured: Upload preset is missing');
      }

      print('Cloudinary Config:');
      print('  Cloud Name: ${CloudinaryConfig.cloudName}');
      print('  Upload Preset: ${CloudinaryConfig.uploadPreset}');
      print('  Uploading for user: $userId');

      // Initialize Cloudinary
      final cloudinary = CloudinaryPublic(
        CloudinaryConfig.cloudName,
        CloudinaryConfig.uploadPreset,
        cache: false,
      );

      print('Cloudinary initialized successfully');
      print('Uploading image: ${image.path}');

      // Upload to Cloudinary with transformations
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          folder: CloudinaryConfig.profilePicturesFolder,
          publicId: userId,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      print('Profile picture uploaded successfully!');
      print('Secure URL: ${response.secureUrl}');

      // Return the secure URL
      return response.secureUrl;
    } catch (e) {
      print('============ UPLOAD ERROR ============');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');

      if (e.toString().contains('NotInitializedError')) {
        print('');
        print('SOLUTION:');
        print('1. Go to https://cloudinary.com/console');
        print('2. Navigate to Settings > Upload');
        print('3. Scroll to "Upload presets"');
        print('4. Click "Add upload preset"');
        print('5. Set preset name: carpool_uploads');
        print('6. Set signing mode: Unsigned');
        print('7. Save the preset');
        print('=====================================');
      }

      return null;
    }
  }

  /// Get transformed profile picture URL
  /// Applies circular crop and optimization
  String getTransformedProfilePictureUrl(String originalUrl) {
    // If using Cloudinary, add transformations
    if (originalUrl.contains('cloudinary.com')) {
      // Extract base URL and public ID
      final urlParts = originalUrl.split('/upload/');
      if (urlParts.length == 2) {
        // Add transformation: circular crop, auto quality, auto format
        return '${urlParts[0]}/upload/w_400,h_400,c_fill,g_face,r_max,q_auto,f_auto/${urlParts[1]}';
      }
    }
    return originalUrl;
  }

  /// Delete profile picture from Cloudinary
  /// Note: This requires server-side implementation with Admin API
  /// For now, we'll just return success and handle deletion server-side
  Future<bool> deleteProfilePicture(String userId) async {
    try {
      // In a real implementation, you would call your backend API
      // which would use Cloudinary Admin API to delete the image
      print('Profile picture deletion requested for user: $userId');
      return true;
    } catch (e) {
      print('Error deleting profile picture: $e');
      return false;
    }
  }
}
