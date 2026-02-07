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

    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

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
                // Ensure push notifications are set up on every launch.
                // If user tapped "Maybe Later" during onboarding, this will prompt them.
                // If already authorized, this re-registers to keep the APNs token fresh.
                await notificationService.ensurePushRegistration()
            }
            .onReceive(refreshTimer) { _ in
                // Poll every 30 seconds for live updates
                Task { await store.refreshSales() }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh data every time user opens the app
                Task { await store.refreshSales() }
                // Re-register for push to keep APNs token fresh
                Task { await notificationService.ensurePushRegistration() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .dashboardDidUpdate)) { notification in
                // Refresh when a push notification signals a dashboard update
                Task { await store.refreshSales() }

                // Save to inbox if notification has alert content
                if let userInfo = notification.userInfo,
                   let aps = userInfo["aps"] as? [String: Any],
                   let alert = aps["alert"] as? [String: Any],
                   let title = alert["title"] as? String,
                   let body = alert["body"] as? String {
                    store.addInboxItem(title: title, body: body)
                }
            }
        }
    }

    private func registerDeviceIfNeeded() async {
        // Use the persistent Keychain device ID as the token for initial registration.
        // The real APNs token is sent separately via NotificationService when push is authorized.
        let deviceId = DeviceIdentifier.persistentID
        do {
            try await APIService.shared.registerDevice(token: deviceId)
            print("Device registered with persistent ID: \(deviceId)")
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
        // Post notification so SwiftUI views refresh (flash sales, pop-ups, and announcements)
        NotificationCenter.default.post(name: .dashboardDidUpdate, object: nil, userInfo: userInfo)
        completionHandler(.newData)
    }

    // Handle foreground notifications — show banner even when app is open
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        // Refresh data when notification arrives in foreground
        NotificationCenter.default.post(name: .dashboardDidUpdate, object: nil, userInfo: userInfo)
        completionHandler([.banner, .list, .badge, .sound])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        // Refresh data on tap
        NotificationCenter.default.post(name: .dashboardDidUpdate, object: nil, userInfo: userInfo)
        completionHandler()
    }
}
