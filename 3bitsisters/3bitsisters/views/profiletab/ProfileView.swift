//
//  ProfileView.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/20/25.
//

import SwiftUI
import MapKit
struct ProfileView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var apiService: WalkSafeAPIService
    
    @State private var showingFriendsList = false
    @State private var showingAddFriend = false
    @State private var showingFriendLocation: Friend? = nil
    @State private var searchText = ""
    
    // Mock friends data
    @State private var friends: [Friend] = [
        Friend(username: "User2", isOnWalk: true,
               location: CLLocationCoordinate2D(latitude: 26.4605, longitude: -80.0718),
               walkStartTime: Date().addingTimeInterval(-15*60), estimatedDuration: 30),
        Friend(username: "User3", isOnWalk: false, location: nil, walkStartTime: nil, estimatedDuration: nil),
        Friend(username: "User4", isOnWalk: true,
               location: CLLocationCoordinate2D(latitude: 26.4630, longitude: -80.0745),
               walkStartTime: Date().addingTimeInterval(-8*60), estimatedDuration: 20),
        Friend(username: "User5", isOnWalk: false, location: nil, walkStartTime: nil, estimatedDuration: nil),
        Friend(username: "User6", isOnWalk: true,
               location: CLLocationCoordinate2D(latitude: 26.4580, longitude: -80.0695),
               walkStartTime: Date().addingTimeInterval(-22*60), estimatedDuration: 45)
    ]
    
    var friendsOnWalk: [Friend] {
        friends.filter { $0.isOnWalk }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("WalkSoflo User")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Stay safe, walk confident")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Friends on Walk Alert
                    if !friendsOnWalk.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "figure.walk.circle.fill")
                                    .foregroundColor(.green)
                                Text("Friends Walking Now")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(friendsOnWalk.count)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            
                            ForEach(friendsOnWalk) { friend in
                                FriendWalkingCard(friend: friend) {
                                    showingFriendLocation = friend
                                }
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(16)
                    }
                    
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
                    
                    // Friends Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Friends")
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 12) {
                                Button(action: { showingAddFriend = true }) {
                                    Image(systemName: "person.badge.plus")
                                        .foregroundColor(.blue)
                                }
                                Button(action: { showingFriendsList = true }) {
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Text("\(friends.count) friends")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !friendsOnWalk.isEmpty {
                                Text("•")
                                    .foregroundColor(.secondary)
                                
                                Text("\(friendsOnWalk.count) walking")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        // Friend avatars preview
                        HStack(spacing: -8) {
                            ForEach(friends.prefix(5)) { friend in
                                Circle()
                                    .fill(friend.isOnWalk ? Color.green : Color.gray)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String(friend.username.last ?? "U"))
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            }
                            
                            if friends.count > 5 {
                                Circle()
                                    .fill(Color.blue.opacity(0.7))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("+\(friends.count - 5)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                            }
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
                            title: "About WalkSoflo ",
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
            .sheet(isPresented: $showingFriendsList) {
                FriendsListView(friends: $friends)
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(friends: $friends)
            }
            .sheet(item: $showingFriendLocation) { friend in
                FriendLocationView(friend: friend)
            }
        }
    }
}
