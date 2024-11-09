import SwiftUI

class CoinCardViewModel {
    var restAPIs: [RestAPIType] = []
    
    func updatePrices(for coin: Coin) async -> Coin {
       return await withTaskGroup(of: CoinPrice?.self) { taskGroup in
            var mutableCoin = coin
            for api in restAPIs {
                taskGroup.addTask {
                    return try? await api.fetchPrice(for: coin)
                }
            }
            
            for await price in taskGroup {
                if let price = price {
                    mutableCoin = mutableCoin.update(with: price)
                } else {
                    print("Request failed or returned no data.")
                }
            }
            
            return mutableCoin
        }
    }
}
