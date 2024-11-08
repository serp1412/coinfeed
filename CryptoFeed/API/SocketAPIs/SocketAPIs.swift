import Foundation

protocol SocketAPIType: AnyObject {
    associatedtype Message: Decodable, CoinPriceConvertable
    var webSocketURL: URL { get }
    var webSocketTask: URLSessionWebSocketTask? { get set }
    var onUpdate: (_ price: CoinPrice) -> Void { get set }
    func connect()
    func subscribe(to currency: String)
    func unsubscribe(from currency: String)
    func disconnect()
}

extension SocketAPIType {
    func sendMessage(_ message: [String: Any]) {
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
    
    func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let jsonData = text.data(using: .utf8),
                       let coinPrice = try? JSONDecoder().decode(Message.self, from: jsonData).toCoinPrice() {
                        self?.onUpdate(coinPrice)
                    }
                default:
                    print("Received unknown message")
                }
                
                self?.receiveMessage()
                
            case .failure(let error):
                print("WebSocket receive error: \(error)")
            }
        }
    }
}
