import Foundation

// MARK: - Flash Sale Model

struct FlashSale: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let cutType: CutType
    let originalPrice: Double
    let salePrice: Double
    let weightLbs: Double
    let startsAt: Date
    let expiresAt: Date
    let imageSystemName: String
    let isActive: Bool

    var discountPercent: Int {
        guard originalPrice > 0 else { return 0 }
        return Int(((originalPrice - salePrice) / originalPrice) * 100)
    }

    var timeRemaining: String {
        let now = Date()
        guard expiresAt > now else { return "Expired" }
        let interval = expiresAt.timeIntervalSince(now)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        }
        return "\(minutes)m left"
    }

    var isExpired: Bool {
        Date() >= expiresAt
    }

    var formattedOriginalPrice: String {
        String(format: "$%.2f", originalPrice)
    }

    var formattedSalePrice: String {
        String(format: "$%.2f", salePrice)
    }

    var pricePerLb: String {
        String(format: "$%.2f/lb", salePrice / weightLbs)
    }
}

// MARK: - Cut Types matching 3 Strands product catalog

enum CutType: String, Codable, CaseIterable {
    case ribeye = "Ribeye"
    case nyStrip = "NY Strip"
    case filetMignon = "Filet Mignon"
    case sirloin = "Sirloin"
    case groundBeef = "Ground Beef"
    case brisket = "Brisket"
    case roast = "Chuck Roast"
    case tBone = "T-Bone"
    case bundle = "Bundle"
    case custom = "Custom Box"

    var emoji: String {
        switch self {
        case .ribeye, .nyStrip, .filetMignon, .tBone, .sirloin:
            return "🥩"
        case .groundBeef:
            return "🍔"
        case .brisket, .roast:
            return "🫕"
        case .bundle, .custom:
            return "📦"
        }
    }
}

// MARK: - Notification Preferences

struct NotificationPreferences: Codable {
    var flashSalesEnabled: Bool = true
    var priceDropsEnabled: Bool = true
    var newArrivalsEnabled: Bool = false
    var weeklyDealsEnabled: Bool = true
    var preferredCuts: Set<CutType> = Set(CutType.allCases)

    static let storageKey = "notification_preferences"
}

// MARK: - Sample Data

extension FlashSale {
    static let samples: [FlashSale] = [
        FlashSale(
            id: "sample-1",
            title: "Weekend Ribeye Blowout",
            description: "Premium Florida-raised ribeye steaks, hand-cut and dry-aged 21 days. Perfect marbling for the grill. Limited supply from our latest harvest.",
            cutType: .ribeye,
            originalPrice: 54.99,
            salePrice: 38.99,
            weightLbs: 2.0,
            startsAt: Date(),
            expiresAt: Date().addingTimeInterval(7200),
            imageSystemName: "flame.fill",
            isActive: true
        ),
        FlashSale(
            id: "sample-2",
            title: "Family Essentials Bundle",
            description: "Our most popular family pack: 2lb ground beef, 2 NY strips, 1 chuck roast, and 1lb stew meat. Feeds a family of 4 for a week. Florida sourced, veteran approved.",
            cutType: .bundle,
            originalPrice: 129.99,
            salePrice: 89.99,
            weightLbs: 8.0,
            startsAt: Date(),
            expiresAt: Date().addingTimeInterval(14400),
            imageSystemName: "shippingbox.fill",
            isActive: true
        ),
        FlashSale(
            id: "sample-3",
            title: "Grillmaster's NY Strip",
            description: "Thick-cut New York strips, perfect 1.25\" thickness. Sourced from our Florida partner ranches. Faith driven quality you can taste.",
            cutType: .nyStrip,
            originalPrice: 44.99,
            salePrice: 32.99,
            weightLbs: 1.5,
            startsAt: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            imageSystemName: "frying.pan.fill",
            isActive: true
        ),
        FlashSale(
            id: "sample-4",
            title: "Brisket — Low & Slow Special",
            description: "Whole packer brisket, untrimmed. Perfect for smoking. From Florida cattle raised on open pasture. Veteran owned quality.",
            cutType: .brisket,
            originalPrice: 89.99,
            salePrice: 64.99,
            weightLbs: 12.0,
            startsAt: Date().addingTimeInterval(-7200),
            expiresAt: Date().addingTimeInterval(1800),
            imageSystemName: "thermometer.sun.fill",
            isActive: true
        ),
        FlashSale(
            id: "sample-5",
            title: "Ground Beef — Bulk Buy",
            description: "80/20 ground beef in 1lb packs. Stock your freezer at an unbeatable price. Always fresh, never frozen until packed.",
            cutType: .groundBeef,
            originalPrice: 8.99,
            salePrice: 5.99,
            weightLbs: 1.0,
            startsAt: Date().addingTimeInterval(-86400),
            expiresAt: Date().addingTimeInterval(-3600),
            imageSystemName: "cart.fill",
            isActive: false
        ),
    ]
}
