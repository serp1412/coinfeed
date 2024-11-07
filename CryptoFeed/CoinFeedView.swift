import SwiftUI

struct CoinFeedView: View {
    @EnvironmentObject var api: API
    @StateObject var viewModel = CoinFeedViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.loadedData {
                ScrollView {
                    VStack {
                        LazyVStack {
                            ForEach(viewModel.coins.indices, id: \.self) { index in
                                let coin = viewModel.coins[index]
                                CoinCard(coin: coin)
                                    .frame(maxWidth: .infinity)
                                    .onAppear {
                                        if index == viewModel.coins.count - 1 {
                                            Task {
                                                try await viewModel.loadCoins()
                                            }
                                        }
                                    }
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
            viewModel.api = api
            viewModel.setup()
            Task {
                try await viewModel.loadCoins()
            }
        }
    }
}

#Preview {
    CoinFeedView()
        .environmentObject(API())
}
