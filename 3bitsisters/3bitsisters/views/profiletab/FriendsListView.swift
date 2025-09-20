//
//  FriendsListView.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/20/25.
//

import SwiftUI
struct FriendsListView: View {
    @Binding var friends: [Friend]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(friends) { friend in
                    HStack {
                        Circle()
                            .fill(friend.isOnWalk ? Color.green : Color.gray)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(friend.username.last ?? "U"))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(friend.username)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text(friend.isOnWalk ? "Currently walking" : "Offline")
                                .font(.caption)
                                .foregroundColor(friend.isOnWalk ? .green : .secondary)
                        }
                        
                        Spacer()
                        
                        if friend.isOnWalk {
                            Image(systemName: "location.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
