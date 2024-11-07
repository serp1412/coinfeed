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
    var change: Change?
    
    var color: Color {
        guard let change else { return .black }
        return change == .increase ? .green : .red
    }
    
    enum CodingKeys: String, CodingKey {
        case platformName
        case symbol
        case price
        case change
    }
}

class CoinFeedViewModel: ObservableObject {
    @Published var coins: [Coin] = []
    @Published var loadedData = false
    @Published var loadingData = false
    var api: API = API()
    let socketManager = OKXWebSocketAPI()
    var cmcAPI = CMCAPI()
    private var page = 1
    
    func coinIsShown(_ coin: Coin) {
        socketManager.subscribe(to: coin.symbol)
    }
    
    func coinIsHidden(_ coin: Coin) {
        socketManager.unsubscribe(from: coin.symbol)
    }
    
    func setup() {
        socketManager.connect()
    }
    
    func loadCoins() async throws {
        if loadingData { return }
        await MainActor.run {
            loadingData = true
        }
        do {
            let newCoins = try await api.fetchCoins(page: page)
            socketManager.onUpdate = { [weak self] price in
                guard let index = self?.coins.firstIndex(where: { $0.symbol == price.symbol }),
                      let coin = self?.coins[index] else { return }
                
                DispatchQueue.main.async { [weak self] in
                    var mutableCoin = coin
                    var priceChange: CoinPrice.Change?
                    if let index = mutableCoin.prices.firstIndex(where: { $0.platformName == price.platformName }) {
                        let removedPrice = mutableCoin.prices.remove(at: index)
                        priceChange = removedPrice.price > price.price ? .decrease : .increase
                    }
                    var mutablePrice = price
                    mutablePrice.change = priceChange
                    mutableCoin.prices.append(mutablePrice)
                    
                    self?.coins[index] = mutableCoin
                }
            }
            
            newCoins.forEach { coin in
                socketManager.subscribe(to: "\(coin.symbol)")
            }
            let cmcPrices = try await cmcAPI.fetchPrices(for: newCoins.map { $0.symbol })
            let modifiedCoins = newCoins.map {
                guard let cmcPrice = cmcPrices[$0.symbol] else {
                    return $0
                }
                
                var coin = $0
                coin.prices.append(cmcPrice)
                
                return coin
            }
            
            await MainActor.run {
                coins.append(contentsOf: modifiedCoins)
                page += 1
                loadedData = true
                loadingData = false
            }
        } catch {
            print("error =====", error)
        }
       
    }
}
