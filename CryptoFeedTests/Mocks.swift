import Foundation
@testable import CryptoFeed

class MockMainAPI: MainAPIType {
    var shouldMock: Bool
    
    required init(shouldMock: Bool = false) {
        self.shouldMock = shouldMock
    }
    
    var stubbedCoins: [Coin] = []
    var shouldFail = false
    
    func fetchCoins(limit: Int, page: Int) async throws -> [Coin] {
        if shouldFail {
            throw NSError(domain: "MockMainAPIError", code: -1, userInfo: nil)
        }
        return stubbedCoins
    }
}

class MockSocketAPI: SocketAPIType {
    struct MockMessage: Decodable, CoinPriceConvertable {
        func toCoinPrice() -> CryptoFeed.CoinPrice? {
            .init(platformName: "", symbol: "", price: 2)
        }
    }
    
    typealias Message = MockMessage
    
    var webSocketURL: URL = URL(string: "ws://localhost:8080/")!
    
    var webSocketTask: URLSessionWebSocketTask? = nil
    
    var onUpdate: (CryptoFeed.CoinPrice) -> Void = { _ in }
    
    var didConnect = false
    var subscribedSymbols: [String] = []
    
    func connect() {
        didConnect = true
    }
    
    func subscribe(to symbol: String) {
        subscribedSymbols.append(symbol)
    }
    
    func unsubscribe(from currency: String) {
        
    }
    
    func disconnect() {
        
    }
}

class MockPlatformAPI: PlatformAPIType {
    var platformName: String = "MockName"
    
    var stubbedPrice: CoinPrice = .init(platformName: "", symbol: "", price: 2)
    
    func fetchPrice(for coin: CryptoFeed.Coin) async throws -> CryptoFeed.CoinPrice {
        return stubbedPrice
    }
    
    var stubbedPrices: [String: CoinPrice] = [:]
    
    func fetchPrices(for coins: [Coin]) async throws -> [String: CoinPrice] {
        return stubbedPrices
    }
}
