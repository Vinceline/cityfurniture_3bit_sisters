//
//  SearchBar.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/20/25.
//

import SwiftUI
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search users...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
