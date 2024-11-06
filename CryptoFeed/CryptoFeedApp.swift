import SwiftUI

@main
struct CryptoFeedApp: App {
    @StateObject var api: API = API()
    
    var body: some Scene {
        WindowGroup {
            CoinFeedView()
        }
        .environmentObject(api)
    }
}
