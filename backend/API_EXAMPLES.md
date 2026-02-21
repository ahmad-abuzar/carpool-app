# API Examples — Request & Response Reference

Complete examples for all backend API endpoints.

---

## Table of Contents

1. [Matching](#1-matching)
2. [Preferences](#2-preferences)
3. [Analytics](#3-analytics)
4. [Notifications](#4-notifications)
5. [Ratings](#5-ratings)
6. [Agora](#6-agora)
7. [Error Responses](#7-error-responses)
8. [Flutter Integration](#8-flutter-integration)

---

## 1. Matching

### Calculate Single Match

```http
POST /api/v1/match
Content-Type: application/json

{
  "user_id": "user123",
  "candidate_id": "driver456",
  "use_ml": false
}
```

**Response:**
```json
{
  "user_id": "user123",
  "candidate_id": "driver456",
  "compatibility_score": 92.5,
  "compatibility_level": "high",
  "reasons": [
    "🏢 Same office/company",
    "🎵 Same music preference",
    "💬 Similar conversation style",
    "⏰ Both highly punctual (90%+)",
    "🕐 Perfect time match (±15 min)"
  ],
  "breakdown": {
    "office_match": 100.0,
    "music_preference": 100.0,
    "talk_preference": 100.0,
    "punctuality": 95.0,
    "gender_preference": 100.0,
    "time_match": 100.0
  },
  "recommendation": "Highly compatible match! You share 5 key preferences."
}
```

---

### Batch Match (Multiple Candidates)

```http
POST /api/v1/match/batch
Content-Type: application/json

{
  "user_id": "user123",
  "candidate_ids": ["driver456", "driver789", "driver101"],
  "use_ml": false
}
```

**Response:**
```json
{
  "user_id": "user123",
  "total_candidates": 3,
  "matches": [
    {
      "candidate_id": "driver456",
      "compatibility_score": 92.5,
      "compatibility_level": "high",
      "reasons": ["🏢 Same office/company", "🎵 Same music preference"],
      "recommendation": "Highly compatible match!"
    },
    {
      "candidate_id": "driver789",
      "compatibility_score": 78.0,
      "compatibility_level": "medium",
      "reasons": ["🏢 Same company domain"],
      "recommendation": "Moderately compatible."
    }
  ]
}
```

---

### Get Match History

```http
GET /api/v1/match/history/user123?limit=20
```

**Response:**
```json
{
  "user_id": "user123",
  "total_matches": 2,
  "matches": [
    {
      "candidate_id": "driver456",
      "compatibility_score": 92.5,
      "reasons": ["Same office", "Same music preference"],
      "timestamp": "2026-02-20T10:30:00"
    }
  ]
}
```

---

## 2. Preferences

### Save Preferences

```http
POST /api/v1/preferences
Content-Type: application/json

{
  "user_id": "user123",
  "preferences": {
    "office": {
      "name": "Arbisoft",
      "location": {
        "latitude": 31.4697,
        "longitude": 74.2728,
        "address": "2 A, Askari Corporate Tower, Gulberg III, Lahore"
      },
      "start_time": "09:00",
      "end_time": "18:00"
    },
    "music_preference": "soft",
    "talk_preference": "normal",
    "gender_preference": "any",
    "ride_frequency": "daily",
    "company_email": "user@arbisoft.com",
    "email_verified": true
  }
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Preferences saved successfully",
  "user_id": "user123"
}
```

---

### Get Preferences

```http
GET /api/v1/preferences/user123
```

**Response:**
```json
{
  "office": {
    "name": "Arbisoft",
    "location": { "latitude": 31.4697, "longitude": 74.2728, "address": "Gulberg III, Lahore" },
    "start_time": "09:00",
    "end_time": "18:00"
  },
  "music_preference": "soft",
  "talk_preference": "normal",
  "gender_preference": "any",
  "ride_frequency": "daily"
}
```

---

### Update Preferences

```http
PUT /api/v1/preferences/user123
Content-Type: application/json

{
  "office": { "name": "Arbisoft", "location": { "latitude": 31.47, "longitude": 74.27 }, "start_time": "10:00", "end_time": "19:00" },
  "music_preference": "loud",
  "talk_preference": "talkative",
  "gender_preference": "same",
  "ride_frequency": "weekly",
  "company_email": "user@arbisoft.com",
  "email_verified": true
}
```

**Response:** `200 OK`

---

### Disable Smart Matching

```http
DELETE /api/v1/preferences/user123
```

**Response:**
```json
{
  "success": true,
  "message": "Smart matching disabled for user user123"
}
```

---

## 3. Analytics

### Ride Statistics

```http
GET /api/v1/analytics/rides/user123
```

**Response:**
```json
{
  "user_id": "user123",
  "total_rides": 45,
  "rides_as_driver": 30,
  "rides_as_passenger": 15,
  "completed_rides": 42,
  "cancelled_rides": 3,
  "completion_rate": 93.3,
  "rating": 4.7,
  "total_ratings": 38
}
```

---

### Earnings

```http
GET /api/v1/analytics/earnings/user123
```

**Response:**
```json
{
  "user_id": "user123",
  "total_earnings": 45000.00,
  "total_rides_paid": 30,
  "average_per_ride": 1500.00,
  "monthly_breakdown": {
    "2026-01": 20000.00,
    "2026-02": 25000.00
  }
}
```

---

### Popular Routes

```http
GET /api/v1/analytics/popular-routes?limit=5
```

**Response:**
```json
{
  "total_routes_analyzed": 500,
  "popular_routes": [
    { "route": "Gulberg, Lahore → DHA Phase 6, Lahore", "trip_count": 45, "rank": 1 },
    { "route": "F-7, Islamabad → Blue Area, Islamabad", "trip_count": 38, "rank": 2 },
    { "route": "Model Town → Mall Road", "trip_count": 22, "rank": 3 }
  ]
}
```

---

## 4. Notifications

### Send Notification

```http
POST /api/v1/notifications/send
Content-Type: application/json

{
  "user_id": "user123",
  "type": "bookingConfirmed",
  "title": "Booking Confirmed!",
  "message": "Your ride from Gulberg to DHA has been confirmed.",
  "ride_id": "ride456"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "notification_id": "notif_abc123",
  "message": "Notification sent successfully"
}
```

---

### Get Notifications

```http
GET /api/v1/notifications/user123?limit=20&unread_only=true
```

**Response:**
```json
{
  "user_id": "user123",
  "total": 3,
  "notifications": [
    {
      "id": "notif_abc123",
      "user_id": "user123",
      "type": "bookingConfirmed",
      "title": "Booking Confirmed!",
      "message": "Your ride from Gulberg to DHA has been confirmed.",
      "timestamp": "2026-02-21T10:30:00",
      "read": false,
      "ride_id": "ride456"
    }
  ]
}
```

---

### Mark as Read

```http
PUT /api/v1/notifications/notif_abc123/read
```

---

### Mark All as Read

```http
PUT /api/v1/notifications/user123/read-all
```

**Response:**
```json
{
  "success": true,
  "message": "5 notifications marked as read",
  "count": 5
}
```

---

### Delete Notification

```http
DELETE /api/v1/notifications/notif_abc123
```

---

## 5. Ratings

### Submit Rating

```http
POST /api/v1/ratings
Content-Type: application/json

{
  "rated_user_id": "driver456",
  "rater_user_id": "user123",
  "stars": 5,
  "tags": ["Safe driving", "On time", "Friendly"],
  "comment": "Bohot acha experience tha, bahut professional driver!",
  "ride_id": "ride789"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "rating_id": "rating_xyz789",
  "message": "Rating submitted successfully",
  "new_average": 4.72
}
```

> **Note:** Duplicate ratings (same rater + rated user + ride) are rejected with `409 Conflict`.

---

### Get User Ratings

```http
GET /api/v1/ratings/user/driver456?limit=20
```

**Response:**
```json
{
  "user_id": "driver456",
  "total_ratings": 38,
  "average_rating": 4.72,
  "distribution": {
    "1": 0,
    "2": 1,
    "3": 3,
    "4": 14,
    "5": 20
  },
  "ratings": [
    {
      "id": "rating_xyz789",
      "rated_user_id": "driver456",
      "rater_user_id": "user123",
      "stars": 5,
      "tags": ["Safe driving", "On time"],
      "comment": "Great ride!",
      "ride_id": "ride789",
      "timestamp": "2026-02-21T10:30:00"
    }
  ]
}
```

---

### Get Ride Ratings

```http
GET /api/v1/ratings/ride/ride789
```

**Response:**
```json
{
  "ride_id": "ride789",
  "total_ratings": 2,
  "ratings": [
    { "stars": 5, "tags": ["Safe driving"], "comment": "Excellent!" },
    { "stars": 4, "tags": ["On time"], "comment": "Good ride." }
  ]
}
```

---

## 6. Agora

### Generate RTC Token

```http
POST /api/v1/agora/token
Content-Type: application/json

{
  "channel_name": "call_user123_driver456",
  "uid": 0,
  "role": "publisher",
  "expiration_seconds": 3600
}
```

**Response:**
```json
{
  "token": "007eJxTYBBi...",
  "channel_name": "call_user123_driver456",
  "uid": 0,
  "expiration_seconds": 3600
}
```

---

### Get Agora Config

```http
GET /api/v1/agora/config
```

**Response:**
```json
{
  "app_id": "your_agora_app_id",
  "token_required": true
}
```

---

## 7. Error Responses

### 404 Not Found
```json
{ "detail": "User user123 not found" }
```

### 409 Conflict (Duplicate Rating)
```json
{ "detail": "You have already rated this user for this ride" }
```

### 422 Validation Error
```json
{
  "detail": [
    {
      "loc": ["body", "stars"],
      "msg": "ensure this value is less than or equal to 5",
      "type": "value_error.number.not_le"
    }
  ]
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error",
  "detail": "Error calculating match: ..."
}
```

---

## 8. Flutter Integration

### Generic API Client

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class BackendApiService {
  static const String baseUrl = 'http://localhost:8000/api/v1';

  /// Submit a rating
  Future<Map<String, dynamic>> submitRating({
    required String ratedUserId,
    required String raterUserId,
    required int stars,
    required String rideId,
    List<String> tags = const [],
    String? comment,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ratings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'rated_user_id': ratedUserId,
        'rater_user_id': raterUserId,
        'stars': stars,
        'tags': tags,
        'comment': comment,
        'ride_id': rideId,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to submit rating: ${response.body}');
  }

  /// Get ride analytics
  Future<Map<String, dynamic>> getRideStats(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/rides/$userId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch stats');
  }

  /// Send notification
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? rideId,
  }) async {
    await http.post(
      Uri.parse('$baseUrl/notifications/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'ride_id': rideId,
      }),
    );
  }

  /// Generate Agora token
  Future<String> getAgoraToken(String channelName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/agora/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'channel_name': channelName,
        'uid': 0,
        'role': 'publisher',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['token'];
    }
    throw Exception('Failed to generate token');
  }
}
```
