//
//  FriendWalkingCard.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/20/25.
//

import SwiftUI
struct FriendWalkingCard: View {
    let friend: Friend
    let onTapLocation: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .scaleEffect(1.0)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.username)
                    .font(.body)
                    .fontWeight(.medium)
                
                if let walkStart = friend.walkStartTime {
                    let elapsed = Int(Date().timeIntervalSince(walkStart) / 60)
                    Text("Walking for \(elapsed) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("View Location") {
                onTapLocation()
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}
