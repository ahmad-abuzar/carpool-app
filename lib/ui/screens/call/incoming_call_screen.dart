import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/call.dart';
import '../../../services/call_service.dart';
import '../../../services/call_notification_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import 'audio_call_screen.dart';

/// Incoming Call Screen
/// Shows when receiving an audio call
class IncomingCallScreen extends StatefulWidget {
  final Call call;

  const IncomingCallScreen({super.key, required this.call});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final CallService _callService = CallService();
  final CallNotificationService _notificationService =
      CallNotificationService();
  StreamSubscription<Call?>? _callStatusSubscription;

  @override
  void initState() {
    super.initState();
    _startRingtone();
    _listenForCallCancellation();
  }

  /// Start ringtone and vibration
  Future<void> _startRingtone() async {
    await _notificationService.startRinging();
    debugPrint('🔔 Ringtone started for incoming call');
  }

  /// Stop ringtone and vibration
  Future<void> _stopRingtone() async {
    await _notificationService.stopRinging();
    debugPrint('🔕 Ringtone stopped');
  }

  /// Listen for call cancellation by caller
  void _listenForCallCancellation() {
    _callStatusSubscription = _callService
        .listenToCallStatus(widget.call.id)
        .listen((updatedCall) {
          if (updatedCall == null || updatedCall.status.isEnded) {
            debugPrint('📵 Call was cancelled by caller');
            _handleCallCancelled();
          }
        });
  }

  /// Handle call cancellation by caller
  void _handleCallCancelled() {
    _stopRingtone();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Call was cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _acceptCall() async {
    try {
      // Stop ringtone
      await _stopRingtone();

      // Update call status to connecting
      await _callService.updateCallStatus(
        widget.call.id,
        CallStatus.connecting,
      );

      // Navigate to audio call screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AudioCallScreen(call: widget.call, isOutgoing: false),
          ),
        );
      }
    } catch (e) {
      print('❌ Error accepting call: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to accept call')));
    }
  }

  Future<void> _rejectCall() async {
    try {
      // Stop ringtone
      await _stopRingtone();

      // Update call status to rejected
      await _callService.updateCallStatus(widget.call.id, CallStatus.rejected);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error rejecting call: $e');
    }
  }

  @override
  void dispose() {
    _stopRingtone();
    _callStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: Spacing.xxxl * 2),

            // Caller Avatar
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: widget.call.callerPhotoUrl != null
                  ? NetworkImage(widget.call.callerPhotoUrl!)
                  : null,
              child: widget.call.callerPhotoUrl == null
                  ? Text(
                      widget.call.callerName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 56,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: Spacing.xl),

            // Caller Name
            Text(
              widget.call.callerName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: Spacing.md),

            // Call Type
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'Incoming Audio Call',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Call Action Buttons
            Padding(
              padding: const EdgeInsets.all(Spacing.xxxl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: AppColors.error,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _rejectCall,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 70,
                            height: 70,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      const Text(
                        'Decline',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),

                  // Accept Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: AppColors.success,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _acceptCall,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 70,
                            height: 70,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.phone,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      const Text(
                        'Accept',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
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
