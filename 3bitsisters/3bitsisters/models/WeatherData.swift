import Foundation

struct WeatherData: Codable {
    let temperature: Double
    let humidity: Double
    let precipitation: Double
    let description: String
    let willRain: Bool
}
