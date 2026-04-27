import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/ride.dart';
import '../../../models/booking.dart';
import '../../../models/payment_method.dart';
import '../../../services/mock_data_service.dart';
import '../../../state/providers.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  final Ride ride;

  const BookingFlowScreen({super.key, required this.ride});

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  int _seatsToBook = 1;
  PaymentMethod _selectedPaymentMethod =
      MockDataService.getPaymentMethods().first;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final totalAmount = widget.ride.pricePerSeat * _seatsToBook;
    final bookingStatus = ref.watch(bookingControllerProvider);
    final isBooking = bookingStatus.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Ride')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride Summary',
                      style: AppTypography.body(
                        context,
                        weight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 20),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            '${widget.ride.origin.address} → ${widget.ride.destination.address}',
                            style: AppTypography.bodySmall(context),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: Spacing.xl),

            // Seat selection
            Text(
              'Number of Seats',
              style: AppTypography.headlineSmall(context),
            ),
            const SizedBox(height: Spacing.md),

            Row(
              children: [
                IconButton.filled(
                  onPressed: _seatsToBook > 1
                      ? () {
                          setState(() {
                            _seatsToBook--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: Spacing.lg),
                Text('$_seatsToBook', style: AppTypography.headline(context)),
                const SizedBox(width: Spacing.lg),
                IconButton.filled(
                  onPressed: _seatsToBook < widget.ride.availableSeats
                      ? () {
                          setState(() {
                            _seatsToBook++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.add),
                ),
                const Spacer(),
                Text(
                  '${widget.ride.availableSeats} available',
                  style: AppTypography.bodySmall(context),
                ),
              ],
            ),

            const SizedBox(height: Spacing.xl),
            const Divider(),
            const SizedBox(height: Spacing.xl),

            // Payment Mode
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Mode',
                  style: AppTypography.headlineSmall(context),
                ),
                TextButton(
                  onPressed: _showPaymentModePicker,
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),

            InkWell(
              onTap: _showPaymentModePicker,
              borderRadius: BorderRadius.circular(12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: Spacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(Spacing.sm),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getPaymentIcon(_selectedPaymentMethod.type),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPaymentMethod.displayName,
                              style: AppTypography.body(
                                context,
                                weight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedPaymentMethod.type ==
                                PaymentMethodType.cash)
                              Text(
                                'Pay driver directly',
                                style: AppTypography.bodySmall(context),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).disabledColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: Spacing.xl),
            const Divider(),
            const SizedBox(height: Spacing.xl),

            // Price breakdown
            Text(
              'Price Breakdown',
              style: AppTypography.headlineSmall(context),
            ),
            const SizedBox(height: Spacing.md),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Price per seat', style: AppTypography.body(context)),
                Text(
                  'Rs. ${widget.ride.pricePerSeat.toInt()}',
                  style: AppTypography.body(context),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Number of seats', style: AppTypography.body(context)),
                Text('×$_seatsToBook', style: AppTypography.body(context)),
              ],
            ),
            const SizedBox(height: Spacing.md),
            const Divider(),
            const SizedBox(height: Spacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTypography.body(context, weight: FontWeight.bold),
                ),
                Text(
                  'Rs. ${totalAmount.toInt()}',
                  style: AppTypography.headline(context),
                ),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: ElevatedButton(
            onPressed: isBooking
                ? null
                : () async {
                    final booking = Booking(
                      id: '', // Will be set by service
                      rideId: widget.ride.id,
                      ride: widget.ride,
                      passenger: currentUser!,
                      seatsBooked: _seatsToBook,
                      totalAmount: totalAmount,
                      status: BookingStatus.confirmed,
                      bookingTime: DateTime.now(),
                    );

                    final bookingId = await ref
                        .read(bookingControllerProvider.notifier)
                        .createBooking(booking);

                    if (bookingId != null && mounted) {
                      context.go(
                        '/booking-confirmation',
                        extra: booking.copyWith(
                          status: BookingStatus.confirmed,
                        ),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Booking failed. Please check your internet connection and try again.',
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  },
            child: isBooking
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Confirm Booking'),
          ),
        ),
      ),
    );
  }

  void _showPaymentModePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: Text(
                    'Select Payment Mode',
                    style: AppTypography.headlineSmall(context),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                ...MockDataService.getPaymentMethods().map((method) {
                  final isSelected = _selectedPaymentMethod.id == method.id;
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(Spacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPaymentIcon(method.type),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      method.displayName,
                      style: AppTypography.body(
                        context,
                        weight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: method.type == PaymentMethodType.cash
                        ? const Text('Pay driver directly')
                        : null,
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = method;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: Spacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getPaymentIcon(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.cash:
        return Icons.money;
      case PaymentMethodType.card:
        return Icons.credit_card;
      case PaymentMethodType.wallet:
        return Icons.account_balance_wallet;
    }
  }
}
