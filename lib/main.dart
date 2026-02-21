import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/data_seeding_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables for Cloudinary and other configs
  try {
    await dotenv.load(fileName: ".env");
    print('Environment variables loaded successfully');
  } catch (e) {
    print('Warning: .env file not found. Using default values.');
    print('Create a .env file with your Cloudinary credentials.');
  }

  // Initialize Firebase (only if not already initialized)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    // Firebase might already be initialized, which is fine
    print('Firebase initialization: $e');
  }

  // Seed test data (only runs if database is empty)
  try {
    print('🌱 Checking if test data is needed...');
    final seeder = DataSeedingService();
    await seeder.seedRidesOnly();
  } catch (e) {
    print('⚠️ Data seeding skipped or failed: $e');
    print('   (This is normal if data already exists)');
  }

  runApp(Phoenix(child: const ProviderScope(child: CarpoolApp())));
}
