import UIKit

class OKXWebSocketManager {
    
    // 1. Define WebSocket URL
    private let webSocketURL = URL(string: "wss://ws.okx.com:8443/ws/v5/public")!
    private var webSocketTask: URLSessionWebSocketTask?
    
    // 2. Create URLSession and connect
    func connect() {
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: webSocketURL)
        webSocketTask?.resume()
        
        // Send initial subscribe message
        subscribe(to: "BTC-USDT")
        
        // Start receiving messages
        receiveMessage()
    }
    
    // 3. Subscribe to a currency pair
    func subscribe(to currencyPair: String) {
        let subscribeMessage: [String: Any] = [
            "op": "subscribe",
            "args": [
                ["channel": "tickers", "instId": currencyPair]
            ]
        ]
        sendMessage(subscribeMessage)
    }
    
    // 4. Unsubscribe from a currency pair
    func unsubscribe(from currencyPair: String) {
        let unsubscribeMessage: [String: Any] = [
            "op": "unsubscribe",
            "args": [
                ["channel": "tickers", "instId": currencyPair]
            ]
        ]
        sendMessage(unsubscribeMessage)
    }
    
    // 5. Send message helper
    private func sendMessage(_ message: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            webSocketTask?.send(.string(jsonString)) { error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                }
            }
        } catch {
            print("JSON Serialization error: \(error)")
        }
    }
    
    // 6. Receive messages and handle data
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received message: \(text)")
                case .data(let data):
                    print("Received data: \(data)")
                @unknown default:
                    print("Received unknown message")
                }
                
                // Continue receiving next message
                self?.receiveMessage()
                
            case .failure(let error):
                print("WebSocket receive error: \(error)")
            }
        }
    }
    
    // 7. Disconnect from WebSocket
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}

// Usage
let webSocketManager = OKXWebSocketManager()
webSocketManager.connect()

// Add or remove currency pairs
webSocketManager.subscribe(to: "ETH-USDT")
//webSocketManager.unsubscribe(from: "BTC-USDT")


//
//struct Instrument: Codable {
//    let instId: String
//    let baseCurrency: String
//    let quoteCurrency: String
//    // Add other properties you need from the response
//    
//    enum CodingKeys: String, CodingKey {
//        case instId
//        case baseCurrency = "baseCcy"
//        case quoteCurrency = "quoteCcy"
//    }
//}
//
//struct Response: Codable {
//    let code: String
//    let data: [Instrument]
//}
//
//class OKXAPI {
//    private let baseURL = "https://www.okx.com/api/v5/public/instruments"
//    private let session = URLSession.shared
//
//    func fetchCryptocurrencies(limit: Int, after: String? = nil, completion: @escaping (Result<[Instrument], Error>) -> Void) {
//        var components = URLComponents(string: baseURL)!
//        components.queryItems = [
//            URLQueryItem(name: "instType", value: "SPOT"),
//            URLQueryItem(name: "limit", value: "\(limit)")
//        ]
//
//        // Only add the pagination parameter if provided
//        if let after = after {
//            components.queryItems?.append(URLQueryItem(name: "after", value: after))
//        }
//
//        guard let url = components.url else {
//            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//
//        let task = session.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let data = data else {
//                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
//                return
//            }
//            
//            do {
//                // Decode JSON response
//                let responseModel = try JSONDecoder().decode(Response.self, from: data)
//                completion(.success(responseModel.data))
//            } catch {
//                completion(.failure(error))
//            }
//        }
//        task.resume()
//    }
//}
//
//// Usage
//let api = OKXAPI()
//api.fetchCryptocurrencies(limit: 20) { result in
//    switch result {
//    case .success(let instruments):
//        print("Fetched instruments: \(instruments)")
//    case .failure(let error):
//        print("Error fetching instruments: \(error)")
//    }
//}
