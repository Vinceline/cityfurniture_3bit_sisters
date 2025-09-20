//
//  ContentView.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/19/25.
//
import SwiftUI
import MapKit
import CoreLocation
struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var apiService: WalkSafeAPIService
    @State private var showingReportSheet = false
    @State private var showingSafetyAlert = false
    @State private var currentSafetyPrediction: SafetyPrediction?
    @State private var showingRouteAnalysis = false
    @State private var selectedRoute: [CLLocationCoordinate2D] = []
    @State private var showingTripPlanner = false
    @State private var showingDangerZones = false
    @State private var showingRouteOnMap = false
    @State private var showingWeatherAlert = true
    @State private var weatherAlertOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Weather Alert Popup
                    if showingWeatherAlert {
                        VStack {
                            HStack {
                                HStack(spacing: 12) {
                                    Image(systemName: "cloud.bolt.rain.fill")
                                        .font(.title2)
                                        .foregroundColor(.yellow)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Weather Alert")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        Text("Heavy rain and lightning expected in 30 minutes. Please seek shelter soon.")
                                            .font(.body)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        dismissWeatherAlert()
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.title3)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .padding()
                                .background(Color.orange.opacity(0.9))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 8)
                            }
                            .padding(.horizontal)
                            .padding(.top, 60) // Account for safe area
                            .offset(y: weatherAlertOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if value.translation.height < 0 {
                                            weatherAlertOffset = value.translation.height
                                        }
                                    }
                                    .onEnded { value in
                                        if value.translation.height < -50 {
                                            dismissWeatherAlert()
                                        } else {
                                            withAnimation(.spring()) {
                                                weatherAlertOffset = 0
                                            }
                                        }
                                    }
                            )

                            Spacer()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1000) // Ensure it appears above map
                    }
            // Main Map View - Remove NavigationView wrapper
            MapView(
                locationManager: locationManager,
                apiService: apiService,
                showingSafetyAlert: $showingSafetyAlert,
                currentSafetyPrediction: $currentSafetyPrediction,
                selectedRoute: $selectedRoute,
                showingRouteAnalysis: $showingRouteAnalysis,
                showingDangerZones: $showingDangerZones,
                showingRouteOnMap: $showingRouteOnMap
            )
            .ignoresSafeArea()
            
            // Top UI Controls
            VStack {
                HStack {
                    Spacer()
                    // Location Status
                    Button(action: {
                        locationManager.requestLocation()
                    }) {
                        Image(systemName: locationManager.isLocationAvailable ? "location.fill" : "location.slash")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(locationManager.isLocationAvailable ? Color.green : Color.red)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                // Bottom Controls - Very bottom, just above tab bar
                HStack(spacing: 16) {
                    // Report Incident Button
                    Button(action: {
                        showingReportSheet = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                            Text("Report")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .cornerRadius(20)
                    }
                    
                    // Trip Planner Button
                    Button(action: {
                        showingTripPlanner = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "map.fill")
                                .font(.title3)
                            Text("Plan Trip")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(20)
                    }
                    
                    // Check Safety / Toggle Danger Zones
                    Button(action: {
                        toggleDangerZones()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: showingDangerZones ? "shield.fill" : "shield.checkered")
                                .font(.title3)
                            Text(showingDangerZones ? "Hide Zones" : "Check Safety")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(showingDangerZones ? Color.orange : Color.blue)
                        .cornerRadius(20)
                    }
                }
                .padding(.bottom, 20) // Much closer to tab bar
            }
            
            // Danger Zone Legend (only when zones are visible)
            if showingDangerZones {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Safety Zones")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red.opacity(0.7))
                                    .frame(width: 12, height: 12)
                                Text("High Risk")
                                    .font(.caption2)
                            }
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.orange.opacity(0.7))
                                    .frame(width: 12, height: 12)
                                Text("Medium Risk")
                                    .font(.caption2)
                            }
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.yellow.opacity(0.7))
                                    .frame(width: 12, height: 12)
                                Text("Low Risk")
                                    .font(.caption2)
                            }
                        }
                        .padding(12)
                        .background(Color(.systemBackground).opacity(0.9))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .padding(.trailing, 16)
                        .padding(.bottom, 180) // Account for tab bar
                    }
                }
            }
        }
        // Keep all your existing sheets and alerts
        .sheet(isPresented: $showingReportSheet) {
            ReportIncidentView(
                apiService: apiService,
                currentLocation: locationManager.currentLocation
            )
        }
        .sheet(isPresented: $showingRouteAnalysis) {
            RouteAnalysisView(
                apiService: apiService,
                route: selectedRoute
            )
        }
        .sheet(isPresented: $showingTripPlanner) {
            TripPlannerView(
                apiService: apiService,
                locationManager: locationManager,
                selectedRoute: $selectedRoute,
                showingRouteOnMap: $showingRouteOnMap,
                showingTripPlanner: $showingTripPlanner
            )
        }
        .alert("Safety Alert", isPresented: $showingSafetyAlert) {
            Button("OK") { }
        } message: {
            if let prediction = currentSafetyPrediction {
                Text(getSafetyMessage(prediction))
            }
        }
        .onAppear {
            locationManager.requestLocationPermission()
        }
    }
    
    // Keep all your existing functions unchanged
    private func toggleDangerZones() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingDangerZones.toggle()
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        if showingDangerZones {
            checkCurrentLocationSafety()
        }
    }
    private func dismissWeatherAlert() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingWeatherAlert = false
        }
    }
    private func checkCurrentLocationSafety() {
        guard let location = locationManager.currentLocation else { return }
        
        Task {
            do {
                let prediction = try await apiService.predictSafety(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude
                )
                
                await MainActor.run {
                    currentSafetyPrediction = prediction
                    if prediction.riskLevel == "LOW" || prediction.riskLevel == "VERY_LOW" {
                        showingSafetyAlert = true
                    }
                }
            } catch {
                print("Error checking safety: \(error)")
            }
        }
    }
    
    private func getSafetyMessage(_ prediction: SafetyPrediction) -> String {
        let safetyPercentage = Int(prediction.safetyScore * 100)
        
        switch prediction.riskLevel {
        case "VERY_HIGH":
            return "Very Safe Area (\(safetyPercentage)%) - Great for walking!"
        case "HIGH":
            return "Safe Area (\(safetyPercentage)%) - Good for walking."
        case "MEDIUM":
            return "Moderate Safety (\(safetyPercentage)%) - Stay alert while walking."
        case "LOW":
            return "Lower Safety (\(safetyPercentage)%) - Consider alternative routes."
        case "VERY_LOW":
            return "High Risk Area (\(safetyPercentage)%) - Avoid walking here if possible."
        default:
            return "Safety Score: \(safetyPercentage)%"
        }
    }
}

