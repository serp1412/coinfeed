import Foundation

struct Coin: Decodable, Identifiable {
    let id: String
    let symbol: String
    let image: String
    let marketCap: Double
    let volume: Double
    var prices: [CoinPrice] = []
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case image
        case marketCap = "market_cap"
        case volume = "total_volume"
        case currentPrice = "current_price"
    }
    
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Decode basic properties
            self.id = try container.decode(String.self, forKey: .id)
            self.symbol = try container.decode(String.self, forKey: .symbol)
            self.image = try container.decode(String.self, forKey: .image)
            self.marketCap = try container.decode(Double.self, forKey: .marketCap)
            self.volume = try container.decode(Double.self, forKey: .volume)

            // Create a CoinPrice object
            let price = try container.decode(Double.self, forKey: .currentPrice)
            let coinPrice = CoinPrice(platformName: "CMC", symbol: symbol, price: price, change: nil)
            self.prices = [coinPrice]
    }
}

struct CoinPrice: Codable {
    enum Change: Codable {
        case increase
        case decrease
    }
    let platformName: String
    let symbol: String
    let price: Double
    let change: Change?
    
    enum CodingKeys: String, CodingKey {
        case platformName
        case symbol
        case price
        case change
    }
}

class CoinFeedViewModel: ObservableObject {
    @Published var coins: [Coin] = []
    var api: API = API()
    private var page = 1
    
    func loadCoins() async throws {
        let newCoins = try await api.fetchCoins(page: 1)
        await MainActor.run {
            coins.append(contentsOf: newCoins)
        }
    }
}
