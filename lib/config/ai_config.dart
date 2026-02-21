/// AI Configuration
/// Manages API keys and AI service settings
class AIConfig {
  // Gemini API Configuration
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // Model Selection
  static const String geminiFlashModel = 'gemini-1.5-flash-latest';
  static const String geminiProModel = 'gemini-1.5-pro-latest';

  // Rate Limiting
  static const int maxRequestsPerMinute = 60;
  static const int maxTokensPerRequest = 8000;

  // Caching Configuration
  static const Duration cacheDuration = Duration(hours: 1);
  static const int maxCacheSize = 100;

  // Temperature settings (0.0 - 1.0)
  static const double chatbotTemperature = 0.7; // More creative
  static const double analysisTemperature = 0.3; // More deterministic

  // Fallback Configuration
  static const bool enableFallback = true;
  static const int maxRetries = 3;

  // Validate configuration
  static bool get isConfigured => geminiApiKey.isNotEmpty;

  // Get API key from environment or throw error
  static String getApiKey() {
    if (!isConfigured) {
      throw Exception(
        'Gemini API key not configured. Please set GEMINI_API_KEY environment variable.',
      );
    }
    return geminiApiKey;
  }
}
