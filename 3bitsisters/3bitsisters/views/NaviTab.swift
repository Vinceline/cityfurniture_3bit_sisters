//
//  NaviTab.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/20/25.
//
import SwiftUI

struct NaviTabView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var apiService = WalkSafeAPIService()
    @State private var selectedTab = 1 // Start on Profile tab (index 1)
    @State private var isMapViewActive = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Map Tab - Walking/Safety functionality (index 0)
            ZStack {
                if isMapViewActive {
                    ContentView()
                        .environmentObject(locationManager)
                        .environmentObject(apiService)
                } else {
                    // Placeholder when map is not active
                    VStack {
                        Image(systemName: "shoe.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("Tap to activate map")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Button("Activate Map") {
                            isMapViewActive = true
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
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
                    // Auto-activate when tab is selected
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


