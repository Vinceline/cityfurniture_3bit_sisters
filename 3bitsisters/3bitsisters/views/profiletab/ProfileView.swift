//
//  ProfileView.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/20/25.
//

import SwiftUI
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
