# ML Models Directory

This directory contains trained machine learning models for compatibility prediction.

## Files

- `compatibility_model.pkl` - Trained Random Forest model (generated after training)

## Training

To train a new model:

```bash
cd backend
python ml/train_model.py
```

## Model Details

- **Algorithm**: Random Forest Classifier
- **Features**: 12 behavioral and preference features
- **Target**: Binary classification (successful ride vs failed)
- **Metrics**: Accuracy, Precision, Recall, F1-Score

## Usage in API

The model is automatically loaded when `ENABLE_ML_MATCHING=true` in `.env`

```python
# In matching service
if use_ml:
    ml_score = ml_service.predict_compatibility(user, candidate)
```

## Model Versioning

Models are versioned by timestamp. Keep previous versions for rollback:

```
models/
├── compatibility_model.pkl          # Current
├── compatibility_model_20240115.pkl # Backup
└── compatibility_model_20240110.pkl # Older
```
