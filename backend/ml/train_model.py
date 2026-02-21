"""
ML Model Training Script for Compatibility Prediction
Phase 2: Machine Learning Integration
"""
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    classification_report,
    confusion_matrix
)
import joblib
import os
from datetime import datetime


class CompatibilityMLTrainer:
    """Train ML model for ride compatibility prediction"""
    
    def __init__(self, model_path='ml/models/compatibility_model.pkl'):
        """
        Initialize trainer
        
        Args:
            model_path: Path to save trained model
        """
        self.model_path = model_path
        self.model = None
        self.feature_names = [
            'office_match',
            'music_difference',
            'talk_difference',
            'user_punctuality',
            'candidate_punctuality',
            'gender_match',
            'time_difference_minutes',
            'user_completion_rate',
            'candidate_completion_rate',
            'user_avg_rating',
            'candidate_avg_rating',
            'rule_based_score'
        ]
    
    def prepare_features(self, ride_history_df):
        """
        Prepare features from ride history
        
        Args:
            ride_history_df: DataFrame with ride history
            
        Returns:
            X: Feature matrix
            y: Labels (1 = successful, 0 = failed)
        """
        features = []
        labels = []
        
        for _, ride in ride_history_df.iterrows():
            # Extract features
            feature_row = [
                ride['office_match'],
                ride['music_difference'],
                ride['talk_difference'],
                ride['user_punctuality'],
                ride['candidate_punctuality'],
                ride['gender_match'],
                ride['time_difference_minutes'],
                ride['user_completion_rate'],
                ride['candidate_completion_rate'],
                ride['user_avg_rating'],
                ride['candidate_avg_rating'],
                ride['compatibility_score']
            ]
            
            # Label: successful if completed and rating >= 4
            label = 1 if (
                ride['status'] == 'completed' and 
                ride['rating'] >= 4
            ) else 0
            
            features.append(feature_row)
            labels.append(label)
        
        return np.array(features), np.array(labels)
    
    def train(self, X, y, test_size=0.2, random_state=42):
        """
        Train Random Forest model
        
        Args:
            X: Feature matrix
            y: Labels
            test_size: Test set proportion
            random_state: Random seed
            
        Returns:
            dict: Training metrics
        """
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_size, random_state=random_state, stratify=y
        )
        
        print(f"Training set: {len(X_train)} samples")
        print(f"Test set: {len(X_test)} samples")
        print(f"Positive class ratio: {y_train.mean():.2%}")
        
        # Initialize model
        self.model = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            min_samples_split=5,
            min_samples_leaf=2,
            random_state=random_state,
            class_weight='balanced'  # Handle imbalanced data
        )
        
        # Train model
        print("\nTraining Random Forest...")
        self.model.fit(X_train, y_train)
        
        # Predictions
        y_pred_train = self.model.predict(X_train)
        y_pred_test = self.model.predict(X_test)
        
        # Calculate metrics
        metrics = {
            'train_accuracy': accuracy_score(y_train, y_pred_train),
            'test_accuracy': accuracy_score(y_test, y_pred_test),
            'precision': precision_score(y_test, y_pred_test),
            'recall': recall_score(y_test, y_pred_test),
            'f1_score': f1_score(y_test, y_pred_test),
        }
        
        # Cross-validation
        cv_scores = cross_val_score(
            self.model, X_train, y_train, cv=5, scoring='f1'
        )
        metrics['cv_f1_mean'] = cv_scores.mean()
        metrics['cv_f1_std'] = cv_scores.std()
        
        # Feature importance
        feature_importance = pd.DataFrame({
            'feature': self.feature_names,
            'importance': self.model.feature_importances_
        }).sort_values('importance', ascending=False)
        
        # Print results
        print("\n" + "="*50)
        print("TRAINING RESULTS")
        print("="*50)
        print(f"Train Accuracy: {metrics['train_accuracy']:.4f}")
        print(f"Test Accuracy:  {metrics['test_accuracy']:.4f}")
        print(f"Precision:      {metrics['precision']:.4f}")
        print(f"Recall:         {metrics['recall']:.4f}")
        print(f"F1 Score:       {metrics['f1_score']:.4f}")
        print(f"CV F1 (mean):   {metrics['cv_f1_mean']:.4f} ± {metrics['cv_f1_std']:.4f}")
        
        print("\n" + "="*50)
        print("FEATURE IMPORTANCE")
        print("="*50)
        print(feature_importance.to_string(index=False))
        
        print("\n" + "="*50)
        print("CLASSIFICATION REPORT")
        print("="*50)
        print(classification_report(y_test, y_pred_test, 
                                   target_names=['Failed', 'Successful']))
        
        print("\n" + "="*50)
        print("CONFUSION MATRIX")
        print("="*50)
        cm = confusion_matrix(y_test, y_pred_test)
        print(f"True Negatives:  {cm[0][0]}")
        print(f"False Positives: {cm[0][1]}")
        print(f"False Negatives: {cm[1][0]}")
        print(f"True Positives:  {cm[1][1]}")
        
        return metrics
    
    def save_model(self):
        """Save trained model to disk"""
        if self.model is None:
            raise ValueError("No model to save. Train the model first.")
        
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(self.model_path), exist_ok=True)
        
        # Save model
        joblib.dump(self.model, self.model_path)
        print(f"\nModel saved to: {self.model_path}")
    
    def load_model(self):
        """Load trained model from disk"""
        if not os.path.exists(self.model_path):
            raise FileNotFoundError(f"Model not found at {self.model_path}")
        
        self.model = joblib.load(self.model_path)
        print(f"Model loaded from: {self.model_path}")
    
    def predict_compatibility(self, features):
        """
        Predict compatibility probability
        
        Args:
            features: Feature array [12 features]
            
        Returns:
            float: Probability of successful ride (0-100)
        """
        if self.model is None:
            raise ValueError("No model loaded. Load or train a model first.")
        
        # Predict probability
        prob = self.model.predict_proba([features])[0][1]
        
        # Convert to 0-100 score
        return prob * 100


def create_sample_dataset():
    """
    Create sample dataset for demonstration
    In production, this would fetch from Firebase
    """
    np.random.seed(42)
    n_samples = 1000
    
    data = {
        'office_match': np.random.choice([0, 80, 100], n_samples, p=[0.4, 0.3, 0.3]),
        'music_difference': np.random.choice([0, 1, 2], n_samples),
        'talk_difference': np.random.choice([0, 1, 2], n_samples),
        'user_punctuality': np.random.normal(85, 10, n_samples).clip(0, 100),
        'candidate_punctuality': np.random.normal(85, 10, n_samples).clip(0, 100),
        'gender_match': np.random.choice([0, 100], n_samples, p=[0.3, 0.7]),
        'time_difference_minutes': np.random.exponential(30, n_samples).clip(0, 180),
        'user_completion_rate': np.random.normal(90, 8, n_samples).clip(0, 100),
        'candidate_completion_rate': np.random.normal(90, 8, n_samples).clip(0, 100),
        'user_avg_rating': np.random.normal(4.5, 0.5, n_samples).clip(1, 5),
        'candidate_avg_rating': np.random.normal(4.5, 0.5, n_samples).clip(1, 5),
    }
    
    df = pd.DataFrame(data)
    
    # Calculate rule-based score
    df['compatibility_score'] = (
        df['office_match'] * 0.25 +
        (100 - df['music_difference'] * 50) * 0.15 +
        (100 - df['talk_difference'] * 50) * 0.15 +
        ((df['user_punctuality'] + df['candidate_punctuality']) / 2) * 0.20 +
        df['gender_match'] * 0.10 +
        (100 - df['time_difference_minutes'].clip(0, 100)) * 0.15
    )
    
    # Simulate ride outcome based on compatibility score + randomness
    success_prob = (df['compatibility_score'] / 100) ** 2
    df['status'] = np.where(
        np.random.random(n_samples) < success_prob,
        'completed',
        'cancelled'
    )
    
    # Rating for completed rides
    df['rating'] = np.where(
        df['status'] == 'completed',
        np.random.choice([3, 4, 5], n_samples, p=[0.1, 0.4, 0.5]),
        0
    )
    
    return df


if __name__ == "__main__":
    print("="*50)
    print("AI SMART MATCHING - ML MODEL TRAINING")
    print("="*50)
    
    # Create sample dataset
    print("\nGenerating sample dataset...")
    df = create_sample_dataset()
    print(f"Dataset size: {len(df)} rides")
    print(f"Successful rides: {(df['status'] == 'completed').sum()}")
    print(f"Failed rides: {(df['status'] != 'completed').sum()}")
    
    # Initialize trainer
    trainer = CompatibilityMLTrainer()
    
    # Prepare features
    print("\nPreparing features...")
    X, y = trainer.prepare_features(df)
    
    # Train model
    metrics = trainer.train(X, y)
    
    # Save model
    trainer.save_model()
    
    # Test prediction
    print("\n" + "="*50)
    print("SAMPLE PREDICTION")
    print("="*50)
    sample_features = X[0]
    prediction = trainer.predict_compatibility(sample_features)
    print(f"Compatibility Score: {prediction:.1f}%")
    print(f"Actual Outcome: {'Successful' if y[0] == 1 else 'Failed'}")
    
    print("\n✅ Training complete!")
