import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var apiService: WalkSafeAPIService
    @Binding var showingSafetyAlert: Bool
    @Binding var currentSafetyPrediction: SafetyPrediction?
    @Binding var selectedRoute: [CLLocationCoordinate2D]
    @Binding var showingRouteAnalysis: Bool
    @Binding var showingDangerZones: Bool
    @Binding var showingRouteOnMap: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none

        let delrayBeach = CLLocationCoordinate2D(latitude: 26.4615, longitude: -80.0728)
        let region = MKCoordinateRegion(center: delrayBeach, latitudinalMeters: 6000, longitudinalMeters: 6000)
        mapView.setRegion(region, animated: false)

        let circle = MKCircle(center: delrayBeach, radius: 4828.03)
        circle.title = "DELREY_BOUNDARY"
        mapView.addOverlay(circle)

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.mapTapped(_:)))
        mapView.addGestureRecognizer(tapGesture)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        if let location = locationManager.currentLocation {
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
            mapView.setRegion(region, animated: true)
        }
        
        context.coordinator.toggleDangerZones(mapView: mapView, show: showingDangerZones)
        context.coordinator.updateRoute(mapView: mapView, route: selectedRoute, showRoute: showingRouteOnMap)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        private var dangerZoneOverlays: [MKOverlay] = []
        private var isDangerZonesVisible = false
        private var routeOverlay: MKOverlay?
        private var routeAnnotations: [MKAnnotation] = []

        init(_ parent: MapView) {
            self.parent = parent
        }

        @objc func mapTapped(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            // check within Delray 3-mile radius
            let delrayCenter = CLLocation(latitude: 26.4615, longitude: -80.0728)
            let tapped = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            if tapped.distance(from: delrayCenter) <= 4828.03 {
                let existing = mapView.annotations.filter { !($0 is MKUserLocation) && $0.title != "Delray Beach Center" && !routeAnnotations.contains(where: { $0.coordinate.latitude == $0.coordinate.latitude && $0.coordinate.longitude == $0.coordinate.longitude }) }
                mapView.removeAnnotations(existing)

                parent.selectedRoute.removeAll()
                parent.selectedRoute.append(coordinate)

                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = "Route Point"
                mapView.addAnnotation(annotation)
            }
        }

        func updateRoute(mapView: MKMapView, route: [CLLocationCoordinate2D], showRoute: Bool) {
            // Remove existing route
            clearRoute(mapView: mapView)
            
            if showRoute && !route.isEmpty {
                displayRoute(mapView: mapView, route: route)
            }
        }
        
        private func clearRoute(mapView: MKMapView) {
            // Remove route overlay
            if let overlay = routeOverlay {
                mapView.removeOverlay(overlay)
                routeOverlay = nil
            }
            
            // Remove route annotations
            mapView.removeAnnotations(routeAnnotations)
            routeAnnotations.removeAll()
        }
        
        private func displayRoute(mapView: MKMapView, route: [CLLocationCoordinate2D]) {
            guard route.count >= 2 else { return }
            
            // Add route annotations for start, waypoints, and end
            addRouteAnnotations(mapView: mapView, route: route)
            
            // Create and add route polyline
            let polyline = MKPolyline(coordinates: route, count: route.count)
            polyline.title = "PLANNED_ROUTE"
            mapView.addOverlay(polyline)
            routeOverlay = polyline
            
            // Zoom to fit the route
            let region = regionThatFits(coordinates: route)
            mapView.setRegion(region, animated: true)
        }
        
        private func addRouteAnnotations(mapView: MKMapView, route: [CLLocationCoordinate2D]) {
            for (index, coordinate) in route.enumerated() {
                // Only add annotations for key points (start, end, and some waypoints)
                let shouldAddAnnotation = index == 0 || index == route.count - 1 || index % 5 == 0
                
                if shouldAddAnnotation {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate
                    
                    if index == 0 {
                        annotation.title = "Start"
                        annotation.subtitle = "Your walking trip begins here"
                    } else if index == route.count - 1 {
                        annotation.title = "Destination"
                        annotation.subtitle = "Your walking trip ends here"
                    } else {
                        annotation.title = "Stop \((index / 5) + 1)"
                        annotation.subtitle = "Waypoint along your route"
                    }
                    
                    mapView.addAnnotation(annotation)
                    routeAnnotations.append(annotation)
                }
            }
        }
        
        private func regionThatFits(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
            guard !coordinates.isEmpty else {
                return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 26.4615, longitude: -80.0728), latitudinalMeters: 2000, longitudinalMeters: 2000)
            }
            
            var minLat = coordinates[0].latitude
            var maxLat = coordinates[0].latitude
            var minLon = coordinates[0].longitude
            var maxLon = coordinates[0].longitude
            
            for coordinate in coordinates {
                minLat = min(minLat, coordinate.latitude)
                maxLat = max(maxLat, coordinate.latitude)
                minLon = min(minLon, coordinate.longitude)
                maxLon = max(maxLon, coordinate.longitude)
            }
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: (maxLat - minLat) * 1.3, // Add 30% padding
                longitudeDelta: (maxLon - minLon) * 1.3
            )
            
            return MKCoordinateRegion(center: center, span: span)
        }

        func toggleDangerZones(mapView: MKMapView, show: Bool) {
            if show && !isDangerZonesVisible {
                addArtificialDangerZones(mapView: mapView)
                isDangerZonesVisible = true
            } else if !show && isDangerZonesVisible {
                removeDangerZones(mapView: mapView)
                isDangerZonesVisible = false
            }
        }
        
        func removeDangerZones(mapView: MKMapView) {
            // Remove only danger zone overlays, keep boundary and route
            let dangerOverlays = mapView.overlays.filter { overlay in
                if let circle = overlay as? MKCircle,
                   let title = circle.title,
                   title.starts(with: "DANGER_ZONE") {
                    return true
                }
                return false
            }
            
            mapView.removeOverlays(dangerOverlays)
            dangerZoneOverlays.removeAll()
        }
        
        func addArtificialDangerZones(mapView: MKMapView) {
            // Remove existing danger zones first
            removeDangerZones(mapView: mapView)
            
            // Define artificial danger hotspots within Delray Beach area
            let artificialHotspots: [(CLLocationCoordinate2D, String, Double)] = [
                // High danger zones (red)
                (CLLocationCoordinate2D(latitude: 26.4590, longitude: -80.0820), "HIGH", 300.0), // Near railroad tracks
                (CLLocationCoordinate2D(latitude: 26.4480, longitude: -80.0650), "HIGH", 250.0), // Industrial area
                (CLLocationCoordinate2D(latitude: 26.4720, longitude: -80.0780), "HIGH", 275.0), // Less lit area
                
                // Medium danger zones (orange)
                (CLLocationCoordinate2D(latitude: 26.4550, longitude: -80.0700), "MEDIUM", 200.0), // Busy intersection
                (CLLocationCoordinate2D(latitude: 26.4640, longitude: -80.0750), "MEDIUM", 180.0), // Parking area
                (CLLocationCoordinate2D(latitude: 26.4420, longitude: -80.0720), "MEDIUM", 220.0), // Construction zone
                (CLLocationCoordinate2D(latitude: 26.4580, longitude: -80.0680), "MEDIUM", 190.0), // Dense commercial
                
                // Low danger zones (yellow)
                (CLLocationCoordinate2D(latitude: 26.4610, longitude: -80.0740), "LOW", 150.0), // Residential transition
                (CLLocationCoordinate2D(latitude: 26.4500, longitude: -80.0760), "LOW", 160.0), // Park edge
                (CLLocationCoordinate2D(latitude: 26.4670, longitude: -80.0710), "LOW", 140.0), // Shopping area edge
                (CLLocationCoordinate2D(latitude: 26.4530, longitude: -80.0800), "LOW", 170.0), // Quiet street
                (CLLocationCoordinate2D(latitude: 26.4680, longitude: -80.0650), "LOW", 155.0), // Residential area
            ]
            
            print("Adding \(artificialHotspots.count) artificial danger zones")
            
            for (coordinate, dangerLevel, radius) in artificialHotspots {
                let circle = MKCircle(center: coordinate, radius: radius)
                
                // Create safety score based on danger level
                let safetyScore: Double
                switch dangerLevel {
                case "HIGH":
                    safetyScore = Double.random(in: 0.15...0.35)
                case "MEDIUM":
                    safetyScore = Double.random(in: 0.35...0.55)
                case "LOW":
                    safetyScore = Double.random(in: 0.55...0.75)
                default:
                    safetyScore = 0.5
                }
                
                circle.title = "DANGER_ZONE|\(safetyScore)|\(dangerLevel)"
                
                mapView.addOverlay(circle, level: .aboveLabels)
                dangerZoneOverlays.append(circle)
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            let id = "RoutePoint"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: id)
                view?.canShowCallout = true
            } else {
                view?.annotation = annotation
            }

            // Customize annotation based on title
            if let title = annotation.title {
                switch title {
                case "Start":
                    view?.image = UIImage(systemName: "location.circle.fill")?
                        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))
                        .withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
                case "Destination":
                    view?.image = UIImage(systemName: "flag.circle.fill")?
                        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))
                        .withTintColor(.systemRed, renderingMode: .alwaysOriginal)
                case let str where str?.starts(with: "Stop") == true:
                    view?.image = UIImage(systemName: "mappin.circle.fill")?
                        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
                        .withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
                default:
                    view?.image = UIImage(systemName: "person.circle.fill")?
                        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
                        .withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
                }
            }

            return view
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline, polyline.title == "PLANNED_ROUTE" {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 4.0
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            
            if let circle = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circle)

                // Boundary circle
                if circle.title == "DELREY_BOUNDARY" || circle.radius > 4000 {
                    renderer.strokeColor = UIColor.blue.withAlphaComponent(0.85)
                    renderer.lineWidth = 2
                    renderer.fillColor = UIColor.clear
                    return renderer
                }

                // Danger zones
                if let title = circle.title, title.starts(with: "DANGER_ZONE") {
                    let components = title.split(separator: "|")
                    
                    if components.count >= 3 {
                        let dangerLevel = String(components[2])
                        
                        switch dangerLevel {
                        case "HIGH":
                            // High danger: Bright red with strong opacity
                            renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.65)
                            renderer.strokeColor = UIColor.systemRed.withAlphaComponent(0.85)
                            renderer.lineWidth = 2.5
                            
                        case "MEDIUM":
                            // Medium danger: Orange with medium opacity
                            renderer.fillColor = UIColor.systemOrange.withAlphaComponent(0.5)
                            renderer.strokeColor = UIColor.systemOrange.withAlphaComponent(0.75)
                            renderer.lineWidth = 2.0
                            
                        case "LOW":
                            // Low danger: Yellow with light opacity
                            renderer.fillColor = UIColor.systemYellow.withAlphaComponent(0.4)
                            renderer.strokeColor = UIColor.systemYellow.withAlphaComponent(0.65)
                            renderer.lineWidth = 1.5
                            
                        default:
                            // Fallback
                            renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.5)
                            renderer.strokeColor = UIColor.systemRed.withAlphaComponent(0.7)
                            renderer.lineWidth = 1.5
                        }
                    } else {
                        // Fallback styling
                        renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.5)
                        renderer.strokeColor = UIColor.systemRed.withAlphaComponent(0.7)
                        renderer.lineWidth = 1.5
                    }
                    
                    return renderer
                }

                renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
                renderer.strokeColor = UIColor.clear
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation, annotation !== mapView.userLocation else { return }

            Task {
                do {
                    let prediction = try await parent.apiService.predictSafety(
                        lat: annotation.coordinate.latitude,
                        lon: annotation.coordinate.longitude
                    )
                    await MainActor.run {
                        parent.currentSafetyPrediction = prediction
                        parent.showingSafetyAlert = true
                    }
                } catch {
                    print("Prediction error: \(error)")
                }
            }
        }
    }
}
