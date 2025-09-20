import SwiftUI
import CoreLocation

struct ReportIncidentView: View {
    @ObservedObject var apiService: WalkSafeAPIService
    let currentLocation: CLLocation?
    
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedIncidentType = "dog"
    @State private var severity: Double = 0.5
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var showingSuccessAlert = false
    
    // Manual location entry states
    @State private var useManualLocation = false
    @State private var manualAddress = ""
    @State private var isGeocodingAddress = false
    @State private var geocodedLocation: CLLocation?
    @State private var showingLocationError = false
    @State private var locationErrorMessage = ""
    @State private var showingContactInfo = false
    
    let incidentTypes = [
        ("dog", "Unleashed Dog", "🐕"),
        ("assault", "Safety Threat", "⚠️"),
        ("flooding", "Flooding", "💧"),
        ("accident", "Accident", "🚗"),
        ("theft", "Theft", "💰"),
        ("other", "Other", "📝")
    ]
    
    // Computed property for the location to use
    private var effectiveLocation: CLLocation? {
        if useManualLocation {
            return geocodedLocation
        } else {
            return currentLocation
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Report Incident")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Location Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location")
                            .font(.headline)
                        
                        if currentLocation != nil {
                            // Option to use current location or manual entry
                            VStack(spacing: 12) {
                                Button(action: {
                                    useManualLocation = false
                                    geocodedLocation = nil
                                }) {
                                    HStack {
                                        Image(systemName: useManualLocation ? "circle" : "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading) {
                                            Text("Use Current Location")
                                                .fontWeight(.medium)
                                            if let location = currentLocation {
                                                Text("\(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .background(useManualLocation ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .foregroundColor(.primary)
                                
                                Button(action: {
                                    useManualLocation = true
                                }) {
                                    HStack {
                                        Image(systemName: useManualLocation ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(.blue)
                                        Text("Enter Address Manually")
                                            .fontWeight(.medium)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(useManualLocation ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .foregroundColor(.primary)
                            }
                        } else {
                            // Only manual entry available
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "location.slash")
                                        .foregroundColor(.orange)
                                    Text("Location not available - Enter manually")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                }
                                
                                Text("Please enter the address where the incident occurred:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .onAppear {
                                useManualLocation = true
                            }
                        }
                        
                        // Manual address input
                        if useManualLocation {
                            VStack(spacing: 8) {
                                TextField("Enter address (e.g., 123 Main St, Delray Beach, FL)", text: $manualAddress)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.words)
                                    .onChange(of: manualAddress) { _ in
                                        geocodedLocation = nil // Clear previous geocoding
                                    }
                                
                                if !manualAddress.isEmpty && !isGeocodingAddress {
                                    Button("Verify Address") {
                                        geocodeAddress()
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                                
                                if isGeocodingAddress {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Verifying address...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if let location = geocodedLocation {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Address verified: \(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude))")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Incident Type Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Incident Type")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(incidentTypes, id: \.0) { type in
                                Button(action: {
                                    selectedIncidentType = type.0
                                }) {
                                    VStack {
                                        Text(type.2)
                                            .font(.title2)
                                        Text(type.1)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedIncidentType == type.0 ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedIncidentType == type.0 ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    // Severity Slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Severity: \(Int(severity * 100))%")
                            .font(.headline)
                        
                        Slider(value: $severity, in: 0...1, step: 0.1) {
                            Text("Severity")
                        } minimumValueLabel: {
                            Text("Low")
                                .font(.caption)
                        } maximumValueLabel: {
                            Text("High")
                                .font(.caption)
                        }
                        .accentColor(.blue)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.headline)
                        
                        TextEditor(text: $description)
                            .frame(height: 80)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Submit Button
                    Button(action: submitReport) {
                        if isSubmitting {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Submitting...")
                            }
                        } else {
                            Text("Submit Report")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmitReport() && !isSubmitting ? Color.red : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(!canSubmitReport() || isSubmitting)
                    
                    if !canSubmitReport() {
                        Text(getSubmitButtonHint())
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
            .alert("Report Submitted", isPresented: $showingSuccessAlert) {
                Button("Show Contacts") {
                    showingContactInfo = true
                }
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Thank you for helping make walking safer for everyone! Would you like to see relevant emergency contacts?")
            }
            .alert("Location Error", isPresented: $showingLocationError) {
                Button("OK") { }
            } message: {
                Text(locationErrorMessage)
            }
            .sheet(isPresented: $showingContactInfo) {
                NavigationView {
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            Image(systemName: "phone.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Emergency Contacts")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("For: \(incidentTypes.first(where: { $0.0 == selectedIncidentType })?.1 ?? "Incident")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        
                        VStack(spacing: 16) {
                            ForEach(getEmergencyContacts(for: selectedIncidentType), id: \.0) { contact in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(contact.0)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Text(contact.1)
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        if let url = URL(string: "tel:\(contact.1.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "-", with: ""))") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Image(systemName: "phone.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .padding(12)
                                            .background(Color.green)
                                            .clipShape(Circle())
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        Text("Tap the phone icon to call directly")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom)
                    }
                    .navigationTitle("Emergency Contacts")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(
                        trailing: Button("Done") {
                            showingContactInfo = false
                        }
                    )
                }
            }
        }
    }
    
    private func canSubmitReport() -> Bool {
        return effectiveLocation != nil
    }
    
    private func getEmergencyContacts(for incidentType: String) -> [(String, String)] {
        switch incidentType {
        case "dog":
            return [
                ("Animal Control", "(561) 243-7911"),
                ("Non-Emergency Police", "(561) 243-7800")
            ]
        case "assault":
            return [
                ("Police Emergency", "911"),
                ("Non-Emergency Police", "(561) 243-7800"),
                ("Crisis Hotline", "(561) 655-2273")
            ]
        case "flooding":
            return [
                ("Emergency Services", "911"),
                ("Public Works", "(561) 243-7045"),
                ("Emergency Management", "(561) 243-7920")
            ]
        case "accident":
            return [
                ("Emergency Services", "911"),
                ("Police Traffic Unit", "(561) 243-7825"),
                ("Road Maintenance", "(561) 243-7045")
            ]
        case "theft":
            return [
                ("Police Emergency", "911"),
                ("Non-Emergency Police", "(561) 243-7800"),
                ("Victim Services", "(561) 355-4943")
            ]
        case "other":
            return [
                ("Non-Emergency Police", "(561) 243-7800"),
                ("City Services", "(561) 243-7000")
            ]
        default:
            return [("Non-Emergency Police", "(561) 243-7800")]
        }
    }
    
    private func getSubmitButtonHint() -> String {
        if useManualLocation && manualAddress.isEmpty {
            return "Please enter an address"
        } else if useManualLocation && geocodedLocation == nil {
            return "Please verify the address"
        } else if effectiveLocation == nil {
            return "Location is required to submit report"
        }
        return ""
    }
    
    private func geocodeAddress() {
        guard !manualAddress.isEmpty else { return }
        
        isGeocodingAddress = true
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(manualAddress) { placemarks, error in
            DispatchQueue.main.async {
                isGeocodingAddress = false
                
                if let error = error {
                    locationErrorMessage = "Could not find the address. Please check and try again."
                    showingLocationError = true
                    geocodedLocation = nil
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    locationErrorMessage = "Invalid address. Please enter a valid address."
                    showingLocationError = true
                    geocodedLocation = nil
                    return
                }
                
                // Optional: Check if location is within service area (e.g., Delray Beach)
                let delrayCenter = CLLocation(latitude: 26.4615, longitude: -80.0728)
                let distance = location.distance(from: delrayCenter)
                
                if distance > 8000 { // 8km radius
                    locationErrorMessage = "Address is outside our service area. Please enter an address in Delray Beach, FL."
                    showingLocationError = true
                    geocodedLocation = nil
                    return
                }
                
                geocodedLocation = location
            }
        }
    }
    
    private func submitReport() {
        guard let location = effectiveLocation else { return }
        
        isSubmitting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSubmitting = false
            showingSuccessAlert = true
        }
        
    }
}
