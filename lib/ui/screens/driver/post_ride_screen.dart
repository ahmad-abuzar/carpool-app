import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../models/ride.dart';
import '../../../models/vehicle.dart';
import '../../../services/mock_data_service.dart';
import '../../../services/commission_service.dart';
import '../../../state/providers.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/location_autocomplete_field.dart';

class PostRideScreen extends ConsumerStatefulWidget {
  const PostRideScreen({super.key});

  @override
  ConsumerState<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends ConsumerState<PostRideScreen> {
  int _currentStep = 0;

  // Step 1: Route & Schedule
  Location? _origin;
  Location? _destination;
  DateTime? _departureDate;
  TimeOfDay? _departureTime;

  // Step 2: Seats & Pricing
  Vehicle? _selectedVehicle;
  int _totalSeats = 3;
  double _pricePerSeat = 100;
  bool _femaleOnly = false;

  // Step 3: Rules
  final List<String> _selectedRules = [];
  final _meetupController = TextEditingController();

  @override
  void dispose() {
    _meetupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final vehicles = MockDataService.getAllVehicles();

    return Scaffold(
      appBar: AppBar(title: const Text('Post a Ride')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          try {
            print('🔘 Continue pressed - Current step: $_currentStep');
            print('📍 Origin: $_origin');
            print('📍 Destination: $_destination');
            print('📅 Date: $_departureDate');
            print('🕐 Time: $_departureTime');

            if (_currentStep < 2) {
              print('⏭️ Attempting to move to next step...');
              setState(() {
                _currentStep++;
                print('✅ Successfully moved to step $_currentStep');
              });
            } else {
              print('🚀 Publishing ride...');
              _publishRide(currentUser!);
            }
          } catch (e, stackTrace) {
            print('❌ ERROR in onStepContinue: $e');
            print('Stack trace: $stackTrace');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep--;
            });
          } else {
            context.pop();
          }
        },
        steps: [
          // Step 1: Route & Schedule
          Step(
            title: const Text('Route & Schedule'),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                // Origin Location with OpenStreetMap Autocomplete
                LocationAutocompleteField(
                  label: 'From',
                  icon: Icons.my_location,
                  initialValue: _origin?.address,
                  onLocationSelected: (suggestion) {
                    setState(() {
                      _origin = Location(
                        address: suggestion.address,
                        latitude: suggestion.latitude,
                        longitude: suggestion.longitude,
                      );
                    });
                    print('✅ Origin selected: ${suggestion.address}');
                  },
                ),

                const SizedBox(height: Spacing.lg),

                // Destination Location with OpenStreetMap Autocomplete
                LocationAutocompleteField(
                  label: 'To',
                  icon: Icons.location_on,
                  initialValue: _destination?.address,
                  onLocationSelected: (suggestion) {
                    setState(() {
                      _destination = Location(
                        address: suggestion.address,
                        latitude: suggestion.latitude,
                        longitude: suggestion.longitude,
                      );
                    });
                    print('✅ Destination selected: ${suggestion.address}');
                  },
                ),

                const SizedBox(height: Spacing.xl),

                // Route preview (optional)
                if (_origin != null && _destination != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.route, size: 20),
                              const SizedBox(width: Spacing.sm),
                              Text(
                                'Route Preview',
                                style: AppTypography.body(
                                  context,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Spacing.sm),
                          Text(
                            '${_origin!.address} → ${_destination!.address}',
                            style: AppTypography.bodySmall(context),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            'Est. 25 km • 45 min',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: Spacing.xl),

                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _departureDate == null
                        ? 'Select Date'
                        : '${_departureDate!.day}/${_departureDate!.month}/${_departureDate!.year}',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      setState(() {
                        _departureDate = date;
                      });
                    }
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    _departureTime == null
                        ? 'Select Time'
                        : _departureTime!.format(context),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _departureTime = time;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Step 2: Seats & Pricing
          Step(
            title: const Text('Seats & Pricing'),
            isActive: _currentStep >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vehicles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No vehicles found. Please contact support.',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<Vehicle>(
                    initialValue: _selectedVehicle,
                    decoration: const InputDecoration(
                      labelText: 'Select Vehicle',
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    isExpanded: true, // Important for Text overflow
                    items: vehicles.map((vehicle) {
                      return DropdownMenuItem(
                        value: vehicle,
                        child: Text(
                          '${vehicle.model} - ${vehicle.color}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVehicle = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a vehicle' : null,
                  ),

                const SizedBox(height: Spacing.xl),

                Text(
                  'Available Seats: $_totalSeats',
                  style: AppTypography.body(context, weight: FontWeight.w600),
                ),
                Slider(
                  value: _totalSeats.toDouble(),
                  min: 1,
                  max: 6,
                  divisions: 5,
                  label: '$_totalSeats',
                  onChanged: (value) {
                    setState(() {
                      _totalSeats = value.toInt();
                    });
                  },
                ),

                const SizedBox(height: Spacing.lg),

                Text(
                  'Price per Seat: Rs ${_pricePerSeat.toInt()}',
                  style: AppTypography.body(context, weight: FontWeight.w600),
                ),
                Slider(
                  value: _pricePerSeat,
                  min: 20,
                  max: 500,
                  divisions: 24,
                  label: 'Rs ${_pricePerSeat.toInt()}',
                  onChanged: (value) {
                    setState(() {
                      _pricePerSeat = value;
                    });
                  },
                ),

                const SizedBox(height: Spacing.lg),

                SwitchListTile(
                  title: const Text('Female Only Ride'),
                  subtitle: const Text('Only female passengers can book'),
                  value: _femaleOnly,
                  onChanged: (value) {
                    setState(() {
                      _femaleOnly = value;
                    });
                  },
                  secondary: const Icon(
                    Icons.female,
                    color: AppColors.femaleOnly,
                  ),
                ),
              ],
            ),
          ),

          // Step 3: Rules & Confirmation
          Step(
            title: const Text('Rules & Confirmation'),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ride Rules',
                  style: AppTypography.body(context, weight: FontWeight.w600),
                ),
                const SizedBox(height: Spacing.md),

                Wrap(
                  spacing: Spacing.sm,
                  children:
                      [
                        'No smoking',
                        'Music allowed',
                        'AC on',
                        'Luggage allowed',
                        'Quiet ride',
                      ].map((rule) {
                        final isSelected = _selectedRules.contains(rule);
                        return FilterChip(
                          label: Text(rule),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedRules.add(rule);
                              } else {
                                _selectedRules.remove(rule);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),

                const SizedBox(height: Spacing.xl),

                TextField(
                  controller: _meetupController,
                  decoration: const InputDecoration(
                    labelText: 'Meetup Instructions (Optional)',
                    hintText: 'e.g., Near metro station gate 2',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _publishRide(dynamic currentUser) async {
    // Check if profile is locked
    final isLocked = await CommissionService().isProfileLocked(currentUser.id);
    if (isLocked && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Profile Locked 🔒'),
          content: const Text(
            'Your profile is locked because you have completed 4 rides '
            'without paying the 5% commission. Please contact the admin '
            'to clear your pending commission and unlock your profile.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Detailed validation with specific error messages
    List<String> missingFields = [];

    if (_origin == null) missingFields.add('Origin location');
    if (_destination == null) missingFields.add('Destination location');
    if (_departureDate == null) missingFields.add('Departure date');
    if (_departureTime == null) missingFields.add('Departure time');
    if (_selectedVehicle == null) missingFields.add('Vehicle');

    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Missing required fields:\n• ${missingFields.join('\n• ')}',
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final departureDateTime = DateTime(
      _departureDate!.year,
      _departureDate!.month,
      _departureDate!.day,
      _departureTime!.hour,
      _departureTime!.minute,
    );

    final ride = Ride(
      id: const Uuid()
          .v4(), // We will let Firestore generate ID ideally, but keeping this for now
      driver: currentUser,
      vehicle: _selectedVehicle!,
      origin: _origin!,
      destination: _destination!,
      departureTime: departureDateTime,
      estimatedArrivalTime: departureDateTime.add(const Duration(hours: 1)),
      pricePerSeat: _pricePerSeat,
      totalSeats: _totalSeats,
      availableSeats: _totalSeats,
      femaleOnly: _femaleOnly,
      rules: _selectedRules,
      meetupInstructions: _meetupController.text.isEmpty
          ? null
          : _meetupController.text,
      distanceKm: 25.0,
      durationMinutes: 45,
    );

    try {
      // Show loading
      print('🚀 PostRideScreen: Starting ride publish process...');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await ref.read(ridesProvider.notifier).addRide(ride);

      if (mounted) {
        Navigator.pop(context); // Pop loading dialog

        print('✅ PostRideScreen: Ride published, navigating to driver home...');

        // Navigate to driver home (rides tab)
        context.go('/rides');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ride published successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ PostRideScreen: Error publishing ride: $e');

      if (mounted) {
        Navigator.pop(context); // Pop loading dialog

        // Show detailed error message
        String errorMessage = 'Failed to publish ride';

        if (e.toString().contains('permission')) {
          errorMessage =
              'Permission denied. Please check your account settings.';
        } else if (e.toString().contains('network')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _publishRide(currentUser),
            ),
          ),
        );
      }
    }
  }
}
