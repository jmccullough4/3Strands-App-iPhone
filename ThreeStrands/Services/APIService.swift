import Foundation

// MARK: - API Service for Dashboard Backend

@MainActor
class APIService {
    static let shared = APIService()

    // Base URL for the dashboard backend - update this to your server's address
    var baseURL: String {
        UserDefaults.standard.string(forKey: "api_base_url") ?? "https://dashboard.3strands.co"
    }

    private let session: URLSession
    private let decoder: JSONDecoder

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    // MARK: - Flash Sales

    func fetchFlashSales() async throws -> [FlashSale] {
        let url = URL(string: "\(baseURL)/api/public/flash-sales")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
        let apiSales = try decoder.decode([APIFlashSale].self, from: data)
        return apiSales.map { $0.toFlashSale() }
    }

    // MARK: - Catalog / Menu

    func fetchCatalog() async throws -> [CatalogItem] {
        let url = URL(string: "\(baseURL)/api/public/catalog")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
        // Dashboard returns {"error": "..."} when Square isn't configured
        if let errorResp = try? decoder.decode(APIErrorResponse.self, from: data), errorResp.error != nil {
            throw APIError.catalogNotConfigured
        }
        let wrapper = try decoder.decode(CatalogResponse.self, from: data)
        return wrapper.groupedItems
    }

    // MARK: - Pop-Up Sales

    func fetchPopUpSales() async throws -> [PopUpSale] {
        let url = URL(string: "\(baseURL)/api/public/pop-up-sales")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
        return try decoder.decode([PopUpSale].self, from: data)
    }

    // MARK: - Device Registration

    func registerDevice(token: String) async throws {
        let url = URL(string: "\(baseURL)/api/public/register-device")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["token": token, "platform": "ios"]
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
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

struct APIErrorResponse: Codable {
    let error: String?
}

// MARK: - Flash Sale API Model
// Dashboard sends camelCase keys: id (string), title, description, cutType,
// originalPrice, salePrice, weightLbs, imageSystemName, isActive, startsAt, expiresAt, createdAt

struct APIFlashSale: Codable {
    let id: String
    let title: String
    let description: String?
    let cutType: String
    let originalPrice: Double
    let salePrice: Double
    let weightLbs: Double
    let startsAt: String?
    let expiresAt: String?
    let imageSystemName: String
    let isActive: Bool

    func toFlashSale() -> FlashSale {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let iso2 = ISO8601DateFormatter()
        iso2.formatOptions = [.withInternetDateTime]

        func parseDate(_ s: String?) -> Date? {
            guard let s else { return nil }
            return iso.date(from: s) ?? iso2.date(from: s)
        }

        return FlashSale(
            id: id,
            title: title,
            description: description ?? "",
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
// Dashboard sends: {"items": [...], "count": N}
// Each item is flat: {id, variationId, name, variationName, description, price, priceCurrency, category, isAvailable}

struct CatalogResponse: Codable {
    let items: [APICatalogItem]
    let count: Int?

    /// Group flat variation rows into CatalogItems
    var groupedItems: [CatalogItem] {
        var dict: [String: CatalogItem] = [:]
        var order: [String] = []

        for item in items {
            let variation = CatalogVariation(
                id: item.variationId,
                name: item.variationName,
                priceCents: Int(item.price * 100)
            )

            if var existing = dict[item.id] {
                existing.variations.append(variation)
                dict[item.id] = existing
            } else {
                order.append(item.id)
                dict[item.id] = CatalogItem(
                    id: item.id,
                    name: item.name,
                    description: item.description,
                    category: item.category,
                    variations: [variation]
                )
            }
        }

        return order.compactMap { dict[$0] }
    }
}

struct APICatalogItem: Codable {
    let id: String
    let variationId: String
    let name: String
    let variationName: String
    let description: String?
    let price: Double
    let priceCurrency: String?
    let category: String?
    let isAvailable: Bool?
}

struct CatalogItem: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let category: String?
    var variations: [CatalogVariation]

    var lowestPrice: Int? {
        variations.compactMap { $0.priceCents }.min()
    }

    var formattedPrice: String {
        guard let cents = lowestPrice else { return "Market Price" }
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
    let priceCents: Int?

    var formattedPrice: String {
        guard let cents = priceCents else { return "Market Price" }
        return String(format: "$%.2f", Double(cents) / 100.0)
    }
}

// MARK: - Pop-Up Sale Model

struct PopUpSale: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let address: String?
    let latitude: Double
    let longitude: Double
    let startsAt: String?
    let endsAt: String?
    let isActive: Bool
}
