import Foundation

struct Coin: Decodable, Identifiable {
    let id: String
    let symbol: String
    let image: String
    let marketCap: Double
    let volume: Int
    var prices: [CoinPrice] = []
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case image
        case marketCap = "market_cap"
        case volume = "total_volume"
        case currentPrice = "current_price"
    }
    
//    init(id: String, symbol: String, image: String, marketCap: Double, volume: Int) {
//        self.id = id
//        self.symbol = symbol
//        self.image = image
//        self.marketCap = marketCap
//        self.volume = volume
//    }
    
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.id = try container.decode(String.self, forKey: .id)
            self.symbol = try container.decode(String.self, forKey: .symbol)
            self.image = try container.decode(String.self, forKey: .image)
            self.marketCap = try container.decode(Double.self, forKey: .marketCap)
            self.volume = try container.decode(Int.self, forKey: .volume)

            let price = try container.decode(Double.self, forKey: .currentPrice)
            let coinPrice = CoinPrice(platformName: "CG", symbol: symbol, price: price, change: nil)
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
    var cmcAPI = CMCAPI()
    private var page = 1
    
    func loadCoins() async throws {
        let newCoins = try await api.fetchCoins(page: 1)
        let cmcPrices = try await cmcAPI.fetchPrices(for: newCoins.map { $0.symbol })
        let modifiedCoins = newCoins.map {
            guard let cmcPrice = cmcPrices[$0.symbol.uppercased()] else {
                return $0
            }
            
            var coin = $0
            coin.prices.append(cmcPrice)
            
            return coin
        }
        
        await MainActor.run {
            coins.append(contentsOf: modifiedCoins)
            page += 1
        }
    }
}
