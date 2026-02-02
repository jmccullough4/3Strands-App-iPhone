import Foundation
import UIKit
import Security

// MARK: - API Service for Dashboard Backend

@MainActor
class APIService {
    static let shared = APIService()

    var dashboardURL: String {
        UserDefaults.standard.string(forKey: "api_base_url") ?? "https://dashboard.3strands.co"
    }

    let websiteURL = "https://3strands.co"

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
        print("Flash sales raw: \(String(data: data, encoding: .utf8) ?? "nil")")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let apiSales = try decoder.decode([APIFlashSale].self, from: data)
        return apiSales.map { $0.toFlashSale() }
    }

    // MARK: - Catalog / Menu (from main website — camelCase JSON)

    func fetchCatalog() async throws -> [CatalogItem] {
        let url = URL(string: "\(websiteURL)/api/catalog")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
        print("Catalog raw (first 500): \(String(data: data.prefix(500), encoding: .utf8) ?? "nil")")
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(CatalogResponse.self, from: data)
        return wrapper.items
    }

    // MARK: - Pop-Up Sales (from dashboard — snake_case JSON)

    func fetchPopUpSales() async throws -> [PopUpSale] {
        let url = URL(string: "\(dashboardURL)/api/public/pop-up-sales")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
        print("Pop-up sales raw: \(String(data: data, encoding: .utf8) ?? "nil")")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([PopUpSale].self, from: data)
    }

    // MARK: - Device Registration (to dashboard)

    func registerDevice(token: String) async throws {
        let url = URL(string: "\(dashboardURL)/api/public/register-device")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "token": token,
            "platform": "ios",
            "device_id": DeviceIdentifier.persistentID,
            "device_name": DeviceIdentifier.deviceName
        ]
        request.httpBody = try JSONEncoder().encode(body)
        print("Register device request: token=\(token.prefix(20))..., device_id=\(DeviceIdentifier.persistentID), device_name=\(DeviceIdentifier.deviceName)")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse {
            let responseBody = String(data: data, encoding: .utf8) ?? "nil"
            print("Register device response: \(http.statusCode) - \(responseBody)")
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

// MARK: - Catalog API Models
// Website 3strands.co/api/catalog sends camelCase:
// {items: [{id, name, description, category, variations: [{id, name, priceMoney: {amount, currency}, pricingType}]}]}

struct CatalogResponse: Codable {
    let items: [CatalogItem]
}

struct CatalogItem: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let category: String?
    let variations: [CatalogVariation]

    var lowestPrice: Int? {
        variations.compactMap { $0.priceMoney?.amount }.min()
    }

    var isSoldOut: Bool {
        // All variations have no price or zero price
        let prices = variations.compactMap { $0.priceMoney?.amount }
        return prices.isEmpty || prices.allSatisfy { $0 == 0 }
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

struct CatalogVariation: Identifiable, Codable {
    let id: String
    let name: String
    let priceMoney: PriceMoney?
    let pricingType: String?

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
