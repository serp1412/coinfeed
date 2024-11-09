import Foundation

enum Method {
    case GET
    case POST(Data)
    case PUT(Data)
    case PATCH(Data)
    case DELETE
}
