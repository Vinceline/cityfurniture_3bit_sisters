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

struct ProfileView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var apiService: WalkSafeAPIService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("WalkSafe User")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Stay safe, walk confident")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Quick Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Safety Stats")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            StatCard(
                                icon: "figure.walk",
                                title: "Safe Walks",
                                value: "23",
                                color: .green
                            )
                            
                            StatCard(
                                icon: "shield.checkered",
                                title: "Routes Planned",
                                value: "12",
                                color: .blue
                            )
                            
                            StatCard(
                                icon: "exclamationmark.triangle",
                                title: "Reports Made",
                                value: "3",
                                color: .orange
                            )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Settings & Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Settings")
                            .font(.headline)
                        
                        SettingsRow(
                            icon: "location.fill",
                            title: "Location Services",
                            subtitle: locationManager.isLocationAvailable ? "Enabled" : "Disabled",
                            color: locationManager.isLocationAvailable ? .green : .red
                        )
                        
                        SettingsRow(
                            icon: "bell.fill",
                            title: "Safety Notifications",
                            subtitle: "Enabled",
                            color: .blue
                        )
                        
                        SettingsRow(
                            icon: "moon.fill",
                            title: "Night Mode Walking",
                            subtitle: "Extra alerts enabled",
                            color: .purple
                        )
                        
                        SettingsRow(
                            icon: "info.circle.fill",
                            title: "About WalkSafe FL",
                            subtitle: "Version 1.0",
                            color: .gray
                        )
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
