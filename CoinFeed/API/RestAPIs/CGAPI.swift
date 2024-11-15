import Foundation

class CGAPI: RestAPIType, APIType {
    let platformName = Strings.platform.cg
    let shouldMock: Bool
    
    required init(shouldMock: Bool = false) {
        self.shouldMock = shouldMock
    }
    
    func fetchPrice(for coin: Coin) async throws -> CoinPrice {
        
        let url = "\(Strings.cgBaseURL)/coins/markets?vs_currency=usd&ids=\(coin.id)"
        
        let coins: [Coin] = try await request(with: url)
        
        guard let price = coins.first?.prices.first else {
            throw APIError.invalidResponse
        }
        
        return price
    }
    
    func fetchPrices(for coins: [Coin]) async throws -> [String: CoinPrice] {
        return [:] // we already have this data in the initial pull of data
    }
}
