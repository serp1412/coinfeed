import Foundation

class OKXWebSocketAPI: SocketAPIType {
    struct SocketUpdate: Decodable, CoinPriceConvertable {
        struct Data: Decodable {
            let id: String
            let lastPrice: String
            
            enum CodingKeys: String, CodingKey {
                case id = "instId"
                case lastPrice = "last"
            }
        }
        let data: [Data]
        
        func toCoinPrice() -> CoinPrice? {
            guard let update = data.first,
                  let symbol = update.id.components(separatedBy: "-").first,
                  let price = Double(update.lastPrice) else {
                return nil
            }
                  
            return .init(platformName: "OKX", symbol: symbol, price: price, change: nil)
        }
    }
    
    typealias Message = SocketUpdate
    
    internal let webSocketURL = URL(string: Strings.okxSocketURL)!
    internal var webSocketTask: URLSessionWebSocketTask?
    var onUpdate: (_ price: CoinPrice) -> Void = { _ in }
    
    func connect() {
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: webSocketURL)
        webSocketTask?.resume()

        receiveMessage()
    }
    
    func subscribe(to currency: String) {
        let subscribeMessage: [String: Any] = [
            "op": "subscribe",
            "args": [
                ["channel": "tickers", "instId": "\(currency)-USDT"]
            ]
        ]
        sendMessage(subscribeMessage)
    }
    
    func unsubscribe(from currency: String) {
        let unsubscribeMessage: [String: Any] = [
            "op": "unsubscribe",
            "args": [
                ["channel": "tickers", "instId": "\(currency)-USDT"]
            ]
        ]
        sendMessage(unsubscribeMessage)
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}


//class OKXWebSocketAPI2: SocketAPIType {
//    struct SocketUpdate: Decodable, CoinPriceConvertable {
//        struct Data: Decodable {
//            let id: String
//            let lastPrice: String
//
//            enum CodingKeys: String, CodingKey {
//                case id = "instId"
//                case lastPrice = "last"
//            }
//        }
//        let data: [Data]
//
//        func toCoinPrice() -> CoinPrice? {
//            guard let update = data.first,
//                  let symbol = update.id.components(separatedBy: "-").first,
//                  let price = Double(update.lastPrice) else {
//                return nil
//            }
//
//            return .init(platformName: "OKX2", symbol: symbol, price: price, change: nil)
//        }
//    }
//
//    typealias Message = SocketUpdate
//
//    internal let webSocketURL = URL(string: "wss://ws.okx.com:8443/ws/v5/public")!
//    internal var webSocketTask: URLSessionWebSocketTask?
//    var onUpdate: (_ price: CoinPrice) -> Void = { _ in }
//
//    func connect() {
//        let urlSession = URLSession(configuration: .default)
//        webSocketTask = urlSession.webSocketTask(with: webSocketURL)
//        webSocketTask?.resume()
//
//        receiveMessage()
//    }
//
//    func subscribe(to currency: String) {
//        let subscribeMessage: [String: Any] = [
//            "op": "subscribe",
//            "args": [
//                ["channel": "tickers", "instId": "\(currency)-USDT"]
//            ]
//        ]
//        sendMessage(subscribeMessage)
//    }
//
//    func unsubscribe(from currency: String) {
//        let unsubscribeMessage: [String: Any] = [
//            "op": "unsubscribe",
//            "args": [
//                ["channel": "tickers", "instId": "\(currency)-USDT"]
//            ]
//        ]
//        sendMessage(unsubscribeMessage)
//    }
//
//    func disconnect() {
//        webSocketTask?.cancel(with: .goingAway, reason: nil)
//    }
//}
//
//
