import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var notificationService: NotificationService
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    // Page 1: Welcome
                    VStack(spacing: 24) {
                        Spacer()

                        Image("Appicon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)

                        Text("Welcome to\n3 Strands Cattle Co.")
                            .font(Theme.heroFont)
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Veteran owned. Faith driven.\nFlorida sourced.")
                            .font(Theme.subheadingFont)
                            .foregroundColor(Theme.primary)
                            .multilineTextAlignment(.center)

                        Text("Premium beef delivered straight from Florida ranches to your door.")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Spacer()
                        Spacer()
                    }
                    .tag(0)

                    // Page 2: Flash Sales
                    onboardingPage(
                        icon: "bolt.fill",
                        iconColor: Theme.gold,
                        title: "Flash Sales",
                        subtitle: "Deals that don't last long.",
                        detail: "Get exclusive access to limited-time offers on premium cuts, bundles, and seasonal specials."
                    )
                    .tag(1)

                    // Page 3: Notifications
                    VStack(spacing: 24) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Theme.primary.opacity(0.1))
                                .frame(width: 120, height: 120)
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Theme.primary)
                        }

                        Text("Never Miss a Deal")
                            .font(Theme.heroFont)
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Enable push notifications to get alerted the moment a flash sale drops.")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Spacer()

                        VStack(spacing: 12) {
                            Button("Enable Notifications") {
                                Task {
                                    let _ = await notificationService.requestAuthorization()
                                    hasCompletedOnboarding = true
                                }
                            }
                            .buttonStyle(BrandButtonStyle(color: Theme.primary))

                            Button("Maybe Later") {
                                hasCompletedOnboarding = true
                            }
                            .buttonStyle(BrandButtonStyle(color: Theme.textSecondary, isOutline: true))
                        }
                        .padding(.horizontal, Theme.screenPadding)
                        .padding(.bottom, 40)
                    }
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                if currentPage < 2 {
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        Text("Next")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                    .fill(Theme.primary)
                            )
                    }
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func onboardingPage(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        detail: String
    ) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(Theme.heroFont)
                .foregroundColor(Theme.primary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(Theme.subheadingFont)
                .foregroundColor(Theme.primary)
                .multilineTextAlignment(.center)

            Text(detail)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}
