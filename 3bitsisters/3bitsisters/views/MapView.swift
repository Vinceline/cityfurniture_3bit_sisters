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
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        private var dangerZoneOverlays: [MKOverlay] = []
        private var isDangerZonesVisible = false

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
                let existing = mapView.annotations.filter { !($0 is MKUserLocation) && $0.title != "Delray Beach Center" }
                mapView.removeAnnotations(existing)

                parent.selectedRoute.removeAll()
                parent.selectedRoute.append(coordinate)

                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = "Route Point"
                mapView.addAnnotation(annotation)
            }
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
            // Remove only danger zone overlays, keep boundary
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

            if annotation.title == "Route Point" {
                view?.image = UIImage(systemName: "person.circle.fill")?
                    .withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
                    .withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
            }

            return view
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
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
