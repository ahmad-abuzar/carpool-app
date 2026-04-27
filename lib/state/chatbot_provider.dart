import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai/ai_chatbot_service.dart';

enum ChatbotRole { user, assistant }

class ChatbotMessage {
  final String text;
  final ChatbotRole role;
  final DateTime timestamp;

  const ChatbotMessage({
    required this.text,
    required this.role,
    required this.timestamp,
  });
}

class ChatbotState {
  final List<ChatbotMessage> messages;
  final bool isSending;
  final String? error;

  const ChatbotState({
    required this.messages,
    required this.isSending,
    this.error,
  });

  factory ChatbotState.initial() {
    return ChatbotState(
      messages: [
        ChatbotMessage(
          text:
              'Hi! I am your EzRide Assistant. Ask me about booking, payments, verification, safety, or anything in the app.',
          role: ChatbotRole.assistant,
          timestamp: DateTime.now(),
        ),
      ],
      isSending: false,
    );
  }

  ChatbotState copyWith({
    List<ChatbotMessage>? messages,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final aiChatbotServiceProvider = Provider<AIChatbotService>((ref) {
  return AIChatbotService();
});

final chatbotProvider = StateNotifierProvider<ChatbotNotifier, ChatbotState>((
  ref,
) {
  return ChatbotNotifier(ref.watch(aiChatbotServiceProvider));
});

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  final AIChatbotService _chatbotService;

  ChatbotNotifier(this._chatbotService) : super(ChatbotState.initial());

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final userMessage = ChatbotMessage(
      text: trimmed,
      role: ChatbotRole.user,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMessage];
    state = state.copyWith(
      messages: _truncate(updatedMessages),
      isSending: true,
      clearError: true,
    );

    try {
      final history = updatedMessages
          .map(
            (m) => {
              'role': m.role == ChatbotRole.user ? 'user' : 'assistant',
              'text': m.text,
            },
          )
          .toList();

      final reply = await _chatbotService.generateReply(
        userMessage: trimmed,
        conversationHistory: history,
      );

      final finalReply = _avoidDuplicateReply(
        reply: reply,
        messages: updatedMessages,
        userMessage: trimmed,
      );

      final assistantMessage = ChatbotMessage(
        text: finalReply,
        role: ChatbotRole.assistant,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: _truncate([...updatedMessages, assistantMessage]),
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'Could not send message. Please try again.',
      );
    }
  }

  void clearConversation() {
    state = ChatbotState.initial();
  }

  String _avoidDuplicateReply({
    required String reply,
    required List<ChatbotMessage> messages,
    required String userMessage,
  }) {
    final previousAssistant = messages
        .where((m) => m.role == ChatbotRole.assistant)
        .map((m) => m.text)
        .toList();

    if (previousAssistant.isEmpty) return reply;

    final lastAssistant = previousAssistant.last;
    final isDuplicate = _normalize(reply) == _normalize(lastAssistant);
    if (!isDuplicate) return reply;

    final lower = userMessage.toLowerCase();
    if (lower.contains('book') || lower.contains('ride')) {
      return 'Aik alternate tareeqa: Home screen se ride open karein, fare aur seats verify karein, phir booking confirm karein.';
    }
    if (lower.contains('pay') || lower.contains('payment')) {
      return 'Alternative: pehle Profile > Payment Methods mein method update karein, phir booking payment retry karein.';
    }
    if (lower.contains('verify') || lower.contains('cnic')) {
      return 'Alternative: verification se pehle camera clean karein aur bright light use karein, phir Profile > Verification flow complete karein.';
    }

    return '$reply\n\nAgar aap chaho to main is ko step-by-step short checklist mein bhi de sakta hoon.';
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), '')
        .trim();
  }

  List<ChatbotMessage> _truncate(List<ChatbotMessage> messages) {
    const maxMessages = 40;
    if (messages.length <= maxMessages) return messages;
    return messages.sublist(messages.length - maxMessages);
  }
}
