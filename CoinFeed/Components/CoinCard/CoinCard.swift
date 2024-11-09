import SwiftUI
import SDWebImageSwiftUI
import SkeletonUI

struct CoinCard: View {
    var coin: Coin
    var index: Int
    var onPriceUpdate: (Coin) -> Void
    @State private var viewModel = CoinCardViewModel()
    @Environment(\.restAPIs) private var restAPIs
    @State private var task: Task<Void, Never>?
    
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
                    .font(.system(size: 14, weight: .bold))
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
        .onAppear {
//            print("create task for \(coin.symbol)")
            task = Task {
                let updatedCoin = await viewModel.updatePrices(for: coin)
                await MainActor.run {
                    onPriceUpdate(updatedCoin)
                }
//                print("completed task for \(coin.symbol)")
            }
        }
        .onDisappear {
            task?.cancel()
//            print("cancelled task for \(coin.symbol)")
        }
    }
}

#Preview {
    CoinCard(coin: .init(id: "bitcoin", symbol: "BTC", image: "", marketCap: 222222, volume: 33333, prices: [.init(platformName: Strings.platform.cg, symbol: "BTC", price: 77777)]), index: 0, onPriceUpdate: { _ in })
        .environment(\.restAPIs, .constant([]))
}
