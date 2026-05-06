import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../config/ai_config.dart';

/// AI chatbot service for in-app assistant conversations.
class AIChatbotService {
  final GenerativeModel? _model;

  AIChatbotService() : _model = _buildModel();

  static GenerativeModel? _buildModel() {
    final envApiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    final configuredApiKey = AIConfig.geminiApiKey.trim();
    final apiKey = envApiKey.isNotEmpty ? envApiKey : configuredApiKey;

    if (apiKey.isEmpty) {
      return null;
    }

    return GenerativeModel(
      model: AIConfig.geminiFlashModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: AIConfig.chatbotTemperature,
        maxOutputTokens: 1000,
      ),
    );
  }

  Future<String> generateReply({
    required String userMessage,
    required List<Map<String, String>> conversationHistory,
  }) async {
    final intentReply = _intentReply(userMessage);

    if (_model == null) {
      return intentReply ??
          _fallbackReply(userMessage, conversationHistory.length);
    }

    final recentHistory = conversationHistory.length > 12
        ? conversationHistory.sublist(conversationHistory.length - 12)
        : conversationHistory;

    final historyText = recentHistory
        .map((entry) {
          final role = entry['role'] ?? 'user';
          final text = entry['text'] ?? '';
          return '$role: $text';
        })
        .join('\n');

    final prompt =
        '''
You are EzRide Assistant, a helpful, concise chatbot inside a Pakistan carpool app.

Your job:
- Help users with ride booking flow, safety, payments, profile verification, and messaging etiquette.
- Be practical and action-oriented.
- Give a direct answer in the first sentence, then short steps.
- Keep answers short (2-5 sentences) unless user asks for details.
- If the user asks something outside the app domain, answer briefly and steer back to app help.
- Never invent account-specific data.
- Do not repeat the exact same wording as your previous answer.
- If a user asks a similar question again, rephrase and add one new practical detail.
- Reply in the same language style as the user (English, Urdu Roman, or Urdu).
- If user question is incomplete, ask one clear follow-up question.

Conversation so far:
$historyText

User just asked:
$userMessage
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        return intentReply ??
            _fallbackReply(userMessage, conversationHistory.length);
      }
      return text;
    } catch (_) {
      return intentReply ??
          _fallbackReply(userMessage, conversationHistory.length);
    }
  }

  String? _intentReply(String userMessage) {
    final lower = userMessage.toLowerCase().trim();
    final isRomanUrdu = _isRomanUrdu(lower);

    bool hasAny(List<String> tokens) => tokens.any(lower.contains);

    if (hasAny([
      'book',
      'booking',
      'ride book',
      'ride kr',
      'ride kar',
      'sawari',
    ])) {
      return isRomanUrdu
          ? 'Ride book karne ke liye Home par jao, kisi ride par tap karo, seats aur fare check karo, phir Confirm Booking karo. Agar chaho to main screen-by-screen guide bhi de deta hoon.'
          : 'To book a ride, open Home, select a ride, review seats and fare, then tap Confirm Booking. I can guide you screen by screen if needed.';
    }

    if (hasAny(['payment', 'pay', 'card', 'wallet', 'method'])) {
      return isRomanUrdu
          ? 'Payment settings Profile > Payment Methods mein milengi. Agar payment fail ho to network check karo aur dusra method try karo.'
          : 'Payment settings are in Profile > Payment Methods. If a payment fails, check connectivity and retry with another method.';
    }

    if (hasAny(['verify', 'verification', 'cnic', 'face', 'fingerprint'])) {
      return isRomanUrdu
          ? 'Verification Profile > Verification se hoti hai. CNIC photo clear light mein lo, phir face aur fingerprint steps complete karo.'
          : 'Verification is available in Profile > Verification. Capture a clear CNIC image, then complete face and fingerprint steps.';
    }

    if (hasAny(['chatbot', 'assistant', 'jin', 'jinn', 'ai'])) {
      return isRomanUrdu
          ? 'Main aap ka AI assistant hoon. Aap booking, payment, verification, safety ya app navigation ka koi bhi specific sawal bhejein, main direct jawab dunga.'
          : 'I am your AI assistant. Ask a specific question about booking, payment, verification, safety, or app navigation and I will answer directly.';
    }

    if (lower.length < 5) {
      return isRomanUrdu
          ? 'Thora detail mein batayein ke app mein kis kaam mein issue aa raha hai?'
          : 'Please share a little more detail about what you are trying to do in the app.';
    }

    return null;
  }

  bool _isRomanUrdu(String text) {
    return text.contains('kya') ||
        text.contains('kaise') ||
        text.contains('karna') ||
        text.contains('mujhe') ||
        text.contains('nai') ||
        text.contains('nahi') ||
        text.contains('kyu') ||
        text.contains('kr') ||
        text.contains('hai');
  }

  String _fallbackReply(String userMessage, int historyLength) {
    final lower = userMessage.toLowerCase();
    final variant = historyLength % 3;

    if (lower.contains('book') || lower.contains('ride')) {
      final options = [
        'To book a ride, open Home, select a suggested/search result ride, then complete booking and confirmation.',
        'Quick way: Home -> choose ride -> check seats and fare -> confirm booking. If you want, I can walk you through each screen.',
        'Ride booking is done from Home. Pick a ride, review details, and confirm. Keep payment method ready for faster checkout.',
      ];
      return options[variant];
    }
    if (lower.contains('pay') || lower.contains('payment')) {
      final options = [
        'You can manage payment options in Profile > Payment Methods. If a payment fails, retry with stable internet.',
        'Payment settings are in Profile > Payment Methods. If one method fails, switch method and try again.',
        'Go to Profile > Payment Methods to update your payment source. For failed payments, recheck network and retry once.',
      ];
      return options[variant];
    }
    if (lower.contains('verify') ||
        lower.contains('cnic') ||
        lower.contains('face')) {
      final options = [
        'Verification is available in Profile > Verification. Keep CNIC image clear and well-lit for best results.',
        'Open Profile > Verification and complete CNIC, face, and fingerprint steps in sequence for smooth approval.',
        'For quick verification, use good lighting, hold phone steady, and follow prompts under Profile > Verification.',
      ];
      return options[variant];
    }
    if (lower.contains('safe') || lower.contains('safety')) {
      final options = [
        'For safer rides, prefer verified drivers with strong ratings and confirm pickup in chat before leaving.',
        'Safety tip: share trip details with a trusted contact and use in-app call/chat before pickup.',
        'Pick verified drivers, review ratings, and avoid off-app communication for safer ride coordination.',
      ];
      return options[variant];
    }

    final generic = [
      'I can help with booking, verification, payments, safety, and app navigation. Tell me your goal and I will guide you quickly.',
      'Share what you are trying to do in the app, and I will give you direct steps. I can help with rides, payments, and verification.',
      'I can guide you across EzRide features. Ask me a specific task like booking, profile verification, or payment setup.',
    ];
    return generic[variant];
  }
}
