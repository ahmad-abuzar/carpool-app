import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/call.dart';
import '../../services/call_service.dart';
import '../../services/call_notification_service.dart';
import '../../state/providers.dart';
import '../screens/call/incoming_call_screen.dart';

/// Wrapper to listen for incoming calls globally
class CallListenerWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  const CallListenerWrapper({
    super.key,
    required this.child,
    this.navigatorKey,
  });

  @override
  ConsumerState<CallListenerWrapper> createState() =>
      _CallListenerWrapperState();
}

class _CallListenerWrapperState extends ConsumerState<CallListenerWrapper> {
  final CallService _callService = CallService();
  final CallNotificationService _notificationService =
      CallNotificationService();
  StreamSubscription<Call?>? _callSubscription;
  bool _isIncomingCallScreenShowing = false;

  @override
  void initState() {
    super.initState();
    // Delay listener initialization to ensure user is logged in
    Future.delayed(const Duration(seconds: 2), _initializeListener);
  }

  void _initializeListener() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    print('🎧 Initializing Call Listener for ${currentUser.name}');

    _callSubscription = _callService
        .listenForIncomingCalls(currentUser.id)
        .listen((call) {
          if (call != null && call.status == CallStatus.ringing) {
            if (!_isIncomingCallScreenShowing) {
              _showIncomingCallScreen(call);
            }
          }
        });
  }

  void _showIncomingCallScreen(Call call) {
    if (!mounted) return;

    _isIncomingCallScreenShowing = true;
    print('📞 Incoming call from ${call.callerName}');

    // Use navigator key context if available, otherwise fall back to local context
    // This allows the wrapper to work when placed above the Navigator in the widget tree
    final navContext = widget.navigatorKey?.currentContext ?? context;

    Navigator.of(navContext)
        .push(
          MaterialPageRoute(
            builder: (context) => IncomingCallScreen(call: call),
          ),
        )
        .then((_) {
          _isIncomingCallScreenShowing = false;
        });
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-initialize if user changes (login/logout)
    ref.listen(currentUserProvider, (previous, next) {
      _callSubscription?.cancel();
      if (next != null) {
        _initializeListener();
      }
    });

    return widget.child;
  }
}
