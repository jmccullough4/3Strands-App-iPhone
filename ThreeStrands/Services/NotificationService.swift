import Foundation
import UserNotifications
import UIKit

// MARK: - Push Notification Service

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var deviceToken: String?
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    override init() {
        super.init()
    }

    // MARK: - Request Permission

    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)

            await MainActor.run {
                self.isAuthorized = granted
            }

            if granted {
                await registerForRemoteNotifications()
            }

            return granted
        } catch {
            print("Notification authorization error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Check Current Status

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
            self.isAuthorized = settings.authorizationStatus == .authorized
        }

        // Re-register if authorized to keep token fresh
        if settings.authorizationStatus == .authorized {
            await registerForRemoteNotifications()
        }
    }

    // MARK: - Ensure Push Registration on Every Launch

    /// Call this on every app launch to guarantee push notifications are set up.
    /// If the user hasn't been asked yet, this prompts them.
    /// If already authorized, it re-registers to keep the APNs token fresh.
    /// If denied, it does nothing (user must change in iOS Settings).
    func ensurePushRegistration() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
            self.isAuthorized = settings.authorizationStatus == .authorized
        }

        switch settings.authorizationStatus {
        case .notDetermined:
            // User hasn't been asked yet — request permission now
            let _ = await requestAuthorization()
        case .authorized, .provisional, .ephemeral:
            // Already authorized — re-register to keep APNs token fresh
            await registerForRemoteNotifications()
        case .denied:
            // User explicitly denied — nothing we can do from code
            print("Push notifications denied by user. They must enable in iOS Settings.")
        @unknown default:
            break
        }
    }

    // MARK: - Register for Remote Notifications

    @MainActor
    private func registerForRemoteNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Handle Device Token from APNs

    func didRegisterForRemoteNotifications(deviceToken data: Data) {
        let token = data.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs Device Token: \(token)")

        Task { @MainActor in
            self.deviceToken = token

            // Send the real APNs token to the dashboard
            do {
                try await APIService.shared.registerDevice(token: token)
                print("APNs token registered with dashboard")
            } catch {
                print("Failed to register APNs token: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Schedule Local Notification (for demo/testing)

    func scheduleTestNotification(sale: String, discount: String) {
        let content = UNMutableNotificationContent()
        content.title = "3 Strands Flash Sale!"
        content.subtitle = sale
        content.body = "Save \(discount) — limited time only! Tap to grab this deal before it's gone."
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
