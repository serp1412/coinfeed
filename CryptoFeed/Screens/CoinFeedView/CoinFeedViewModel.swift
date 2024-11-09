import Foundation
import SwiftUI

class CoinFeedViewModel: ObservableObject {
    @Published var coins: [Coin] = []
    @Published var loadedData = false
    @Published var loadingData = false
    var api: MainAPIType = MainAPI()
    var socketAPIs: [any SocketAPIType] = []
    var restAPIs: [RestAPIType] = []
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
            
            subscribeSocketAPIs(to: newCoins)
            let updatedCoins = await loadPricesFromRestAPIs(for: newCoins)

            await MainActor.run {
                coins.append(contentsOf: updatedCoins)
                page += 1
                loadedData = true
                loadingData = false
            }
        } catch {
            print("error =====", error)
            await MainActor.run {
                // @todo show error screen
                loadingData = false
            }
        }
    }
    
    fileprivate func subscribeSocketAPIs(to newCoins: [Coin]) {
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
    }
    
    fileprivate func loadPricesFromRestAPIs(for newCoins: [Coin]) async -> [Coin] {
        return await withTaskGroup(of: [String: CoinPrice]?.self) { taskGroup in
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
            
            return modifiedCoins
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
