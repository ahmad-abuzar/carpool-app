import 'package:flutter/material.dart';
import 'package:carpool_app/models/user_preferences.dart';
import 'package:carpool_app/models/preferences_enums.dart';
import 'package:carpool_app/models/ride.dart';
import 'package:carpool_app/services/matching_api_service.dart';
import 'package:carpool_app/ui/theme/color_palette.dart';

/// Screen for setting up user preferences for smart matching
class PreferencesSetupScreen extends StatefulWidget {
  final String userId;
  final UserPreferences? existingPreferences;

  const PreferencesSetupScreen({
    super.key,
    required this.userId,
    this.existingPreferences,
  });

  @override
  State<PreferencesSetupScreen> createState() => _PreferencesSetupScreenState();
}

class _PreferencesSetupScreenState extends State<PreferencesSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _officeNameController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  MusicPreference _musicPreference = MusicPreference.none;
  TalkPreference _talkPreference = TalkPreference.normal;
  GenderPreference _genderPreference = GenderPreference.any;
  RideFrequency _rideFrequency = RideFrequency.occasional;

  Location? _officeLocation;
  bool _isLoading = false;
  bool _smartMatchingEnabled = true;

  final _matchingService = MatchingApiService();

  @override
  void initState() {
    super.initState();
    _loadExistingPreferences();
  }

  void _loadExistingPreferences() {
    final prefs = widget.existingPreferences;
    if (prefs != null) {
      _officeNameController.text = prefs.office.name;
      _startTimeController.text = prefs.office.startTime;
      _endTimeController.text = prefs.office.endTime;
      _companyEmailController.text = prefs.companyEmail ?? '';
      _officeLocation = prefs.office.location;
      _musicPreference = prefs.musicPreference;
      _talkPreference = prefs.talkPreference;
      _genderPreference = prefs.genderPreference;
      _rideFrequency = prefs.rideFrequency;
    }
  }

  @override
  void dispose() {
    _officeNameController.dispose();
    _companyEmailController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _matchingService.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    if (_officeLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select office location')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final preferences = UserPreferences(
        office: OfficeInfo(
          name: _officeNameController.text.trim(),
          location: _officeLocation!,
          startTime: _startTimeController.text.trim(),
          endTime: _endTimeController.text.trim(),
        ),
        musicPreference: _musicPreference,
        talkPreference: _talkPreference,
        genderPreference: _genderPreference,
        rideFrequency: _rideFrequency,
        companyEmail: _companyEmailController.text.trim().isEmpty
            ? null
            : _companyEmailController.text.trim(),
        emailVerified: false,
      );

      final success = await _matchingService.savePreferences(
        userId: widget.userId,
        preferences: preferences,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Preferences saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, preferences);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Smart Matching Preferences'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),

            // Office Information
            _buildSectionTitle('🏢 Office Information'),
            const SizedBox(height: 12),
            _buildOfficeFields(),
            const SizedBox(height: 24),

            // Ride Preferences
            _buildSectionTitle('🎵 Ride Preferences'),
            const SizedBox(height: 12),
            _buildMusicPreference(),
            const SizedBox(height: 16),
            _buildTalkPreference(),
            const SizedBox(height: 16),
            _buildGenderPreference(),
            const SizedBox(height: 16),
            _buildRideFrequency(),
            const SizedBox(height: 24),

            // Company Email (Optional)
            _buildSectionTitle('📧 Company Email (Optional)'),
            const SizedBox(height: 12),
            _buildCompanyEmailField(),
            const SizedBox(height: 24),

            // Smart Matching Toggle
            _buildSmartMatchingToggle(),
            const SizedBox(height: 32),

            // Save Button
            _buildSaveButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark.withOpacity(0.1),
            AppColors.secondaryDark.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.psychology, size: 48, color: AppColors.primaryDark),
          const SizedBox(height: 12),
          Text(
            'AI Smart Matching',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us find the best ride matches for you based on your preferences and behavior',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildOfficeFields() {
    return Column(
      children: [
        TextFormField(
          controller: _officeNameController,
          decoration: const InputDecoration(
            labelText: 'Office/Company Name',
            hintText: 'e.g., Google India',
            prefixIcon: Icon(Icons.business),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter office name';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _startTimeController,
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  hintText: '09:00',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectTime(context, _startTimeController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _endTimeController,
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  hintText: '18:00',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectTime(context, _endTimeController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _selectOfficeLocation,
          icon: const Icon(Icons.location_on),
          label: Text(
            _officeLocation == null
                ? 'Select Office Location'
                : 'Location Selected',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildMusicPreference() {
    return _buildPreferenceSelector<MusicPreference>(
      title: 'Music Preference',
      values: MusicPreference.values,
      currentValue: _musicPreference,
      onChanged: (value) => setState(() => _musicPreference = value),
      getLabel: (value) => value.displayName,
      getIcon: (value) => value.icon,
    );
  }

  Widget _buildTalkPreference() {
    return _buildPreferenceSelector<TalkPreference>(
      title: 'Conversation Preference',
      values: TalkPreference.values,
      currentValue: _talkPreference,
      onChanged: (value) => setState(() => _talkPreference = value),
      getLabel: (value) => value.displayName,
      getIcon: (value) => value.icon,
    );
  }

  Widget _buildGenderPreference() {
    return _buildPreferenceSelector<GenderPreference>(
      title: 'Gender Preference',
      values: GenderPreference.values,
      currentValue: _genderPreference,
      onChanged: (value) => setState(() => _genderPreference = value),
      getLabel: (value) => value.displayName,
      getIcon: (value) => '👥',
    );
  }

  Widget _buildRideFrequency() {
    return _buildPreferenceSelector<RideFrequency>(
      title: 'Ride Frequency',
      values: RideFrequency.values,
      currentValue: _rideFrequency,
      onChanged: (value) => setState(() => _rideFrequency = value),
      getLabel: (value) => value.displayName,
      getIcon: (value) => value.icon,
    );
  }

  Widget _buildPreferenceSelector<T>({
    required String title,
    required List<T> values,
    required T currentValue,
    required ValueChanged<T> onChanged,
    required String Function(T) getLabel,
    required String Function(T) getIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) {
            final isSelected = value == currentValue;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(getIcon(value)),
                  const SizedBox(width: 6),
                  Text(getLabel(value)),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onChanged(value),
              selectedColor: AppColors.primaryDark.withOpacity(0.2),
              backgroundColor: Colors.grey[100],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompanyEmailField() {
    return TextFormField(
      controller: _companyEmailController,
      decoration: InputDecoration(
        labelText: 'Company Email',
        hintText: 'your.name@company.com',
        prefixIcon: const Icon(Icons.email),
        border: const OutlineInputBorder(),
        helperText: 'For better office matching',
        helperStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (!value.contains('@')) {
            return 'Please enter a valid email';
          }
        }
        return null;
      },
    );
  }

  Widget _buildSmartMatchingToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enable Smart Matching',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  'Use AI to find compatible ride matches',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: _smartMatchingEnabled,
            onChanged: (value) {
              setState(() => _smartMatchingEnabled = value);
            },
            activeThumbColor: AppColors.primaryDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _savePreferences,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Save Preferences',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  void _selectOfficeLocation() {
    // TODO: Integrate with Google Places API or map picker
    // For now, use a dummy location
    setState(() {
      _officeLocation = const Location(
        latitude: 28.5355,
        longitude: 77.3910,
        address: 'Sector 62, Noida, UP',
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location selected (Demo)'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
