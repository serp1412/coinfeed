import SwiftUI
import SDWebImageSwiftUI
import SkeletonUI

struct CoinCard: View {
    var coin: Coin
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                WebImage(url: URL(string: coin.image)) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.white
                        .skeleton(with: true, shape: .circle)
                        .frame(height: 50)
                }
                .clipShape(.circle)
                .frame(width: 50, height: 50)
                Text(coin.symbol.uppercased())
                    .font(.system(size: 14, weight: .medium))
                if let bestPrice = coin.bestPrice {
                    PriceLabel(price: bestPrice, font: .system(size: 14, weight: .bold))
                }
                Spacer()
            }
            HStack {
                ForEach(coin.prices.indices, id: \.self) { index in
                    let price = coin.prices[index]
                    PriceLabel(price: price)
                }
            }
            Text("Market cap: $\(coin.marketCap, specifier: "%.2f")")
                .font(.system(size: 14, weight: .medium))
            Text("Vol (24h): \(coin.volume)")
                .font(.system(size: 14, weight: .medium))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
        )
        .frame(maxWidth: .infinity)
    }
}
