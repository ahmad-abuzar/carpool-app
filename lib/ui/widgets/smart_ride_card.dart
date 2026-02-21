import 'package:flutter/material.dart';
import 'package:carpool_app/models/ride.dart';
import 'package:carpool_app/models/compatibility_result.dart';
import 'package:carpool_app/services/matching_api_service.dart';
import 'package:carpool_app/ui/widgets/compatibility_badge.dart';
import 'package:carpool_app/ui/widgets/compatibility_reasons.dart';
import 'package:carpool_app/ui/theme/color_palette.dart';

/// Enhanced ride card with AI compatibility score
class SmartRideCard extends StatefulWidget {
  final Ride ride;
  final String currentUserId;
  final VoidCallback? onTap;

  const SmartRideCard({
    super.key,
    required this.ride,
    required this.currentUserId,
    this.onTap,
  });

  @override
  State<SmartRideCard> createState() => _SmartRideCardState();
}

class _SmartRideCardState extends State<SmartRideCard> {
  final _matchingService = MatchingApiService();
  CompatibilityResult? _compatibility;
  bool _isLoadingCompatibility = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCompatibility();
  }

  @override
  void dispose() {
    _matchingService.dispose();
    super.dispose();
  }

  Future<void> _loadCompatibility() async {
    if (widget.ride.driverId == widget.currentUserId) {
      return; // Don't show compatibility for own rides
    }

    setState(() {
      _isLoadingCompatibility = true;
      _error = null;
    });

    try {
      final result = await _matchingService.calculateMatch(
        userId: widget.currentUserId,
        candidateId: widget.ride.driverId,
        useMl: false,
      );

      if (mounted) {
        setState(() {
          _compatibility = result;
          _isLoadingCompatibility = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingCompatibility = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with driver info and compatibility
              Row(
                children: [
                  // Driver avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: widget.ride.driverPhotoUrl != null
                        ? NetworkImage(widget.ride.driverPhotoUrl!)
                        : null,
                    child: widget.ride.driverPhotoUrl == null
                        ? Text(
                            widget.ride.driverName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Driver name and rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ride.driverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.ride.driverRating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Compatibility badge
                  if (_isLoadingCompatibility)
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_compatibility != null)
                    GestureDetector(
                      onTap: () => _showCompatibilityDetails(),
                      child: CompatibilityBadge(
                        result: _compatibility!,
                        size: 60,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Route information
              _buildRouteInfo(),

              const SizedBox(height: 12),

              // Time and price
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(widget.ride.departureTime),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  Text(
                    'PKR ${widget.ride.pricePerSeat}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(' /seat', style: TextStyle(fontSize: 12)),
                ],
              ),

              // Compatibility reasons (if high match)
              if (_compatibility != null &&
                  _compatibility!.level == CompatibilityLevel.high) ...[
                const SizedBox(height: 12),
                _buildQuickReasons(),
              ],

              // Available seats
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.event_seat, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.ride.availableSeats} seats available',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            Container(width: 2, height: 24, color: Colors.grey[300]),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.ride.origin.address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              Text(
                widget.ride.destination.address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickReasons() {
    final reasons = _compatibility!.reasons.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
              const SizedBox(width: 6),
              Text(
                'Great Match!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...reasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                reason,
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (_compatibility!.reasons.length > 2)
            GestureDetector(
              onTap: _showCompatibilityDetails,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${_compatibility!.reasons.length - 2} more reasons',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCompatibilityDetails() {
    if (_compatibility != null) {
      CompatibilityDetailsSheet.show(context, _compatibility!);
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
