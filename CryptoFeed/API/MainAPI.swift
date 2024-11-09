import Foundation

protocol MainAPIType: APIType {
    func fetchCoins(limit: Int, page: Int) async throws -> [Coin]
}

class MainAPI: ObservableObject, MainAPIType {
    let shouldMock: Bool
    required init(shouldMock: Bool = false) {
        self.shouldMock = shouldMock
    }
    func fetchCoins(limit: Int = 20, page: Int) async throws -> [Coin] {
        let url = "\(Strings.cgBaseURL)/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=\(limit)&page=\(page)"
        
        return try await request(with: url)
    }
}
