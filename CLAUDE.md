# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

3 Strands Cattle Co. iOS app - a SwiftUI application for flash sale push notifications for premium Florida-sourced beef. Requires iOS 17.0+, Xcode 15.0+, Swift 5.9+.

## Build & Run

```bash
# Open project in Xcode
open ThreeStrands.xcodeproj

# Build from command line
xcodebuild -project ThreeStrands.xcodeproj -scheme ThreeStrands -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15'
```

Push notifications require a physical device - simulator testing is limited.

## Architecture

**Pattern**: MVVM with SwiftUI Observation

- **Models/** - Data models (`FlashSale`, `CutType` enum, `NotificationPreferences`, `InboxItem`) and `SaleStore` (central `@Observable` state container)
- **Views/** - SwiftUI components using `@EnvironmentObject` for state access
- **Services/** - `APIService` (singleton for API calls) and `NotificationService` (APNs handling)

**State Management**: `SaleStore` is the single source of truth, persisting preferences and inbox to UserDefaults. Published properties trigger reactive UI updates.

**Navigation**: Tab-based (6 tabs: Home, Menu, Flash Sales, Inbox, Events, Settings) with `NavigationStack`.

## Key Implementation Details

**Push Notifications**:
- Always uses production APNs environment regardless of build type
- Device token persisted in UserDefaults and Keychain
- Token re-registered on every app launch
- Background task ID: `com.threestrandscattle.app.refresh`

**API Endpoints**:
- Dashboard: `https://dashboard.3strands.co` (snake_case JSON)
- Website: `https://3strands.co` (camelCase JSON)
- `APIService` handles both JSON formats with flexible date parsing

**Background Tasks**:
- 30-second polling timer while app is active
- `BGAppRefresh` for background content checks
- Local notifications created for announcements detected during background refresh

**Device Identification**: Persistent UUID stored in Keychain (service: `com.threestrandscattle.app.device-id`)

## Theme System

Brand colors defined in `Models/Theme.swift`:
- Primary: Saddle Brown `#8B4513`
- Secondary: Forest Green `#2C5530`
- Accent: Gold `#D4AF37`

Use `Theme.saddleBrown`, `Theme.forestGreen`, `Theme.gold` for consistency. Corner radius: 14pt, screen padding: 20pt.

## Testing Notifications

No automated test suite. For manual notification testing, use `notificationService.scheduleTestNotification()` which fires a sample notification after 5 seconds.

## No External Dependencies

Pure Swift/native frameworks only - no CocoaPods, SPM packages, or third-party libraries.
