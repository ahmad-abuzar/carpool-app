import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';
import 'auth_provider.dart';

/// Rating Service Provider
final ratingServiceProvider = Provider<RatingService>((ref) {
  return RatingService();
});

/// User Ratings Provider (ratings received by logged-in user, real-time)
final userRatingsProvider = StreamProvider<List<Rating>>((ref) {
  final service = ref.watch(ratingServiceProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value([]);
  }

  return service.listenToRatingsForUser(user.id);
});

/// Rating Statistics Provider
final ratingStatsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, userId) {
    final service = ref.watch(ratingServiceProvider);
    return service.getRatingStatistics(userId);
  },
);
