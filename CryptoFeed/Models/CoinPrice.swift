import Foundation
import SwiftUI

struct CoinPrice: Codable {
    enum Change: Codable {
        case increase
        case decrease
    }
    let platformName: String
    let symbol: String
    let price: Double
    var change: Change?
    
    var color: Color {
        guard let change else { return .black }
        return change == .increase ? .green : .red
    }
    
    enum CodingKeys: String, CodingKey {
        case platformName
        case symbol
        case price
        case change
    }
}

protocol CoinPriceConvertable {
    func toCoinPrice() -> CoinPrice?
}

