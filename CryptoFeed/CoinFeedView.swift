import SwiftUI
import SDWebImageSwiftUI
import SkeletonUI

struct CoinFeedView: View {
    @EnvironmentObject var api: API
    @StateObject var viewModel = CoinFeedViewModel()
    
    var body: some View {
        ScrollView {
            VStack {
                LazyVStack {
                    ForEach(viewModel.coins) { coin in
                        CoinCard(coin: coin)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.api = api
            Task {
                try await viewModel.loadCoins()
            }
        }
    }
}

#Preview {
    CoinFeedView()
}

//Image BTC $67 000 (CG)
//OKX: $67k, CG: $70,6k, CMC:  $55,9k
//Market cap: $560 000
//Vol (24h): 69019

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
                Spacer()
//                Text(child.name)
//                    .font(.custom("Poppins-Regular", size: 18))
//                    .foregroundStyle(Color.text.black100)
            }
            HStack {
                ForEach(coin.prices.indices, id: \.self) { index in
                    let price = coin.prices[index]
                    Text("\(price.platformName): $\(price.price, specifier: "%.2f")")
                        .font(.system(size: 14, weight: .medium))
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
