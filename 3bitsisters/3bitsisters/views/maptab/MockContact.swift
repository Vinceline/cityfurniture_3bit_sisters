//
//  MockContact.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/20/25.
//


import SwiftUI
import MapKit

struct MockContact: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let phone: String
}

struct MockContactSheet: View {
    let contacts: [MockContact]
    var onSelect: (MockContact) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(contacts) { contact in
                Button {
                    onSelect(contact)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .frame(width: 44, height: 44)
                            .overlay(Text(String(contact.name.prefix(1))).font(.headline))
                            .foregroundColor(.white)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.name)
                                .font(.headline)
                            Text(contact.phone)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Select Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
