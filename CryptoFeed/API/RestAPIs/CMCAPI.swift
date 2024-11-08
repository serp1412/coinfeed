import Foundation

class CMCAPI: PlatformAPIType, APIType {
    let platformName = "CMC"
    private let httpFields : [String: String] = ["X-CMC_PRO_API_KEY" : "6e1040d4-ad3a-4d5f-87a1-7ce62917ec97"]
    
    fileprivate struct CoinResponse: Codable {
        let data: [String: CoinData]
        
        struct CoinData: Codable {
            let symbol: String
            let quote: QuoteData
        }
        
        struct QuoteData: Codable {
            let USD: USDQuote
        }
        
        struct USDQuote: Codable {
            let price: Double
        }
    }
    
    func fetchPrice(for coin: Coin) async throws -> CoinPrice {
        let url = "\(Strings.cmcBaseURL)/cryptocurrency/quotes/latest?symbol=\(coin.symbol)&convert=USD"
        
        let coinData: CoinResponse = try await request(with: url,
                                                       httpFields: httpFields)
        
        let coinPrices: [CoinPrice] = coinData.data.map {
            .init(platformName: platformName, symbol: $0.key, price: $0.value.quote.USD.price)
        }
        
        guard let price = coinPrices.first else {
            throw APIError.invalidResponse
        }
        
        return price
    }
    
    func fetchPrices(for coins: [Coin]) async throws -> [String: CoinPrice] {
        let symbols = coins.map { $0.symbol }.joined(separator: ",")
        let url = "\(Strings.cmcBaseURL)/cryptocurrency/quotes/latest?symbol=\(symbols)&convert=USD"
        
        let coinData: CoinResponse = try await request(with: url,
                                                       httpFields: httpFields)
        
        return coinData.data.mapValues { value in
            return .init(platformName: platformName, symbol: value.symbol, price: value.quote.USD.price)
        }
    }
}
