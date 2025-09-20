//
//  FriendLocationView.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/20/25.
//

import SwiftUI
import MapKit
struct FriendLocationView: View {
    let friend: Friend
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if let location = friend.location {
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: location,
                        latitudinalMeters: 1000,
                        longitudinalMeters: 1000
                    )), annotationItems: [friend]) { friend in
                        MapAnnotation(coordinate: location) {
                            VStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                    )
                                Text(friend.username)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.7))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(height: 300)
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("\(friend.username) is walking")
                                .font(.headline)
                            Spacer()
                        }
                        
                        if let walkStart = friend.walkStartTime {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                                Text("Started \(timeAgo(from: walkStart)) ago")
                                Spacer()
                            }
                        }
                        
                        if let duration = friend.estimatedDuration {
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.orange)
                                Text("Estimated \(duration) min walk")
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("\(friend.username)'s Location")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        return "\(minutes) min"
    }
}
