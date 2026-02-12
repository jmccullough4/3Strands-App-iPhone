import Foundation
import UIKit
import Security

// MARK: - API Service for Dashboard Backend

@MainActor
class APIService {
    static let shared = APIService()

    var dashboardURL: String {
        #if DEBUG
        return UserDefaults.standard.string(forKey: "api_base_url") ?? "https://dashboard.3strands.co"
        #else
        return "https://dashboard.3strands.co"
        #endif
    }

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Flash Sales (from dashboard — snake_case JSON)

    func fetchFlashSales() async throws -> [FlashSale] {
        let url = URL(string: "\(dashboardURL)/api/public/flash-sales")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
        #if DEBUG
        print("Flash sales raw: \(String(data: data, encoding: .utf8) ?? "nil")")
        #endif
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let apiSales = try decoder.decode([APIFlashSale].self, from: data)
        return apiSales.map { $0.toFlashSale() }
    }

    // MARK: - Catalog / Menu (direct from Square API)

    func fetchCatalog() async throws -> [CatalogItem] {
        // Use SquareService for direct Square API access
        return try await SquareService.shared.fetchCatalog()
    }

    // MARK: - Pop-Up Markets (from dashboard — snake_case JSON)

    func fetchPopUpMarkets() async throws -> [PopUpSale] {
        let url = URL(string: "\(dashboardURL)/api/public/pop-up-markets")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
        #if DEBUG
        print("Pop-up sales raw: \(String(data: data, encoding: .utf8) ?? "nil")")
        #endif
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([PopUpSale].self, from: data)
    }

    // MARK: - Announcements (from dashboard — snake_case JSON)

    func fetchAnnouncements() async throws -> [Announcement] {
        let url = URL(string: "\(dashboardURL)/api/public/announcements")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
        #if DEBUG
        print("Announcements raw: \(String(data: data, encoding: .utf8) ?? "nil")")
        #endif
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([Announcement].self, from: data)
    }

    // MARK: - Events (from dashboard — snake_case JSON)

    func fetchEvents() async throws -> [CattleEvent] {
        let url = URL(string: "\(dashboardURL)/api/public/events")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
        #if DEBUG
        print("Events raw: \(String(data: data, encoding: .utf8) ?? "nil")")
        #endif
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let apiEvents = try decoder.decode([APIEvent].self, from: data)
        return apiEvents.map { $0.toCattleEvent() }
    }

    // MARK: - Device Registration (to dashboard)

    func registerDevice(token: String) async throws {
        let url = URL(string: "\(dashboardURL)/api/public/register-device")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // APNs key is configured for Production only in Apple Developer Portal
        // Always use production environment regardless of build type
        let apnsEnvironment = "production"

        let body: [String: String] = [
            "token": token,
            "platform": "ios",
            "device_id": DeviceIdentifier.persistentID,
            "device_name": DeviceIdentifier.deviceName,
            "os_version": DeviceIdentifier.osVersion,
            "app_version": DeviceIdentifier.appVersion,
            "device_model": DeviceIdentifier.deviceModel,
            "locale": DeviceIdentifier.locale,
            "timezone": DeviceIdentifier.timezone,
            "apns_environment": apnsEnvironment
        ]
        request.httpBody = try JSONEncoder().encode(body)
        #if DEBUG
        print("Register device request: token=\(token.prefix(20))..., device_id=\(DeviceIdentifier.persistentID), device_name=\(DeviceIdentifier.deviceName)")
        #endif
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse {
            #if DEBUG
            let responseBody = String(data: data, encoding: .utf8) ?? "nil"
            print("Register device response: \(http.statusCode) - \(responseBody)")
            #endif
            guard http.statusCode == 200 else {
                throw APIError.serverError
            }
        } else {
            throw APIError.serverError
        }
    }
}

// MARK: - API Error

enum APIError: LocalizedError {
    case serverError
    case decodingError
    case catalogNotConfigured

    var errorDescription: String? {
        switch self {
        case .serverError: return "Unable to reach the server. Please try again."
        case .decodingError: return "Unexpected response from server."
        case .catalogNotConfigured: return "Menu is being set up. Check back soon!"
        }
    }
}

// MARK: - Flash Sale API Model
// Dashboard sends snake_case: id (int), title, description, cut_type,
// original_price, sale_price, weight_lbs, image_system_name, is_active, starts_at, expires_at

struct APIFlashSale: Codable {
    let id: Int
    let title: String
    let description: String
    let cutType: String
    let originalPrice: Double
    let salePrice: Double
    let weightLbs: Double
    let startsAt: String?
    let expiresAt: String?
    let imageSystemName: String
    let isActive: Bool

    func toFlashSale() -> FlashSale {
        // Dashboard stores times as entered (local time) without timezone info.
        // Parse bare timestamps as local timezone so expiration logic works correctly.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = .current

        // Also handle fractional seconds (e.g. created_at has microseconds)
        let fractionalFormatter = DateFormatter()
        fractionalFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        fractionalFormatter.timeZone = .current

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        func parseDate(_ s: String?) -> Date? {
            guard let s else { return nil }
            return formatter.date(from: s)
                ?? fractionalFormatter.date(from: s)
                ?? iso.date(from: s)
        }

        return FlashSale(
            id: String(id),
            title: title,
            description: description,
            cutType: CutType(rawValue: cutType) ?? .custom,
            originalPrice: originalPrice,
            salePrice: salePrice,
            weightLbs: weightLbs,
            startsAt: parseDate(startsAt) ?? Date(),
            expiresAt: parseDate(expiresAt) ?? Date().addingTimeInterval(86400),
            imageSystemName: imageSystemName,
            isActive: isActive
        )
    }
}

// MARK: - Catalog API Models (used by SquareService)

struct CatalogItem: Identifiable {
    let id: String
    let name: String
    let description: String?
    let category: String?
    var variations: [CatalogVariation]

    var lowestPrice: Int? {
        variations.compactMap { $0.priceMoney?.amount }.min()
    }

    /// Whether any variation has inventory tracking enabled
    var hasInventoryTracking: Bool {
        variations.contains { $0.quantity != nil }
    }

    /// Total quantity across all tracked variations
    var totalQuantity: Double? {
        guard hasInventoryTracking else { return nil }
        return variations.compactMap { $0.quantity }.reduce(0, +)
    }

    var isSoldOut: Bool {
        // Only sold out if inventory is tracked AND all tracked variations have qty <= 0
        guard hasInventoryTracking else { return false }
        return variations.filter { $0.quantity != nil }.allSatisfy { $0.quantity! <= 0 }
    }

    var isLowStock: Bool {
        // Low stock if tracked and total quantity is between 1 and 5
        guard let qty = totalQuantity else { return false }
        return qty > 0 && qty <= 5
    }

    var formattedPrice: String {
        guard let cents = lowestPrice, cents > 0 else { return "Market Price" }
        let dollars = Double(cents) / 100.0
        if variations.count > 1 {
            return String(format: "From $%.2f", dollars)
        }
        return String(format: "$%.2f", dollars)
    }
}

struct CatalogVariation: Identifiable {
    let id: String
    let name: String
    let priceMoney: PriceMoney?
    let pricingType: String?
    var quantity: Double?

    /// Only sold out if inventory is tracked (quantity != nil) AND qty <= 0
    var isSoldOut: Bool {
        guard let qty = quantity else { return false }
        return qty <= 0
    }

    var formattedPrice: String {
        guard let cents = priceMoney?.amount else { return "Market Price" }
        return String(format: "$%.2f", Double(cents) / 100.0)
    }
}

struct PriceMoney: Codable {
    let amount: Int
    let currency: String
}

// MARK: - Pop-Up Sale Model
// Dashboard sends snake_case: id (int), title, description, address,
// latitude, longitude, starts_at, ends_at, is_active

struct PopUpSale: Identifiable, Codable {
    let id: Int
    let title: String
    let description: String?
    let address: String?
    let latitude: Double
    let longitude: Double
    let startsAt: String?
    let endsAt: String?
    let isActive: Bool

    var stringId: String { String(id) }
}

// MARK: - Announcement Model
// Dashboard sends snake_case: id (int), title, message, created_at, is_active

struct Announcement: Identifiable, Codable {
    let id: Int
    let title: String
    let message: String
    let createdAt: String?
    let isActive: Bool

    var formattedDate: String? {
        guard let createdAt else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = .current

        let fractionalFormatter = DateFormatter()
        fractionalFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        fractionalFormatter.timeZone = .current

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        let date = formatter.date(from: createdAt)
            ?? fractionalFormatter.date(from: createdAt)
            ?? iso.date(from: createdAt)

        guard let date else { return nil }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }
}

// MARK: - Event API Model
// Dashboard sends snake_case: id (int), title, description, location,
// latitude, longitude, start_date, end_date, icon, is_active

struct APIEvent: Codable {
    let id: Int
    let title: String
    let description: String?
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let startDate: String?
    let endDate: String?
    let icon: String?
    let isActive: Bool
    let isPopup: Bool?

    func toCattleEvent() -> CattleEvent {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = .current

        let fractionalFormatter = DateFormatter()
        fractionalFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        fractionalFormatter.timeZone = .current

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        func parseDate(_ s: String?) -> Date? {
            guard let s else { return nil }
            return formatter.date(from: s)
                ?? fractionalFormatter.date(from: s)
                ?? iso.date(from: s)
        }

        return CattleEvent(
            id: id,
            title: title,
            date: parseDate(startDate) ?? Date(),
            endDate: parseDate(endDate),
            location: location ?? "",
            latitude: latitude ?? 0,
            longitude: longitude ?? 0,
            icon: icon ?? "calendar.fill",
            isPopup: isPopup ?? false
        )
    }
}

// MARK: - Persistent Device Identifier

enum DeviceIdentifier {
    private static let keychainKey = "com.threestrandscattle.app.device-id"

    /// A persistent UUID that survives app reinstalls (stored in Keychain)
    static var persistentID: String {
        if let existing = readFromKeychain() {
            return existing
        }
        let newID = UUID().uuidString
        saveToKeychain(newID)
        return newID
    }

    /// Human-readable device name (e.g. "John's iPhone 15")
    static var deviceName: String {
        UIDevice.current.name
    }

    /// OS version string (e.g. "17.2")
    static var osVersion: String {
        UIDevice.current.systemVersion
    }

    /// App version from bundle (e.g. "1.3.0")
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    /// Hardware model identifier (e.g. "iPhone15,2")
    static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
    }

    /// User locale identifier (e.g. "en_US")
    static var locale: String {
        Locale.current.identifier
    }

    /// User timezone identifier (e.g. "America/New_York")
    static var timezone: String {
        TimeZone.current.identifier
    }

    private static func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func saveToKeychain(_ value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainKey,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
}
