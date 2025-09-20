import SwiftUI
import MapKit
import CoreLocation

struct TripPlannerView: View {
    @ObservedObject var apiService: WalkSafeAPIService
    @ObservedObject var locationManager: LocationManager
    
    @Environment(\.presentationMode) var presentationMode
    @State private var startAddress = ""
    @State private var endAddress = ""
    @State private var waypoints: [Waypoint] = []
    @State private var isSearching = false
    @State private var routeAnalysis: RouteAnalysis?
    @State private var showingAnalysis = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    // Add these bindings
    @Binding var selectedRoute: [CLLocationCoordinate2D]
    @Binding var showingRouteOnMap: Bool
    @Binding var showingTripPlanner: Bool
    
    // Manual location states
    @State private var useCurrentLocationForStart = false
    @State private var showCurrentLocationOption = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    addressInputCard
                    destinationOptionsCard
                    routeSummarySection
                    planRouteSection
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingAnalysis) {
                if let analysis = routeAnalysis {
                    TripAnalysisView(
                        analysis: analysis,
                        startAddress: getDisplayStartAddress(),
                        endAddress: endAddress,
                        waypoints: waypoints.map { $0.address },
                        selectedRoute: $selectedRoute,
                        showingRouteOnMap: $showingRouteOnMap,
                        showingTripPlanner: $showingTripPlanner
                    )
                }
            }
            .alert("Route Planning Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if locationManager.isLocationAvailable && startAddress.isEmpty {
                    useCurrentLocationForStart = true
                    useCurrentLocationAsStart()
                }
            }
        }
    }
    
    // MARK: - Computed Views
    
    private var headerView: some View {
        Text("Plan Your Walking Trip")
            .font(.title2)
            .fontWeight(.bold)
            .padding(.top)
    }
    
    private var addressInputCard: some View {
        VStack(spacing: 16) {
            startAddressSection
            waypointsSection
            endAddressSection
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var startAddressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.green)
                Text("Starting Address")
                    .font(.headline)
            }
            
            if locationManager.isLocationAvailable {
                currentLocationButton
            }
            
            startAddressInput
        }
    }
    
    private var currentLocationButton: some View {
        Button(action: {
            useCurrentLocationForStart.toggle()
            if useCurrentLocationForStart {
                useCurrentLocationAsStart()
            } else {
                startAddress = ""
            }
        }) {
            HStack {
                Image(systemName: useCurrentLocationForStart ? "checkmark.square.fill" : "square")
                    .foregroundColor(.blue)
                Text("Use Current Location")
                    .fontWeight(.medium)
                Spacer()
                if locationManager.currentLocation != nil {
                    Text("📍")
                }
            }
            .padding(.vertical, 8)
        }
        .foregroundColor(.primary)
    }
    
    private var startAddressInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !useCurrentLocationForStart || !locationManager.isLocationAvailable {
                TextField("Enter starting address", text: $startAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .disabled(useCurrentLocationForStart && locationManager.isLocationAvailable)
                
                if !locationManager.isLocationAvailable {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Location services not available - enter address manually")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                    Text(startAddress.isEmpty ? "Using current location..." : startAddress)
                        .foregroundColor(.secondary)
                        .italic()
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var waypointsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.blue)
                Text("Stop Points (Optional)")
                    .font(.headline)
                Spacer()
                Button(action: addWaypoint) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            
            if waypoints.isEmpty {
                Text("Add stops along your route for a safer journey")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(Array(waypoints.enumerated()), id: \.offset) { index, waypoint in
                    HStack {
                        Image(systemName: "mappin.circle")
                            .foregroundColor(.blue)
                        
                        TextField("Stop \(index + 1) address", text: Binding(
                            get: { waypoints[index].address },
                            set: { waypoints[index].address = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                        
                        Button(action: { removeWaypoint(at: index) }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }
    
    private var endAddressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flag.circle.fill")
                    .foregroundColor(.red)
                Text("Final Destination")
                    .font(.headline)
            }
            
            TextField("Enter destination address", text: $endAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
        }
    }
    
    private var destinationOptionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Delray Beach Destinations")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(popularDestinations, id: \.name) { destination in
                    destinationButton(for: destination)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func destinationButton(for destination: PopularDestination) -> some View {
        Button(action: {
            if endAddress.isEmpty {
                endAddress = destination.address
            } else {
                addWaypointWithAddress(destination.address)
            }
        }) {
            VStack {
                Image(systemName: destination.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(destination.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isDestinationSelected(destination.address) ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isDestinationSelected(destination.address) ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
    
    @ViewBuilder
    private var routeSummarySection: some View {
        if !getRouteStops().isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Route Summary")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(getRouteStops().enumerated()), id: \.offset) { index, stop in
                        HStack {
                            Image(systemName: getStopIcon(for: index, total: getRouteStops().count))
                                .foregroundColor(getStopColor(for: index, total: getRouteStops().count))
                            Text(getStopLabel(for: index, total: getRouteStops().count))
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(stop.isEmpty ? "Not set" : stop)
                                .font(.caption)
                                .foregroundColor(stop.isEmpty ? .secondary : .primary)
                            Spacer()
                        }
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var planRouteSection: some View {
        VStack(spacing: 12) {
            Button(action: planRoute) {
                if isSearching {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Planning Route...")
                    }
                } else {
                    Text("Plan Safe Route")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canPlanRoute() && !isSearching ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(!canPlanRoute() || isSearching)
            
            if !canPlanRoute() {
                Text(getPlanRouteHint())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Data and Functions
    
    private let popularDestinations = [
        PopularDestination(name: "Atlantic Ave", address: "Atlantic Avenue, Delray Beach, FL", icon: "storefront.fill"),
        PopularDestination(name: "Delray Beach", address: "Delray Beach Public Beach, FL", icon: "beach.umbrella.fill"),
        PopularDestination(name: "Pineapple Grove", address: "Pineapple Grove Arts District, Delray Beach, FL", icon: "paintbrush.fill"),
        PopularDestination(name: "Old School Square", address: "Old School Square, Delray Beach, FL", icon: "building.columns.fill"),
        PopularDestination(name: "Wakodahatchee", address: "Wakodahatchee Wetlands, Delray Beach, FL", icon: "leaf.fill"),
        PopularDestination(name: "Cornell Art Museum", address: "Cornell Art Museum, Delray Beach, FL", icon: "building.fill")
    ]
    
    private func addWaypoint() {
        waypoints.append(Waypoint(address: ""))
    }
    
    private func addWaypointWithAddress(_ address: String) {
        waypoints.append(Waypoint(address: address))
    }
    
    private func removeWaypoint(at index: Int) {
        waypoints.remove(at: index)
    }
    
    private func isDestinationSelected(_ address: String) -> Bool {
        return endAddress == address || waypoints.contains { $0.address == address }
    }
    
    private func getRouteStops() -> [String] {
        var stops: [String] = []
        
        let effectiveStart = getEffectiveStartAddress()
        if !effectiveStart.isEmpty {
            stops.append(effectiveStart)
        }
        
        for waypoint in waypoints where !waypoint.address.isEmpty {
            stops.append(waypoint.address)
        }
        
        if !endAddress.isEmpty {
            stops.append(endAddress)
        }
        
        return stops
    }
    
    private func getStopIcon(for index: Int, total: Int) -> String {
        if index == 0 {
            return "location.circle.fill"
        } else if index == total - 1 {
            return "flag.circle.fill"
        } else {
            return "mappin.circle.fill"
        }
    }
    
    private func getStopColor(for index: Int, total: Int) -> Color {
        if index == 0 {
            return .green
        } else if index == total - 1 {
            return .red
        } else {
            return .blue
        }
    }
    
    private func getStopLabel(for index: Int, total: Int) -> String {
        if index == 0 {
            return "Start:"
        } else if index == total - 1 {
            return "End:"
        } else {
            return "Stop \(index):"
        }
    }
    
    private func canPlanRoute() -> Bool {
        let hasStartAddress = !getEffectiveStartAddress().isEmpty
        let hasEndAddress = !endAddress.isEmpty
        return hasStartAddress && hasEndAddress
    }
    
    private func getPlanRouteHint() -> String {
        let hasStart = !getEffectiveStartAddress().isEmpty
        let hasEnd = !endAddress.isEmpty
        
        if !hasStart && !hasEnd {
            return "Please enter both starting address and destination"
        } else if !hasStart {
            return "Please enter a starting address"
        } else if !hasEnd {
            return "Please enter a destination address"
        }
        return ""
    }
    
    private func getEffectiveStartAddress() -> String {
        if useCurrentLocationForStart && locationManager.isLocationAvailable {
            return startAddress.isEmpty ? "Current Location" : startAddress
        }
        return startAddress
    }
    
    private func getDisplayStartAddress() -> String {
        if useCurrentLocationForStart && locationManager.isLocationAvailable {
            return startAddress.isEmpty ? "Current Location" : startAddress
        }
        return startAddress
    }
    
    private func useCurrentLocationAsStart() {
        guard let location = locationManager.currentLocation else {
            useCurrentLocationForStart = false
            return
        }
        
        startAddress = "Current Location (Delray Beach, FL)"
    }
    
    private func planRoute() {
        isSearching = true
        errorMessage = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let mockAnalysis = generateMockRouteAnalysis()
            routeAnalysis = mockAnalysis
            showingAnalysis = true
            isSearching = false
        }
    }
    
    private func generateMockRouteAnalysis() -> RouteAnalysis {
        let totalStops = 1 + waypoints.count + 1
        let hasWaypoints = !waypoints.isEmpty
        
        let baseSafety = hasWaypoints ? 0.85 : 0.75
        let safetyVariation = Double.random(in: -0.1...0.1)
        let overallSafety = max(0.4, min(1.0, baseSafety + safetyVariation))
        
        let riskLevel: String
        switch overallSafety {
        case 0.8...1.0: riskLevel = "VERY_HIGH"
        case 0.6..<0.8: riskLevel = "HIGH"
        case 0.4..<0.6: riskLevel = "MEDIUM"
        case 0.2..<0.4: riskLevel = "LOW"
        default: riskLevel = "VERY_LOW"
        }
        
        let totalPoints = 50 + totalStops * 15 + Int.random(in: -10...20)
        let riskPoints = max(0, Int(Double(totalPoints) * (1.0 - overallSafety)) + Int.random(in: -5...5))
        let safestScore = min(1.0, overallSafety + Double.random(in: 0.05...0.15))
        let riskiestScore = max(0.2, overallSafety - Double.random(in: 0.15...0.25))
        
        let baseMinutes = 15 + (totalStops - 2) * 8
        let estimatedDuration = max(10, baseMinutes + Int.random(in: -5...5))
        
        var recommendations = [
            "Stay on well-lit sidewalks and main streets",
            "Walk during daylight hours when possible",
            "Keep your phone charged and share your route with someone"
        ]
        
        if hasWaypoints {
            recommendations.append("Your planned stops are in safe, populated areas")
            recommendations.append("Take breaks at your waypoints to stay alert")
        }
        
        if overallSafety < 0.7 {
            recommendations.append("Consider using ride-share for portions of this route")
            recommendations.append("Walk with a companion if possible")
        }
        
        let dangerZones: [DangerZone] = []
        
        if !dangerZones.isEmpty {
            recommendations.append("Be extra cautious in identified danger zones")
        }
        
        return RouteAnalysis(
            overallSafety: overallSafety,
            riskLevel: riskLevel,
            riskPoints: riskPoints,
            totalPoints: totalPoints,
            safestScore: safestScore,
            riskiestScore: riskiestScore,
            estimatedDuration: Double(estimatedDuration),
            recommendations: recommendations,
            dangerZones: dangerZones
        )
    }
}

struct Waypoint: Identifiable {
    let id = UUID()
    var address: String
}

struct PopularDestination {
    let name: String
    let address: String
    let icon: String
}

enum TripPlanningError: Error {
    case invalidStartAddress
    case invalidEndAddress
    case outsideCoverageArea
    case locationNotAvailable
    
    var localizedDescription: String {
        switch self {
        case .invalidStartAddress:
            return "Could not find the starting address. Please check and try again."
        case .invalidEndAddress:
            return "Could not find the destination address. Please check and try again."
        case .outsideCoverageArea:
            return "One or both addresses are outside our Delray Beach coverage area."
        case .locationNotAvailable:
            return "Current location is not available. Please enter a starting address manually."
        }
    }
}
