import Foundation

struct RouteAnalysis: Codable {
    let overallSafety: Double
    let riskLevel: String
    let riskPoints: Int
    let totalPoints: Int
    let safestScore: Double
    let riskiestScore: Double
    let estimatedDuration: Double
    let recommendations: [String]
    let dangerZones: [DangerZone]
    
    enum CodingKeys: String, CodingKey {
        case recommendations
        case overallSafety = "overall_safety"
        case riskLevel = "risk_level"
        case riskPoints = "risk_points"
        case totalPoints = "total_points"
        case safestScore = "safest_score"
        case riskiestScore = "riskiest_score"
        case estimatedDuration = "estimated_duration"
        case dangerZones = "danger_zones"
    }
}
