import Foundation
import SwiftUI

private struct APIKey: EnvironmentKey {
    static let defaultValue: Binding<MainAPIType> = .constant(MainAPI())
}

private struct RestAPIsKey: EnvironmentKey {
    static let defaultValue: Binding<[PlatformAPIType]> = .constant([])
}

private struct SocketAPIsKey: EnvironmentKey {
    static let defaultValue: Binding<[any SocketAPIType]> = .constant([])
}

extension EnvironmentValues {
    var api: Binding<MainAPIType> {
        get { self[APIKey.self] }
        set { self[APIKey.self] = newValue }
    }
    
    var restAPIs: Binding<[PlatformAPIType]> {
        get { self[RestAPIsKey.self] }
        set { self[RestAPIsKey.self] = newValue }
    }
    
    var socketAPIs: Binding<[any SocketAPIType]> {
        get { self[SocketAPIsKey.self] }
        set { self[SocketAPIsKey.self] = newValue }
    }
}
