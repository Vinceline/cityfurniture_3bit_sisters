//
//  Constants.swift
//  3bitsisters
//
//  Created by Vinceline Bertrand on 9/19/25.
//

import Foundation
import SwiftUI

struct Constants {
    // Delray Beach coordinates
    static let delrayBeachCenter = (lat: 26.4615, lon: -80.0728)
    static let coverageRadiusMiles = 3.0
    static let coverageRadiusMeters = 4828.03
    
    // Safety score thresholds
    static let safetyThresholds = (
        verySafe: 0.8,
        safe: 0.6,
        moderate: 0.4,
        risky: 0.2
    )
    
    // Colors
    static let safetyColors = (
        verySafe: Color.green,
        safe: Color.yellow,
        moderate: Color.orange,
        risky: Color.red,
        dangerous: Color.purple
    )
    
    // API Configuration - Updated with your Mac's IP address
    static let apiBaseURL = "http://10.0.0.116:8000"
    static let apiTimeout: TimeInterval = 30.0
    
    // Map Configuration
    static let defaultMapZoom = 2000.0 // meters
    static let heatmapPointRadius = 200.0 // meters
    
    // Incident Types
    static let incidentTypes = [
        "dog": "Unleashed Dog",
        "assault": "Safety Threat",
        "flooding": "Flooding",
        "accident": "Accident",
        "theft": "Theft",
        "other": "Other"
    ]
}

extension Color {
    static func safetyColor(for score: Double) -> Color {
        switch score {
        case Constants.safetyThresholds.verySafe...1.0:
            return Constants.safetyColors.verySafe
        case Constants.safetyThresholds.safe..<Constants.safetyThresholds.verySafe:
            return Constants.safetyColors.safe
        case Constants.safetyThresholds.moderate..<Constants.safetyThresholds.safe:
            return Constants.safetyColors.moderate
        case Constants.safetyThresholds.risky..<Constants.safetyThresholds.moderate:
            return Constants.safetyColors.risky
        default:
            return Constants.safetyColors.dangerous
        }
    }
}
