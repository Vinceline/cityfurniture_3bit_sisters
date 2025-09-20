import Foundation
import CoreLocation
import Combine

class WeatherService: ObservableObject {
    private let apiKey = "a6ebcd801172cb845f870656df9f97dc" 
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    
    @Published var currentWeather: WeatherData?
    @Published var willRainSoon = false
    
    func checkWeatherForLocation(_ location: CLLocation) async {
        await fetchCurrentWeather(location)
        await checkRainForecast(location)
    }
    
    private func fetchCurrentWeather(_ location: CLLocation) async {
        guard !apiKey.isEmpty else {
            // Mock weather data for demo
            let mockWeather = WeatherData(
                temperature: 78.0,
                humidity: 65.0,
                precipitation: 0.1,
                description: "Partly cloudy",
                willRain: false
            )
            
            await MainActor.run {
                currentWeather = mockWeather
            }
            return
        }
        
        let urlString = "\(baseURL)/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(apiKey)&units=imperial"
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
            
            let weather = WeatherData(
                temperature: response.main.temp,
                humidity: response.main.humidity,
                precipitation: response.rain?.oneHour ?? 0.0,
                description: response.weather.first?.description ?? "Unknown",
                willRain: (response.rain?.oneHour ?? 0.0) > 0.0
            )
            
            await MainActor.run {
                currentWeather = weather
            }
        } catch {
            print("Weather fetch error: \(error)")
        }
    }
    
    private func checkRainForecast(_ location: CLLocation) async {
        guard !apiKey.isEmpty && apiKey != "YOUR_OPENWEATHER_API_KEY" else {
            // Mock rain check
            await MainActor.run {
                willRainSoon = Bool.random() && Bool.random() // 25% chance for demo
            }
            return
        }
        
        let urlString = "\(baseURL)/forecast?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(apiKey)&units=imperial&cnt=8"
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenWeatherForecastResponse.self, from: data)
            
            let willRain = response.list.prefix(2).contains { forecast in
                (forecast.rain?.threeHour ?? 0.0) > 0.0
            }
            
            await MainActor.run {
                willRainSoon = willRain
            }
        } catch {
            print("Weather forecast error: \(error)")
        }
    }
}
