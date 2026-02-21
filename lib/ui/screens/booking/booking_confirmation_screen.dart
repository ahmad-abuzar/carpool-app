import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/booking.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Booking booking;

  const BookingConfirmationScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEE, MMM d');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: AppColors.success,
                ),
              ),

              const SizedBox(height: Spacing.xl),

              Text(
                'Booking Confirmed!',
                style: AppTypography.headline(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.md),

              Text(
                'Your ride has been successfully booked',
                style: AppTypography.bodySmall(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.xxxl),

              // Booking details card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        label: 'Date & Time',
                        value:
                            '${dateFormat.format(booking.ride.departureTime)} • ${timeFormat.format(booking.ride.departureTime)}',
                      ),
                      const Divider(),
                      _DetailRow(
                        label: 'From',
                        value: booking.ride.origin.address,
                      ),
                      const Divider(),
                      _DetailRow(
                        label: 'To',
                        value: booking.ride.destination.address,
                      ),
                      const Divider(),
                      _DetailRow(
                        label: 'Driver',
                        value: booking.ride.driver.name,
                      ),
                      const Divider(),
                      _DetailRow(
                        label: 'Seats Booked',
                        value: '${booking.seatsBooked}',
                      ),
                      const Divider(),
                      _DetailRow(
                        label: 'Total Amount',
                        value: 'Rs. ${booking.totalAmount.toInt()}',
                        valueStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/home');
                  },
                  child: const Text('Go to Home'),
                ),
              ),

              const SizedBox(height: Spacing.md),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Stub: Share ride details
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ride details shared!')),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share Ride Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySmall(context)),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              value,
              style:
                  valueStyle ??
                  AppTypography.body(context, weight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
