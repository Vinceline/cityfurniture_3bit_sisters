//
//  LocationSharingView.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/20/25.
//
import SwiftUI
import MessageUI
import CoreLocation
import MapKit
struct LocationSharingView: View {
    // sheet state
    @State private var isContactSheetPresented = false
    // selected mock contact
    @State private var selectedContact: MockContact? = nil
    // simple map state for preview (uses MapKit's Map)
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 26.4615, longitude: -80.0728), // Delray Beach, FL
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    // mock contacts
    private let mockContacts: [MockContact] = [
        MockContact(name: "Alice Johnson", phone: "123-456-7890"),
        MockContact(name: "Bob Smith", phone: "987-654-3210"),
        MockContact(name: "Charlie Brown", phone: "555-555-5555"),
        MockContact(name: "Dana Scully", phone: "202-555-0143"),
        MockContact(name: "Elliot Alderson", phone: "202-555-0127")
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Map preview — replace or wire to your real location manager
            Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: false, userTrackingMode: nil)
                .frame(height: 240)
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)

            // Location info / selected contact
            VStack(spacing: 6) {
                if let contact = selectedContact {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Sharing with")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(contact.name)
                                .font(.headline)
                        }
                        Spacer()
                        Button(action: {
                            // quick unselect
                            selectedContact = nil
                        }) {
                            Text("Unshare")
                                .font(.callout)
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("No contact selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Tap Share to pick a mock contact")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)

            // Share button
            Button(action: {
                // sanity check: open the mock contacts sheet
                isContactSheetPresented = true
            }) {
                Label(selectedContact == nil ? "Share Location" : "Change Contact", systemImage: "paperplane.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            // Simulated "send" button to demonstrate sharing action
            Button(action: {
                guard let contact = selectedContact else {
                    print("Please pick a contact.")
                    return
                }
                let lat = region.center.latitude
                let lon = region.center.longitude
                let locationURL = "https://maps.apple.com/?ll=\(lat),\(lon)"
                // Replace with your apiService call if you have one:
                print("Simulated sharing \(locationURL) with \(contact.name) • \(contact.phone)")
                // Optionally show confirmation UI, toast, etc.
            }) {
                Text("Send Location")
                    .font(.subheadline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(8)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.top)
        .sheet(isPresented: $isContactSheetPresented) {
            MockContactSheet(contacts: mockContacts) { contact in
                // selected: update state and dismiss (MockContactSheet will dismiss itself)
                selectedContact = contact
                // If you want to auto-perform share immediately, do it here.
                // e.g. apiService.shareLocation(with: contact, location: region.center)
            }
        }
    }
}

// -------------------- PREVIEW --------------------
struct LocationSharingView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSharingView()
            .previewDevice("iPhone 14")
    }
}
