import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../state/providers.dart';
import '../../../models/ride.dart';
import '../../../models/user.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/ride_card.dart';

class RideSearchScreen extends ConsumerStatefulWidget {
  const RideSearchScreen({super.key});

  @override
  ConsumerState<RideSearchScreen> createState() => _RideSearchScreenState();
}

class _RideSearchScreenState extends ConsumerState<RideSearchScreen> {
  DateTime? _selectedDate;
  bool _femaleOnlyFilter = false;
  double _maxPrice = 200;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final allRides = ref.watch(ridesProvider);

    // Apply filters - only show scheduled rides to passengers
    final filteredRides = allRides.where((ride) {
      if (ride.status != RideStatus.scheduled) return false;
      // Don't show user's own rides in search results
      if (currentUser != null && ride.driver.id == currentUser.id) return false;
      if (_femaleOnlyFilter && !ride.femaleOnly) return false;
      if (ride.pricePerSeat > _maxPrice) return false;
      if (_selectedDate != null) {
        final rideDate = DateTime(
          ride.departureTime.year,
          ride.departureTime.month,
          ride.departureTime.day,
        );
        final searchDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
        );
        if (!rideDate.isAtSameMomentAs(searchDate)) return false;
      }
      return ride.availableSeats > 0 &&
          ride.departureTime.isAfter(DateTime.now());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Rides'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search filters
          Container(
            padding: const EdgeInsets.all(Spacing.lg),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Date selector
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.lg),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.dividerLight),
                      borderRadius: BorderRadius.circular(Spacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: Spacing.md),
                        Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : DateFormat('EEE, MMM d').format(_selectedDate!),
                          style: AppTypography.body(context),
                        ),
                        const Spacer(),
                        if (_selectedDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _selectedDate = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: Spacing.md),

                // Quick filters
                Wrap(
                  spacing: Spacing.sm,
                  children: [
                    FilterChip(
                      label: const Text('Today'),
                      selected:
                          _selectedDate != null &&
                          _selectedDate!.day == DateTime.now().day,
                      onSelected: (selected) {
                        setState(() {
                          _selectedDate = selected ? DateTime.now() : null;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Tomorrow'),
                      selected:
                          _selectedDate != null &&
                          _selectedDate!.day ==
                              DateTime.now().add(const Duration(days: 1)).day,
                      onSelected: (selected) {
                        setState(() {
                          _selectedDate = selected
                              ? DateTime.now().add(const Duration(days: 1))
                              : null;
                        });
                      },
                    ),
                    if (currentUser?.gender == Gender.female)
                      FilterChip(
                        label: const Text('Female Only'),
                        avatar: const Icon(Icons.female, size: 16),
                        selected: _femaleOnlyFilter,
                        onSelected: (selected) {
                          setState(() {
                            _femaleOnlyFilter = selected;
                          });
                        },
                        selectedColor: AppColors.femaleOnlyLight,
                      ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Results
          Expanded(
            child: filteredRides.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: Spacing.lg),
                        Text(
                          'No rides found',
                          style: AppTypography.body(
                            context,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          'Try adjusting your filters',
                          style: AppTypography.bodySmall(context),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(Spacing.lg),
                    children: [
                      Text(
                        '${filteredRides.length} rides available',
                        style: AppTypography.bodySmall(
                          context,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      ...filteredRides.map((ride) => RideCard(ride: ride)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filters', style: AppTypography.headlineSmall(context)),
              const SizedBox(height: Spacing.xl),

              Text(
                'Max Price: Rs. ${_maxPrice.toInt()}',
                style: AppTypography.body(context, weight: FontWeight.w600),
              ),
              Slider(
                value: _maxPrice,
                min: 0,
                max: 500,
                divisions: 10,
                label: 'Rs ${_maxPrice.toInt()}',
                onChanged: (value) {
                  setModalState(() {
                    _maxPrice = value;
                  });
                  setState(() {
                    _maxPrice = value;
                  });
                },
              ),

              const SizedBox(height: Spacing.lg),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
