import Foundation


struct SafetyPrediction: Codable {
    let lat: Double
    let lon: Double
    let safetyScore: Double
    let riskLevel: String
    let confidence: Double
    let factors: [String: Double]
    let recommendations: [String]
    
    enum CodingKeys: String, CodingKey {
        case lat, lon, confidence, factors, recommendations
        case safetyScore = "safety_score"
        case riskLevel = "risk_level"
    }
}
struct HeatmapPoint: Codable {
    let lat: Double
    let lon: Double
    let safetyScore: Double
    let riskLevel: String
    
    enum CodingKeys: String, CodingKey {
        case lat, lon
        case safetyScore = "safety_score"
        case riskLevel = "risk_level"
    }
}

struct HeatmapBounds: Codable {
    let north: Double
    let south: Double
    let east: Double
    let west: Double
}

struct HeatmapResponse: Codable {
    let heatmapData: [HeatmapPoint]
    let totalPoints: Int
    let bounds: HeatmapBounds
    let resolution: Int
    let optimizedFor: String?
    
    enum CodingKeys: String, CodingKey {
        case bounds, resolution
        case heatmapData = "heatmap_data"
        case totalPoints = "total_points"
        case optimizedFor = "optimized_for"
    }
}
struct DangerZone: Codable {
    let lat: Double
    let lon: Double
    let safetyScore: Double
    let dangerLevel: String
    let confidence: Double
    let clusterSize: Int?
    let waypointIndex: Int?  
    
    enum CodingKeys: String, CodingKey {
        case lat, lon, confidence
        case safetyScore = "safety_score"
        case dangerLevel = "danger_level"
        case clusterSize = "cluster_size"
        case waypointIndex = "waypoint_index"
    }
}
struct DangerZonesResponse: Codable {
    let dangerZones: [DangerZone]
    let totalZones: Int
    let dangerThreshold: Double
    let highDangerThreshold: Double
    
    enum CodingKeys: String, CodingKey {
        case dangerZones = "danger_zones"
        case totalZones = "total_zones"
        case dangerThreshold = "danger_threshold"
        case highDangerThreshold = "high_danger_threshold"
    }
}
struct NearbyAlert: Codable {
    let lat: Double
    let lon: Double
    let alertType: String
    let severity: Double
    let distance: Double
    let description: String
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case lat, lon, severity, distance, description, timestamp
        case alertType = "alert_type"
    }
}

struct NearbyAlertsResponse: Codable {
    let alerts: [NearbyAlert]
    let totalAlerts: Int
    let searchRadius: Double
    let location: LocationCoordinate
    
    enum CodingKeys: String, CodingKey {
        case alerts, location
        case totalAlerts = "total_alerts"
        case searchRadius = "search_radius"
    }
}

struct LocationCoordinate: Codable {
    let lat: Double
    let lon: Double
}

struct SafetyStatistics: Codable {
    let delrayBeachStats: DelrayBeachStats
    let safetyInsights: SafetyInsights
    let coverage: String
    let lastUpdated: String
    
    enum CodingKeys: String, CodingKey {
        case coverage
        case delrayBeachStats = "delray_beach_stats"
        case safetyInsights = "safety_insights"
        case lastUpdated = "last_updated"
    }
}

struct DelrayBeachStats: Codable {
    let totalCrimes: Int
    let highRiskCrimes: Int
    let totalAccidents: Int
    let pedestrianAccidents: Int
    let userReportsThisWeek: Int
    
    enum CodingKeys: String, CodingKey {
        case totalCrimes = "total_crimes"
        case highRiskCrimes = "high_risk_crimes"
        case totalAccidents = "total_accidents"
        case pedestrianAccidents = "pedestrian_accidents"
        case userReportsThisWeek = "user_reports_this_week"
    }
}

struct SafetyInsights: Codable {
    let mostDangerousTime: String
    let safestAreas: String
    let highestRiskFactors: [String]
    
    enum CodingKeys: String, CodingKey {
        case mostDangerousTime = "most_dangerous_time"
        case safestAreas = "safest_areas"
        case highestRiskFactors = "highest_risk_factors"
    }
}


struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
    let error: String?
}

struct IncidentReportResponse: Codable {
    let success: Bool
    let message: String
    let reportId: String
    let thankYou: String
    
    enum CodingKeys: String, CodingKey {
        case success, message
        case reportId = "report_id"
        case thankYou = "thank_you"
    }
}


enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(String)
    case serverError(Int, String?)
    case networkError(String)
    case modelNotReady
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let details):
            return "Failed to decode response: \(details)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .networkError(let details):
            return "Network error: \(details)"
        case .modelNotReady:
            return "Safety model is still initializing. Please try again in a moment."
        }
    }
}
