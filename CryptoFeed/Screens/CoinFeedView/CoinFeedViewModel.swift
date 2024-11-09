import Foundation
import SwiftUI

class CoinFeedViewModel: ObservableObject {
    @Published var coins: [Coin] = []
    @Published var loadedData = false
    @Published var loadingData = false
    var api: MainAPIType = API()
    var socketAPIs: [any SocketAPIType] = []
    var restAPIs: [PlatformAPIType] = []
    private var page = 1
    
    func setup() {
        socketAPIs.forEach { $0.connect() }
    }
    
    func loadCoins() async throws {
        if loadingData { return }
        await MainActor.run {
            loadingData = true
        }
        do {
            let newCoins = try await api.fetchCoins(limit: 20, page: page)
            newCoins.forEach { coin in
                socketAPIs.forEach {
                    $0.subscribe(to: "\(coin.symbol)")
                    $0.onUpdate = { [weak self] price in
                        guard let index = self?.coins.firstIndex(where: { $0.symbol == price.symbol }),
                              let coin = self?.coins[index],
                              let welf = self else { return }
                        
                        DispatchQueue.main.async {
                            welf.coins[index] = coin.update(with: price)
                        }
                    }
                }
            }
            
            await withTaskGroup(of: [String: CoinPrice]?.self) { taskGroup in
                var modifiedCoins = newCoins
                for api in restAPIs {
                    taskGroup.addTask {
                        return try? await api.fetchPrices(for: newCoins)
                    }
                }
                
                for await prices in taskGroup {
                    if let prices = prices {
                        modifiedCoins = update(coins: modifiedCoins, with: prices)
                    } else {
                        print("Request failed or returned no data.")
                    }
                }
                
                await MainActor.run { [modifiedCoins] in
                    coins.append(contentsOf: modifiedCoins)
                    page += 1
                    loadedData = true
                    loadingData = false
                }
            }
        } catch {
            print("error =====", error)
        }
       
    }
    
    fileprivate func update(coins: [Coin], with prices: [String: CoinPrice]) -> [Coin] {
        let modifiedCoins = coins.map {
            guard let price = prices[$0.symbol] else {
                return $0
            }

            return $0.update(with: price)
        }
        
        return modifiedCoins
    }
}

extension Coin {
    func update(with price: CoinPrice) -> Coin {
        var mutableCoin = self
        
        var priceChange: CoinPrice.Change?
        if let index = mutableCoin.prices.firstIndex(where: { $0.platformName == price.platformName }) {
            let removedPrice = mutableCoin.prices.remove(at: index)
            if price.platformName == "OKX" {
                priceChange = removedPrice.price > price.price ? .decrease : .increase
            }
        }
        
        var mutablePrice = price
        mutablePrice.change = priceChange
        
        mutableCoin.prices.append(mutablePrice)
        
        return mutableCoin
    }
}
