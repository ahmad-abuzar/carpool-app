import 'package:google_generative_ai/google_generative_ai.dart';
import '../../config/ai_config.dart';

/// AI Chatbot Service
/// Bilingual (Urdu/English) customer support chatbot using Gemini
class AIChatbotService {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  AIChatbotService() {
    _model = GenerativeModel(
      model: AIConfig.geminiFlashModel,
      apiKey: AIConfig.getApiKey(),
      generationConfig: GenerationConfig(
        temperature: AIConfig.chatbotTemperature,
        maxOutputTokens: 500,
      ),
      systemInstruction: Content.system(_getSystemPrompt()),
    );
    _chatSession = _model.startChat();
  }

  /// System prompt for the chatbot
  String _getSystemPrompt() {
    return '''
You are a helpful customer support assistant for a carpool app in Pakistan called "EzRide".

Your role:
- Answer questions about how to use the app
- Help with booking, payment, and verification issues
- Provide ride suggestions
- Handle complaints professionally
- Support both English and Urdu languages

Guidelines:
1. Be friendly, professional, and concise
2. If user writes in Urdu, respond in Urdu
3. If user writes in English, respond in English
4. Keep responses under 100 words
5. If you don't know something, admit it and offer to connect them with human support
6. Never make up information about rides, prices, or policies
7. Use Pakistani context (PKR currency, local cities, cultural norms)

Common Topics:
- How to book a ride
- How to offer a ride as a driver
- Payment methods (Cash, Card, JazzCash, EasyPaisa)
- Verification process (ID, face, fingerprints)
- Safety features
- Cancellation policies
- Rating system

Example interactions:
User: "How do I book a ride?"
You: "To book a ride: 1) Search for your destination, 2) Select a ride that fits your schedule, 3) Choose number of seats, 4) Confirm booking and payment method. You'll get driver details after confirmation!"

User: "میں رائیڈ کیسے بک کروں؟"
You: "رائیڈ بک کرنے کے لیے: 1) اپنی منزل تلاش کریں، 2) اپنے وقت کے مطابق رائیڈ منتخب کریں، 3) سیٹوں کی تعداد چنیں، 4) بکنگ اور ادائیگی کی تصدیق کریں۔ تصدیق کے بعد آپ کو ڈرائیور کی تفصیلات مل جائیں گی!"
''';
  }

  /// Send message to chatbot
  Future<String> sendMessage(String message) async {
    try {
      final response = await _chatSession.sendMessage(Content.text(message));
      return response.text ??
          'I apologize, I could not process that. Please try again.';
    } catch (e) {
      print('Chatbot error: $e');
      return _getFallbackResponse(message);
    }
  }

  /// Get chat history
  List<Content> getChatHistory() {
    return _chatSession.history.toList();
  }

  /// Reset chat session
  void resetChat() {
    _chatSession = _model.startChat();
  }

  /// Fallback responses for common queries
  String _getFallbackResponse(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('book') || lowerMessage.contains('بک')) {
      return 'To book a ride, search for your destination, select a ride, and confirm your booking. Need more help? Contact support.';
    } else if (lowerMessage.contains('payment') ||
        lowerMessage.contains('ادائیگی')) {
      return 'We accept Cash, Card, JazzCash, and EasyPaisa. You can select your payment method during booking.';
    } else if (lowerMessage.contains('cancel') ||
        lowerMessage.contains('منسوخ')) {
      return 'You can cancel a booking from "My Rides" section. Cancellation policies apply based on timing.';
    } else if (lowerMessage.contains('verify') ||
        lowerMessage.contains('تصدیق')) {
      return 'Verification includes ID upload, face scan, and fingerprints. Go to Profile > Verification to start.';
    } else {
      return 'I\'m here to help! Please ask about bookings, payments, verification, or any other app features.';
    }
  }

  /// Quick help for common topics
  Future<String> getQuickHelp(String topic) async {
    final prompts = {
      'booking': 'Explain how to book a ride in 2-3 sentences.',
      'offering_ride':
          'Explain how to offer a ride as a driver in 2-3 sentences.',
      'payment': 'Explain available payment methods in 2-3 sentences.',
      'verification': 'Explain the verification process in 2-3 sentences.',
      'safety': 'Explain safety features in 2-3 sentences.',
      'cancellation': 'Explain cancellation policy in 2-3 sentences.',
    };

    final prompt = prompts[topic];
    if (prompt == null) {
      return 'Topic not found. Please ask a specific question.';
    }

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? _getFallbackResponse(topic);
    } catch (e) {
      return _getFallbackResponse(topic);
    }
  }

  /// Detect language of message
  String detectLanguage(String message) {
    // Simple detection: if contains Urdu characters, it's Urdu
    final urduPattern = RegExp(r'[\u0600-\u06FF]');
    return urduPattern.hasMatch(message) ? 'ur' : 'en';
  }

  /// Get suggested questions
  List<String> getSuggestedQuestions(String language) {
    if (language == 'ur') {
      return [
        'میں رائیڈ کیسے بک کروں؟',
        'ادائیگی کے کیا طریقے ہیں؟',
        'تصدیق کیسے کروں؟',
        'بکنگ کیسے منسوخ کروں؟',
        'ڈرائیور کیسے بنوں؟',
      ];
    } else {
      return [
        'How do I book a ride?',
        'What payment methods are available?',
        'How do I verify my account?',
        'How do I cancel a booking?',
        'How do I become a driver?',
      ];
    }
  }
}
