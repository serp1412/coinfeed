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
        func toCoinPrice() -> CoinPrice? { nil }
    }
    
    typealias Message = MockMessage
    
    var webSocketURL: URL = URL(string: "ws://localhost:8080/")!
    
    var webSocketTask: URLSessionWebSocketTask? = nil
    
    var onUpdate: (CoinPrice) -> Void = { _ in }
    
    var didConnect = false
    var subscribedSymbols: [String] = []
    
    func connect() {
        didConnect = true
    }
    
    func subscribe(to symbol: String) {
        subscribedSymbols.append(symbol)
    }
    
    func unsubscribe(from currency: String) { }

    func disconnect() { }
}

class MockRestAPI: RestAPIType {
    var platformName: String = "MockName"
    var shouldFail = false
    
    var stubbedPrice: CoinPrice = .init(platformName: "", symbol: "", price: 2)
    
    func fetchPrice(for coin: Coin) async throws -> CoinPrice {
        if shouldFail {
            throw NSError(domain: "MockPlatformAPIError", code: -1, userInfo: nil)
        }
        
        return stubbedPrice
    }
    
    var stubbedPrices: [String: CoinPrice] = [:]
    
    func fetchPrices(for coins: [Coin]) async throws -> [String: CoinPrice] {
        if shouldFail {
            throw NSError(domain: "MockPlatformAPIError", code: -1, userInfo: nil)
        }
        return stubbedPrices
    }
}
