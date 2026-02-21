import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/rating.dart';
import '../../../services/rating_service.dart';
import '../../../state/providers.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String rideId;
  final bool isDriver;
  final String ratedUserId;

  const RatingScreen({
    super.key,
    required this.rideId,
    this.isDriver = false,
    required this.ratedUserId,
  });

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _stars = 0;
  final List<String> _selectedTags = [];
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = widget.isDriver
        ? RatingTags.passengerTags
        : RatingTags.driverTags;

    return Scaffold(
      appBar: AppBar(
        title: Text('Rate ${widget.isDriver ? "Passenger" : "Driver"}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 48,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'How was your ride?',
                    style: AppTypography.headline(context),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Your feedback helps us improve',
                    style: AppTypography.bodySmall(context),
                  ),
                  const SizedBox(height: Spacing.xl),

                  // Star rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _stars = index + 1;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            index < _stars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 52,
                            color: index < _stars
                                ? Colors.amber
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.3),
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_stars > 0) ...[
                    const SizedBox(height: Spacing.sm),
                    Text(
                      _ratingLabel,
                      style: AppTypography.body(
                        context,
                        weight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: Spacing.xxxl),

            if (_stars > 0) ...[
              Text(
                _stars >= 4 ? 'What did you like?' : 'What could be better?',
                style: AppTypography.body(context, weight: FontWeight.w600),
              ),
              const SizedBox(height: Spacing.md),

              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: tags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: AppColors.primaryContainer,
                    checkmarkColor: AppColors.primaryDark,
                  );
                }).toList(),
              ),

              const SizedBox(height: Spacing.xl),

              Text(
                'Additional Comments (Optional)',
                style: AppTypography.body(context, weight: FontWeight.w600),
              ),
              const SizedBox(height: Spacing.md),

              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share more about your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Spacing.radiusMd),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _stars > 0 && !_isSubmitting
                      ? _submitRating
                      : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Rating',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Skip'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _ratingLabel {
    switch (_stars) {
      case 1:
        return 'Poor 😞';
      case 2:
        return 'Fair 😐';
      case 3:
        return 'Good 🙂';
      case 4:
        return 'Great 😄';
      case 5:
        return 'Excellent 🤩';
      default:
        return '';
    }
  }

  Future<void> _submitRating() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final rating = Rating(
        id: '${widget.rideId}_${currentUser.id}_${widget.ratedUserId}',
        ratedUserId: widget.ratedUserId,
        raterUserId: currentUser.id,
        stars: _stars,
        tags: _selectedTags,
        comment: _commentController.text.isNotEmpty
            ? _commentController.text
            : null,
        rideId: widget.rideId,
        timestamp: DateTime.now(),
      );

      await RatingService().submitRating(rating);

      if (mounted) {
        context.go('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback! ⭐'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
