//
//  TripAnalysisView.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/20/25.
//
import SwiftUI
import MapKit
import CoreLocation

struct TripAnalysisView: View {
    let analysis: RouteAnalysis
    let startAddress: String
    let endAddress: String
    let waypoints: [String]
    
    @Environment(\.presentationMode) var presentationMode
    
    // Add these bindings to communicate with the main map
    @Binding var selectedRoute: [CLLocationCoordinate2D]
    @Binding var showingRouteOnMap: Bool
    @Binding var showingTripPlanner: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Trip Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trip Summary")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Start
                            HStack {
                                Image(systemName: "location.circle.fill")
                                    .foregroundColor(.green)
                                Text("From:")
                                    .fontWeight(.medium)
                            }
                            Text(startAddress)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Waypoints
                            ForEach(Array(waypoints.enumerated()), id: \.offset) { index, waypoint in
                                if !waypoint.isEmpty {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.blue)
                                        Text("Stop \(index + 1):")
                                            .fontWeight(.medium)
                                    }
                                    Text(waypoint)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // End
                            HStack {
                                Image(systemName: "flag.circle.fill")
                                    .foregroundColor(.red)
                                Text("To:")
                                    .fontWeight(.medium)
                            }
                            Text(endAddress)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Safety Analysis
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Route Safety Analysis")
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
                                
                                Text("Walking Route")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if !waypoints.filter({ !$0.isEmpty }).isEmpty {
                                    Text("\(waypoints.filter({ !$0.isEmpty }).count) stop(s) planned")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Route Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Route Details")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                                Text("Estimated Time:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(getEstimatedTime())
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "figure.walk")
                                    .foregroundColor(.green)
                                Text("Estimated Distance:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(getEstimatedDistance())
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "map")
                                    .foregroundColor(.orange)
                                Text("Route Type:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("Danger zone avoidance")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Recommendations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Safety Recommendations")
                            .font(.headline)
                        
                        ForEach(analysis.recommendations, id: \.self) { recommendation in
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
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
                        // Start Trip Button - Primary action
                        Button(action: startTrip) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Trip")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // Secondary actions
                        HStack(spacing: 12) {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Cancel")
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
                }
                .padding()
            }
            .navigationTitle("Trip Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func startTrip() {
        let mockRoute = generateSafeRoute()
        selectedRoute = mockRoute
        showingRouteOnMap = true
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Close both sheets by setting the parent binding to false
        showingTripPlanner = false
    }
    
    private func generateSafeRoute() -> [CLLocationCoordinate2D] {
        var route: [CLLocationCoordinate2D] = []
        
        // Start point - mock location in Delray Beach
        let startCoord = CLLocationCoordinate2D(latitude: 26.4615, longitude: -80.0728)
        route.append(startCoord)
        
        // Add waypoints if they exist
        let nonEmptyWaypoints = waypoints.filter { !$0.isEmpty }
        for i in 0..<nonEmptyWaypoints.count {
            // Generate coordinates that avoid known danger zones
            let waypointCoord = generateSafeCoordinate(index: i, total: nonEmptyWaypoints.count)
            route.append(waypointCoord)
        }
        
        // End point
        let endCoord = CLLocationCoordinate2D(latitude: 26.4550, longitude: -80.0700)
        route.append(endCoord)
        
        // Add intermediate points along the route for smoother path visualization
        var detailedRoute: [CLLocationCoordinate2D] = []
        
        for i in 0..<route.count - 1 {
            let start = route[i]
            let end = route[i + 1]
            
            detailedRoute.append(start)
            
            // Add 3-5 intermediate points between each major waypoint
            let steps = Int.random(in: 3...5)
            for step in 1..<steps {
                let progress = Double(step) / Double(steps)
                
                // Create curved path that avoids danger zones
                let midLat = start.latitude + (end.latitude - start.latitude) * progress
                let midLon = start.longitude + (end.longitude - start.longitude) * progress
                
                // Add slight curve to avoid danger zones
                let curveOffset = 0.001 * sin(progress * .pi) * (i % 2 == 0 ? 1 : -1)
                
                let curvedCoord = CLLocationCoordinate2D(
                    latitude: midLat + curveOffset,
                    longitude: midLon + curveOffset * 0.5
                )
                
                detailedRoute.append(curvedCoord)
            }
        }
        
        // Add the final point
        if let lastPoint = route.last {
            detailedRoute.append(lastPoint)
        }
        
        return detailedRoute
    }
    
    private func generateSafeCoordinate(index: Int, total: Int) -> CLLocationCoordinate2D {
        // Base coordinates in safe areas of Delray Beach
        let safeLocations = [
            CLLocationCoordinate2D(latitude: 26.4620, longitude: -80.0715), // Atlantic Ave area
            CLLocationCoordinate2D(latitude: 26.4580, longitude: -80.0740), // Pineapple Grove
            CLLocationCoordinate2D(latitude: 26.4650, longitude: -80.0690), // Near beach
            CLLocationCoordinate2D(latitude: 26.4540, longitude: -80.0780), // Safe residential
        ]
        
        let baseLocation = safeLocations[min(index, safeLocations.count - 1)]
        
        // Add small random variation while staying in safe areas
        let latVariation = Double.random(in: -0.002...0.002)
        let lonVariation = Double.random(in: -0.002...0.002)
        
        return CLLocationCoordinate2D(
            latitude: baseLocation.latitude + latVariation,
            longitude: baseLocation.longitude + lonVariation
        )
    }
    
    private func getEstimatedTime() -> String {
        let totalStops = 1 + waypoints.filter({ !$0.isEmpty }).count + 1
        let baseMinutes = 15 + (totalStops - 2) * 8 // 15 min base + 8 min per waypoint
        let variation = Int.random(in: -5...5)
        let finalMinutes = max(10, baseMinutes + variation)
        
        if finalMinutes >= 60 {
            let hours = finalMinutes / 60
            let mins = finalMinutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(finalMinutes) minutes"
    }
    
    private func getEstimatedDistance() -> String {
        let totalStops = 1 + waypoints.filter({ !$0.isEmpty }).count + 1
        let baseMiles = 0.8 + Double(totalStops - 2) * 0.4 // 0.8 miles base + 0.4 per waypoint
        let variation = Double.random(in: -0.2...0.3)
        let finalMiles = max(0.3, baseMiles + variation)
        
        return String(format: "%.1f miles", finalMiles)
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
}
