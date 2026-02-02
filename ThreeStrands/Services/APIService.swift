import Foundation

// MARK: - API Service for Dashboard Backend

@MainActor
class APIService {
    static let shared = APIService()

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

        // Dashboard to_dict() sends camelCase keys, so use default decoding (no convertFromSnakeCase)
        self.decoder = JSONDecoder()
    }

    // MARK: - Flash Sales

    func fetchFlashSales() async throws -> [FlashSale] {
        let url = URL(string: "\(baseURL)/api/public/flash-sales")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
        print("Flash sales raw: \(String(data: data, encoding: .utf8) ?? "nil")")
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
        print("Catalog raw: \(String(data: data, encoding: .utf8) ?? "nil")")
        let wrapper = try decoder.decode(CatalogResponse.self, from: data)
        if wrapper.items.isEmpty && wrapper.source == "unavailable" {
            throw APIError.catalogNotConfigured
        }
        return wrapper.items
    }

    // MARK: - Pop-Up Sales

    func fetchPopUpSales() async throws -> [PopUpSale] {
        let url = URL(string: "\(baseURL)/api/public/pop-up-sales")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
        print("Pop-up sales raw: \(String(data: data, encoding: .utf8) ?? "nil")")
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

// MARK: - Flash Sale API Model
// Dashboard to_dict() sends camelCase: id (string), title, description, cutType,
// originalPrice, salePrice, weightLbs, imageSystemName, isActive, startsAt, expiresAt

struct APIFlashSale: Codable {
    let id: String
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        func parseDate(_ s: String?) -> Date? {
            guard let s else { return nil }
            return formatter.date(from: s) ?? iso.date(from: s)
        }

        return FlashSale(
            id: id,
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
// Dashboard sends: {"items": [{id, name, description, category, variations: [{id, name, price_cents}]}], "source": "square"}

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

    var formattedPrice: String {
        guard let cents = priceCents else { return "Market Price" }
        return String(format: "$%.2f", Double(cents) / 100.0)
    }
}

// MARK: - Pop-Up Sale Model
// Dashboard to_dict() sends camelCase: id (string), title, description, address,
// latitude, longitude, startsAt, endsAt, isActive

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
