import pandas as pd
import numpy as np
import math
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score
import joblib
import os
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def load_and_prepare_data(csv_file="data.csv"):
    """Load and prepare the data from CSV file"""
    logger.info(f"Loading data from {csv_file}...")
    
    try:
        df = pd.read_csv(csv_file)
        logger.info(f"Loaded {len(df)} records with {len(df.columns)} columns")
        
        # Display basic info about the data
        logger.info(f"Data types:\n{df.dtypes}")
        logger.info(f"Data shape: {df.shape}")
        logger.info(f"Missing values:\n{df.isnull().sum()}")
        
        return df
    except Exception as e:
        logger.error(f"Error loading data: {e}")
        raise

def preprocess_data(df):
    """Preprocess the data for training"""
    logger.info("Preprocessing data...")
    
    # Separate accidents and crimes
    accidents = df[df['type'] == 'ACCIDENT'].copy()
    crimes = df[df['type'] == 'CRIME'].copy()
    
    logger.info(f"Found {len(accidents)} accidents and {len(crimes)} crimes")
    
    # Convert boolean strings to actual booleans
    if 'intersection' in accidents.columns:
        accidents['intersection'] = accidents['intersection'].map({'TRUE': True, 'FALSE': False, True: True, False: False})
        accidents['intersection'] = accidents['intersection'].fillna(False)
    
    # Handle missing values
    accidents = accidents.fillna({
        'weather': 'Clear',
        'roadType': 'City Street',
        'speedLimit': 30,
        'lightCondition': 'Daylight',
        'intersection': False
    })
    
    crimes = crimes.fillna({
        'category': 'other'
    })
    
    # Convert categorical variables
    day_mapping = {
        'Monday': 0, 'Tuesday': 1, 'Wednesday': 2, 'Thursday': 3,
        'Friday': 4, 'Saturday': 5, 'Sunday': 6
    }
    
    accidents['dayOfWeek_num'] = accidents['dayOfWeek'].map(day_mapping).fillna(0)
    crimes['dayOfWeek_num'] = crimes['dayOfWeek'].map(day_mapping).fillna(0)
    
    # Create pedestrian_involved and bicycle_involved columns for accidents
    if 'category' in accidents.columns:
        accidents['pedestrian_involved'] = accidents['category'] == 'pedestrian'
        accidents['bicycle_involved'] = accidents['category'] == 'bicycle'
    else:
        accidents['pedestrian_involved'] = accidents['description'].str.contains('Pedestrian', na=False)
        accidents['bicycle_involved'] = accidents['description'].str.contains('Bicycle', na=False)
    
    # Map crime categories to types
    crime_type_mapping = {
        'theft': 'theft',
        'burglary': 'burglary', 
        'assault': 'violent',
        'robbery': 'violent',
        'vandalism': 'vandalism',
        'violent': 'violent',
        'other': 'other'
    }
    
    crimes['crime_type'] = crimes['category'].map(crime_type_mapping).fillna('other')
    
    return accidents, crimes

def create_safety_labels(accidents, crimes):
    """Create safety score labels for training"""
    logger.info("Creating safety labels...")
    
    # Create a grid for Delray Beach area
    lat_min, lat_max = 26.42, 26.50
    lon_min, lon_max = -80.10, -80.05
    
    # Create training points
    training_data = []
    
    # Grid resolution for training points
    resolution = 50
    lat_step = (lat_max - lat_min) / resolution
    lon_step = (lon_max - lon_min) / resolution
    
    for i in range(resolution):
        for j in range(resolution):
            lat = lat_min + i * lat_step
            lon = lon_min + j * lon_step
            
            # Calculate safety features for this location
            features = calculate_location_features(lat, lon, accidents, crimes)
            
            # Calculate safety score (inverse of risk)
            safety_score = calculate_safety_score(features)
            
            training_data.append({
                'lat': lat,
                'lon': lon,
                'safety_score': safety_score,
                **features
            })
    
    return pd.DataFrame(training_data)

def calculate_location_features(lat, lon, accidents, crimes, radius=0.3):
    """Calculate features for a specific location"""
    import math
    
    # Find nearby incidents
    nearby_crimes = []
    nearby_accidents = []
    
    for _, crime in crimes.iterrows():
        distance = calculate_distance(lat, lon, crime['lat'], crime['lon'])
        if distance <= radius:
            nearby_crimes.append(crime)
    
    for _, accident in accidents.iterrows():
        distance = calculate_distance(lat, lon, accident['lat'], accident['lon'])
        if distance <= radius:
            nearby_accidents.append(accident)
    
    # Calculate features
    area = math.pi * radius * radius
    
    features = {
        'crime_density': len(nearby_crimes) / area if area > 0 else 0,
        'crime_severity_avg': np.mean([c['severity'] for c in nearby_crimes]) if nearby_crimes else 0,
        'violent_crime_ratio': len([c for c in nearby_crimes if c['crime_type'] == 'violent']) / len(nearby_crimes) if nearby_crimes else 0,
        'recent_crime_count': len(nearby_crimes),  # Simplified for training
        'accident_density': len(nearby_accidents) / area if area > 0 else 0,
        'pedestrian_accident_ratio': len([a for a in nearby_accidents if a['pedestrian_involved']]) / len(nearby_accidents) if nearby_accidents else 0,
        'fatal_accident_ratio': len([a for a in nearby_accidents if a['severity'] >= 0.9]) / len(nearby_accidents) if nearby_accidents else 0,
        'intersection_accident_ratio': len([a for a in nearby_accidents if a['intersection']]) / len(nearby_accidents) if nearby_accidents else 0,
        'time_risk_score': 0.4,  # Default moderate risk
        'day_risk_score': 0.4,   # Default moderate risk
        'weather_risk': 0.3      # Default low weather risk
    }
    
    return features

def calculate_safety_score(features):
    """Calculate safety score based on features"""
    # Start with baseline safety
    safety = 0.7
    
    # Reduce safety based on crime factors
    safety -= features['crime_density'] * 0.3
    safety -= features['crime_severity_avg'] * 0.2
    safety -= features['violent_crime_ratio'] * 0.25
    
    # Reduce safety based on accident factors
    safety -= features['accident_density'] * 0.2
    safety -= features['pedestrian_accident_ratio'] * 0.15
    safety -= features['fatal_accident_ratio'] * 0.2
    safety -= features['intersection_accident_ratio'] * 0.1
    
    # Ensure safety score is between 0 and 1
    return max(0.0, min(1.0, safety))

def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two points in miles"""
    R = 3959  # Earth radius in miles
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)
    
    a = (math.sin(delta_lat/2) * math.sin(delta_lat/2) +
         math.cos(lat1_rad) * math.cos(lat2_rad) *
         math.sin(delta_lon/2) * math.sin(delta_lon/2))
    
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    return R * c

def train_model(training_df):
    """Train the Random Forest model"""
    logger.info("Training model...")
    
    # Define features
    feature_columns = [
        'crime_density', 'crime_severity_avg', 'violent_crime_ratio', 'recent_crime_count',
        'accident_density', 'pedestrian_accident_ratio', 'fatal_accident_ratio', 
        'intersection_accident_ratio', 'time_risk_score', 'day_risk_score', 'weather_risk'
    ]
    
    X = training_df[feature_columns].values
    y = training_df['safety_score'].values
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Scale features
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Train Random Forest model
    model = RandomForestRegressor(
        n_estimators=100,
        max_depth=10,
        random_state=42,
        n_jobs=-1
    )
    
    model.fit(X_train_scaled, y_train)
    
    # Evaluate model
    y_pred = model.predict(X_test_scaled)
    mse = mean_squared_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)
    
    logger.info(f"Model Performance:")
    logger.info(f"  MSE: {mse:.4f}")
    logger.info(f"  R²: {r2:.4f}")
    
    # Feature importance
    feature_importance = dict(zip(feature_columns, model.feature_importances_))
    logger.info(f"Feature Importance: {feature_importance}")
    
    return model, scaler, feature_importance, feature_columns

def save_model_and_data(model, scaler, feature_importance, feature_columns, accidents, crimes, model_dir="models"):
    """Save model and preprocessed data"""
    logger.info(f"Saving model to {model_dir}/...")
    
    # Create models directory
    os.makedirs(model_dir, exist_ok=True)
    
    # Save model components
    joblib.dump(model, f"{model_dir}/walksafe_model.pkl")
    joblib.dump(scaler, f"{model_dir}/walksafe_scaler.pkl")
    joblib.dump(feature_importance, f"{model_dir}/walksafe_feature_importance.pkl")
    
    # Create features config
    features_config = {feature: i for i, feature in enumerate(feature_columns)}
    joblib.dump(features_config, f"{model_dir}/walksafe_features_config.pkl")
    
    # Prepare data for model
    crime_data = []
    for _, crime in crimes.iterrows():
        crime_data.append({
            'lat': crime['lat'],
            'lon': crime['lon'],
            'date': crime['date'],
            'severity': crime['severity'],
            'crime_type': crime['crime_type'],
            'category': crime['category']
        })
    
    accident_data = []
    for _, accident in accidents.iterrows():
        accident_data.append({
            'lat': accident['lat'],
            'lon': accident['lon'],
            'date': accident['date'],
            'severity': accident['severity'],
            'pedestrian_involved': accident['pedestrian_involved'],
            'intersection': accident['intersection']
        })
    
    # Save data
    joblib.dump(crime_data, f"{model_dir}/walksafe_crime_data.pkl")
    joblib.dump(accident_data, f"{model_dir}/walksafe_accident_data.pkl")
    
    # Delray Beach center coordinates
    delray_center = {'lat': 26.4615, 'lon': -80.0728}
    joblib.dump(delray_center, f"{model_dir}/walksafe_delray_center.pkl")
    
    # Metadata
    metadata = {
        'total_crimes': len(crimes),
        'total_accidents': len(accidents),
        'real_crimes': len(crimes[crimes['source'].str.contains('REAL', na=False)]),
        'real_accidents': len(accidents[accidents['source'].str.contains('REAL', na=False)]),
        'feature_names': feature_columns,
        'trained_at': datetime.now().isoformat(),
        'model_type': 'RandomForestRegressor'
    }
    joblib.dump(metadata, f"{model_dir}/walksafe_metadata.pkl")
    
    logger.info("Model and data saved successfully!")
    return metadata

def main():
    """Main training pipeline"""
    logger.info("Starting WalkSafe+ model training...")
    
    try:
        # Load data
        df = load_and_prepare_data("data.csv")
        
        # Preprocess
        accidents, crimes = preprocess_data(df)
        
        # Create training data with safety labels
        training_df = create_safety_labels(accidents, crimes)
        logger.info(f"Created {len(training_df)} training samples")
        
        # Train model
        model, scaler, feature_importance, feature_columns = train_model(training_df)
        
        # Save everything
        metadata = save_model_and_data(model, scaler, feature_importance, feature_columns, accidents, crimes)
        
        logger.info("Training completed successfully!")
        logger.info(f"Model trained on {metadata['total_crimes']} crimes and {metadata['total_accidents']} accidents")
        logger.info("You can now start the API server - the model will load automatically.")
        
    except Exception as e:
        logger.error(f"Training failed: {e}")
        raise

if __name__ == "__main__":
    main()