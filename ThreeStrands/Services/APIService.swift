import Foundation

// MARK: - API Service for Dashboard Backend

@MainActor
class APIService {
    static let shared = APIService()

    // Base URL for the dashboard backend - update this to your server's address
    var baseURL: String {
        UserDefaults.standard.string(forKey: "api_base_url") ?? "https://dashboard.3strandsbeef.com"
    }

    private let session: URLSession
    private let decoder: JSONDecoder

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
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
        let wrapper = try decoder.decode(CatalogResponse.self, from: data)
        return wrapper.items
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

    var errorDescription: String? {
        switch self {
        case .serverError: return "Unable to reach the server. Please try again."
        case .decodingError: return "Unexpected response from server."
        }
    }
}

// MARK: - API Response Models

struct APIFlashSale: Codable {
    let id: Int
    let title: String
    let description: String
    let cutType: String
    let originalPrice: Double
    let salePrice: Double
    let weightLbs: Double
    let startsAt: String
    let expiresAt: String
    let imageSystemName: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case cutType = "cut_type"
        case originalPrice = "original_price"
        case salePrice = "sale_price"
        case weightLbs = "weight_lbs"
        case startsAt = "starts_at"
        case expiresAt = "expires_at"
        case imageSystemName = "image_system_name"
        case isActive = "is_active"
    }

    func toFlashSale() -> FlashSale {
        let iso = ISO8601DateFormatter()
        return FlashSale(
            id: UUID(),
            title: title,
            description: description,
            cutType: CutType(rawValue: cutType) ?? .custom,
            originalPrice: originalPrice,
            salePrice: salePrice,
            weightLbs: weightLbs,
            startsAt: iso.date(from: startsAt) ?? Date(),
            expiresAt: iso.date(from: expiresAt) ?? Date(),
            imageSystemName: imageSystemName,
            isActive: isActive
        )
    }
}

struct CatalogResponse: Codable {
    let items: [CatalogItem]
    let source: String
}

struct CatalogItem: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let category: String?
    let variations: [CatalogVariation]

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

    enum CodingKeys: String, CodingKey {
        case id, name
        case priceCents = "price_cents"
    }

    var formattedPrice: String {
        guard let cents = priceCents else { return "Market Price" }
        return String(format: "$%.2f", Double(cents) / 100.0)
    }
}
