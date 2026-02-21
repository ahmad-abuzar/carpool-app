import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/message.dart';
import '../../../state/providers.dart';
import '../../../services/call_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../call/audio_call_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? rideId;

  const ChatScreen({super.key, required this.userId, this.rideId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CallService _callService = CallService();

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      await ref
          .read(messagingServiceProvider)
          .markMessagesAsRead(currentUser.id, widget.userId);
    }
  }

  Future<void> _initiateAudioCall(
    dynamic currentUser,
    dynamic otherUser,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Initiate Agora call
      final call = await _callService.initiateAgoraCall(
        callerId: currentUser.id,
        callerName: currentUser.name,
        callerPhotoUrl: currentUser.profileImageUrl ?? currentUser.avatarUrl,
        receiverId: otherUser.id,
        receiverName: otherUser.name,
        receiverPhotoUrl: otherUser.profileImageUrl ?? otherUser.avatarUrl,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (call != null) {
          // Navigate to audio call screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AudioCallScreen(call: call, isOutgoing: true),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to initiate call')),
          );
        }
      }
    } catch (e) {
      print('❌ Error initiating call: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final otherUserAsync = ref.watch(userProvider(widget.userId));
    final messagesAsync = ref.watch(messagesProvider(widget.userId));

    return otherUserAsync.when(
      data: (otherUser) {
        if (otherUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: const Center(child: Text('User not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    otherUser.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            otherUser.name,
                            style: AppTypography.body(
                              context,
                              weight: FontWeight.w600,
                            ),
                          ),
                          if (otherUser.idVerified) ...[
                            const SizedBox(width: Spacing.xs),
                            const Icon(Icons.verified, size: 14),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: Spacing.xs),
                          Text(
                            otherUser.rating.toStringAsFixed(1),
                            style: AppTypography.labelSmall(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () => _initiateAudioCall(currentUser, otherUser),
                tooltip: 'Audio Call',
              ),
            ],
          ),
          body: Column(
            children: [
              // Ride info banner (if associated with a ride)
              if (widget.rideId != null)
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  color: AppColors.primaryContainer,
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car, size: 20),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Text(
                          'Ride conversation',
                          style: AppTypography.bodySmall(context),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to ride details
                        },
                        child: const Text('View Ride'),
                      ),
                    ],
                  ),
                ),

              // Messages list
              Expanded(
                child: messagesAsync.when(
                  data: (messages) => ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Newest messages at bottom
                    padding: const EdgeInsets.all(Spacing.lg),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      // Reverse index to show correct order
                      final message = messages[messages.length - 1 - index];
                      final isMe = message.senderId == currentUser?.id;
                      final timeFormat = DateFormat('h:mm a');

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: Spacing.lg),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              // Sender avatar for incoming messages
                              if (!isMe) ...[
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      child: Text(
                                        otherUser.name[0].toUpperCase(),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: Spacing.sm),
                                    Text(
                                      otherUser.name,
                                      style: AppTypography.labelSmall(
                                        context,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: Spacing.xs),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Spacing.lg,
                                  vertical: Spacing.lg,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(
                                      Spacing.radiusLg,
                                    ),
                                    topRight: const Radius.circular(
                                      Spacing.radiusLg,
                                    ),
                                    bottomLeft: Radius.circular(
                                      isMe
                                          ? Spacing.radiusLg
                                          : Spacing.radiusSm,
                                    ),
                                    bottomRight: Radius.circular(
                                      isMe
                                          ? Spacing.radiusSm
                                          : Spacing.radiusLg,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  message.content,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.4,
                                    color: isMe
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(height: Spacing.xs),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    timeFormat.format(message.timestamp),
                                    style: AppTypography.labelSmall(context),
                                  ),
                                  // Read receipt indicators
                                  if (isMe) ...[
                                    const SizedBox(width: Spacing.xs),
                                    Icon(
                                      message.read
                                          ? Icons.done_all
                                          : Icons.done,
                                      size: 14,
                                      color: message.read
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withOpacity(0.6),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),

              // Quick replies
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.sm,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickReplyChip(
                        label: 'I\'m here',
                        onTap: () => _sendQuickReply('I\'m here', currentUser!),
                      ),
                      const SizedBox(width: Spacing.sm),
                      _QuickReplyChip(
                        label: '5 mins late',
                        onTap: () => _sendQuickReply(
                          'Running 5 minutes late',
                          currentUser!,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      _QuickReplyChip(
                        label: 'On my way',
                        onTap: () =>
                            _sendQuickReply('On my way!', currentUser!),
                      ),
                    ],
                  ),
                ),
              ),

              // Message input
              Container(
                padding: const EdgeInsets.all(Spacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Spacing.radiusXl,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: Spacing.lg,
                              vertical: Spacing.md,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      IconButton.filled(
                        onPressed: () {
                          if (_messageController.text.isNotEmpty &&
                              currentUser != null) {
                            _sendMessage(_messageController.text, currentUser);
                            _messageController.clear();
                          }
                        },
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  void _sendMessage(String content, dynamic currentUser) {
    final conversationId = _getConversationId(currentUser.id, widget.userId);
    final message = Message(
      id: '', // Will be set by service/firestore
      conversationId: conversationId,
      senderId: currentUser.id,
      receiverId: widget.userId,
      content: content,
      timestamp: DateTime.now(),
      rideId: widget.rideId,
    );

    ref.read(messagingServiceProvider).sendMessage(message);

    // With reverse: true, ListView automatically maintains scroll position
    // No manual scrolling needed
  }

  void _sendQuickReply(String message, dynamic currentUser) {
    _sendMessage(message, currentUser);
  }

  String _getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}

class _QuickReplyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickReplyChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}
