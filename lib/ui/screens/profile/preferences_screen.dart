import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_preferences.dart';
import '../../../models/preferences_enums.dart';
import '../../../models/ride.dart';
import '../../../state/providers.dart';
import '../../../services/user_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/location_autocomplete_field.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  final UserService _userService = UserService();

  // Office Info
  final TextEditingController _officeNameController = TextEditingController();
  Location? _officeLocation;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Preferences
  MusicPreference _musicPreference = MusicPreference.none;
  TalkPreference _talkPreference = TalkPreference.normal;
  GenderPreference _genderPreference = GenderPreference.any;
  RideFrequency _rideFrequency = RideFrequency.occasional;

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPreferences();
  }

  void _loadCurrentPreferences() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser?.preferences != null) {
      final prefs = currentUser!.preferences!;
      setState(() {
        _officeNameController.text = prefs.office.name;
        _officeLocation = prefs.office.location;
        _startTime = _parseTime(prefs.office.startTime);
        _endTime = _parseTime(prefs.office.endTime);
        _musicPreference = prefs.musicPreference;
        _talkPreference = prefs.talkPreference;
        _genderPreference = prefs.genderPreference;
        _rideFrequency = prefs.rideFrequency;
      });
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _savePreferences() async {
    if (_officeLocation == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete office information'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Read providers BEFORE async operations
      final currentUser = ref.read(currentUserProvider);
      final authNotifier = ref.read(authProvider.notifier);

      if (currentUser == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final officeInfo = OfficeInfo(
        name: _officeNameController.text.isEmpty
            ? 'My Office'
            : _officeNameController.text,
        location: _officeLocation!,
        startTime: _formatTime(_startTime!),
        endTime: _formatTime(_endTime!),
      );

      final preferences = UserPreferences(
        office: officeInfo,
        musicPreference: _musicPreference,
        talkPreference: _talkPreference,
        genderPreference: _genderPreference,
        rideFrequency: _rideFrequency,
      );

      final updatedUser = currentUser.copyWith(preferences: preferences);
      await _userService.updateUser(updatedUser);

      // Refresh auth state
      await authNotifier.refreshAuthState();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Preferences saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving preferences: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _officeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Preferences'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _savePreferences,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          // Office Information Section
          _buildSectionHeader('🏢 Office Information'),
          const SizedBox(height: Spacing.md),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                children: [
                  TextField(
                    controller: _officeNameController,
                    decoration: const InputDecoration(
                      labelText: 'Office Name (Optional)',
                      prefixIcon: Icon(Icons.business),
                      hintText: 'e.g., Tech Corp HQ',
                    ),
                    onChanged: (_) => _markChanged(),
                  ),

                  const SizedBox(height: Spacing.lg),

                  LocationAutocompleteField(
                    label: 'Office Location',
                    icon: Icons.location_on,
                    initialValue: _officeLocation?.address,
                    onLocationSelected: (suggestion) {
                      setState(() {
                        _officeLocation = Location(
                          address: suggestion.address,
                          latitude: suggestion.latitude,
                          longitude: suggestion.longitude,
                        );
                      });
                      _markChanged();
                    },
                  ),

                  const SizedBox(height: Spacing.lg),

                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.access_time),
                          title: const Text('Start Time'),
                          subtitle: Text(
                            _startTime?.format(context) ?? 'Not set',
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime:
                                  _startTime ??
                                  const TimeOfDay(hour: 9, minute: 0),
                            );
                            if (time != null) {
                              setState(() => _startTime = time);
                              _markChanged();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.access_time_filled),
                          title: const Text('End Time'),
                          subtitle: Text(
                            _endTime?.format(context) ?? 'Not set',
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime:
                                  _endTime ??
                                  const TimeOfDay(hour: 17, minute: 0),
                            );
                            if (time != null) {
                              setState(() => _endTime = time);
                              _markChanged();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Spacing.xl),

          // Music Preference
          _buildSectionHeader('🎵 Music Preference'),
          const SizedBox(height: Spacing.md),

          Card(
            child: Column(
              children: MusicPreference.values.map((pref) {
                return RadioListTile<MusicPreference>(
                  value: pref,
                  groupValue: _musicPreference,
                  onChanged: (value) {
                    setState(() => _musicPreference = value!);
                    _markChanged();
                  },
                  title: Row(
                    children: [
                      Text(pref.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: Spacing.md),
                      Text(pref.displayName),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: Spacing.xl),

          // Talk Preference
          _buildSectionHeader('💬 Conversation Style'),
          const SizedBox(height: Spacing.md),

          Card(
            child: Column(
              children: TalkPreference.values.map((pref) {
                return RadioListTile<TalkPreference>(
                  value: pref,
                  groupValue: _talkPreference,
                  onChanged: (value) {
                    setState(() => _talkPreference = value!);
                    _markChanged();
                  },
                  title: Row(
                    children: [
                      Text(pref.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: Spacing.md),
                      Text(pref.displayName),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: Spacing.xl),

          // Gender Preference
          _buildSectionHeader('👥 Co-Rider Preference'),
          const SizedBox(height: Spacing.md),

          Card(
            child: Column(
              children: GenderPreference.values.map((pref) {
                return RadioListTile<GenderPreference>(
                  value: pref,
                  groupValue: _genderPreference,
                  onChanged: (value) {
                    setState(() => _genderPreference = value!);
                    _markChanged();
                  },
                  title: Text(pref.displayName),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: Spacing.xl),

          // Ride Frequency
          _buildSectionHeader('📅 Ride Frequency'),
          const SizedBox(height: Spacing.md),

          Card(
            child: Column(
              children: RideFrequency.values.map((freq) {
                return RadioListTile<RideFrequency>(
                  value: freq,
                  groupValue: _rideFrequency,
                  onChanged: (value) {
                    setState(() => _rideFrequency = value!);
                    _markChanged();
                  },
                  title: Row(
                    children: [
                      Text(freq.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: Spacing.md),
                      Text(freq.displayName),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: Spacing.xxl),

          // Save Button
          if (_hasChanges)
            ElevatedButton(
              onPressed: _isLoading ? null : _savePreferences,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(Spacing.lg),
                backgroundColor: AppColors.primaryDark,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Preferences',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

          const SizedBox(height: Spacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.body(
        context,
        weight: FontWeight.bold,
      ).copyWith(fontSize: 18),
    );
  }
}
