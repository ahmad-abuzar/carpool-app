import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/call.dart';

/// Service for making phone calls and handling call-related functionality
class CallService {
  /// Make a phone call to the given number
  /// Returns true if call was initiated successfully
  static Future<bool> makeCall(String phoneNumber) async {
    try {
      // Clean the phone number (remove spaces, dashes, etc.)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      if (cleanNumber.isEmpty) {
        debugPrint('❌ Invalid phone number: $phoneNumber');
        return false;
      }

      final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);

      debugPrint('📞 Attempting to call: $cleanNumber');

      if (await canLaunchUrl(launchUri)) {
        final result = await launchUrl(launchUri);
        if (result) {
          debugPrint('✅ Call initiated successfully');
        } else {
          debugPrint('❌ Failed to launch dialer');
        }
        return result;
      } else {
        debugPrint('❌ Cannot launch phone dialer');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error making call: $e');
      return false;
    }
  }

  /// Make a call with user feedback (shows snackbar on error)
  static Future<void> makeCallWithFeedback(
    BuildContext context,
    String phoneNumber,
  ) async {
    final success = await makeCall(phoneNumber);

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Could not make the call. Please try again.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Send SMS to the given number
  static Future<bool> sendSMS(String phoneNumber, {String? message}) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      if (cleanNumber.isEmpty) {
        debugPrint('❌ Invalid phone number: $phoneNumber');
        return false;
      }

      final Uri launchUri = Uri(
        scheme: 'sms',
        path: cleanNumber,
        queryParameters: message != null ? {'body': message} : null,
      );

      debugPrint('💬 Attempting to send SMS to: $cleanNumber');

      if (await canLaunchUrl(launchUri)) {
        final result = await launchUrl(launchUri);
        if (result) {
          debugPrint('✅ SMS app opened successfully');
        }
        return result;
      } else {
        debugPrint('❌ Cannot launch SMS app');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending SMS: $e');
      return false;
    }
  }

  /// Open WhatsApp chat with the given number
  static Future<bool> openWhatsApp(
    String phoneNumber, {
    String? message,
  }) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      if (cleanNumber.isEmpty) {
        debugPrint('❌ Invalid phone number: $phoneNumber');
        return false;
      }

      // Remove leading + or 0
      String whatsappNumber = cleanNumber;
      if (whatsappNumber.startsWith('+')) {
        whatsappNumber = whatsappNumber.substring(1);
      } else if (whatsappNumber.startsWith('0')) {
        // Assuming Pakistan (+92), replace 0 with country code
        whatsappNumber = '92${whatsappNumber.substring(1)}';
      }

      final Uri launchUri = Uri.parse(
        'https://wa.me/$whatsappNumber${message != null ? '?text=${Uri.encodeComponent(message)}' : ''}',
      );

      debugPrint('💚 Attempting to open WhatsApp: $whatsappNumber');

      if (await canLaunchUrl(launchUri)) {
        final result = await launchUrl(
          launchUri,
          mode: LaunchMode.externalApplication,
        );
        if (result) {
          debugPrint('✅ WhatsApp opened successfully');
        }
        return result;
      } else {
        debugPrint('❌ Cannot open WhatsApp');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error opening WhatsApp: $e');
      return false;
    }
  }

  /// Show contact options bottom sheet
  static void showContactOptions(
    BuildContext context, {
    required String name,
    required String phoneNumber,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        phoneNumber,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Contact via:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            // Call option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.phone, color: Colors.green.shade700),
              ),
              title: const Text('Phone Call'),
              subtitle: const Text('Make a voice call'),
              onTap: () {
                Navigator.pop(context);
                makeCallWithFeedback(context, phoneNumber);
              },
            ),

            // SMS option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.message, color: Colors.blue.shade700),
              ),
              title: const Text('SMS'),
              subtitle: const Text('Send a text message'),
              onTap: () {
                Navigator.pop(context);
                sendSMS(phoneNumber);
              },
            ),

            // WhatsApp option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chat, color: Colors.green.shade700),
              ),
              title: const Text('WhatsApp'),
              subtitle: const Text('Chat on WhatsApp'),
              onTap: () {
                Navigator.pop(context);
                openWhatsApp(phoneNumber);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ========== AGORA IN-APP CALLING ==========

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initiate an in-app audio call using Agora
  Future<Call?> initiateAgoraCall({
    required String callerId,
    required String callerName,
    String? callerPhotoUrl,
    required String receiverId,
    required String receiverName,
    String? receiverPhotoUrl,
  }) async {
    try {
      final callId = const Uuid().v4();
      final channelName = 'call_$callId';
      final agoraUid = DateTime.now().millisecondsSinceEpoch;

      final call = Call(
        id: callId,
        callerId: callerId,
        callerName: callerName,
        callerPhotoUrl: callerPhotoUrl,
        receiverId: receiverId,
        receiverName: receiverName,
        receiverPhotoUrl: receiverPhotoUrl,
        type: CallType.audio,
        status: CallStatus.ringing,
        createdAt: DateTime.now(),
        channelName: channelName,
        agoraUid: agoraUid,
      );

      // Save call to Firestore
      await _firestore.collection('calls').doc(callId).set(call.toMap());

      debugPrint('✅ Agora call initiated: $callId');
      return call;
    } catch (e) {
      debugPrint('❌ Error initiating Agora call: $e');
      return null;
    }
  }

  /// Update call status
  Future<void> updateCallStatus(String callId, CallStatus status) async {
    try {
      await _firestore.collection('calls').doc(callId).update({
        'status': status.name,
        if (status == CallStatus.connected)
          'startedAt': DateTime.now().millisecondsSinceEpoch,
        if (status.isEnded) 'endedAt': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('✅ Call status updated: $status');
    } catch (e) {
      debugPrint('❌ Error updating call status: $e');
    }
  }

  /// Listen to incoming calls for a user
  Stream<Call?> listenForIncomingCalls(String userId) {
    return _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: CallStatus.ringing.name)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return Call.fromMap(snapshot.docs.first.data());
        });
  }

  /// Listen to call status updates for a specific call
  Stream<Call?> listenToCallStatus(String callId) {
    return _firestore.collection('calls').doc(callId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      return Call.fromMap(snapshot.data()!);
    });
  }

  /// End call for both parties
  Future<void> endCallForBothParties(String callId) async {
    try {
      await _firestore.collection('calls').doc(callId).update({
        'status': CallStatus.ended.name,
        'endedAt': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('✅ Call ended for both parties: $callId');
    } catch (e) {
      debugPrint('❌ Error ending call for both parties: $e');
    }
  }

  /// Cancel a call (before it's answered)
  Future<void> cancelCall(String callId) async {
    try {
      final doc = await _firestore.collection('calls').doc(callId).get();
      if (doc.exists) {
        final call = Call.fromMap(doc.data()!);
        // Only cancel if still ringing or connecting
        if (call.status == CallStatus.ringing ||
            call.status == CallStatus.connecting) {
          await updateCallStatus(callId, CallStatus.ended);
          debugPrint('✅ Call cancelled: $callId');
        }
      }
    } catch (e) {
      debugPrint('❌ Error cancelling call: $e');
    }
  }

  /// Auto-end calls that are stuck in ringing/connecting state
  Future<void> cleanupStaleCalls(
    String userId, {
    int timeoutMinutes = 2,
  }) async {
    try {
      final cutoffTime = DateTime.now()
          .subtract(Duration(minutes: timeoutMinutes))
          .millisecondsSinceEpoch;

      // Check calls where user is caller
      final callerCalls = await _firestore
          .collection('calls')
          .where('callerId', isEqualTo: userId)
          .where('createdAt', isLessThan: cutoffTime)
          .get();

      for (var doc in callerCalls.docs) {
        final call = Call.fromMap(doc.data());
        if (call.status == CallStatus.ringing ||
            call.status == CallStatus.connecting) {
          await updateCallStatus(call.id, CallStatus.missed);
          debugPrint('🧹 Cleaned up stale call: ${call.id}');
        }
      }

      // Check calls where user is receiver
      final receiverCalls = await _firestore
          .collection('calls')
          .where('receiverId', isEqualTo: userId)
          .where('createdAt', isLessThan: cutoffTime)
          .get();

      for (var doc in receiverCalls.docs) {
        final call = Call.fromMap(doc.data());
        if (call.status == CallStatus.ringing ||
            call.status == CallStatus.connecting) {
          await updateCallStatus(call.id, CallStatus.missed);
          debugPrint('🧹 Cleaned up stale call: ${call.id}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up stale calls: $e');
    }
  }
}
