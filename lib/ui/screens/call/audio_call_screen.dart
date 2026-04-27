import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../models/call.dart';
import '../../../services/agora_service.dart';
import '../../../services/call_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';

/// Audio Call Screen
/// Displays UI for ongoing audio call with controls
class AudioCallScreen extends ConsumerStatefulWidget {
  final Call call;
  final bool isOutgoing;

  const AudioCallScreen({
    super.key,
    required this.call,
    required this.isOutgoing,
  });

  @override
  ConsumerState<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends ConsumerState<AudioCallScreen> {
  final AgoraService _agoraService = AgoraService();
  final CallService _callService = CallService();

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isConnected = false;
  Timer? _callTimer;
  Timer? _connectionTimeout;
  int _callDuration = 0;
  String _callStatus = 'Connecting...';
  StreamSubscription<Call?>? _callStatusSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCall();
    _listenToCallStatus();
    _startConnectionTimeout();
  }

  /// Listen to call status changes in Firestore
  void _listenToCallStatus() {
    _callStatusSubscription = _callService
        .listenToCallStatus(widget.call.id)
        .listen((updatedCall) {
          if (updatedCall == null) return;

          // If call ended by remote party, close this screen
          if (updatedCall.status.isEnded) {
            debugPrint('🔴 Call ended by remote party');
            _handleCallEnded();
          }
        });
  }

  /// Start connection timeout (30 seconds)
  void _startConnectionTimeout() {
    _connectionTimeout = Timer(const Duration(seconds: 30), () {
      if (!_isConnected) {
        debugPrint('⏰ Connection timeout');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection timeout. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          _endCall();
        }
      }
    });
  }

  /// Handle call ended by remote party
  void _handleCallEnded() {
    _callTimer?.cancel();
    _connectionTimeout?.cancel();
    _agoraService.leaveChannel();
    _agoraService.dispose();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _initializeCall() async {
    try {
      // Initialize Agora
      await _agoraService.initialize();

      // Register event handlers
      _agoraService.registerEventHandlers(
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _isConnected = true;
            _callStatus = 'Connected';
          });
          _startCallTimer();
          print('✅ Remote user joined: $remoteUid');
        },
        onUserOffline: (connection, remoteUid, reason) {
          print('👋 Remote user left: $remoteUid');
          _endCall();
        },
        onError: (err, msg) {
          print('❌ Agora error: $err - $msg');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Call error: $msg')));
        },
      );

      // Join channel
      final channelName = widget.call.channelName ?? 'call_${widget.call.id}';
      const uid = 0; // Use 0 to let Agora assign a unique random UID

      await _agoraService.joinChannel(channelName: channelName, uid: uid);

      // Update call status to connecting
      if (widget.isOutgoing) {
        await _callService.updateCallStatus(
          widget.call.id,
          CallStatus.connecting,
        );
      }
    } catch (e) {
      print('❌ Failed to initialize call: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to connect call')));
        Navigator.pop(context);
      }
    }
  }

  void _startCallTimer() {
    // Cancel timeout when connected
    _connectionTimeout?.cancel();

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    await _agoraService.toggleMute();
    setState(() {
      _isMuted = _agoraService.isMuted;
    });
  }

  Future<void> _toggleSpeaker() async {
    await _agoraService.toggleSpeaker();
    setState(() {
      _isSpeakerOn = _agoraService.isSpeakerOn;
    });
  }

  Future<void> _endCall() async {
    _callTimer?.cancel();
    _connectionTimeout?.cancel();

    // End call for both parties (synchronized)
    await _callService.endCallForBothParties(widget.call.id);

    // Leave channel and cleanup
    await _agoraService.leaveChannel();
    await _agoraService.dispose();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _connectionTimeout?.cancel();
    _callStatusSubscription?.cancel();
    _agoraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = widget.isOutgoing
        ? widget.call.receiverName
        : widget.call.callerName;
    final otherUserPhoto = widget.isOutgoing
        ? widget.call.receiverPhotoUrl
        : widget.call.callerPhotoUrl;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: Spacing.xxxl),

            // User Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: otherUserPhoto != null
                  ? NetworkImage(otherUserPhoto)
                  : null,
              child: otherUserPhoto == null
                  ? Text(
                      otherUser[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: Spacing.xl),

            // User Name
            Text(
              otherUser,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: Spacing.md),

            // Call Status / Duration
            Text(
              _isConnected ? _formatDuration(_callDuration) : _callStatus,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.8),
              ),
            ),

            const Spacer(),

            // Call Controls
            Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Button
                  _CallButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    onPressed: _toggleMute,
                    backgroundColor: _isMuted
                        ? AppColors.error
                        : Colors.white.withOpacity(0.2),
                  ),

                  // End Call Button
                  _CallButton(
                    icon: Icons.call_end,
                    label: 'End',
                    onPressed: _endCall,
                    backgroundColor: AppColors.error,
                    size: 70,
                  ),

                  // Speaker Button
                  _CallButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                    onPressed: _toggleSpeaker,
                    backgroundColor: _isSpeakerOn
                        ? AppColors.success
                        : Colors.white.withOpacity(0.2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.xl),
          ],
        ),
      ),
    );
  }
}

/// Call Control Button Widget
class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final double size;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: size * 0.4),
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
