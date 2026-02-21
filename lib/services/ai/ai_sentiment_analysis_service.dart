import 'package:google_generative_ai/google_generative_ai.dart';
import '../../config/ai_config.dart';

/// AI Sentiment Analysis Service
/// Analyzes reviews and feedback for sentiment and insights
class AISentimentAnalysisService {
  late final GenerativeModel _model;

  AISentimentAnalysisService() {
    _model = GenerativeModel(
      model: AIConfig.geminiFlashModel,
      apiKey: AIConfig.getApiKey(),
      generationConfig: GenerationConfig(
        temperature: AIConfig.analysisTemperature,
        maxOutputTokens: 500,
      ),
    );
  }

  /// Analyze sentiment of a review
  Future<SentimentResult> analyzeSentiment(String reviewText) async {
    if (reviewText.trim().isEmpty) {
      return SentimentResult(
        sentiment: Sentiment.neutral,
        score: 0,
        keywords: [],
        summary: 'No review text provided',
      );
    }

    try {
      final prompt =
          '''
Analyze the sentiment of this review for a carpool ride:

Review: "$reviewText"

Provide analysis in this format:
SENTIMENT|SCORE|KEYWORDS|SUMMARY

Where:
- SENTIMENT: positive, negative, neutral, or mixed
- SCORE: -100 to +100 (negative to positive)
- KEYWORDS: Comma-separated key phrases (max 5)
- SUMMARY: One sentence summary

Example:
positive|75|great driver,safe ride,on time|Passenger had an excellent experience with punctual and safe service.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return _parseSentimentResponse(response.text ?? '', reviewText);
    } catch (e) {
      print('Error in sentiment analysis: $e');
      return _fallbackSentimentAnalysis(reviewText);
    }
  }

  /// Parse sentiment response
  SentimentResult _parseSentimentResponse(
    String response,
    String originalText,
  ) {
    try {
      final line = response
          .split('\n')
          .firstWhere((l) => l.contains('|'), orElse: () => '');

      if (line.isEmpty) {
        return _fallbackSentimentAnalysis(originalText);
      }

      final parts = line.split('|');
      if (parts.length >= 4) {
        final sentimentStr = parts[0].trim().toLowerCase();
        final sentiment = Sentiment.values.firstWhere(
          (e) => e.name == sentimentStr,
          orElse: () => Sentiment.neutral,
        );

        return SentimentResult(
          sentiment: sentiment,
          score: int.parse(parts[1].trim()),
          keywords: parts[2].trim().split(',').map((k) => k.trim()).toList(),
          summary: parts[3].trim(),
        );
      }
    } catch (e) {
      print('Error parsing sentiment response: $e');
    }

    return _fallbackSentimentAnalysis(originalText);
  }

  /// Fallback sentiment analysis (keyword-based)
  SentimentResult _fallbackSentimentAnalysis(String text) {
    final lowerText = text.toLowerCase();

    // Positive keywords
    final positiveKeywords = [
      'great', 'excellent', 'good', 'amazing', 'wonderful', 'fantastic',
      'safe', 'clean', 'friendly', 'professional', 'punctual', 'recommend',
      'اچھا', 'بہترین', 'محفوظ', // Urdu positive words
    ];

    // Negative keywords
    final negativeKeywords = [
      'bad', 'terrible', 'awful', 'worst', 'rude', 'late', 'dirty',
      'unsafe', 'dangerous', 'unprofessional', 'cancel', 'complaint',
      'برا', 'خراب', 'غیر محفوظ', // Urdu negative words
    ];

    int positiveCount = 0;
    int negativeCount = 0;

    for (final keyword in positiveKeywords) {
      if (lowerText.contains(keyword)) positiveCount++;
    }

    for (final keyword in negativeKeywords) {
      if (lowerText.contains(keyword)) negativeCount++;
    }

    Sentiment sentiment;
    int score;

    if (positiveCount > negativeCount) {
      sentiment = Sentiment.positive;
      score = 50 + (positiveCount * 10);
    } else if (negativeCount > positiveCount) {
      sentiment = Sentiment.negative;
      score = -50 - (negativeCount * 10);
    } else if (positiveCount > 0 && negativeCount > 0) {
      sentiment = Sentiment.mixed;
      score = 0;
    } else {
      sentiment = Sentiment.neutral;
      score = 0;
    }

    return SentimentResult(
      sentiment: sentiment,
      score: score.clamp(-100, 100),
      keywords: [],
      summary: 'Review analyzed using keyword matching',
    );
  }

  /// Analyze multiple reviews for trends
  Future<SentimentTrends> analyzeTrends(List<String> reviews) async {
    if (reviews.isEmpty) {
      return SentimentTrends(
        overallSentiment: Sentiment.neutral,
        averageScore: 0,
        positiveCount: 0,
        negativeCount: 0,
        neutralCount: 0,
        commonThemes: [],
      );
    }

    final results = await Future.wait(
      reviews.map((review) => analyzeSentiment(review)),
    );

    final positiveCount = results
        .where((r) => r.sentiment == Sentiment.positive)
        .length;
    final negativeCount = results
        .where((r) => r.sentiment == Sentiment.negative)
        .length;
    final neutralCount = results
        .where((r) => r.sentiment == Sentiment.neutral)
        .length;

    final averageScore =
        results.fold<int>(0, (sum, r) => sum + r.score) / results.length;

    Sentiment overallSentiment;
    if (averageScore > 20) {
      overallSentiment = Sentiment.positive;
    } else if (averageScore < -20) {
      overallSentiment = Sentiment.negative;
    } else {
      overallSentiment = Sentiment.neutral;
    }

    // Extract common keywords
    final allKeywords = results.expand((r) => r.keywords).toList();
    final keywordCounts = <String, int>{};
    for (final keyword in allKeywords) {
      keywordCounts[keyword] = (keywordCounts[keyword] ?? 0) + 1;
    }

    final commonThemes = keywordCounts.entries
        .where((e) => e.value > 1)
        .map((e) => e.key)
        .take(5)
        .toList();

    return SentimentTrends(
      overallSentiment: overallSentiment,
      averageScore: averageScore.round(),
      positiveCount: positiveCount,
      negativeCount: negativeCount,
      neutralCount: neutralCount,
      commonThemes: commonThemes,
    );
  }

  /// Detect urgent issues in review
  Future<bool> detectUrgentIssue(String reviewText) async {
    final lowerText = reviewText.toLowerCase();

    // Urgent keywords
    final urgentKeywords = [
      'unsafe', 'dangerous', 'harass', 'threat', 'assault', 'drunk',
      'accident', 'police', 'emergency', 'help',
      'غیر محفوظ', 'خطرناک', 'ہراساں', // Urdu urgent words
    ];

    return urgentKeywords.any((keyword) => lowerText.contains(keyword));
  }
}

/// Sentiment analysis result
class SentimentResult {
  final Sentiment sentiment;
  final int score; // -100 to +100
  final List<String> keywords;
  final String summary;

  SentimentResult({
    required this.sentiment,
    required this.score,
    required this.keywords,
    required this.summary,
  });
}

/// Sentiment trends across multiple reviews
class SentimentTrends {
  final Sentiment overallSentiment;
  final int averageScore;
  final int positiveCount;
  final int negativeCount;
  final int neutralCount;
  final List<String> commonThemes;

  SentimentTrends({
    required this.overallSentiment,
    required this.averageScore,
    required this.positiveCount,
    required this.negativeCount,
    required this.neutralCount,
    required this.commonThemes,
  });
}

enum Sentiment { positive, negative, neutral, mixed }
