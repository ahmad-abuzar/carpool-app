import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating.dart';

/// Rating Service
/// Handles rating submissions, retrieval, and user average updates
class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'ratings';

  /// Submit a rating and update the rated user's average
  Future<String> submitRating(Rating rating) async {
    try {
      // Use a transaction to atomically submit rating + update user average
      final ratingId = await _firestore.runTransaction<String>((
        transaction,
      ) async {
        // 1. Create the rating document
        final ratingRef = _firestore.collection(_collection).doc(rating.id);
        transaction.set(ratingRef, rating.toMap());

        // 2. Get the rated user's current data
        final userRef = _firestore.collection('users').doc(rating.ratedUserId);
        final userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final currentRating = (userData['rating'] ?? 0.0).toDouble();
          final totalRatings = (userData['totalRatings'] ?? 0) as int;

          // Calculate new average
          final newTotal = totalRatings + 1;
          final newAverage =
              ((currentRating * totalRatings) + rating.stars) / newTotal;

          // 3. Update the user's average rating
          transaction.update(userRef, {
            'rating': double.parse(newAverage.toStringAsFixed(2)),
            'totalRatings': newTotal,
          });
        }

        return rating.id;
      });

      print('✅ RatingService: Rating submitted successfully: $ratingId');
      return ratingId;
    } catch (e) {
      print('❌ RatingService: Error submitting rating: $e');
      rethrow;
    }
  }

  /// Get a rating by ID
  Future<Rating?> getRatingById(String ratingId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(ratingId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return Rating.fromMap(data);
    } catch (e) {
      print('❌ RatingService: Error getting rating: $e');
      return null;
    }
  }

  /// Get all ratings for a specific user (received)
  Future<List<Rating>> getRatingsForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('ratedUserId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Rating.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ RatingService: Error getting user ratings: $e');
      return [];
    }
  }

  /// Get all ratings given by a user
  Future<List<Rating>> getRatingsGivenByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('raterUserId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Rating.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ RatingService: Error getting given ratings: $e');
      return [];
    }
  }

  /// Get all ratings for a specific ride
  Future<List<Rating>> getRatingsForRide(String rideId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('rideId', isEqualTo: rideId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Rating.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ RatingService: Error getting ride ratings: $e');
      return [];
    }
  }

  /// Check if a user has already rated another user for a ride
  Future<bool> hasRated({
    required String raterUserId,
    required String ratedUserId,
    required String rideId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('raterUserId', isEqualTo: raterUserId)
          .where('ratedUserId', isEqualTo: ratedUserId)
          .where('rideId', isEqualTo: rideId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ RatingService: Error checking if rated: $e');
      return false;
    }
  }

  /// Get the average rating for a user
  Future<double> getUserAverageRating(String userId) async {
    try {
      final ratings = await getRatingsForUser(userId);
      if (ratings.isEmpty) return 0.0;

      final total = ratings.fold<int>(0, (sum, r) => sum + r.stars);
      return total / ratings.length;
    } catch (e) {
      print('❌ RatingService: Error calculating average: $e');
      return 0.0;
    }
  }

  /// Listen to ratings for a user (real-time)
  Stream<List<Rating>> listenToRatingsForUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('ratedUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Rating.fromMap(data);
          }).toList();
        });
  }

  /// Get rating statistics for a user
  Future<Map<String, dynamic>> getRatingStatistics(String userId) async {
    try {
      final ratings = await getRatingsForUser(userId);

      if (ratings.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalRatings': 0,
          'distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
          'topTags': <String>[],
        };
      }

      // Calculate distribution
      final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      final tagCounts = <String, int>{};

      for (final rating in ratings) {
        distribution[rating.stars] = (distribution[rating.stars] ?? 0) + 1;
        for (final tag in rating.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      // Top tags sorted by frequency
      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topTags = sortedTags.take(5).map((e) => e.key).toList();

      final total = ratings.fold<int>(0, (sum, r) => sum + r.stars);
      final average = total / ratings.length;

      return {
        'averageRating': double.parse(average.toStringAsFixed(2)),
        'totalRatings': ratings.length,
        'distribution': distribution,
        'topTags': topTags,
      };
    } catch (e) {
      print('❌ RatingService: Error getting statistics: $e');
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        'topTags': <String>[],
      };
    }
  }

  /// Delete a rating (admin use)
  Future<void> deleteRating(String ratingId) async {
    try {
      await _firestore.collection(_collection).doc(ratingId).delete();
    } catch (e) {
      print('❌ RatingService: Error deleting rating: $e');
    }
  }
}
