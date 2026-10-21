import Foundation
import CoreLocation
import Combine

final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    private let manager = CLLocationManager()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var insideRegionIds: Set<String> = []

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorization() { manager.requestAlwaysAuthorization() }
    func startUpdating() { manager.startUpdatingLocation() }

    func startMonitoring(id: String, latitude: Double, longitude: Double, radius: Double) {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let r = min(radius, manager.maximumRegionMonitoringDistance)
        let region = CLCircularRegion(center: center, radius: r, identifier: id)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        manager.startMonitoring(for: region)
        manager.requestState(for: region)
    }

    func stopMonitoring(id: String) {
        manager.monitoredRegions
            .filter { $0.identifier == id }
            .forEach { manager.stopMonitoring(for: $0) }
    }

    func isInside(id: String) -> Bool { insideRegionIds.contains(id) }

    func distance(to latitude: Double, longitude: Double) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        return current.distance(from: CLLocation(latitude: latitude, longitude: longitude))
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        insideRegionIds.insert(region.identifier)
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        insideRegionIds.remove(region.identifier)
    }
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if state == .inside { insideRegionIds.insert(region.identifier) }
        else { insideRegionIds.remove(region.identifier) }
    }
}
