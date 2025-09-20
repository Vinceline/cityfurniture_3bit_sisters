//
//  MapTabContent.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/20/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapTabContent: View {
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
    @State private var showingLocationOptions = false
    @State private var showingContactPicker = false
    
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
                    .padding(.top, 60)
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
                .zIndex(1000)
            }
            
            // Main Map View
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
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        // Location Status Button (simplified)
                        Button(action: {
                            showingLocationOptions = true
                        }) {
                            Image(systemName: locationManager.isLocationAvailable ? "location.fill" : "location.slash")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(locationManager.isLocationAvailable ? Color.green : Color.red)
                                .clipShape(Circle())
                        }
                    }
                    
                    HStack {
                        Spacer()
                        // Dedicated Location Sharing Button
                        Button(action: {
                            showingContactPicker = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                // Bottom Controls
                HStack(spacing: 16) {
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
                .padding(.bottom, 100) // Account for tab bar
            }
            
            // Danger Zone Legend
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
                        .padding(.bottom, 180)
                    }
                }
            }
        }
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
        .actionSheet(isPresented: $showingLocationOptions) {
            ActionSheet(
                title: Text("Location Options"),
                message: Text("Manage your location settings"),
                buttons: [
                    .default(Text("Refresh Location")) {
                        locationManager.requestLocation()
                    },
                    .default(Text("Open Location Settings")) {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    },
                    .cancel()
                ]
            )
        }
        // parent view
        .sheet(isPresented: $showingContactPicker) {
            LocationSharingView()
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
