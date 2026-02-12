import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: SaleStore
    @EnvironmentObject var notificationService: NotificationService
    @State private var showTestAlert = false

    var body: some View {
        NavigationStack {
            List {
                // Notification Status
                Section {
                    HStack {
                        Image(systemName: notificationService.isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                            .font(.system(size: 22))
                            .foregroundColor(notificationService.isAuthorized ? Theme.bronze : Theme.textSecondary)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Push Notifications")
                                .font(.system(size: 15, weight: .medium))
                            Text(notificationService.isAuthorized ? "Enabled" : "Disabled")
                                .font(Theme.captionFont)
                                .foregroundColor(notificationService.isAuthorized ? Theme.bronze : Theme.textSecondary)
                        }

                        Spacer()

                        if !notificationService.isAuthorized {
                            Button("Enable") {
                                Task {
                                    let _ = await notificationService.requestAuthorization()
                                }
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Theme.primary))
                        }
                    }
                } header: {
                    Text("Notification Status")
                }

                // Notification Preferences
                Section {
                    Toggle(isOn: $store.notificationPrefs.flashSalesEnabled) {
                        settingsRow(icon: "bolt.fill", title: "Flash Sales", color: Theme.bronzeGold)
                    }
                    Toggle(isOn: $store.notificationPrefs.priceDropsEnabled) {
                        settingsRow(icon: "arrow.down.circle.fill", title: "Price Drops", color: Theme.bronze)
                    }
                    Toggle(isOn: $store.notificationPrefs.newArrivalsEnabled) {
                        settingsRow(icon: "sparkles", title: "New Arrivals", color: Theme.primary)
                    }
                    Toggle(isOn: $store.notificationPrefs.weeklyDealsEnabled) {
                        settingsRow(icon: "calendar.badge.clock", title: "Weekly Deals", color: .blue)
                    }
                } header: {
                    Text("Notification Types")
                } footer: {
                    Text("Choose which notifications you'd like to receive from 3 Strands Cattle Co.")
                }
                .onChange(of: store.notificationPrefs.flashSalesEnabled) { _, _ in store.savePreferences() }
                .onChange(of: store.notificationPrefs.priceDropsEnabled) { _, _ in store.savePreferences() }
                .onChange(of: store.notificationPrefs.newArrivalsEnabled) { _, _ in store.savePreferences() }
                .onChange(of: store.notificationPrefs.weeklyDealsEnabled) { _, _ in store.savePreferences() }

                // Preferred Cuts
                Section {
                    ForEach(CutType.allCases, id: \.self) { cut in
                        Toggle(isOn: Binding(
                            get: { store.notificationPrefs.preferredCuts.contains(cut) },
                            set: { isOn in
                                if isOn {
                                    store.notificationPrefs.preferredCuts.insert(cut)
                                } else {
                                    store.notificationPrefs.preferredCuts.remove(cut)
                                }
                                store.savePreferences()
                            }
                        )) {
                            Text("\(cut.emoji)  \(cut.rawValue)")
                                .font(.system(size: 15))
                        }
                    }
                } header: {
                    Text("Preferred Cuts")
                } footer: {
                    Text("Only get notified about flash sales for cuts you care about.")
                }

                #if DEBUG
                // Test notification — hidden in release builds
                Section {
                    Button {
                        notificationService.scheduleTestNotification(
                            sale: "Test Flash Sale",
                            discount: "25%"
                        )
                        showTestAlert = true
                    } label: {
                        settingsRow(icon: "paperplane.fill", title: "Send Test Notification", color: Theme.primary)
                    }
                } header: {
                    Text("Testing")
                }
                #endif

                // About
                Section {
                    HStack {
                        settingsRow(icon: "info.circle.fill", title: "Version", color: Theme.textSecondary)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                    HStack {
                        settingsRow(icon: "globe", title: "Website", color: Theme.bronze)
                        Spacer()
                        Text("3strandsbeef.com")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("3 Strands Cattle Co. — Veteran owned. Faith driven. Florida sourced.")
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
            }
            .tint(Theme.primary)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primary)
                }
            }
            .alert("Test Sent!", isPresented: $showTestAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("A test notification will appear in ~5 seconds.")
            }
            .task {
                await notificationService.checkAuthorizationStatus()
            }
        }
    }

    private func settingsRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 15))
        }
    }
}
