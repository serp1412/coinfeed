import Foundation

protocol CoinPriceConvertable {
    func toCoinPrice() -> CoinPrice?
}

protocol MainAPIType: APIType {
    func fetchCoins(limit: Int, page: Int) async throws -> [Coin]
}

enum APIError: Error {
    case wrongCode(HTTPURLResponse)
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

class API: ObservableObject, MainAPIType {
    func fetchCoins(limit: Int = 20, page: Int) async throws -> [Coin] {
        let url = "\(Strings.cgBaseURL)/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=\(limit)&page=\(page)"
        
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

extension APIType {
    func request<T: Decodable, U: URLProtocol>(
        with url: String,
        method: Method = .GET,
        httpFields: [String: String]? = nil,
        reauthenticate: Bool = true,
        mockProtocol: U.Type? = nil,
        intercept: ((Data, HTTPURLResponse) async throws -> T?)? = { data, response in
            guard response.statusCode == 200 else {
        throw APIError.wrongCode(response)
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
        throw APIError.wrongCode(response)
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
