import Foundation
import SwiftUI

struct Coin: Decodable, Identifiable {
    let id: String
    let symbol: String
    let image: String
    let marketCap: Double
    let volume: Int
    var prices: [CoinPrice] = []
    
    var bestPrice: CoinPrice? {
        return prices.sorted { $0.price > $1.price }.last
    }
    
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
        
        self.id = try container.decode(String.self, forKey: .id)
        self.symbol = try container.decode(String.self, forKey: .symbol).uppercased()
        self.image = try container.decode(String.self, forKey: .image)
        self.marketCap = try container.decode(Double.self, forKey: .marketCap)
        self.volume = try container.decode(Int.self, forKey: .volume)
        
        let price = try container.decode(Double.self, forKey: .currentPrice)
        let coinPrice = CoinPrice(platformName: "CG", symbol: symbol, price: price)
        self.prices = [coinPrice]
    }
}
