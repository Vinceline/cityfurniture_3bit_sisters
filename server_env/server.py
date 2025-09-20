from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Dict, Optional
from datetime import datetime
import uvicorn
import logging
from model import WalkSafeModel

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="WalkSafe+ API",
    description="AI-powered pedestrian safety prediction system for Delray Beach, FL",
    version="2.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Initialize model
walksafe_model = WalkSafeModel()

# Pydantic models
class LocationRequest(BaseModel):
    lat: float = Field(..., ge=26.4, le=26.5)
    lon: float = Field(..., ge=-80.15, le=-80.0)
    time_of_day: Optional[int] = Field(None, ge=0, le=23)
    day_of_week: Optional[int] = Field(None, ge=0, le=6)

class RouteRequest(BaseModel):
    coordinates: List[Dict[str, float]] = Field(..., description="Route waypoints")
    walking_speed: Optional[float] = Field(3.0, description="Walking speed in mph")

class SafetyPrediction(BaseModel):
    lat: float
    lon: float
    safety_score: float
    risk_level: str
    confidence: float
    factors: Dict[str, float]
    recommendations: List[str]

class RouteAnalysis(BaseModel):
    overall_safety: float
    risk_level: str
    risk_points: int
    total_points: int
    safest_score: float
    riskiest_score: float
    estimated_duration: float
    recommendations: List[str]
    danger_zones: List[Dict]

class IncidentReport(BaseModel):
    lat: float
    lon: float
    incident_type: str
    severity: float = Field(..., ge=0.0, le=1.0)
    description: Optional[str] = None
    user_id: Optional[str] = None

# API Endpoints
@app.on_event("startup")
async def startup_event():
    """Load model on startup"""
    logger.info("WalkSafe+ API starting up...")
    if not walksafe_model.load_model():
        logger.error("Failed to load model - server will not function properly")
    else:
        logger.info("Server ready!")

@app.get("/")
async def root():
    """API status"""
    return {
        "service": "WalkSafe+ API",
        "version": "2.0.0",
        "status": "ready" if walksafe_model.is_loaded() else "model_not_loaded",
        "coverage": "Delray Beach, FL",
        "model_info": {
            "trained_at": walksafe_model.metadata.get('trained_at', 'unknown'),
            "total_crimes": walksafe_model.metadata.get('total_crimes', 0),
            "total_accidents": walksafe_model.metadata.get('total_accidents', 0)
        }
    }

@app.get("/health")
async def health_check():
    """Health check for monitoring"""
    return {
        "status": "healthy" if walksafe_model.is_loaded() else "model_not_loaded",
        "model_ready": walksafe_model.is_loaded(),
        "data_points": {
            "crimes": len(walksafe_model.crime_data),
            "accidents": len(walksafe_model.accident_data),
            "user_reports": len(walksafe_model.incident_reports)
        },
        "timestamp": datetime.now().isoformat()
    }

@app.post("/predict", response_model=SafetyPrediction)
async def predict_location_safety(location: LocationRequest):
    """Predict safety score for a specific location"""
    try:
        if not walksafe_model.is_loaded():
            raise HTTPException(status_code=503, detail="Model not loaded")
        
        prediction = walksafe_model.predict_safety(
            location.lat, 
            location.lon, 
            location.time_of_day, 
            location.day_of_week
        )
        
        return SafetyPrediction(**prediction)
    except Exception as e:
        logger.error(f"Prediction error: {e}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

@app.post("/analyze-route", response_model=RouteAnalysis)
async def analyze_route(route: RouteRequest):
    """Analyze safety along a walking route"""
    try:
        if not walksafe_model.is_loaded():
            raise HTTPException(status_code=503, detail="Model not loaded")
        
        if len(route.coordinates) < 2:
            raise HTTPException(status_code=400, detail="Route must have at least 2 coordinates")
        
        analysis = walksafe_model.analyze_route(route.coordinates, route.walking_speed)
        return RouteAnalysis(**analysis)
        
    except Exception as e:
        logger.error(f"Route analysis error: {e}")
        raise HTTPException(status_code=500, detail=f"Route analysis failed: {str(e)}")

@app.get("/nearby-alerts")
async def get_nearby_alerts(
    lat: float = Query(..., ge=26.4, le=26.5, description="Latitude"),
    lon: float = Query(..., ge=-80.15, le=-80.0, description="Longitude"),
    radius: float = Query(0.5, ge=0.1, le=2.0, description="Search radius in miles")
):
    """Get nearby safety alerts"""
    try:
        if not walksafe_model.is_loaded():
            raise HTTPException(status_code=503, detail="Model not loaded")
        
        alerts = walksafe_model.get_nearby_alerts(lat, lon, radius)
        
        return {
            "alerts": alerts,
            "total_alerts": len(alerts),
            "search_radius": radius,
            "location": {"lat": lat, "lon": lon}
        }
    except Exception as e:
        logger.error(f"Nearby alerts error: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get alerts: {str(e)}")

@app.post("/report")
async def submit_incident_report(report: IncidentReport):
    """Submit incident report from users"""
    try:
        report_data = {
            'lat': report.lat,
            'lon': report.lon,
            'incident_type': report.incident_type,
            'severity': report.severity,
            'description': report.description,
            'user_id': report.user_id
        }
        
        saved_report = walksafe_model.add_incident_report(report_data)
        
        return {
            "success": True,
            "message": "Incident report submitted successfully",
            "report_id": f"{report.incident_type}_{len(walksafe_model.incident_reports)}",
            "thank_you": "Thank you for helping keep Delray Beach safe!"
        }
    except Exception as e:
        logger.error(f"Report submission error: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to submit report: {str(e)}")

@app.get("/heatmap")
async def get_safety_heatmap(
    north: float = Query(26.50, description="Northern boundary"),
    south: float = Query(26.42, description="Southern boundary"),
    east: float = Query(-80.05, description="Eastern boundary"),
    west: float = Query(-80.10, description="Western boundary"),
    resolution: int = Query(20, ge=10, le=50, description="Grid resolution"),
    min_safety: float = Query(0.0, ge=0.0, le=1.0, description="Minimum safety score")
):
    """Generate safety heatmap for map visualization"""
    try:
        if not walksafe_model.is_loaded():
            raise HTTPException(status_code=503, detail="Model not loaded")
        
        heatmap_data = walksafe_model.generate_heatmap_data(
            north, south, east, west, resolution, min_safety
        )
        
        return {
            "heatmap_data": heatmap_data,
            "total_points": len(heatmap_data),
            "bounds": {
                "north": north,
                "south": south, 
                "east": east,
                "west": west
            },
            "resolution": resolution,
            "optimized_for": "iOS_rendering"
        }
    except Exception as e:
        logger.error(f"Heatmap generation error: {e}")
        raise HTTPException(status_code=500, detail=f"Heatmap generation failed: {str(e)}")

@app.get("/stats")
async def get_safety_statistics():
    """Get safety statistics for dashboard"""
    try:
        if not walksafe_model.is_loaded():
            raise HTTPException(status_code=503, detail="Model not loaded")
        
        stats = walksafe_model.get_statistics()
        return stats
    except Exception as e:
        logger.error(f"Statistics error: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get statistics: {str(e)}")

@app.get("/danger-zones")
async def get_danger_zones(
    danger_threshold: float = Query(0.4, description="Danger threshold"),
    high_danger_threshold: float = Query(0.25, description="High danger threshold")
):
    """Get danger zones for map visualization"""
    try:
        if not walksafe_model.is_loaded():
            raise HTTPException(status_code=503, detail="Model not loaded")
        
        danger_zones = walksafe_model.get_danger_zones(danger_threshold, high_danger_threshold)
        
        return {
            "danger_zones": danger_zones,
            "total_zones": len(danger_zones),
            "danger_threshold": danger_threshold,
            "high_danger_threshold": high_danger_threshold
        }
    except Exception as e:
        logger.error(f"Danger zones error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/model/info")
async def get_model_info():
    """Model information"""
    if not walksafe_model.is_loaded():
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    return {
        "model_type": "Random Forest Regressor",
        "training_data": {
            "crimes": walksafe_model.metadata.get('total_crimes', 0),
            "accidents": walksafe_model.metadata.get('total_accidents', 0),
            "real_data_percentage": {
                "crimes": round((walksafe_model.metadata.get('real_crimes', 0) / walksafe_model.metadata.get('total_crimes', 1)) * 100, 1),
                "accidents": round((walksafe_model.metadata.get('real_accidents', 0) / walksafe_model.metadata.get('total_accidents', 1)) * 100, 1)
            }
        },
        "features": walksafe_model.metadata.get('feature_names', []),
        "feature_importance": {k: round(v, 3) for k, v in walksafe_model.feature_importance.items()},
        "coverage_area": "Delray Beach, FL (3-mile radius)",
        "prediction_range": "0.0 (very unsafe) to 1.0 (very safe)",
        "trained_at": walksafe_model.metadata.get('trained_at', 'unknown')
    }

if __name__ == "__main__":
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=8000,
        log_level="info"
    )