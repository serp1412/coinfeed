import SwiftUI

struct CoinFeedView: View {
    @Environment(\.api) var api
    @StateObject var viewModel = CoinFeedViewModel()
    
    func coinCard(index: Int) -> some View {
        let coin = viewModel.coins[index]
        return CoinCard(coin: coin, index: index, onPriceUpdate: { updatedCoin in
            viewModel.coins[index] = updatedCoin
        })
        .frame(maxWidth: .infinity)
        .onAppear {
            if index == viewModel.coins.count - 1 {
                Task {
                    try await viewModel.loadCoins()
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            if viewModel.loadedData {
                ScrollView {
                    VStack {
                        LazyVStack {
                            ForEach(viewModel.coins.indices, id: \.self) { index in
                                coinCard(index: index)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            viewModel.api = api.wrappedValue
            viewModel.setup()
            Task {
                try await viewModel.loadCoins()
            }
        }
    }
}
