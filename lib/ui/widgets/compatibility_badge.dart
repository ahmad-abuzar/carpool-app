import 'package:flutter/material.dart';
import 'package:carpool_app/models/compatibility_result.dart';

/// Widget to display compatibility score badge
class CompatibilityBadge extends StatelessWidget {
  final CompatibilityResult result;
  final bool showPercentage;
  final double size;

  const CompatibilityBadge({
    super.key,
    required this.result,
    this.showPercentage = true,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: result.level.color.withOpacity(0.1),
        border: Border.all(color: result.level.color, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showPercentage) ...[
              Text(
                result.scorePercentage,
                style: TextStyle(
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
                  color: result.level.color,
                ),
              ),
              Text(
                'Match',
                style: TextStyle(
                  fontSize: size * 0.15,
                  color: result.level.color,
                ),
              ),
            ] else
              Icon(
                result.level.icon,
                color: result.level.color,
                size: size * 0.5,
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact compatibility badge for list items
class CompactCompatibilityBadge extends StatelessWidget {
  final CompatibilityResult result;

  const CompactCompatibilityBadge({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: result.level.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: result.level.color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(result.level.icon, color: result.level.color, size: 16),
          const SizedBox(width: 4),
          Text(
            result.scorePercentage,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: result.level.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Linear compatibility indicator
class CompatibilityBar extends StatelessWidget {
  final CompatibilityResult result;
  final double height;

  const CompatibilityBar({super.key, required this.result, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Compatibility', style: Theme.of(context).textTheme.bodySmall),
            Text(
              result.scorePercentage,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: result.level.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: result.score / 100,
            minHeight: height,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(result.level.color),
          ),
        ),
      ],
    );
  }
}
