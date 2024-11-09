import Foundation

enum APIError: Error {
    case wrongCode(HTTPURLResponse)
    case notFound
    case decodingError
    case invalidResponse
    case invalidURL
}
