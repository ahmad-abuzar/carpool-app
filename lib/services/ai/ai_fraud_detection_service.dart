import 'package:google_generative_ai/google_generative_ai.dart';
import '../../config/ai_config.dart';
import '../../models/user.dart';
import '../../models/booking.dart';

/// AI Fraud Detection Service
/// Detects suspicious activities and potential fraud
class AIFraudDetectionService {
  late final GenerativeModel _model;

  AIFraudDetectionService() {
    _model = GenerativeModel(
      model: AIConfig.geminiFlashModel,
      apiKey: AIConfig.getApiKey(),
      generationConfig: GenerationConfig(
        temperature: 0.1, // Very deterministic for fraud detection
        maxOutputTokens: 500,
      ),
    );
  }

  /// Analyze user behavior for fraud
  Future<FraudAnalysis> analyzeUserBehavior({
    required User user,
    required List<Booking> recentBookings,
    int? cancelledBookingsCount,
    int? reportedCount,
  }) async {
    try {
      final prompt = _buildFraudPrompt(
        user,
        recentBookings,
        cancelledBookingsCount ?? 0,
        reportedCount ?? 0,
      );

      final response = await _model.generateContent([Content.text(prompt)]);
      return _parseFraudResponse(response.text ?? '');
    } catch (e) {
      print('Error in fraud detection: $e');
      return _fallbackFraudDetection(
        user,
        recentBookings,
        cancelledBookingsCount ?? 0,
        reportedCount ?? 0,
      );
    }
  }

  /// Build fraud detection prompt
  String _buildFraudPrompt(
    User user,
    List<Booking> recentBookings,
    int cancelledBookingsCount,
    int reportedCount,
  ) {
    final bookingPatterns = recentBookings
        .map((b) {
          return '${b.bookingTime.toString()}: ${b.status.name} (${b.seatsBooked} seats, PKR ${b.totalAmount})';
        })
        .join('\n');

    return '''
Analyze this user for potential fraudulent behavior:

User Profile:
- Name: ${user.name}
- Account Age: ${DateTime.now().difference(user.verificationDate ?? DateTime.now()).inDays} days
- Total Rides: ${user.totalRides}
- Rating: ${user.rating}/5.0
- Verification Level: ${user.verificationLevel.name}
- Cancelled Bookings: $cancelledBookingsCount
- Times Reported: $reportedCount

Recent Booking Activity:
$bookingPatterns

Red Flags to Check:
1. Excessive cancellations (>30% cancellation rate)
2. Multiple bookings in short time
3. Low rating with many rides
4. Unverified account with high activity
5. Reported multiple times
6. Unusual booking patterns

Provide analysis in this format:
RISK_LEVEL|CONFIDENCE|FLAGS|RECOMMENDATION

Where:
- RISK_LEVEL: low, medium, high, critical
- CONFIDENCE: 0-100 (how confident in this assessment)
- FLAGS: Comma-separated list of detected issues
- RECOMMENDATION: Brief action to take

Example:
high|85|excessive_cancellations,multiple_reports|Suspend account pending review
''';
  }

  /// Parse fraud detection response
  FraudAnalysis _parseFraudResponse(String response) {
    try {
      final line = response
          .split('\n')
          .firstWhere((l) => l.contains('|'), orElse: () => '');

      if (line.isEmpty) {
        return FraudAnalysis(
          riskLevel: FraudRiskLevel.low,
          confidence: 50,
          flags: [],
          recommendation: 'Continue monitoring',
        );
      }

      final parts = line.split('|');
      if (parts.length >= 4) {
        final riskLevelStr = parts[0].trim().toLowerCase();
        final riskLevel = FraudRiskLevel.values.firstWhere(
          (e) => e.name == riskLevelStr,
          orElse: () => FraudRiskLevel.low,
        );

        return FraudAnalysis(
          riskLevel: riskLevel,
          confidence: int.parse(parts[1].trim()),
          flags: parts[2].trim().split(',').map((f) => f.trim()).toList(),
          recommendation: parts[3].trim(),
        );
      }
    } catch (e) {
      print('Error parsing fraud response: $e');
    }

    return FraudAnalysis(
      riskLevel: FraudRiskLevel.low,
      confidence: 50,
      flags: [],
      recommendation: 'Continue monitoring',
    );
  }

  /// Fallback fraud detection (rule-based)
  FraudAnalysis _fallbackFraudDetection(
    User user,
    List<Booking> recentBookings,
    int cancelledBookingsCount,
    int reportedCount,
  ) {
    final flags = <String>[];
    var riskScore = 0;

    // Check cancellation rate
    if (recentBookings.isNotEmpty) {
      final cancellationRate = cancelledBookingsCount / recentBookings.length;
      if (cancellationRate > 0.3) {
        flags.add('high_cancellation_rate');
        riskScore += 30;
      }
    }

    // Check reports
    if (reportedCount > 2) {
      flags.add('multiple_reports');
      riskScore += 40;
    }

    // Check verification
    if (user.verificationLevel == VerificationLevel.none &&
        user.totalRides > 5) {
      flags.add('unverified_high_activity');
      riskScore += 20;
    }

    // Check rating
    if (user.rating < 3.0 && user.totalRides > 3) {
      flags.add('low_rating');
      riskScore += 15;
    }

    // Determine risk level
    FraudRiskLevel riskLevel;
    String recommendation;

    if (riskScore >= 70) {
      riskLevel = FraudRiskLevel.critical;
      recommendation = 'Suspend account immediately';
    } else if (riskScore >= 50) {
      riskLevel = FraudRiskLevel.high;
      recommendation = 'Review account and restrict features';
    } else if (riskScore >= 30) {
      riskLevel = FraudRiskLevel.medium;
      recommendation = 'Monitor closely and verify identity';
    } else {
      riskLevel = FraudRiskLevel.low;
      recommendation = 'Continue normal monitoring';
    }

    return FraudAnalysis(
      riskLevel: riskLevel,
      confidence: 75,
      flags: flags,
      recommendation: recommendation,
    );
  }

  /// Check for duplicate accounts
  Future<bool> checkDuplicateAccount({
    required String phone,
    required String email,
    List<String>? existingPhones,
    List<String>? existingEmails,
  }) async {
    // Simple check for now
    if (existingPhones != null && existingPhones.contains(phone)) {
      return true;
    }
    if (existingEmails != null && existingEmails.contains(email)) {
      return true;
    }
    return false;
  }
}

/// Fraud analysis result
class FraudAnalysis {
  final FraudRiskLevel riskLevel;
  final int confidence; // 0-100
  final List<String> flags;
  final String recommendation;

  FraudAnalysis({
    required this.riskLevel,
    required this.confidence,
    required this.flags,
    required this.recommendation,
  });

  bool get isHighRisk =>
      riskLevel == FraudRiskLevel.high || riskLevel == FraudRiskLevel.critical;
}

enum FraudRiskLevel { low, medium, high, critical }
