import SwiftUI

@main
struct CryptoFeedApp: App {
    @State var api: MainAPIType = API()
    @State var restApis: [PlatformAPIType] = [CMCAPI(), CGAPI()]
    @State var socketAPIs: [any SocketAPIType] = [OKXWebSocketAPI()]
    
    var body: some Scene {
        WindowGroup {
            CoinFeedView()
        }
        .environment(\.api, $api)
        .environment(\.restAPIs, $restApis)
        .environment(\.socketAPIs, $socketAPIs)
    }
}
