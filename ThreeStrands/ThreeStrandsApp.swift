import SwiftUI

@main
struct ThreeStrandsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = SaleStore()
    @StateObject private var notificationService = NotificationService.shared
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false
    @State private var isLaunching = true

    init() {
        // Force light mode and set navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Theme.background)
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Theme.primary)
        ]
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.primary)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(Theme.primary)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isLaunching {
                    LaunchScreenView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    isLaunching = false
                                }
                            }
                        }
                } else if hasCompletedOnboarding {
                    ContentView()
                        .environmentObject(store)
                        .environmentObject(notificationService)
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .environmentObject(notificationService)
                }
            }
            .preferredColorScheme(.light)
            .task {
                await registerDeviceIfNeeded()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh data every time user opens the app
                Task { await store.refreshSales() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .dashboardDidUpdate)) { _ in
                // Refresh when a push notification signals a dashboard update
                Task { await store.refreshSales() }
            }
        }
    }

    private func registerDeviceIfNeeded() async {
        let key = "device_registered"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        do {
            try await APIService.shared.registerDevice(token: deviceId)
            UserDefaults.standard.set(true, forKey: key)
        } catch {
            print("Device registration failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Custom Notification Name

extension Notification.Name {
    static let dashboardDidUpdate = Notification.Name("dashboardDidUpdate")
}

// MARK: - App Delegate for Push Notification Registration

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationService.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // Handle silent push / content-available for background refresh
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Post notification so SwiftUI views refresh
        NotificationCenter.default.post(name: .dashboardDidUpdate, object: nil)
        completionHandler(.newData)
    }

    // Handle foreground notifications — show banner even when app is open
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Refresh data when notification arrives in foreground
        NotificationCenter.default.post(name: .dashboardDidUpdate, object: nil)
        completionHandler([.banner, .badge, .sound])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Refresh data on tap
        NotificationCenter.default.post(name: .dashboardDidUpdate, object: nil)
        completionHandler()
    }
}
