import Foundation

struct IncidentReport: Codable {
    let lat: Double
    let lon: Double
    let incidentType: String
    let severity: Double
    let description: String?
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case lat, lon, severity, description
        case incidentType = "incident_type"
        case userId = "user_id"
    }
}
