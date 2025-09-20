import numpy as np
import joblib
import math
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import logging

logger = logging.getLogger(__name__)

class WalkSafeModel:
    """WalkSafe+ ML model handler for safety predictions"""
    
    def __init__(self):
        self.model = None
        self.scaler = None
        self.feature_importance = {}
        self.features_config = {}
        self.crime_data = []
        self.accident_data = []
        self.delray_center = {}
        self.metadata = {}
        self.incident_reports = []

    def load_model(self, model_dir="models"):
        """Load trained model and data"""
        try:
            logger.info(f"Loading model from {model_dir}/...")
            
            # Load model components
            self.model = joblib.load(f"{model_dir}/walksafe_model.pkl")
            self.scaler = joblib.load(f"{model_dir}/walksafe_scaler.pkl")
            self.feature_importance = joblib.load(f"{model_dir}/walksafe_feature_importance.pkl")
            self.features_config = joblib.load(f"{model_dir}/walksafe_features_config.pkl")
            self.crime_data = joblib.load(f"{model_dir}/walksafe_crime_data.pkl")
            self.accident_data = joblib.load(f"{model_dir}/walksafe_accident_data.pkl")
            self.delray_center = joblib.load(f"{model_dir}/walksafe_delray_center.pkl")
            self.metadata = joblib.load(f"{model_dir}/walksafe_metadata.pkl")
            
            logger.info("Model loaded successfully!")
            logger.info(f"Trained on {self.metadata['total_crimes']} crimes and {self.metadata['total_accidents']} accidents")
            logger.info(f"Model trained at: {self.metadata['trained_at']}")
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            return False

    def is_loaded(self):
        """Check if model is loaded"""
        return self.model is not None

    def predict_safety(self, lat, lon, time_of_day=None, day_of_week=None):
        """Predict safety score using loaded model"""
        if self.model is None:
            raise ValueError("Model not loaded")
        
        # Extract features for location
        features = self.extract_location_features(lat, lon, time_of_day, day_of_week)
        
        # Scale features
        feature_names = list(self.features_config.keys())
        feature_vector = np.array([[features.get(feature, 0) for feature in feature_names]])
        scaled_features = self.scaler.transform(feature_vector)
        
        # Make prediction
        safety_score = float(self.model.predict(scaled_features)[0])
        safety_score = max(0.0, min(1.0, safety_score))
        
        # Generate recommendations
        recommendations = self.generate_recommendations(features, safety_score)
        
        return {
            'lat': lat,
            'lon': lon,
            'safety_score': safety_score,
            'risk_level': self.categorize_safety(safety_score),
            'confidence': float(abs(safety_score - 0.5) * 2),
            'factors': features,
            'recommendations': recommendations
        }

    def extract_location_features(self, lat, lon, time_of_day=None, day_of_week=None):
        """Extract features for a specific location"""
        radius = 0.3
        nearby_crimes = self.get_incidents_in_radius(self.crime_data, {'lat': lat, 'lon': lon}, radius)
        nearby_accidents = self.get_incidents_in_radius(self.accident_data, {'lat': lat, 'lon': lon}, radius)
        
        return {
            'crime_density': self.calculate_density(nearby_crimes, radius),
            'crime_severity_avg': self.calculate_average_severity(nearby_crimes),
            'violent_crime_ratio': self.calculate_violent_crime_ratio(nearby_crimes),
            'recent_crime_count': self.count_recent_incidents(nearby_crimes, 30),
            'accident_density': self.calculate_density(nearby_accidents, radius),
            'pedestrian_accident_ratio': self.calculate_pedestrian_ratio(nearby_accidents),
            'fatal_accident_ratio': self.calculate_fatal_ratio(nearby_accidents),
            'intersection_accident_ratio': self.calculate_intersection_ratio(nearby_accidents),
            'time_risk_score': self.get_time_risk(time_of_day) if time_of_day else self.get_current_time_risk(),
            'day_risk_score': self.get_day_risk(day_of_week) if day_of_week else self.get_current_day_risk(),
            'weather_risk': 0.3
        }

    def generate_recommendations(self, features, safety_score):
        """Generate safety recommendations"""
        recommendations = []
        
        if safety_score < 0.3:
            recommendations.append("High risk area - consider alternative route")
        if safety_score < 0.5:
            recommendations.append("Use well-lit streets when possible")
        if features.get('time_risk_score', 0) > 0.6:
            recommendations.append("Extra caution advised during night hours")
        if features.get('violent_crime_ratio', 0) > 0.3:
            recommendations.append("Walk with others if possible")
        if features.get('pedestrian_accident_ratio', 0) > 0.3:
            recommendations.append("Use crosswalks and stay alert for vehicles")
        if safety_score > 0.7:
            recommendations.append("Generally safe area")
        
        return recommendations

    def categorize_safety(self, score):
        """Categorize safety score into risk levels"""
        if score >= 0.8:
            return 'VERY_HIGH'
        elif score >= 0.6:
            return 'HIGH'
        elif score >= 0.4:
            return 'MEDIUM'
        elif score >= 0.2:
            return 'LOW'
        else:
            return 'VERY_LOW'

    def analyze_route(self, coordinates, walking_speed=3.0):
        """Analyze safety along a walking route"""
        if self.model is None:
            raise ValueError("Model not loaded")
        
        route_scores = []
        danger_zones = []
        
        for i, coord in enumerate(coordinates):
            prediction = self.predict_safety(coord['lat'], coord['lon'])
            route_scores.append(prediction)
            
            # Identify danger zones
            if prediction['safety_score'] < 0.4:
                danger_zones.append({
                    'lat': coord['lat'],
                    'lon': coord['lon'],
                    'safety_score': prediction['safety_score'],
                    'risk_level': prediction['risk_level'],
                    'waypoint_index': i
                })
        
        safety_scores = [score['safety_score'] for score in route_scores]
        avg_safety = sum(safety_scores) / len(safety_scores)
        min_safety = min(safety_scores)
        max_safety = max(safety_scores)
        
        # Calculate estimated walking time
        total_distance = self.calculate_route_distance(coordinates)
        estimated_duration = (total_distance / walking_speed) * 60  # Convert to minutes
        
        # Generate route recommendations
        recommendations = []
        if avg_safety < 0.4:
            recommendations.append("Consider finding a safer alternative route")
        if len(danger_zones) > 0:
            recommendations.append(f"{len(danger_zones)} high-risk areas detected")
        if min_safety < 0.2:
            recommendations.append("Extremely dangerous area - avoid if possible")
        if avg_safety > 0.7:
            recommendations.append("Generally safe route")
        
        return {
            'overall_safety': avg_safety,
            'risk_level': self.categorize_safety(avg_safety),
            'risk_points': len(danger_zones),
            'total_points': len(coordinates),
            'safest_score': max_safety,
            'riskiest_score': min_safety,
            'estimated_duration': estimated_duration,
            'recommendations': recommendations,
            'danger_zones': danger_zones
        }

    def get_nearby_alerts(self, lat, lon, radius=0.5):
        """Get nearby safety alerts"""
        alerts = []
        
        # Check for recent incident reports
        for report in self.incident_reports:
            distance = self.calculate_distance(lat, lon, report['lat'], report['lon'])
            if distance <= radius:
                alerts.append({
                    'lat': report['lat'],
                    'lon': report['lon'],
                    'alert_type': report['incident_type'],
                    'severity': report['severity'],
                    'distance': distance,
                    'description': report.get('description', 'User reported incident'),
                    'timestamp': report.get('timestamp', datetime.now().isoformat())
                })
        
        # Check for high-risk crimes in area
        nearby_crimes = self.get_incidents_in_radius(self.crime_data, {'lat': lat, 'lon': lon}, radius)
        high_risk_crimes = [c for c in nearby_crimes if c['severity'] > 0.7]
        
        for crime in high_risk_crimes[:3]:  # Limit to 3 most severe
            distance = self.calculate_distance(lat, lon, crime['lat'], crime['lon'])
            alerts.append({
                'lat': crime['lat'],
                'lon': crime['lon'],
                'alert_type': 'crime_alert',
                'severity': crime['severity'],
                'distance': distance,
                'description': f"{crime['category']} reported in area",
                'timestamp': crime['date']
            })
        
        # Sort by severity
        alerts = sorted(alerts, key=lambda x: x['severity'], reverse=True)
        
        return alerts

    def add_incident_report(self, report_data):
        """Add incident report to the system"""
        report_dict = {
            **report_data,
            'timestamp': datetime.now().isoformat()
        }
        self.incident_reports.append(report_dict)
        return report_dict

    def generate_heatmap_data(self, north, south, east, west, resolution=20, min_safety=0.0):
        """Generate safety heatmap data"""
        heatmap_data = []
        
        lat_step = (north - south) / resolution
        lon_step = (east - west) / resolution
        
        for i in range(resolution):
            for j in range(resolution):
                lat = south + i * lat_step
                lon = west + j * lon_step
                
                # Check if point is within Delray Beach coverage
                distance = self.calculate_distance(
                    lat, lon, 
                    self.delray_center['lat'], 
                    self.delray_center['lon']
                )
                
                if distance <= 3.0:
                    prediction = self.predict_safety(lat, lon)
                    
                    # Filter by minimum safety score if specified
                    if prediction['safety_score'] >= min_safety:
                        heatmap_data.append({
                            'lat': round(lat, 6),
                            'lon': round(lon, 6),
                            'safety_score': round(prediction['safety_score'], 3),
                            'risk_level': prediction['risk_level']
                        })
        
        return heatmap_data

    def get_danger_zones(self, danger_threshold=0.4, high_danger_threshold=0.25):
        """Get danger zones for map visualization"""
        danger_zones = []
        
        # Generate grid points and find dangerous ones
        resolution = 25
        bounds = {
            'north': 26.50, 'south': 26.42,
            'east': -80.05, 'west': -80.10
        }
        
        lat_step = (bounds['north'] - bounds['south']) / resolution
        lon_step = (bounds['east'] - bounds['west']) / resolution
        
        for i in range(resolution):
            for j in range(resolution):
                lat = bounds['south'] + i * lat_step
                lon = bounds['west'] + j * lon_step
                
                distance = self.calculate_distance(lat, lon, self.delray_center['lat'], self.delray_center['lon'])
                if distance <= 3.0:
                    prediction = self.predict_safety(lat, lon)
                    
                    if prediction['safety_score'] < danger_threshold:
                        danger_level = "HIGH" if prediction['safety_score'] < high_danger_threshold else "MODERATE"
                        
                        danger_zones.append({
                            'lat': lat,
                            'lon': lon,
                            'safety_score': prediction['safety_score'],
                            'danger_level': danger_level,
                            'confidence': prediction['confidence']
                        })
        
        return danger_zones

    def get_statistics(self):
        """Get safety statistics"""
        # Calculate area statistics
        high_risk_crimes = [c for c in self.crime_data if c['severity'] > 0.7]
        pedestrian_accidents = [a for a in self.accident_data if a['pedestrian_involved']]
        recent_reports = [r for r in self.incident_reports 
                         if datetime.fromisoformat(r['timestamp']) > datetime.now() - timedelta(days=7)]
        
        return {
            "delray_beach_stats": {
                "total_crimes": len(self.crime_data),
                "high_risk_crimes": len(high_risk_crimes),
                "total_accidents": len(self.accident_data),
                "pedestrian_accidents": len(pedestrian_accidents),
                "user_reports_this_week": len(recent_reports)
            },
            "safety_insights": {
                "most_dangerous_time": "10 PM - 5 AM",
                "safest_areas": "Residential neighborhoods",
                "highest_risk_factors": ["Poor lighting", "High crime density", "Intersection accidents"]
            },
            "coverage": "3-mile radius from downtown Delray Beach",
            "last_updated": datetime.now().isoformat()
        }

    # Helper methods
    def get_incidents_in_radius(self, incidents, center, radius):
        """Get incidents within radius of a point"""
        nearby_incidents = []
        for incident in incidents:
            distance = self.calculate_distance(
                incident['lat'], incident['lon'],
                center['lat'], center['lon']
            )
            if distance <= radius:
                nearby_incidents.append(incident)
        return nearby_incidents

    def calculate_density(self, incidents, radius):
        """Calculate incident density per square mile"""
        area = math.pi * radius * radius
        return len(incidents) / area if area > 0 else 0

    def calculate_average_severity(self, crimes):
        """Calculate average severity of crimes"""
        if not crimes:
            return 0
        return sum(crime.get('severity', 0.5) for crime in crimes) / len(crimes)

    def calculate_violent_crime_ratio(self, crimes):
        """Calculate ratio of violent crimes"""
        if not crimes:
            return 0
        violent_crimes = [c for c in crimes if c['crime_type'] == 'violent']
        return len(violent_crimes) / len(crimes)

    def calculate_pedestrian_ratio(self, accidents):
        """Calculate ratio of pedestrian accidents"""
        if not accidents:
            return 0
        ped_accidents = [a for a in accidents if a['pedestrian_involved']]
        return len(ped_accidents) / len(accidents)

    def calculate_fatal_ratio(self, accidents):
        """Calculate ratio of fatal accidents"""
        if not accidents:
            return 0
        fatal_accidents = [a for a in accidents if a['severity'] >= 0.9]
        return len(fatal_accidents) / len(accidents)

    def calculate_intersection_ratio(self, accidents):
        """Calculate ratio of intersection accidents"""
        if not accidents:
            return 0
        intersection_accidents = [a for a in accidents if a['intersection']]
        return len(intersection_accidents) / len(accidents)

    def count_recent_incidents(self, incidents, days):
        """Count incidents within recent days"""
        cutoff_date = datetime.now() - timedelta(days=days)
        recent_count = 0
        
        for incident in incidents:
            try:
                incident_date = datetime.strptime(incident['date'], '%Y-%m-%d')
                if incident_date >= cutoff_date:
                    recent_count += 1
            except (ValueError, KeyError):
                continue
        
        return recent_count

    def get_current_time_risk(self):
        """Get risk score for current time"""
        hour = datetime.now().hour
        if hour >= 22 or hour <= 5:
            return 0.8
        elif (7 <= hour <= 9) or (17 <= hour <= 19):
            return 0.6
        else:
            return 0.3

    def get_current_day_risk(self):
        """Get risk score for current day"""
        day = datetime.now().weekday()
        if day >= 5:
            return 0.7
        else:
            return 0.4

    def get_time_risk(self, hour):
        """Get risk score for specific hour"""
        if hour >= 22 or hour <= 5:
            return 0.8
        elif (7 <= hour <= 9) or (17 <= hour <= 19):
            return 0.6
        else:
            return 0.3

    def get_day_risk(self, day):
        """Get risk score for specific day"""
        if day >= 5:
            return 0.7
        else:
            return 0.4

    def calculate_distance(self, lat1, lon1, lat2, lon2):
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

    def calculate_route_distance(self, coordinates):
        """Calculate total route distance in miles"""
        total_distance = 0
        for i in range(len(coordinates) - 1):
            distance = self.calculate_distance(
                coordinates[i]['lat'], coordinates[i]['lon'],
                coordinates[i+1]['lat'], coordinates[i+1]['lon']
            )
            total_distance += distance
        return total_distance