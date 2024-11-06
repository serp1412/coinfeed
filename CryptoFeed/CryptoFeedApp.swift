//
//  CryptoFeedApp.swift
//  CryptoFeed
//
//  Created by Serghei on 06.11.2024.
//

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
