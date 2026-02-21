import 'package:google_generative_ai/google_generative_ai.dart';
import '../../config/ai_config.dart';
import '../../models/ride.dart';
import '../../models/user.dart';

/// AI-Powered Ride Matching Service
/// Uses Google Gemini to match passengers with compatible drivers
class AIRideMatchingService {
  late final GenerativeModel _model;

  AIRideMatchingService() {
    _model = GenerativeModel(
      model: AIConfig.geminiFlashModel,
      apiKey: AIConfig.getApiKey(),
      generationConfig: GenerationConfig(
        temperature: AIConfig.analysisTemperature,
        maxOutputTokens: 2000,
      ),
    );
  }

  /// Match passenger with best rides
  Future<List<RideMatch>> matchRides({
    required User passenger,
    required List<Ride> availableRides,
    String? preferredRoute,
  }) async {
    if (availableRides.isEmpty) return [];

    try {
      final prompt = _buildMatchingPrompt(
        passenger,
        availableRides,
        preferredRoute,
      );
      final response = await _model.generateContent([Content.text(prompt)]);

      final matchResults = _parseMatchingResponse(
        response.text ?? '',
        availableRides,
      );
      return matchResults;
    } catch (e) {
      print('Error in AI ride matching: $e');
      // Fallback to basic matching
      return _fallbackMatching(passenger, availableRides);
    }
  }

  /// Build prompt for Gemini
  String _buildMatchingPrompt(
    User passenger,
    List<Ride> rides,
    String? preferredRoute,
  ) {
    final rideDescriptions = rides
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final ride = entry.value;
          return '''
Ride $index:
- Driver: ${ride.driver.name} (Rating: ${ride.driver.rating}/5.0, ${ride.driver.totalRidesAsDriver} rides)
- Route: ${ride.origin.address} → ${ride.destination.address}
- Departure: ${ride.departureTime}
- Price: PKR ${ride.pricePerSeat} per seat
- Available Seats: ${ride.availableSeats}/${ride.totalSeats}
- Female Only: ${ride.femaleOnly}
- Rules: ${ride.rules.join(', ')}
- Driver Verified: ${ride.driver.verificationLevel.name}
''';
        })
        .join('\n');

    return '''
You are an AI ride-matching assistant for a carpool app in Pakistan.

Passenger Profile:
- Name: ${passenger.name}
- Gender: ${passenger.gender.name}
- Rating: ${passenger.rating}/5.0
- Total Rides: ${passenger.totalRides}
- Preferences: ${passenger.preferFemaleOnlyRides ? 'Female-only rides' : 'No gender preference'}
- Verified: ${passenger.verificationLevel.name}
${preferredRoute != null ? '- Preferred Route: $preferredRoute' : ''}

Available Rides:
$rideDescriptions

Task: Analyze and rank these rides for this passenger based on:
1. Route compatibility (if preferred route is specified)
2. Safety (driver rating, verification level)
3. Price value
4. Gender preferences
5. Driver experience
6. Ride rules compatibility

Provide output in this exact format for each ride (one per line):
RIDE_INDEX|SCORE|REASON

Where:
- RIDE_INDEX is the ride number (0, 1, 2, etc.)
- SCORE is 0-100 (100 being perfect match)
- REASON is a brief explanation (max 50 words)

Example:
0|95|Excellent match: Highly rated driver, direct route, good price, verified
1|75|Good option: Slightly longer route but cheaper, experienced driver

Rank from best to worst match.
''';
  }

  /// Parse Gemini response
  List<RideMatch> _parseMatchingResponse(String response, List<Ride> rides) {
    final matches = <RideMatch>[];
    final lines = response
        .split('\n')
        .where((line) => line.contains('|'))
        .toList();

    for (final line in lines) {
      try {
        final parts = line.split('|');
        if (parts.length >= 3) {
          final rideIndex = int.parse(parts[0].trim());
          final score = int.parse(parts[1].trim());
          final reason = parts[2].trim();

          if (rideIndex >= 0 && rideIndex < rides.length) {
            matches.add(
              RideMatch(
                ride: rides[rideIndex],
                compatibilityScore: score,
                matchReason: reason,
              ),
            );
          }
        }
      } catch (e) {
        print('Error parsing match line: $line');
      }
    }

    // Sort by score descending
    matches.sort(
      (a, b) => b.compatibilityScore.compareTo(a.compatibilityScore),
    );
    return matches;
  }

  /// Fallback matching algorithm (rule-based)
  List<RideMatch> _fallbackMatching(User passenger, List<Ride> rides) {
    final matches = rides.map((ride) {
      int score = 50; // Base score
      String reason = 'Basic match';

      // Gender preference
      if (passenger.preferFemaleOnlyRides && !ride.femaleOnly) {
        score -= 30;
        reason = 'Does not match gender preference';
      } else if (passenger.preferFemaleOnlyRides && ride.femaleOnly) {
        score += 20;
        reason = 'Matches gender preference';
      }

      // Driver rating
      if (ride.driver.rating >= 4.5) {
        score += 15;
        reason += ', highly rated driver';
      } else if (ride.driver.rating < 3.0) {
        score -= 20;
        reason += ', low driver rating';
      }

      // Verification
      if (ride.driver.verificationLevel == VerificationLevel.full) {
        score += 10;
        reason += ', fully verified';
      }

      // Available seats
      if (ride.availableSeats >= 2) {
        score += 5;
      }

      return RideMatch(
        ride: ride,
        compatibilityScore: score.clamp(0, 100),
        matchReason: reason,
      );
    }).toList();

    matches.sort(
      (a, b) => b.compatibilityScore.compareTo(a.compatibilityScore),
    );
    return matches;
  }

  /// Get compatibility explanation
  Future<String> explainCompatibility({
    required User passenger,
    required Ride ride,
  }) async {
    try {
      final prompt =
          '''
Explain why this ride is a good or bad match for this passenger in 2-3 sentences.

Passenger: ${passenger.name} (${passenger.gender.name}, Rating: ${passenger.rating})
Preferences: ${passenger.preferFemaleOnlyRides ? 'Female-only' : 'Any'}

Ride: ${ride.origin.address} → ${ride.destination.address}
Driver: ${ride.driver.name} (Rating: ${ride.driver.rating}, ${ride.driver.totalRidesAsDriver} rides)
Price: PKR ${ride.pricePerSeat}
Female Only: ${ride.femaleOnly}

Keep it friendly and conversational.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'This ride matches your preferences.';
    } catch (e) {
      return 'This ride is available for booking.';
    }
  }
}

/// Ride match result
class RideMatch {
  final Ride ride;
  final int compatibilityScore; // 0-100
  final String matchReason;

  RideMatch({
    required this.ride,
    required this.compatibilityScore,
    required this.matchReason,
  });
}
