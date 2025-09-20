import SwiftUI
import MapKit

struct RouteAnalysisView: View {
    @ObservedObject var apiService: WalkSafeAPIService
    let route: [CLLocationCoordinate2D]
    
    @Environment(\.presentationMode) var presentationMode
    @State private var routeAnalysis: RouteAnalysis?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Analyzing route safety...")
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let analysis = routeAnalysis {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Overall Safety Score
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Overall Route Safety")
                                    .font(.headline)
                                
                                HStack {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                            .frame(width: 80, height: 80)
                                        
                                        Circle()
                                            .trim(from: 0, to: CGFloat(analysis.overallSafety))
                                            .stroke(getSafetyColor(analysis.overallSafety), lineWidth: 8)
                                            .frame(width: 80, height: 80)
                                            .rotationEffect(.degrees(-90))
                                        
                                        Text("\(Int(analysis.overallSafety * 100))%")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(getRiskLevelText(analysis.riskLevel))
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(getSafetyColor(analysis.overallSafety))
                                        
                                        Text("\(analysis.riskPoints) risk points")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Route Statistics
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Route Details")
                                    .font(.headline)
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Total Points")
                                        Text("\(analysis.totalPoints)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("Risk Points")
                                        Text("\(analysis.riskPoints)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                Divider()
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Safest Point")
                                        Text("\(Int(analysis.safestScore * 100))%")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("Riskiest Point")
                                        Text("\(Int(analysis.riskiestScore * 100))%")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Recommendations
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recommendations")
                                    .font(.headline)
                                
                                ForEach(analysis.recommendations, id: \.self) { recommendation in
                                    HStack(alignment: .top) {
                                        Image(systemName: getRecommendationIcon(recommendation))
                                            .foregroundColor(getRecommendationColor(recommendation))
                                            .frame(width: 20)
                                        
                                        Text(recommendation)
                                            .font(.body)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Action Buttons
                            VStack(spacing: 12) {
                                Button(action: {
                                    // Clear route and close
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Text("Clear Route")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                
                                if analysis.overallSafety < 0.6 {
                                    Button(action: {
                                        // In a real app, this would suggest alternative routes
                                        presentationMode.wrappedValue.dismiss()
                                    }) {
                                        Text("Find Safer Route")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Route Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                analyzeRoute()
            }
        }
    }
    
    private func analyzeRoute() {
        let coordinates = route.map { coord in
            ["lat": coord.latitude, "lon": coord.longitude]
        }
        
        Task {
            do {
                let analysis = try await apiService.analyzeRoute(coordinates: coordinates)
                
                await MainActor.run {
                    self.routeAnalysis = analysis
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Error analyzing route: \(error)")
                }
            }
        }
    }
    
    private func getSafetyColor(_ score: Double) -> Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        case 0.2..<0.4: return .red
        default: return .purple
        }
    }
    
    private func getRiskLevelText(_ riskLevel: String) -> String {
        switch riskLevel {
        case "VERY_HIGH": return "Very Safe"
        case "HIGH": return "Safe"
        case "MEDIUM": return "Moderate"
        case "LOW": return "Risky"
        case "VERY_LOW": return "High Risk"
        default: return riskLevel
        }
    }
    
    private func getRecommendationIcon(_ recommendation: String) -> String {
        if recommendation.contains("alternative") || recommendation.contains("avoid") {
            return "exclamationmark.triangle.fill"
        } else if recommendation.contains("night") || recommendation.contains("late") {
            return "moon.fill"
        } else if recommendation.contains("safe") {
            return "checkmark.circle.fill"
        } else {
            return "info.circle.fill"
        }
    }
    
    private func getRecommendationColor(_ recommendation: String) -> Color {
        if recommendation.contains("alternative") || recommendation.contains("avoid") {
            return .red
        } else if recommendation.contains("night") {
            return .orange
        } else if recommendation.contains("safe") {
            return .green
        } else {
            return .blue
        }
    }
}
