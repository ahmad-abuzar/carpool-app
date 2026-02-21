import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cloudinary configuration for image upload and management
class CloudinaryConfig {
  // Load from environment variables
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  // Upload preset name (create this in Cloudinary dashboard)
  static const String uploadPreset = 'carpool_uploads';

  // Folder structure
  static const String verificationFacesFolder = 'verification/faces';
  static const String verificationFingerprintsFolder =
      'verification/fingerprints';
  static const String verificationIdsFolder = 'verification/ids';
  static const String profilePicturesFolder = 'profiles';
  static const String vehicleImagesFolder = 'vehicles';

  // Image transformation presets
  static const String profileImageTransform = 'w_400,h_400,c_fill,g_face';
  static const String thumbnailTransform = 'w_150,h_150,c_fill';
  static const String verificationImageTransform = 'q_auto,f_auto';
}
