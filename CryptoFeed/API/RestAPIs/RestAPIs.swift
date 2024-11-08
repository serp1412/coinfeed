import Foundation

protocol PlatformAPIType {
    var platformName: String { get }
    func fetchPrice(for coin: Coin) async throws -> CoinPrice
    func fetchPrices(for coins: [Coin]) async throws -> [String: CoinPrice]
}
