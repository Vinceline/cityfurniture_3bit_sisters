//
//  Friend.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/20/25.
//

import Foundation
import MapKit
struct Friend: Identifiable {
    let id = UUID()
    let username: String
    let isOnWalk: Bool
    let location: CLLocationCoordinate2D?
    let walkStartTime: Date?
    let estimatedDuration: Int? // minutes
}
