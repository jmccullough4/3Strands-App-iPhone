# 3 Strands Cattle Co. — iOS App

A SwiftUI iPhone app for **3 Strands Cattle Co.** that delivers flash sale push notifications for premium Florida-sourced beef.

## Features

- **Flash Sale Feed** — Browse live and upcoming limited-time deals on cuts and bundles
- **Push Notifications** — Sign up to receive alerts the moment a new flash sale drops
- **Notification Preferences** — Choose which cut types and deal categories you care about
- **Sale Detail View** — See pricing, weight, discount %, and per-pound cost at a glance
- **Onboarding Flow** — Three-step welcome that introduces the brand and requests notification permission
- **Pull-to-Refresh** — Refresh the sale feed from the server

## Brand Integration

Colors, typography, and messaging match the [3 Strands website](https://github.com/jmccullough4/3strands-Site):

| Token | Color |
|-------|-------|
| Primary | Saddle Brown `#8B4513` |
| Secondary | Forest Green `#2C5530` |
| Accent | Gold `#D4AF37` |

## Project Structure

```
ThreeStrands/
├── ThreeStrandsApp.swift        # App entry point + AppDelegate for APNs
├── ContentView.swift            # Tab bar root
├── Models/
│   ├── Theme.swift              # Brand colors, fonts, button styles
│   ├── FlashSale.swift          # Sale model, CutType enum, sample data
│   └── SaleStore.swift          # Observable store for sales + preferences
├── Views/
│   ├── OnboardingView.swift     # 3-page onboarding with notification opt-in
│   ├── HomeView.swift           # Hero banner, live sales carousel, quick links
│   ├── FlashSalesView.swift     # Filterable list of all flash sales
│   ├── FlashSaleCard.swift      # Reusable sale card component
│   ├── SaleDetailView.swift     # Full sale detail with order CTA
│   └── SettingsView.swift       # Notification toggles + cut preferences
├── Services/
│   └── NotificationService.swift # APNs registration + local notification scheduling
└── Assets.xcassets/             # App icon, accent color
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. Open `ThreeStrands.xcodeproj` in Xcode
2. Select your team under Signing & Capabilities
3. Build and run on a device (push notifications require a real device)
4. For production APNs, configure your Apple Developer account and backend server

## Push Notification Architecture

The app registers for remote notifications via APNs. In production, the device token should be sent to your backend server which can then push flash sale alerts using Apple's Push Notification service.

For testing, the app includes a local notification scheduler that fires a sample notification after 5 seconds.

---

**Veteran Owned. Faith Driven. Florida Sourced.**
