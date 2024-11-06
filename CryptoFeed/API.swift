import Foundation

protocol PlatformAPIType {
    func fetchPrice(for currency: String) async throws -> CoinPrice
    func fetchPrices(for currencies: [String]) async throws -> [String: CoinPrice]
}

class CMCAPI: PlatformAPIType, APIType {
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
    
    func fetchPrice(for currency: String) async throws -> CoinPrice {
        return .init(platformName: "", symbol: "", price: 2, change: nil)
    }
    
    func fetchPrices(for currencies: [String]) async throws -> [String: CoinPrice] {
        let symbols = currencies.joined(separator: ",")
        let url = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol=\(symbols)&convert=USD"
        
        let coinData: CoinResponse = try await request(with: url,
                                                       httpFields: ["X-CMC_PRO_API_KEY" : "6e1040d4-ad3a-4d5f-87a1-7ce62917ec97"])
        
        return coinData.data.mapValues { value in
            return .init(platformName: "CMC", symbol: value.symbol, price: value.quote.USD.price, change: nil)
        }
    }
}

class API: ObservableObject, APIType {
    func fetchCoins(limit: Int = 20, page: Int) async throws -> [Coin] {
        let url = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=\(limit)&page=\(page)"
        
        return try await request(with: url)
    }
}

protocol APIType {
    func request<T: Decodable, U: URLProtocol>(
        with url: String,
        method: Method,
        httpFields: [String: String]?,
        reauthenticate: Bool,
        mockProtocol: U.Type?,
        intercept: ((Data, HTTPURLResponse) async throws -> T?)?
    ) async throws -> T
    
    func request<U: URLProtocol>(
        with url: String,
        method: Method,
        httpFields: [String: String]?,
        reauthenticate: Bool,
        mockProtocol: U.Type?,
        intercept: ((Data, HTTPURLResponse) async throws -> Void?)?
    ) async throws
}

enum APIError: Error {
    case wrongCode
    case notFound
    case decodingError
    case invalidResponse
    case invalidURL
}

enum Method {
    case GET
    case POST(Data)
    case PUT(Data)
    case PATCH(Data)
    case DELETE
}

extension APIType {
    func request<T: Decodable, U: URLProtocol>(
        with url: String,
        method: Method = .GET,
        httpFields: [String: String]? = nil,
        reauthenticate: Bool = true,
        mockProtocol: U.Type? = nil,
        intercept: ((Data, HTTPURLResponse) async throws -> T?)? = { data, response in
            guard response.statusCode == 200 else {
        throw APIError.wrongCode
    }
            return nil
        }
    ) async throws -> T {
        let (data, response) = try await performRequest(with: url,
                                                        method: method,
                                                        httpFields: httpFields,
                                                        mockProtocol: mockProtocol,
                                                        reauthenticate: reauthenticate)
        
        if let intercept = intercept, let decision = try await intercept(data, response) {
            return decision
        }
        
        return try decodeResponseData(data: data)
    }
    
    func request<U: URLProtocol>(
        with url: String,
        method: Method = .GET,
        httpFields: [String: String]? = nil,
        reauthenticate: Bool = true,
        mockProtocol: U.Type? = nil,
        intercept: ((Data, HTTPURLResponse) async throws -> Void?)? = { data, response in
            guard response.statusCode == 200 else {
        throw APIError.wrongCode
    }
            return nil
        }
    ) async throws {
        let (data, response) = try await performRequest(with: url,
                                                        method: method,
                                                        httpFields: httpFields,
                                                        mockProtocol: mockProtocol,
                                                        reauthenticate: reauthenticate)
        
        if let intercept = intercept {
            _ = try await intercept(data, response)
        }
    }
    
    fileprivate func performRequest<U: URLProtocol>(
        with urlString: String,
        method: Method = .GET,
        httpFields: [String: String]? = nil,
        mockProtocol: U.Type? = nil,
        reauthenticate: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        switch method {
        case .GET:
            request.httpMethod = "GET"
        case .POST(let jsonData):
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
        case .PUT(let jsonData):
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
        case .PATCH(let jsonData):
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
        case .DELETE:
            request.httpMethod = "DELETE"
        }
             
        httpFields?.forEach({ (key: String, value: String) in
            request.setValue(value, forHTTPHeaderField: key)
        })
        
        let config = URLSessionConfiguration.default
        if let mock = mockProtocol {
            config.protocolClasses = [mock]
        }
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        return (data, httpResponse)
    }

    
    fileprivate func decodeResponseData<T: Decodable>(data: Data) throws -> T {
        do {
            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
            return decodedResponse
        } catch {
            print("decode error ======", error)
            throw APIError.decodingError
        }
    }
}
