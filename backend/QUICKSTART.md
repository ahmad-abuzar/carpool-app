# Quick Start Guide - AI Smart Matching Backend

## 🚀 Getting Started

### 1. Setup Environment

```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings → Service Accounts
4. Click "Generate New Private Key"
5. Save the JSON file as `firebase-credentials.json` in the `backend/` directory

### 3. Setup Environment Variables

```bash
# Copy example env file
copy .env.example .env

# Edit .env and update if needed
```

### 4. Run Development Server

```bash
# Start the server
uvicorn app.main:app --reload --port 8000
```

Server will start at: `http://localhost:8000`

API Documentation: `http://localhost:8000/docs`

## 📝 Testing the API

### Using Swagger UI (Recommended)

1. Open `http://localhost:8000/docs`
2. Try the `/match` endpoint:
   - Click "Try it out"
   - Enter sample data
   - Click "Execute"

### Using cURL

```bash
# Health check
curl http://localhost:8000/health

# Calculate match
curl -X POST http://localhost:8000/api/v1/match \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "candidate_id": "driver456",
    "use_ml": false
  }'
```

### Using Python

```python
import requests

url = "http://localhost:8000/api/v1/match"
data = {
    "user_id": "user123",
    "candidate_id": "driver456",
    "use_ml": False
}

response = requests.post(url, json=data)
print(response.json())
```

## 🧪 Running Tests

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=app --cov-report=html

# View coverage report
# Open htmlcov/index.html in browser
```

## 📦 Project Structure

```
backend/
├── app/
│   ├── main.py              # FastAPI app
│   ├── core/
│   │   └── config.py        # Configuration
│   ├── models/
│   │   └── match.py         # Pydantic models
│   ├── services/
│   │   ├── firebase_service.py
│   │   └── matching_service.py
│   └── api/
│       ├── match.py         # Match endpoints
│       └── preferences.py   # Preferences endpoints
├── tests/
│   └── test_matching.py     # Unit tests
├── requirements.txt
├── Dockerfile
└── README.md
```

## 🔧 Common Issues

### Firebase Credentials Not Found

**Error:** `FileNotFoundError: Firebase credentials not found`

**Solution:** Make sure `firebase-credentials.json` is in the `backend/` directory

### Port Already in Use

**Error:** `Address already in use`

**Solution:** Change port or kill existing process
```bash
# Use different port
uvicorn app.main:app --reload --port 8001

# Or kill process on port 8000 (Windows)
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

### Import Errors

**Error:** `ModuleNotFoundError: No module named 'app'`

**Solution:** Make sure you're in the `backend/` directory and virtual environment is activated

## 📚 Next Steps

1. ✅ Backend is running
2. 📱 Integrate with Flutter app
3. 🧠 Train ML model (Phase 2)
4. 🚀 Deploy to production

## 🔗 Useful Links

- API Docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- Health Check: http://localhost:8000/health

## 💡 Tips

- Use `/docs` for interactive API testing
- Check logs for debugging
- Run tests before committing changes
- Keep Firebase credentials secure (never commit to git)

Happy Coding! 🎉
