//
//  NaviTab.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/20/25.
//
import SwiftUI
import MapKit
import CoreLocation

struct NaviTabView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var apiService = WalkSafeAPIService()
    @State private var selectedTab = 1 // Start on Profile tab (index 1)
    @State private var isMapViewActive = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Map Tab - Walking/Safety functionality (index 0)
            NavigationView {
                ZStack {
                    if isMapViewActive {
                        MapTabContent()
                            .environmentObject(locationManager)
                            .environmentObject(apiService)
                            .navigationBarHidden(true)
                    } else {
                        // Placeholder when map is not active
                        VStack(spacing: 20) {
                            Image(systemName: "shoe.2.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            Text("WalkSafe Map")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Tap to activate map and safety features")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Activate Map") {
                                isMapViewActive = true
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding()
                        .navigationTitle("Walk Safe")
                    }
                }
            }
            .tabItem {
                Image(systemName: "shoe.2.fill")
                Text("Walk Safe")
            }
            .tag(0)
            .onAppear {
                if selectedTab == 0 && !isMapViewActive {
                    isMapViewActive = true
                }
            }
            
            // Profile Tab - User/Other functionality (index 1)
            ProfileView()
                .environmentObject(locationManager)
                .environmentObject(apiService)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(1)
        }
        .accentColor(.blue)
        .onChange(of: selectedTab) { newTab in
            if newTab == 0 {
                isMapViewActive = true
            }
        }
    }
}

