import 'package:google_generative_ai/google_generative_ai.dart';
import '../../config/ai_config.dart';
import '../../models/ride.dart';

/// AI-Powered Dynamic Pricing Service
/// Provides intelligent pricing recommendations based on demand, weather, events, etc.
class AIPricingService {
  late final GenerativeModel _model;

  AIPricingService() {
    _model = GenerativeModel(
      model: AIConfig.geminiFlashModel,
      apiKey: AIConfig.getApiKey(),
      generationConfig: GenerationConfig(
        temperature: AIConfig.analysisTemperature,
        maxOutputTokens: 1000,
      ),
    );
  }

  /// Get pricing recommendation for a ride
  Future<PricingRecommendation> getPricingRecommendation({
    required Location origin,
    required Location destination,
    required DateTime departureTime,
    required double distanceKm,
    int? currentDemand,
    String? weatherCondition,
    bool? hasEvent,
  }) async {
    try {
      final prompt = _buildPricingPrompt(
        origin: origin,
        destination: destination,
        departureTime: departureTime,
        distanceKm: distanceKm,
        currentDemand: currentDemand,
        weatherCondition: weatherCondition,
        hasEvent: hasEvent,
      );

      final response = await _model.generateContent([Content.text(prompt)]);
      return _parsePricingResponse(response.text ?? '', distanceKm);
    } catch (e) {
      print('Error in AI pricing: $e');
      return _fallbackPricing(distanceKm);
    }
  }

  /// Build pricing prompt
  String _buildPricingPrompt({
    required Location origin,
    required Location destination,
    required DateTime departureTime,
    required double distanceKm,
    int? currentDemand,
    String? weatherCondition,
    bool? hasEvent,
  }) {
    final hour = departureTime.hour;
    final dayOfWeek = departureTime.weekday;
    final isPeakHour = (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19);
    final isWeekend = dayOfWeek >= 6;

    return '''
You are a pricing expert for a carpool service in Pakistan.

Ride Details:
- Route: ${origin.address} → ${destination.address}
- Distance: ${distanceKm.toStringAsFixed(1)} km
- Departure: ${departureTime.toString()}
- Day: ${isWeekend ? 'Weekend' : 'Weekday'}
- Time: ${isPeakHour ? 'Peak hours' : 'Off-peak'}
${currentDemand != null ? '- Current Demand: $currentDemand rides requested in this area' : ''}
${weatherCondition != null ? '- Weather: $weatherCondition' : ''}
${hasEvent != null && hasEvent ? '- Special Event: Yes (concert/sports/holiday)' : ''}

Context:
- Base rate in Pakistan: PKR 15-25 per km
- Fuel price: ~PKR 280/liter
- Average vehicle: 12 km/liter

Task: Recommend optimal pricing per seat considering:
1. Distance and fuel costs
2. Time of day (peak/off-peak)
3. Day of week
4. Weather conditions
5. Demand levels
6. Special events
7. Competitive pricing
8. Driver earnings vs passenger affordability

Provide output in this exact format:
RECOMMENDED_PRICE|MIN_PRICE|MAX_PRICE|REASONING

Where:
- RECOMMENDED_PRICE: Optimal price per seat (PKR)
- MIN_PRICE: Minimum acceptable price (PKR)
- MAX_PRICE: Maximum reasonable price (PKR)
- REASONING: Brief explanation (max 40 words)

Example:
450|350|550|Peak hour pricing with high demand. Fair for 25km distance considering fuel costs.
''';
  }

  /// Parse pricing response
  PricingRecommendation _parsePricingResponse(
    String response,
    double distanceKm,
  ) {
    try {
      final line = response
          .split('\n')
          .firstWhere((l) => l.contains('|'), orElse: () => '');

      if (line.isEmpty) {
        return _fallbackPricing(distanceKm);
      }

      final parts = line.split('|');
      if (parts.length >= 4) {
        return PricingRecommendation(
          recommendedPrice: double.parse(parts[0].trim()),
          minPrice: double.parse(parts[1].trim()),
          maxPrice: double.parse(parts[2].trim()),
          reasoning: parts[3].trim(),
        );
      }
    } catch (e) {
      print('Error parsing pricing response: $e');
    }

    return _fallbackPricing(distanceKm);
  }

  /// Fallback pricing calculation
  PricingRecommendation _fallbackPricing(double distanceKm) {
    const baseRatePerKm = 20.0; // PKR per km
    final basePrice = distanceKm * baseRatePerKm;

    return PricingRecommendation(
      recommendedPrice: basePrice,
      minPrice: basePrice * 0.8,
      maxPrice: basePrice * 1.3,
      reasoning: 'Standard pricing based on distance (PKR $baseRatePerKm/km)',
    );
  }

  /// Analyze pricing trends
  Future<PricingTrends> analyzePricingTrends({
    required String route,
    required List<double> historicalPrices,
    required List<DateTime> timestamps,
  }) async {
    if (historicalPrices.isEmpty) {
      return PricingTrends(
        averagePrice: 0,
        peakPrice: 0,
        offPeakPrice: 0,
        trend: 'stable',
        recommendation: 'No historical data available',
      );
    }

    try {
      final avgPrice =
          historicalPrices.reduce((a, b) => a + b) / historicalPrices.length;
      final maxPrice = historicalPrices.reduce((a, b) => a > b ? a : b);
      final minPrice = historicalPrices.reduce((a, b) => a < b ? a : b);

      final prompt =
          '''
Analyze pricing trends for this carpool route:

Route: $route
Historical Prices (PKR): ${historicalPrices.map((p) => p.toStringAsFixed(0)).join(', ')}
Average: ${avgPrice.toStringAsFixed(0)}
Range: ${minPrice.toStringAsFixed(0)} - ${maxPrice.toStringAsFixed(0)}

Determine:
1. Trend: increasing, decreasing, or stable
2. Recommendation for drivers (1-2 sentences)

Format:
TREND|RECOMMENDATION

Example:
increasing|Demand is rising. Consider pricing at upper range (PKR ${maxPrice.toStringAsFixed(0)}).
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final parts = (response.text ?? '').split('|');

      return PricingTrends(
        averagePrice: avgPrice,
        peakPrice: maxPrice,
        offPeakPrice: minPrice,
        trend: parts.isNotEmpty ? parts[0].trim() : 'stable',
        recommendation: parts.length > 1
            ? parts[1].trim()
            : 'Price competitively',
      );
    } catch (e) {
      final avgPrice =
          historicalPrices.reduce((a, b) => a + b) / historicalPrices.length;
      return PricingTrends(
        averagePrice: avgPrice,
        peakPrice: historicalPrices.reduce((a, b) => a > b ? a : b),
        offPeakPrice: historicalPrices.reduce((a, b) => a < b ? a : b),
        trend: 'stable',
        recommendation:
            'Price around PKR ${avgPrice.toStringAsFixed(0)} based on historical average',
      );
    }
  }
}

/// Pricing recommendation result
class PricingRecommendation {
  final double recommendedPrice;
  final double minPrice;
  final double maxPrice;
  final String reasoning;

  PricingRecommendation({
    required this.recommendedPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.reasoning,
  });
}

/// Pricing trends analysis
class PricingTrends {
  final double averagePrice;
  final double peakPrice;
  final double offPeakPrice;
  final String trend; // 'increasing', 'decreasing', 'stable'
  final String recommendation;

  PricingTrends({
    required this.averagePrice,
    required this.peakPrice,
    required this.offPeakPrice,
    required this.trend,
    required this.recommendation,
  });
}
