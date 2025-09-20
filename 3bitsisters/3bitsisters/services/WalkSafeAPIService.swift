import Foundation
import UIKit
import Combine
import Foundation
import Combine
import CoreLocation

class WalkSafeAPIService: ObservableObject {
    private let baseURL = "http:12.248.84.182:8000"
    private let session: URLSession
    
    @Published var isModelReady = false
    @Published var connectionStatus: ConnectionStatus = .unknown
    
    enum ConnectionStatus {
        case unknown
        case connected
        case disconnected
        case modelInitializing
    }
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        // Check model status on init
        Task {
            await checkModelStatus()
        }
    }
    
    
    func checkModelStatus() async {
        do {
            let url = URL(string: "\(baseURL)/health")!
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(HealthResponse.self, from: data)
            
            await MainActor.run {
                self.isModelReady = response.modelReady
                self.connectionStatus = response.modelReady ? .connected : .modelInitializing
            }
        } catch {
            await MainActor.run {
                self.connectionStatus = .disconnected
                self.isModelReady = false
            }
            print("Health check failed: \(error)")
        }
    }
    
    
    func predictSafety(lat: Double, lon: Double, timeOfDay: Int? = nil, dayOfWeek: Int? = nil) async throws -> SafetyPrediction {
        guard isModelReady else {
            throw APIError.modelNotReady
        }
        
        let url = URL(string: "\(baseURL)/predict")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["lat": lat, "lon": lon]
        if let timeOfDay = timeOfDay {
            body["time_of_day"] = timeOfDay
        }
        if let dayOfWeek = dayOfWeek {
            body["day_of_week"] = dayOfWeek
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(SafetyPrediction.self, from: data)
    }
    
    func analyzeRoute(coordinates: [[String: Double]], walkingSpeed: Double = 3.0) async throws -> RouteAnalysis {
        guard isModelReady else {
            throw APIError.modelNotReady
        }
        
        let url = URL(string: "\(baseURL)/analyze-route")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "coordinates": coordinates,
            "walking_speed": walkingSpeed
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🚶‍♀️ Analyzing route with \(coordinates.count) waypoints")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        return try decoder.decode(RouteAnalysis.self, from: data)
    }
    
    
    func getNearbyAlerts(lat: Double, lon: Double, radius: Double = 0.5) async throws -> NearbyAlertsResponse {
        guard isModelReady else {
            throw APIError.modelNotReady
        }
        
        var urlComponents = URLComponents(string: "\(baseURL)/nearby-alerts")!
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "radius", value: String(radius))
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        
        return try JSONDecoder().decode(NearbyAlertsResponse.self, from: data)
    }
    
    func getSafetyStatistics() async throws -> SafetyStatistics {
        let url = URL(string: "\(baseURL)/stats")!
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        
        return try JSONDecoder().decode(SafetyStatistics.self, from: data)
    }
    
    
    func submitIncidentReport(_ report: IncidentReport) async throws -> IncidentReportResponse {
        let url = URL(string: "\(baseURL)/report")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(report)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(IncidentReportResponse.self, from: data)
    }
    
    
    func getHeatmapData(resolution: Int = 40, minSafety: Double = 0.0) async throws -> HeatmapResponse {
        guard isModelReady else {
            throw APIError.modelNotReady
        }
        
        var urlComponents = URLComponents(string: "\(baseURL)/heatmap")!
        urlComponents.queryItems = [
            URLQueryItem(name: "resolution", value: String(resolution)),
            URLQueryItem(name: "min_safety", value: String(minSafety))
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        
        return try JSONDecoder().decode(HeatmapResponse.self, from: data)
    }
    
    func getDangerZones() async throws -> DangerZonesResponse {
        guard isModelReady else {
            throw APIError.modelNotReady
        }
        
        let url = URL(string: "\(baseURL)/danger-zones")!
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        
        return try JSONDecoder().decode(DangerZonesResponse.self, from: data)
    }
    
    
    /// Predict safety for current location with current time context
    func predictCurrentLocationSafety(location: CLLocation) async throws -> SafetyPrediction {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now) - 1 // Convert to 0-6 scale
        
        return try await predictSafety(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude,
            timeOfDay: hour,
            dayOfWeek: weekday
        )
    }
    
    /// Convert CLLocationCoordinate2D array to API format
    func analyzeRoute(coordinates: [CLLocationCoordinate2D], walkingSpeed: Double = 3.0) async throws -> RouteAnalysis {
        let apiCoordinates = coordinates.map { coord in
            ["lat": coord.latitude, "lon": coord.longitude]
        }
        
        return try await analyzeRoute(coordinates: apiCoordinates, walkingSpeed: walkingSpeed)
    }
    
    /// Get alerts near current location
    func getNearbyAlerts(location: CLLocation, radius: Double = 0.5) async throws -> NearbyAlertsResponse {
        return try await getNearbyAlerts(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude,
            radius: radius
        )
    }
    
    /// Submit incident at current location
    func submitIncident(
        location: CLLocation,
        type: IncidentType,
        severity: Double,
        description: String? = nil,
        userId: String? = nil
    ) async throws -> IncidentReportResponse {
        let report = IncidentReport(
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude,
            incidentType: type.rawValue,
            severity: severity,
            description: description,
            userId: userId
        )
        
        return try await submitIncidentReport(report)
    }
    
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response type")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 503:
            throw APIError.modelNotReady
        case 400...499:
            throw APIError.serverError(httpResponse.statusCode, "Client error")
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode, "Server error")
        default:
            throw APIError.serverError(httpResponse.statusCode, "Unknown error")
        }
    }
}


struct HealthResponse: Codable {
    let status: String
    let modelReady: Bool
    let dataPoints: DataPoints
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case status, timestamp
        case modelReady = "model_ready"
        case dataPoints = "data_points"
    }
}

struct DataPoints: Codable {
    let crimes: Int
    let accidents: Int
    let userReports: Int
    
    enum CodingKeys: String, CodingKey {
        case crimes, accidents
        case userReports = "user_reports"
    }
}

enum IncidentType: String, CaseIterable {
    case harassment = "harassment"
    case assault = "assault"
    case theft = "theft"
    case accident = "accident"
    case suspiciousActivity = "suspicious_activity"
    case poorLighting = "poor_lighting"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .harassment:
            return "Harassment"
        case .assault:
            return "Assault"
        case .theft:
            return "Theft"
        case .accident:
            return "Accident"
        case .suspiciousActivity:
            return "Suspicious Activity"
        case .poorLighting:
            return "Poor Lighting"
        case .other:
            return "Other"
        }
    }
    
    var severity: Double {
        switch self {
        case .assault:
            return 0.9
        case .harassment:
            return 0.7
        case .theft:
            return 0.6
        case .accident:
            return 0.5
        case .suspiciousActivity:
            return 0.4
        case .poorLighting:
            return 0.3
        case .other:
            return 0.5
        }
    }
}


extension SafetyPrediction {
    var riskColor: UIColor {
        switch riskLevel {
        case "VERY_HIGH":
            return .systemGreen
        case "HIGH":
            return .systemYellow
        case "MEDIUM":
            return .systemOrange
        case "LOW":
            return .systemRed
        case "VERY_LOW":
            return .systemPurple
        default:
            return .systemGray
        }
    }
    
    var riskEmoji: String {
        switch riskLevel {
        case "VERY_HIGH":
            return "✅"
        case "HIGH":
            return "🟡"
        case "MEDIUM":
            return "🟠"
        case "LOW":
            return "🔴"
        case "VERY_LOW":
            return "🚨"
        default:
            return "❓"
        }
    }
    
    var shortDescription: String {
        switch riskLevel {
        case "VERY_HIGH":
            return "Very Safe"
        case "HIGH":
            return "Safe"
        case "MEDIUM":
            return "Moderate Risk"
        case "LOW":
            return "High Risk"
        case "VERY_LOW":
            return "Very Dangerous"
        default:
            return "Unknown"
        }
    }
}

extension RouteAnalysis {
    var formattedDuration: String {
        let minutes = Int(estimatedDuration)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
    
    var safetyGrade: String {
        switch overallSafety {
        case 0.8...1.0:
            return "A"
        case 0.6..<0.8:
            return "B"
        case 0.4..<0.6:
            return "C"
        case 0.2..<0.4:
            return "D"
        default:
            return "F"
        }
    }
}
