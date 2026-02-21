import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Firebase Storage Service
/// Handles file uploads, downloads, and deletions
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload file to Firebase Storage
  Future<String> uploadFile({
    required File file,
    required String path,
    Function(double)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);

      // Listen to upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Wait for upload to complete
      await uploadTask;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw 'Error uploading file: $e';
    }
  }

  /// Upload image from XFile (from image_picker)
  Future<String> uploadImage({
    required XFile image,
    required String path,
    Function(double)? onProgress,
  }) async {
    final file = File(image.path);
    return await uploadFile(file: file, path: path, onProgress: onProgress);
  }

  /// Upload profile picture
  Future<String> uploadProfilePicture({
    required String userId,
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    final path = 'users/$userId/profile.jpg';
    return await uploadFile(
      file: imageFile,
      path: path,
      onProgress: onProgress,
    );
  }

  /// Upload ID document
  Future<String> uploadIdDocument({
    required String userId,
    required File imageFile,
    required String documentType, // 'front' or 'back'
    Function(double)? onProgress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'users/$userId/documents/id_$documentType\_$timestamp.jpg';
    return await uploadFile(
      file: imageFile,
      path: path,
      onProgress: onProgress,
    );
  }

  /// Upload vehicle image
  Future<String> uploadVehicleImage({
    required String userId,
    required String vehicleId,
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'users/$userId/vehicles/$vehicleId\_$timestamp.jpg';
    return await uploadFile(
      file: imageFile,
      path: path,
      onProgress: onProgress,
    );
  }

  /// Upload face verification image
  Future<String> uploadFaceImage({
    required String userId,
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'users/$userId/verification/face_$timestamp.jpg';
    return await uploadFile(
      file: imageFile,
      path: path,
      onProgress: onProgress,
    );
  }

  /// Upload fingerprint image
  Future<String> uploadFingerprintImage({
    required String userId,
    required File imageFile,
    required String fingerType, // 'left' or 'right'
    Function(double)? onProgress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path =
        'users/$userId/verification/fingerprint_$fingerType\_$timestamp.jpg';
    return await uploadFile(
      file: imageFile,
      path: path,
      onProgress: onProgress,
    );
  }

  /// Get download URL for a file
  Future<String> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw 'Error getting download URL: $e';
    }
  }

  /// Delete file from storage
  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      throw 'Error deleting file: $e';
    }
  }

  /// Delete file by URL
  Future<void> deleteFileByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw 'Error deleting file by URL: $e';
    }
  }

  /// Delete all files in a directory
  Future<void> deleteDirectory(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final listResult = await ref.listAll();

      // Delete all files
      for (final item in listResult.items) {
        await item.delete();
      }

      // Recursively delete subdirectories
      for (final prefix in listResult.prefixes) {
        await deleteDirectory(prefix.fullPath);
      }
    } catch (e) {
      throw 'Error deleting directory: $e';
    }
  }

  /// List all files in a directory
  Future<List<String>> listFiles(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final listResult = await ref.listAll();

      final urls = <String>[];
      for (final item in listResult.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      throw 'Error listing files: $e';
    }
  }

  /// Get file metadata
  Future<FullMetadata> getFileMetadata(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getMetadata();
    } catch (e) {
      throw 'Error getting file metadata: $e';
    }
  }

  /// Update file metadata
  Future<void> updateFileMetadata({
    required String path,
    Map<String, String>? customMetadata,
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        customMetadata: customMetadata,
        contentType: contentType,
      );
      await ref.updateMetadata(metadata);
    } catch (e) {
      throw 'Error updating file metadata: $e';
    }
  }
}
