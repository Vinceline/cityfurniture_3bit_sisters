struct OpenWeatherResponse: Codable {
    let main: MainWeather
    let weather: [WeatherDescription]
    let rain: Rain?
}

struct OpenWeatherForecastResponse: Codable {
    let list: [ForecastItem]
}

struct ForecastItem: Codable {
    let main: MainWeather
    let weather: [WeatherDescription]
    let rain: Rain?
}

struct MainWeather: Codable {
    let temp: Double
    let humidity: Double
}

struct WeatherDescription: Codable {
    let description: String
}

struct Rain: Codable {
    let oneHour: Double?
    let threeHour: Double?
    
    enum CodingKeys: String, CodingKey {
        case oneHour = "1h"
        case threeHour = "3h"
    }
}
