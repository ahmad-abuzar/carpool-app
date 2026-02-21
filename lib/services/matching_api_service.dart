import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carpool_app/models/user_preferences.dart';
import 'package:carpool_app/models/compatibility_result.dart';

/// Service for AI Smart Matching API
class MatchingApiService {
  // TODO: Update this URL based on your deployment
  // Local development: http://localhost:8000
  // Production: Your Cloud Run/AWS Lambda URL
  static const String baseUrl = 'http://localhost:8000/api/v1';

  final http.Client _client;

  MatchingApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Calculate compatibility between user and candidate
  Future<CompatibilityResult> calculateMatch({
    required String userId,
    required String candidateId,
    bool useMl = false,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/match'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'candidate_id': candidateId,
          'use_ml': useMl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CompatibilityResult.fromMap(data);
      } else if (response.statusCode == 404) {
        throw MatchingException('User or candidate not found');
      } else {
        final error = jsonDecode(response.body);
        throw MatchingException(error['detail'] ?? 'Failed to calculate match');
      }
    } catch (e) {
      if (e is MatchingException) rethrow;
      throw MatchingException('Network error: ${e.toString()}');
    }
  }

  /// Calculate compatibility for multiple candidates (batch)
  Future<BatchMatchResult> batchMatch({
    required String userId,
    required List<String> candidateIds,
    bool useMl = false,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/match/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'candidate_ids': candidateIds,
          'use_ml': useMl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BatchMatchResult.fromMap(data);
      } else {
        final error = jsonDecode(response.body);
        throw MatchingException(error['detail'] ?? 'Failed to batch match');
      }
    } catch (e) {
      if (e is MatchingException) rethrow;
      throw MatchingException('Network error: ${e.toString()}');
    }
  }

  /// Save user preferences
  Future<bool> savePreferences({
    required String userId,
    required UserPreferences preferences,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/preferences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'preferences': preferences.toMap(),
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw MatchingException(
          error['detail'] ?? 'Failed to save preferences',
        );
      }
    } catch (e) {
      if (e is MatchingException) rethrow;
      throw MatchingException('Network error: ${e.toString()}');
    }
  }

  /// Get user preferences
  Future<UserPreferences?> getPreferences(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/preferences/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserPreferences.fromMap(data);
      } else if (response.statusCode == 404) {
        return null; // Preferences not found
      } else {
        final error = jsonDecode(response.body);
        throw MatchingException(error['detail'] ?? 'Failed to get preferences');
      }
    } catch (e) {
      if (e is MatchingException) rethrow;
      throw MatchingException('Network error: ${e.toString()}');
    }
  }

  /// Update user preferences
  Future<bool> updatePreferences({
    required String userId,
    required UserPreferences preferences,
  }) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/preferences/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(preferences.toMap()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw MatchingException(
          error['detail'] ?? 'Failed to update preferences',
        );
      }
    } catch (e) {
      if (e is MatchingException) rethrow;
      throw MatchingException('Network error: ${e.toString()}');
    }
  }

  /// Delete preferences (disable smart matching)
  Future<bool> deletePreferences(String userId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/preferences/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw MatchingException(
          error['detail'] ?? 'Failed to delete preferences',
        );
      }
    } catch (e) {
      if (e is MatchingException) rethrow;
      throw MatchingException('Network error: ${e.toString()}');
    }
  }

  /// Check API health
  Future<bool> checkHealth() async {
    try {
      final response = await _client.get(
        Uri.parse('${baseUrl.replaceAll('/api/v1', '')}/health'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Custom exception for matching errors
class MatchingException implements Exception {
  final String message;

  MatchingException(this.message);

  @override
  String toString() => message;
}
