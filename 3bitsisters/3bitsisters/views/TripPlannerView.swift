import SwiftUI
import MapKit
import CoreLocation

struct TripPlannerView: View {
    @ObservedObject var apiService: WalkSafeAPIService
    @ObservedObject var locationManager: LocationManager
    
    @Environment(\.presentationMode) var presentationMode
    @State private var startAddress = ""
    @State private var endAddress = ""
    @State private var isSearching = false
    @State private var routeAnalysis: RouteAnalysis?
    @State private var showingAnalysis = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    // Manual location states
    @State private var useCurrentLocationForStart = false
    @State private var showCurrentLocationOption = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Plan Your Walking Trip")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    VStack(spacing: 16) {
                        // Start Address Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "location.circle.fill")
                                    .foregroundColor(.green)
                                Text("Starting Address")
                                    .font(.headline)
                            }
                            
                            // Current location option (if available)
                            if locationManager.isLocationAvailable {
                                VStack(spacing: 8) {
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
                            }
                            
                            // Manual address input for start
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
                                    // Show current location address when using GPS
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
                        
                        // End Address Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                Text("Destination Address")
                                    .font(.headline)
                            }
                            
                            TextField("Enter destination address", text: $endAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Quick Destination Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Popular Delray Beach Destinations")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(popularDestinations, id: \.name) { destination in
                                Button(action: {
                                    endAddress = destination.address
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
                                    .background(endAddress == destination.address ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(endAddress == destination.address ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Additional Address Input Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Need Help with Addresses?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            addressSuggestionButton("My Home", address: getUserHomeAddress())
                            addressSuggestionButton("Delray Beach City Hall", address: "100 NW 1st Ave, Delray Beach, FL 33444")
                            addressSuggestionButton("Delray Beach Station", address: "345 S Congress Ave, Delray Beach, FL 33445")
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Plan Route Button
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
                    TripAnalysisView(analysis: analysis, startAddress: getDisplayStartAddress(), endAddress: endAddress)
                }
            }
            .alert("Route Planning Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Auto-enable current location if available
                if locationManager.isLocationAvailable && startAddress.isEmpty {
                    useCurrentLocationForStart = true
                    useCurrentLocationAsStart()
                }
            }
        }
    }
    
    private let popularDestinations = [
        PopularDestination(name: "Atlantic Ave", address: "Atlantic Avenue, Delray Beach, FL", icon: "storefront.fill"),
        PopularDestination(name: "Delray Beach", address: "Delray Beach Public Beach, FL", icon: "beach.umbrella.fill"),
        PopularDestination(name: "Pineapple Grove", address: "Pineapple Grove Arts District, Delray Beach, FL", icon: "paintbrush.fill"),
        PopularDestination(name: "Old School Square", address: "Old School Square, Delray Beach, FL", icon: "building.columns.fill"),
        PopularDestination(name: "Wakodahatchee", address: "Wakodahatchee Wetlands, Delray Beach, FL", icon: "leaf.fill"),
        PopularDestination(name: "Cornell Art Museum", address: "Cornell Art Museum, Delray Beach, FL", icon: "building.fill")
    ]
    
    private func addressSuggestionButton(_ title: String, address: String?) -> some View {
        Button(action: {
            if let address = address {
                if startAddress.isEmpty {
                    startAddress = address
                } else if endAddress.isEmpty {
                    endAddress = address
                } else {
                    // Replace end address if both are filled
                    endAddress = address
                }
            }
        }) {
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                Spacer()
                if address == nil {
                    Text("Not available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .foregroundColor(.primary)
        .disabled(address == nil)
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
    
    private func getUserHomeAddress() -> String? {
        return nil
    }
    
    private func useCurrentLocationAsStart() {
        guard let location = locationManager.currentLocation else {
            useCurrentLocationForStart = false
            return
        }
        
        // Reverse geocode to get address
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    let address = [
                        placemark.subThoroughfare,
                        placemark.thoroughfare,
                        placemark.locality,
                        placemark.administrativeArea
                    ].compactMap { $0 }.joined(separator: " ")
                    
                    startAddress = address
                } else {
                    // Fallback to coordinates if reverse geocoding fails
                    startAddress = "Current Location (\(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude)))"
                }
            }
        }
    }
    
    private func planRoute() {
        isSearching = true
        errorMessage = ""
        
        let geocoder = CLGeocoder()
        let effectiveStartAddress = getEffectiveStartAddress()
        
        Task {
            do {
                var startLocation: CLLocation
                
                // Handle start location
                if useCurrentLocationForStart && locationManager.isLocationAvailable {
                    if let currentLoc = locationManager.currentLocation {
                        startLocation = currentLoc
                    } else {
                        throw TripPlanningError.locationNotAvailable
                    }
                } else {
                    // Geocode start address
                    let startPlacemarks = try await geocoder.geocodeAddressString(effectiveStartAddress)
                    guard let geocodedStart = startPlacemarks.first?.location else {
                        throw TripPlanningError.invalidStartAddress
                    }
                    startLocation = geocodedStart
                }
                
                // Geocode end address
                let endPlacemarks = try await geocoder.geocodeAddressString(endAddress)
                guard let endLocation = endPlacemarks.first?.location else {
                    throw TripPlanningError.invalidEndAddress
                }
                
                // Check if both locations are within Delray Beach area
                let delrayCenter = CLLocation(latitude: 26.4615, longitude: -80.0728)
                let startDistance = startLocation.distance(from: delrayCenter)
                let endDistance = endLocation.distance(from: delrayCenter)
                
                if startDistance > 8000 || endDistance > 8000 { // 8km instead of 3 miles for more coverage
                    throw TripPlanningError.outsideCoverageArea
                }
                
                // Create route coordinates (simplified - in real app would use routing service)
                let coordinates = [
                    ["lat": startLocation.coordinate.latitude, "lon": startLocation.coordinate.longitude],
                    ["lat": endLocation.coordinate.latitude, "lon": endLocation.coordinate.longitude]
                ]
                
                // Analyze route safety
                let analysis = try await apiService.analyzeRoute(coordinates: coordinates)
                
                await MainActor.run {
                    routeAnalysis = analysis
                    showingAnalysis = true
                    isSearching = false
                }
                
            } catch {
                await MainActor.run {
                    if let tripError = error as? TripPlanningError {
                        errorMessage = tripError.localizedDescription
                    } else {
                        errorMessage = "Failed to plan route. Please check your addresses and try again."
                    }
                    showingError = true
                    isSearching = false
                }
            }
        }
    }
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

struct TripAnalysisView: View {
    let analysis: RouteAnalysis
    let startAddress: String
    let endAddress: String
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Trip Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trip Summary")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "location.circle.fill")
                                    .foregroundColor(.green)
                                Text("From:")
                                    .fontWeight(.medium)
                            }
                            Text(startAddress)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "mappin.circle.fill")
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
                            }
                            
                            Spacer()
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
