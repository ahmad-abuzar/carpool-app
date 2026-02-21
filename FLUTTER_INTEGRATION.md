# Flutter Integration Guide

## Overview

This guide shows how to integrate the AI Smart Matching backend with your Flutter app.

## Files Added

### Models
- `lib/models/preferences_enums.dart` - Preference enums (Music, Talk, Gender, Frequency)
- `lib/models/user_preferences.dart` - User preferences and office info
- `lib/models/compatibility_result.dart` - Compatibility result with levels

### Services
- `lib/services/matching_api_service.dart` - API client for backend

### UI Widgets
- `lib/ui/widgets/compatibility_badge.dart` - Score badge widgets
- `lib/ui/widgets/compatibility_reasons.dart` - Reasons display & details sheet
- `lib/ui/widgets/smart_ride_card.dart` - Enhanced ride card with compatibility

### Screens
- `lib/ui/screens/preferences/preferences_setup_screen.dart` - Preferences setup

## Setup Steps

### 1. Update Backend URL

Edit `lib/services/matching_api_service.dart`:

```dart
// For local development
static const String baseUrl = 'http://localhost:8000/api/v1';

// For Android emulator
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

// For production
static const String baseUrl = 'https://your-api-url.com/api/v1';
```

### 2. Add to Existing Screens

#### A. Add Preferences Button to Profile/Settings

```dart
// In your profile or settings screen
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreferencesSetupScreen(
          userId: currentUser.id,
          existingPreferences: currentUser.preferences,
        ),
      ),
    );
  },
  child: const Text('Setup Smart Matching'),
)
```

#### B. Replace Ride Cards in Ride List

```dart
// Instead of your current ride card
RideCard(ride: ride)

// Use the smart ride card
SmartRideCard(
  ride: ride,
  currentUserId: currentUser.id,
  onTap: () {
    // Navigate to ride details
  },
)
```

### 3. Update User Model

Add preferences field to your existing `User` model:

```dart
// In lib/models/user.dart
import 'package:carpool_app/models/user_preferences.dart';

class User {
  // ... existing fields
  final UserPreferences? preferences;
  final bool smartMatchingEnabled;
  
  // ... rest of the model
}
```

### 4. Save Preferences to Firebase

After user saves preferences, also save to Firestore:

```dart
// In your user service
Future<void> saveUserPreferences(
  String userId,
  UserPreferences preferences,
) async {
  // Save to Firestore
  await FirebaseFirestore.instance
      .collection('user_preferences')
      .doc(userId)
      .set({
    'preferences': preferences.toMap(),
    'smart_matching_enabled': true,
    'updated_at': FieldValue.serverTimestamp(),
  });
  
  // Also send to backend
  final matchingService = MatchingApiService();
  await matchingService.savePreferences(
    userId: userId,
    preferences: preferences,
  );
}
```

## Usage Examples

### Calculate Single Match

```dart
final matchingService = MatchingApiService();

try {
  final result = await matchingService.calculateMatch(
    userId: 'user123',
    candidateId: 'driver456',
  );
  
  print('Score: ${result.scorePercentage}');
  print('Level: ${result.level.label}');
  print('Reasons: ${result.reasons}');
} catch (e) {
  print('Error: $e');
}
```

### Batch Match (Multiple Drivers)

```dart
final driverIds = rides.map((r) => r.driverId).toList();

final batchResult = await matchingService.batchMatch(
  userId: currentUserId,
  candidateIds: driverIds,
);

// Sort rides by compatibility
final sortedRides = rides.map((ride) {
  final match = batchResult.matches.firstWhere(
    (m) => m.candidateId == ride.driverId,
  );
  return (ride: ride, compatibility: match);
}).toList()
  ..sort((a, b) => b.compatibility.score.compareTo(a.compatibility.score));
```

### Show Compatibility Details

```dart
// On tap of compatibility badge
CompatibilityDetailsSheet.show(context, compatibilityResult);
```

## UI Components

### Compatibility Badge

```dart
CompatibilityBadge(
  result: compatibilityResult,
  showPercentage: true,
  size: 60,
)
```

### Compact Badge (for lists)

```dart
CompactCompatibilityBadge(
  result: compatibilityResult,
)
```

### Compatibility Bar

```dart
CompatibilityBar(
  result: compatibilityResult,
  height: 8,
)
```

### Reasons Display

```dart
CompatibilityReasons(
  result: compatibilityResult,
  showRecommendation: true,
)
```

## Testing

### 1. Start Backend

```bash
cd backend
uvicorn app.main:app --reload
```

### 2. Test API Connection

```dart
final matchingService = MatchingApiService();
final isHealthy = await matchingService.checkHealth();
print('Backend healthy: $isHealthy');
```

### 3. Create Test Users

Create test users with preferences in Firebase and test matching.

## Error Handling

```dart
try {
  final result = await matchingService.calculateMatch(...);
  // Success
} on MatchingException catch (e) {
  // Show user-friendly error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
} catch (e) {
  // Generic error
  print('Unexpected error: $e');
}
```

## Performance Tips

1. **Cache Results**: Cache compatibility results to avoid repeated API calls
2. **Batch Requests**: Use batch matching for multiple drivers
3. **Lazy Loading**: Load compatibility only when needed
4. **Debouncing**: Debounce API calls when filtering/searching

## Next Steps

1. ✅ Setup backend (see backend/QUICKSTART.md)
2. ✅ Add Flutter models and services
3. 🔲 Test API integration
4. 🔲 Add preferences screen to onboarding
5. 🔲 Update ride list with smart cards
6. 🔲 Train ML model (Phase 2)
7. 🔲 Deploy to production

## Support

- Backend API Docs: http://localhost:8000/docs
- Backend Examples: backend/API_EXAMPLES.md
- Flutter Models: See files in lib/models/

## Demo Flow

1. User opens app → Navigate to Preferences Setup
2. Fill in office details, preferences → Save
3. Browse rides → See compatibility scores
4. Tap badge → View detailed reasons
5. Book high-compatibility rides → Better experience!

---

**Happy Coding! 🚀**
