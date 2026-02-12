import Foundation
import Security

// MARK: - Square Catalog API Service

@MainActor
class SquareService {
    static let shared = SquareService()

    private let baseURL = "https://connect.squareup.com/v2"
    private let apiVersion = "2024-01-18"
    private let session: URLSession

    // Access token stored securely in Keychain
    private static let keychainKey = "com.threestrandscattle.app.square-token"

    // Default token - stored in Keychain on first launch for security
    private static let defaultToken = "EAAAl23jxhQmIejnibi8LPDjN9LLCkW2JhrrfnknRYoq_CuY0Kb6jJ0NRu8ucheC"

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)

        // Initialize token in Keychain if not present
        if Self.readFromKeychain() == nil {
            Self.saveToKeychain(Self.defaultToken)
        }
    }

    // MARK: - Token Management (Keychain)

    var accessToken: String? {
        get { Self.readFromKeychain() }
        set {
            if let value = newValue {
                Self.saveToKeychain(value)
            } else {
                Self.deleteFromKeychain()
            }
        }
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
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainKey,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainKey
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Catalog API

    func fetchCatalog() async throws -> [CatalogItem] {
        guard let token = accessToken else {
            throw APIError.catalogNotConfigured
        }

        var allItems: [CatalogItem] = []
        var allVariationIds: [String] = []
        var cursor: String? = nil

        // Step 1: Fetch all catalog items
        repeat {
            var urlComponents = URLComponents(string: "\(baseURL)/catalog/list")!
            var queryItems = [URLQueryItem(name: "types", value: "ITEM")]
            if let cursor = cursor {
                queryItems.append(URLQueryItem(name: "cursor", value: cursor))
            }
            urlComponents.queryItems = queryItems

            var request = URLRequest(url: urlComponents.url!)
            request.setValue(apiVersion, forHTTPHeaderField: "Square-Version")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw APIError.serverError
            }

            if http.statusCode != 200 {
                #if DEBUG
                print("Square API error: \(http.statusCode) - \(String(data: data, encoding: .utf8) ?? "nil")")
                #endif
                throw APIError.serverError
            }

            let catalogResponse = try JSONDecoder().decode(SquareCatalogResponse.self, from: data)

            // Transform Square objects to CatalogItem format
            for obj in catalogResponse.objects ?? [] {
                guard let itemData = obj.itemData else { continue }

                let variations = (itemData.variations ?? []).compactMap { variation -> CatalogVariation? in
                    guard let varData = variation.itemVariationData else { return nil }
                    allVariationIds.append(variation.id)
                    return CatalogVariation(
                        id: variation.id,
                        name: varData.name ?? "",
                        priceMoney: varData.priceMoney.map { PriceMoney(amount: $0.amount, currency: $0.currency) },
                        pricingType: varData.pricingType,
                        quantity: nil
                    )
                }

                let item = CatalogItem(
                    id: obj.id,
                    name: itemData.name ?? "",
                    description: itemData.description,
                    category: itemData.categoryId,
                    variations: variations
                )
                allItems.append(item)
            }

            cursor = catalogResponse.cursor
        } while cursor != nil

        #if DEBUG
        print("Square catalog fetched: \(allItems.count) items, \(allVariationIds.count) variations")
        #endif

        // Step 2: Fetch inventory counts for all variations
        let inventoryCounts = try await fetchInventoryCounts(catalogObjectIds: allVariationIds)

        // Step 3: Merge inventory into catalog items
        for i in 0..<allItems.count {
            for j in 0..<allItems[i].variations.count {
                let varId = allItems[i].variations[j].id
                if let qty = inventoryCounts[varId] {
                    allItems[i].variations[j].quantity = qty
                }
            }
        }

        return allItems
    }

    // MARK: - Inventory API

    private func fetchInventoryCounts(catalogObjectIds: [String]) async throws -> [String: Double] {
        guard let token = accessToken else { return [:] }
        guard !catalogObjectIds.isEmpty else { return [:] }

        var inventoryCounts: [String: Double] = [:]

        // Square limits batch requests to 100 IDs at a time
        let batchSize = 100
        for startIndex in stride(from: 0, to: catalogObjectIds.count, by: batchSize) {
            let endIndex = min(startIndex + batchSize, catalogObjectIds.count)
            let batchIds = Array(catalogObjectIds[startIndex..<endIndex])

            let url = URL(string: "\(baseURL)/inventory/counts/batch-retrieve")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(apiVersion, forHTTPHeaderField: "Square-Version")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "catalog_object_ids": batchIds
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse else { continue }

            if http.statusCode != 200 {
                #if DEBUG
                print("Square Inventory API error: \(http.statusCode) - \(String(data: data, encoding: .utf8) ?? "nil")")
                #endif
                continue
            }

            let inventoryResponse = try JSONDecoder().decode(SquareInventoryResponse.self, from: data)

            // Sum quantities by catalog object ID (may have multiple location counts)
            for count in inventoryResponse.counts ?? [] {
                let qty = Double(count.quantity ?? "0") ?? 0
                inventoryCounts[count.catalogObjectId, default: 0] += qty
            }
        }

        #if DEBUG
        print("Square inventory fetched: \(inventoryCounts.count) items with stock")
        #endif
        return inventoryCounts
    }
}

// MARK: - Square API Response Models (snake_case from Square API)

private struct SquareCatalogResponse: Codable {
    let objects: [SquareCatalogObject]?
    let cursor: String?
}

private struct SquareCatalogObject: Codable {
    let id: String
    let type: String
    let itemData: SquareItemData?

    enum CodingKeys: String, CodingKey {
        case id, type
        case itemData = "item_data"
    }
}

private struct SquareItemData: Codable {
    let name: String?
    let description: String?
    let categoryId: String?
    let variations: [SquareVariation]?

    enum CodingKeys: String, CodingKey {
        case name, description, variations
        case categoryId = "category_id"
    }
}

private struct SquareVariation: Codable {
    let id: String
    let itemVariationData: SquareVariationData?

    enum CodingKeys: String, CodingKey {
        case id
        case itemVariationData = "item_variation_data"
    }
}

private struct SquareVariationData: Codable {
    let name: String?
    let priceMoney: SquarePriceMoney?
    let pricingType: String?

    enum CodingKeys: String, CodingKey {
        case name
        case priceMoney = "price_money"
        case pricingType = "pricing_type"
    }
}

private struct SquarePriceMoney: Codable {
    let amount: Int
    let currency: String
}

// MARK: - Square Inventory Response Models

private struct SquareInventoryResponse: Codable {
    let counts: [SquareInventoryCount]?
}

private struct SquareInventoryCount: Codable {
    let catalogObjectId: String
    let quantity: String?

    enum CodingKeys: String, CodingKey {
        case catalogObjectId = "catalog_object_id"
        case quantity
    }
}
