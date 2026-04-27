import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Agora Audio Call Service
/// Handles audio-only calling using Agora RTC Engine
class AgoraService {
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;

  // Agora App ID from environment
  static String get appId => dotenv.env['AGORA_APP_ID'] ?? '';

  /// Initialize Agora Engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        print('❌ Microphone permission denied');
        throw Exception('Microphone permission required');
      }

      // Create RTC Engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // Enable audio
      await _engine!.enableAudio();
      await _engine!.enableLocalAudio(true);

      // Set audio profile for voice call
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioDefault,
      );

      _isInitialized = true;
      print('✅ Agora Engine initialized');
    } catch (e) {
      print('❌ Failed to initialize Agora: $e');
      rethrow;
    }
  }

  /// Join audio channel
  Future<int?> joinChannel({
    required String channelName,
    required int uid,
    String? token,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      print('📞 Joining channel: $channelName with UID: $uid');

      await _engine!.joinChannel(
        token: token ?? '', // Use empty string for testing without token
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true, // IMPORTANT: Must be true to send audio
          autoSubscribeAudio: true,
        ),
      );

      // Ensure local audio is unmuted
      await _engine!.muteLocalAudioStream(false);

      print('✅ Joined channel successfully');
      return uid;
    } catch (e) {
      print('❌ Failed to join channel: $e');
      return null;
    }
  }

  /// Leave channel
  Future<void> leaveChannel() async {
    try {
      await _engine?.leaveChannel();
      print('👋 Left channel');
    } catch (e) {
      print('❌ Error leaving channel: $e');
    }
  }

  /// Toggle mute/unmute
  Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      await _engine?.muteLocalAudioStream(_isMuted);
      print('🔇 Mute: $_isMuted');
    } catch (e) {
      print('❌ Error toggling mute: $e');
    }
  }

  /// Toggle speaker on/off
  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerOn = !_isSpeakerOn;
      await _engine?.setEnableSpeakerphone(_isSpeakerOn);
      print('🔊 Speaker: $_isSpeakerOn');
    } catch (e) {
      print('❌ Error toggling speaker: $e');
    }
  }

  /// Register event handlers
  void registerEventHandlers({
    required Function(RtcConnection connection, int remoteUid, int elapsed)
    onUserJoined,
    required Function(
      RtcConnection connection,
      int remoteUid,
      UserOfflineReasonType reason,
    )
    onUserOffline,
    required Function(ErrorCodeType err, String msg) onError,
  }) {
    _engine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
          print('✅ Local user joined: ${connection.localUid}');

          // Set speakerphone state when channel is successfully joined
          try {
            await _engine?.setEnableSpeakerphone(_isSpeakerOn);
            print('🔊 Speakerphone successfully set to: $_isSpeakerOn');
          } catch (e) {
            print('⚠️ Failed to set speakerphone state after join: $e');
          }
        },
        onUserJoined: onUserJoined,
        onUserOffline: onUserOffline,
        onError: (ErrorCodeType err, String msg) {
          if (err == ErrorCodeType.errInvalidToken ||
              err == ErrorCodeType.errTokenExpired) {
            print(
              '❌ AGORA TOKEN ERROR: Your Agora project might require a valid token.',
            );
            print(
              '👉 Please ensure "App Certificate" is disabled in Agora Console for testing with empty tokens.',
            );
          }
          onError(err, msg);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print('👋 Left channel - Duration: ${stats.duration}s');
        },
      ),
    );
  }

  /// Dispose engine
  Future<void> dispose() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
      _isInitialized = false;
      print('🗑️ Agora Engine disposed');
    } catch (e) {
      print('❌ Error disposing engine: $e');
    }
  }

  // Getters
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isInitialized => _isInitialized;
}
