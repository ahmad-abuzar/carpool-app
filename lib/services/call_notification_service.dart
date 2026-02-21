import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

/// Service for handling call notifications (ringtone, vibration)
class CallNotificationService {
  static final CallNotificationService _instance =
      CallNotificationService._internal();
  factory CallNotificationService() => _instance;
  CallNotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  /// Start ringing for incoming call
  Future<void> startRinging() async {
    if (_isPlaying) return;

    try {
      _isPlaying = true;

      // Play default notification sound on loop
      // Note: Using a system sound. For custom ringtone, add asset to pubspec.yaml
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);

      // Use a simple beep sound (you can replace with custom ringtone asset)
      // For now, we'll use URL to a ringtone or you can add a local asset
      // await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));

      // Alternative: Play a system notification sound
      // Since we don't have a custom ringtone asset, we'll use AssetSource
      // You can add a ringtone.mp3 file to assets/sounds/ and uncomment below:
      // await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));

      debugPrint('🔔 Ringtone started');

      // Start vibration pattern
      _startVibration();
    } catch (e) {
      debugPrint('❌ Error starting ringtone: $e');
      _isPlaying = false;
    }
  }

  /// Stop ringing
  Future<void> stopRinging() async {
    if (!_isPlaying) return;

    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      debugPrint('🔕 Ringtone stopped');

      // Stop vibration
      await Vibration.cancel();
    } catch (e) {
      debugPrint('❌ Error stopping ringtone: $e');
    }
  }

  /// Start vibration pattern for incoming call
  Future<void> _startVibration() async {
    try {
      // Check if device supports vibration
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Vibration pattern: [wait, vibrate, wait, vibrate, ...]
        // Pattern: wait 500ms, vibrate 1000ms, wait 500ms, vibrate 1000ms
        final pattern = [500, 1000, 500, 1000, 500, 1000];

        // Note: On Android, pattern vibration repeats automatically
        // On iOS, we need to call it repeatedly (not supported the same way)
        await Vibration.vibrate(pattern: pattern, repeat: 0);
        debugPrint('📳 Vibration started');
      }
    } catch (e) {
      debugPrint('❌ Error starting vibration: $e');
    }
  }

  /// Play a single vibration (for button press, etc.)
  Future<void> vibrateOnce({int duration = 100}) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: duration);
      }
    } catch (e) {
      debugPrint('❌ Error vibrating: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopRinging();
    await _audioPlayer.dispose();
  }
}
