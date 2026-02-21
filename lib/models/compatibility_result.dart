import 'package:flutter/material.dart';

/// Compatibility level categories
enum CompatibilityLevel {
  high,
  medium,
  low;

  Color get color {
    switch (this) {
      case CompatibilityLevel.high:
        return Colors.green;
      case CompatibilityLevel.medium:
        return Colors.orange;
      case CompatibilityLevel.low:
        return Colors.red;
    }
  }

  String get label {
    switch (this) {
      case CompatibilityLevel.high:
        return 'Highly Compatible';
      case CompatibilityLevel.medium:
        return 'Moderately Compatible';
      case CompatibilityLevel.low:
        return 'Low Compatibility';
    }
  }

  IconData get icon {
    switch (this) {
      case CompatibilityLevel.high:
        return Icons.check_circle;
      case CompatibilityLevel.medium:
        return Icons.info;
      case CompatibilityLevel.low:
        return Icons.warning;
    }
  }
}

/// Compatibility result from AI matching
class CompatibilityResult {
  final String userId;
  final String candidateId;
  final double score; // 0-100
  final CompatibilityLevel level;
  final List<String> reasons;
  final Map<String, double> breakdown;
  final String recommendation;

  const CompatibilityResult({
    required this.userId,
    required this.candidateId,
    required this.score,
    required this.level,
    required this.reasons,
    required this.breakdown,
    required this.recommendation,
  });

  factory CompatibilityResult.fromMap(Map<String, dynamic> map) {
    final score = (map['compatibility_score'] as num).toDouble();

    return CompatibilityResult(
      userId: map['user_id'] as String,
      candidateId: map['candidate_id'] as String,
      score: score,
      level: _parseCompatibilityLevel(map['compatibility_level'] as String),
      reasons: List<String>.from(map['reasons'] ?? []),
      breakdown: Map<String, double>.from(
        (map['breakdown'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      recommendation: map['recommendation'] as String,
    );
  }

  static CompatibilityLevel _parseCompatibilityLevel(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return CompatibilityLevel.high;
      case 'medium':
        return CompatibilityLevel.medium;
      case 'low':
        return CompatibilityLevel.low;
      default:
        return CompatibilityLevel.low;
    }
  }

  /// Get score as percentage string
  String get scorePercentage => '${score.toStringAsFixed(0)}%';

  /// Check if this is a good match (score >= 70)
  bool get isGoodMatch => score >= 70.0;

  /// Get color based on score
  Color get scoreColor => level.color;

  /// Get badge text
  String get badgeText => level.label;
}

/// Batch match response
class BatchMatchResult {
  final String userId;
  final List<CompatibilityResult> matches;
  final int totalCandidates;

  const BatchMatchResult({
    required this.userId,
    required this.matches,
    required this.totalCandidates,
  });

  factory BatchMatchResult.fromMap(Map<String, dynamic> map) {
    return BatchMatchResult(
      userId: map['user_id'] as String,
      matches: (map['matches'] as List<dynamic>)
          .map((m) => CompatibilityResult.fromMap(m as Map<String, dynamic>))
          .toList(),
      totalCandidates: map['total_candidates'] as int,
    );
  }

  /// Get matches sorted by score (highest first)
  List<CompatibilityResult> get sortedMatches {
    final sorted = List<CompatibilityResult>.from(matches);
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }

  /// Get only high compatibility matches
  List<CompatibilityResult> get highCompatibilityMatches {
    return matches.where((m) => m.level == CompatibilityLevel.high).toList();
  }

  /// Get best match
  CompatibilityResult? get bestMatch {
    if (matches.isEmpty) return null;
    return sortedMatches.first;
  }
}
