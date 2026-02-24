import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai/ai_ride_matching_service.dart';
import '../services/ai/ai_pricing_service.dart';
import '../services/ai/ai_route_optimization_service.dart';
import '../services/ai/ai_fraud_detection_service.dart';
import '../services/ai/ai_sentiment_analysis_service.dart';

/// AI Ride Matching Service Provider
final aiRideMatchingServiceProvider = Provider<AIRideMatchingService>((ref) {
  return AIRideMatchingService();
});

/// AI Pricing Service Provider
final aiPricingServiceProvider = Provider<AIPricingService>((ref) {
  return AIPricingService();
});

/// AI Route Optimization Service Provider
final aiRouteOptimizationServiceProvider = Provider<AIRouteOptimizationService>(
  (ref) {
    return AIRouteOptimizationService();
  },
);

/// AI Fraud Detection Service Provider
final aiFraudDetectionServiceProvider = Provider<AIFraudDetectionService>((
  ref,
) {
  return AIFraudDetectionService();
});

/// AI Sentiment Analysis Service Provider
final aiSentimentAnalysisServiceProvider = Provider<AISentimentAnalysisService>(
  (ref) {
    return AISentimentAnalysisService();
  },
);
