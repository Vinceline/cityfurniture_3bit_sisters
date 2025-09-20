//
//  AddFriendView.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/20/25.
//

import SwiftUI
import MapKit
struct AddFriendView: View {
    @Binding var friends: [Friend]
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    
    private let suggestedUsers = ["User7", "User8", "User9", "User10", "SafeWalker1", "CityExplorer"]
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                
                List {
                    Section("Suggested Users") {
                        ForEach(suggestedUsers, id: \.self) { username in
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String(username.last ?? "U"))
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                                
                                Text(username)
                                    .font(.body)
                                
                                Spacer()
                                
                                Button("Add") {
                                    addFriend(username: username)
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func addFriend(username: String) {
        let newFriend = Friend(
            username: username,
            isOnWalk: Bool.random(),
            location: Bool.random() ? CLLocationCoordinate2D(
                latitude: 26.4615 + Double.random(in: -0.01...0.01),
                longitude: -80.0728 + Double.random(in: -0.01...0.01)
            ) : nil,
            walkStartTime: Bool.random() ? Date().addingTimeInterval(-Double.random(in: 0...3600)) : nil,
            estimatedDuration: Bool.random() ? Int.random(in: 15...60) : nil
        )
        friends.append(newFriend)
    }
}
