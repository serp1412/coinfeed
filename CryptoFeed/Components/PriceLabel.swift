import SwiftUI

struct PriceLabel: View {
    var price: CoinPrice
    var font: Font = .system(size: 12, weight: .medium)
    
    var body: some View {
        Text("\(price.platformName): ")
            .font(font) + Text("$\(price.price, specifier: "%.2f")")
            .font(font)
            .foregroundStyle(price.color)
    }
}

#Preview {
    PriceLabel(price: .init(platformName: Strings.platform.cg, symbol: "BTC", price: 79999.99))
}
