import SwiftUI
internal import WebKit
import Combine

enum RTSNavAction {
    case none
    case home
    case back
    case forward
    case reload
}

final class RTSNavigationState: ObservableObject {

    @Published var canGoBack    = false
    @Published var canGoForward = false
    @Published var isLoading    = false
    @Published var lastError: URLError?
    @Published var navAction: RTSNavAction = .none

    weak var webView: WKWebView?
    var homeRequest: URLRequest?
}
