import Foundation
import CoreLocation
import UserNotifications

// MARK: - Location Service for Event Proximity Alerts

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Radius in meters for proximity alerts
    private let alertRadius: CLLocationDistance = 500

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Permission

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Region Monitoring for Events

    func startMonitoringEvents(_ events: [CattleEvent]) {
        // Clear existing monitored regions
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }

        // Monitor unique locations only (max 20 regions allowed by iOS)
        var seen = Set<String>()
        for event in events {
            let key = "\(event.latitude),\(event.longitude)"
            guard !seen.contains(key) else { continue }
            seen.insert(key)

            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude),
                radius: alertRadius,
                identifier: event.title
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false
            locationManager.startMonitoring(for: region)
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }

        // Check if there's currently an active event at this location
        let now = Date()
        let activeAtLocation = CattleEvent.upcoming.filter { event in
            event.title == circularRegion.identifier &&
            event.date <= now &&
            (event.endDate ?? now) >= now
        }

        if let event = activeAtLocation.first {
            sendProximityNotification(for: event)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationService error: \(error.localizedDescription)")
    }

    // MARK: - Proximity Notification

    private func sendProximityNotification(for event: CattleEvent) {
        let content = UNMutableNotificationContent()
        content.title = "3 Strands Is Nearby!"
        content.body = "We're at \(event.title) right now — stop by and say hello!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "proximity-\(event.title)-\(event.date.timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
