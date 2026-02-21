# AI Smart Ride Matching Backend

FastAPI-based backend powering the **Carpool App** — an AI-driven ride-sharing platform for college students and office employees.

---

## Features

| Category | Details |
|----------|---------|
| **Smart Matching** | Rule-based + ML compatibility scoring |
| **Analytics** | Ride stats, earnings breakdown, popular routes |
| **Notifications** | In-app notification management via Firestore |
| **Ratings** | Submit ratings, auto-update user averages |
| **Agora** | Secure RTC token generation for in-app calling |
| **Preferences** | User ride preference management |

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | FastAPI (Python 3.10+) |
| Database | Firebase Cloud Firestore |
| ML | scikit-learn (Random Forest) |
| Auth | Firebase Authentication |
| Calling | Agora RTC (token server) |
| Deployment | Docker / Google Cloud Run |

---

## Project Structure

```
backend/
├── app/
│   ├── main.py                     # FastAPI entry point, CORS, routers
│   ├── core/
│   │   └── config.py               # Settings, weights, thresholds
│   ├── api/
│   │   ├── match.py                # POST /match, /match/batch, GET /match/history
│   │   ├── preferences.py          # CRUD for user preferences
│   │   ├── analytics.py            # Ride stats, earnings, popular routes
│   │   ├── agora.py                # Agora RTC token generation
│   │   ├── notifications.py        # Notification CRUD
│   │   └── ratings.py              # Rating submission & retrieval
│   ├── models/
│   │   └── match.py                # Pydantic models
│   └── services/
│       ├── firebase_service.py     # Firestore operations (singleton)
│       └── matching_service.py     # Compatibility scoring engine
├── ml/
│   ├── train_model.py              # ML training script
│   └── models/
│       └── compatibility_model.pkl # Trained model (generated)
├── tests/
│   └── test_matching.py            # Unit tests (pytest)
├── requirements.txt
├── Dockerfile
├── .env.example
└── README.md
```

---

## Quick Start

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Configure Firebase

Place your Firebase service account key as `firebase-credentials.json` in the `backend/` directory.

> Download from: Firebase Console → Project Settings → Service Accounts → Generate New Private Key

### 3. Environment Variables

Copy and configure the `.env` file:

```bash
cp .env.example .env
```

```env
FIREBASE_CREDENTIALS_PATH=firebase-credentials.json
ML_MODEL_PATH=ml/models/compatibility_model.pkl
ENABLE_ML_MATCHING=false
AGORA_APP_ID=your_agora_app_id
AGORA_APP_CERTIFICATE=your_agora_certificate
```

### 4. Run Development Server

```bash
uvicorn app.main:app --reload --port 8000
```

- **API**: http://localhost:8000
- **Swagger Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

---

## API Endpoints

All endpoints are prefixed with `/api/v1`.

### Matching

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/match` | Calculate compatibility between two users |
| `POST` | `/match/batch` | Calculate compatibility for multiple candidates |
| `GET` | `/match/history/{user_id}` | Get match history for a user |

### Preferences

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/preferences` | Save user preferences |
| `GET` | `/preferences/{user_id}` | Get user preferences |
| `PUT` | `/preferences/{user_id}` | Update user preferences |
| `DELETE` | `/preferences/{user_id}` | Disable smart matching |

### Analytics

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/analytics/rides/{user_id}` | Ride statistics (total, as driver/passenger, completion rate) |
| `GET` | `/analytics/earnings/{user_id}` | Earnings with monthly breakdown |
| `GET` | `/analytics/popular-routes` | Most popular routes |

### Notifications

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/notifications/send` | Send a notification to a user |
| `GET` | `/notifications/{user_id}` | Get user notifications (supports `?unread_only=true`) |
| `PUT` | `/notifications/{id}/read` | Mark notification as read |
| `PUT` | `/notifications/{user_id}/read-all` | Mark all as read |
| `DELETE` | `/notifications/{id}` | Delete a notification |

### Ratings

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/ratings` | Submit a rating (auto-updates user average) |
| `GET` | `/ratings/user/{user_id}` | Get ratings with statistics & distribution |
| `GET` | `/ratings/ride/{ride_id}` | Get all ratings for a ride |

### Agora

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/agora/token` | Generate Agora RTC token for calls |
| `GET` | `/agora/config` | Get Agora config (App ID, token requirement) |

### System

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | API info |
| `GET` | `/health` | Health check |

---

## Matching Algorithm

### Rule-Based Scoring (Weights sum to 1.0)

| Factor | Weight | Description |
|--------|--------|-------------|
| Office Match | 0.25 | Same company = 100, same domain = 80 |
| Music Preference | 0.15 | Same = 100, one step difference = 50 |
| Talk Preference | 0.15 | Same = 100, one step difference = 50 |
| Punctuality | 0.20 | Average of both users' punctuality scores |
| Gender Preference | 0.10 | Matches if preference is "any" or same gender |
| Time Match | 0.15 | Based on departure time difference |

### Compatibility Levels

| Level | Score Range |
|-------|-------------|
| 🟢 High | ≥ 80 |
| 🟡 Medium | 60 – 79 |
| 🔴 Low | < 60 |

### ML Model (Phase 2)

Enable ML predictions by setting `ENABLE_ML_MATCHING=true` in `.env`.

```bash
# Train the model
python -m ml.train_model
```

**ML Features (12 total):**

| # | Feature |
|---|---------|
| 1 | office_match |
| 2 | music_difference |
| 3 | talk_difference |
| 4 | user_punctuality |
| 5 | candidate_punctuality |
| 6 | gender_match |
| 7 | time_difference_minutes |
| 8 | user_completion_rate |
| 9 | candidate_completion_rate |
| 10 | user_avg_rating |
| 11 | candidate_avg_rating |
| 12 | rule_based_score |

**Model**: RandomForestClassifier (100 trees, max_depth=10, balanced class weights)

**Latest Training Results (sample data):**

| Metric | Value |
|--------|-------|
| Train Accuracy | 97.88% |
| Test Accuracy | 57.00% |
| Precision | 41.38% |
| Recall | 31.58% |
| F1 Score | 35.82% |
| CV F1 (mean ± std) | 45.10% ± 4.80% |

> **Note:** These metrics are on synthetic data. Real ride history data will significantly improve model performance.

---

## Testing

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ -v --cov=app
```

### Test Coverage

- `test_matching.py` — 10 test cases covering:
  - Same office match
  - Different gender preference handling
  - Music/talk preference scoring
  - Punctuality calculations
  - Time match scoring
  - Compatibility level thresholds (high/medium/low)

---

## Deployment

### Docker

```bash
docker build -t ai-matching-backend .
docker run -p 8080:8080 \
  -e FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json \
  ai-matching-backend
```

### Google Cloud Run

```bash
gcloud run deploy carpool-backend \
  --source . \
  --platform managed \
  --region asia-south1 \
  --allow-unauthenticated
```

---

## Configuration Reference

All settings are in `app/core/config.py` and can be overridden via `.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `PROJECT_NAME` | AI Smart Ride Matching API | API title |
| `API_V1_PREFIX` | /api/v1 | API route prefix |
| `DEBUG` | true | Debug mode |
| `FIREBASE_CREDENTIALS_PATH` | firebase-credentials.json | Firebase key path |
| `ML_MODEL_PATH` | ml/models/compatibility_model.pkl | Trained model path |
| `ENABLE_ML_MATCHING` | false | Enable ML predictions |
| `WEIGHT_OFFICE_MATCH` | 0.25 | Office match weight |
| `WEIGHT_MUSIC_PREFERENCE` | 0.15 | Music pref weight |
| `WEIGHT_TALK_PREFERENCE` | 0.15 | Talk pref weight |
| `WEIGHT_PUNCTUALITY` | 0.20 | Punctuality weight |
| `WEIGHT_GENDER_PREFERENCE` | 0.10 | Gender pref weight |
| `WEIGHT_TIME_MATCH` | 0.15 | Time match weight |
| `HIGH_COMPATIBILITY_THRESHOLD` | 80.0 | High compatibility cutoff |
| `MEDIUM_COMPATIBILITY_THRESHOLD` | 60.0 | Medium compatibility cutoff |
| `AGORA_APP_ID` | — | Agora App ID |
| `AGORA_APP_CERTIFICATE` | — | Agora App Certificate |

---

## License

MIT
