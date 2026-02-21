# 🚗 EzRide — Smart Carpooling Application

A full-featured, production-ready carpooling application built with **Flutter** and **Firebase**, designed for college students and young professionals (18–25) in Pakistan. The app connects riders and drivers for shared commutes with AI-powered matching, real-time messaging, in-app calling, and a complete ride lifecycle.

---

## ✨ Features

### 🧑‍💼 User Management
- **Phone/Google Sign-In** — Firebase Auth with OTP verification and Google Sign-In
- **Profile Setup** — Name, photo, university/workplace, bio, and vehicle details
- **Role Switching** — Seamlessly toggle between Driver and Passenger modes
- **Biometric Security** — Fingerprint and face unlock via device local auth

### 🔍 Ride Discovery & Booking
- **Smart Search** — Search rides by origin, destination, date, and filters (female-only, max price, min seats)
- **Ride Details** — View driver info, vehicle, route map, price per seat, and ride rules
- **Booking Flow** — Select seats, confirm booking, and receive real-time confirmation
- **Dynamic Pricing** — AI-suggested fare adjustments based on demand and distance

### 🚘 Driver Features
- **Post a Ride** — Set origin/destination with Google Maps autocomplete, departure time, price, seat count, and rules
- **Manage Rides** — View upcoming, active, and past rides in a tabbed interface
- **Start / Complete Ride** — Full ride lifecycle with Firestore status updates
- **Earnings Dashboard** — Track per-ride and total earnings

### 📍 Live Trip
- **Real-time Tracking** — Live trip view with animated navigation UI
- **ETA, Distance, Fare** — Key stats displayed during the ride
- **In-trip Communication** — Message or call passengers/driver directly
- **SOS Emergency** — One-tap emergency alert to notify contacts
- **Ride Completion** — Driver marks ride complete, all bookings finalized automatically

### ⭐ Ratings & Reviews
- **Star Rating (1–5)** — Rate driver or passenger after each ride
- **Tag Selection** — Quick feedback tags (e.g., "Safe driving", "On time", "Friendly")
- **Comments** — Optional detailed feedback
- **Firestore Persistence** — Ratings atomically update the user's average rating

### 💬 Messaging
- **Real-time Chat** — Firebase-powered 1:1 messaging between riders and drivers
- **Conversation List** — View all active conversations with last message preview
- **Read Receipts** — Track message delivery and read status

### 📞 In-App Calling
- **Agora VoIP** — Crystal-clear audio calls powered by Agora RTC
- **Incoming Call UI** — Full-screen ringing notification with accept/reject
- **Call Controls** — Mute, speaker, and end call actions

### 🤖 AI Features
- **Intelligent Ride Assistant** — Google Gemini-powered chatbot for ride suggestions
- **Smart Matching** — AI compatibility scoring between riders and drivers
- **Ride Recommendations** — Personalized ride suggestions based on preferences

### 🔐 Identity Verification
- **CNIC Scanning** — ML Kit text recognition for Pakistani national ID cards
- **Face Liveness Detection** — Anti-spoofing face verification with pose detection
- **Fingerprint Capture** — Biometric enrollment for enhanced security

### 🎨 UI/UX
- **Light & Dark Themes** — Adaptive Material 3 theming with custom color palette
- **Smooth Animations** — Micro-interactions and transitions via `flutter_animate`
- **Google Fonts** — Premium typography with Inter font family
- **Responsive Layout** — Optimized for all Android screen sizes

---

## 🏗️ Architecture

```
carpool_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # MaterialApp configuration
│   ├── firebase_options.dart     # Firebase config (auto-generated)
│   ├── config/                   # Environment & app configuration
│   ├── models/                   # 15 data models (Ride, User, Booking, etc.)
│   ├── services/                 # 33 service classes (Firestore, Agora, AI, etc.)
│   ├── state/                    # Riverpod providers & state management
│   ├── routes/                   # GoRouter navigation configuration
│   └── ui/
│       ├── screens/              # 35+ screens across 14 feature modules
│       ├── widgets/              # Reusable UI components
│       └── theme/                # Color palette, typography, spacing tokens
│
├── backend/                      # Python FastAPI backend
│   └── app/
│       ├── main.py               # FastAPI server entry
│       ├── api/                   # REST endpoints
│       │   ├── agora.py          # Agora token generation
│       │   ├── analytics.py      # Ride & user analytics
│       │   ├── match.py          # AI ride matching engine
│       │   ├── notifications.py  # Push notification service
│       │   ├── preferences.py    # User preferences API
│       │   └── ratings.py        # Rating analytics & aggregation
│       ├── core/                  # Config & middleware
│       ├── models/                # Pydantic schemas
│       └── services/             # Business logic services
│
├── android/                      # Android platform config
├── ios/                          # iOS platform config
├── web/                          # Web platform config
└── assets/                       # Images & illustrations
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.x, Dart |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Backend** | Python FastAPI |
| **Database** | Cloud Firestore |
| **Authentication** | Firebase Auth (Phone + Google) |
| **Maps** | Google Maps Flutter + Flutter Map |
| **VoIP Calling** | Agora RTC Engine |
| **AI/ML** | Google Gemini, ML Kit (Face, Text, Pose) |
| **Image Upload** | Cloudinary |
| **Biometrics** | local_auth |

---

## 📦 Data Models

| Model | Description |
|-------|-----------|
| `User` | Profile, role, vehicle, verification status, rating |
| `Ride` | Origin/destination, departure, price, seats, status, passengers |
| `Booking` | Ride reference, passenger, seats booked, amount, status |
| `Rating` | Stars (1–5), tags, comment, rater/rated user IDs |
| `Message` | Sender, receiver, content, timestamp, read status |
| `Call` | Caller, receiver, channel, status, duration |
| `Vehicle` | Make, model, color, plate number, year |
| `CnicData` | National ID extraction from ML Kit scanning |
| `UserPreferences` | Music, smoking, conversation, AC preferences |
| `Notification` | Type, title, body, read status, deep link |
| `PaymentMethod` | Card/wallet details for fare payments |
| `CompatibilityResult` | AI matching score between users |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** `>=3.10.4`
- **Dart SDK** `>=3.x`
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Project** with Firestore, Auth, and Cloud Functions enabled
- **Python 3.9+** (for backend)
- **API Keys**: Google Maps, Agora, Google Gemini, Cloudinary

### 1. Clone the Repository

```bash
git clone https://github.com/ahmad-abuzar/carpool-app.git
cd carpool-app
```

### 2. Configure Environment

Create a `.env` file in the project root:

```env
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
AGORA_APP_ID=your_agora_app_id
GEMINI_API_KEY=your_gemini_api_key
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
BACKEND_URL=http://your-backend-url:8000
```

### 3. Install Flutter Dependencies

```bash
flutter pub get
```

### 4. Configure Firebase

- Add your `google-services.json` (Android) to `android/app/`
- Add your `GoogleService-Info.plist` (iOS) to `ios/Runner/`
- Ensure `firebase_options.dart` matches your Firebase project

### 5. Run the App

```bash
flutter run
```

### 6. Backend Setup (Optional)

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## 📱 Screens Overview

| Module | Screens |
|--------|---------|
| **Auth** | Welcome, Phone Auth, OTP, Profile Setup, Face Verification, Biometric Setup |
| **Onboarding** | Onboarding Carousel, Role Selection |
| **Home** | Home (Driver/Passenger toggle), Ride Search |
| **Rides** | Ride Details, Upcoming Trip, Live Trip, Ride Completion, Rating |
| **Booking** | Booking Flow, Booking Confirmation |
| **Driver** | Driver Home (My Rides), Manage Rides, Post Ride |
| **Messages** | Conversations List, Chat |
| **Calls** | Audio Call, Incoming Call |
| **Profile** | Profile, Preferences, Payment Methods, Ride History, Appearance, Verification |
| **Verification** | CNIC Scan, CNIC Confirmation, Face Liveness, Face Verification, Fingerprint, ID Scan |
| **AI** | AI Features Hub |

---

## 🔄 Ride Lifecycle

```
Driver posts ride → Passenger books → Driver starts ride → Live tracking
    → Driver completes ride → Bookings finalized → Both rate each other → Home
```

| Status | Description |
|--------|-----------|
| `scheduled` | Ride posted, waiting for departure time |
| `driverEnRoute` | Driver has started heading to pickup |
| `inProgress` | Ride actively in progress |
| `completed` | Ride finished, bookings auto-completed |
| `cancelled` | Ride cancelled by driver or system |

---

## 🔌 Backend API Endpoints

| Endpoint | Method | Description |
|----------|--------|-----------|
| `/api/agora/token` | POST | Generate Agora RTC token for calls |
| `/api/match/find` | POST | AI-powered ride matching |
| `/api/match/compatibility` | POST | Calculate rider-driver compatibility |
| `/api/ratings/statistics/{user_id}` | GET | Get user rating statistics |
| `/api/ratings/analyze` | POST | AI rating analysis |
| `/api/analytics/rides` | GET | Ride analytics dashboard |
| `/api/analytics/users` | GET | User analytics |
| `/api/preferences` | GET/POST | User preference management |
| `/api/notifications/send` | POST | Send push notifications |

---

## 👨‍💻 Author

**Ahmad Abuzar**
- GitHub: [@ahmad-abuzar](https://github.com/ahmad-abuzar)

---

## 📄 License

This project is for academic/personal use. All rights reserved.
