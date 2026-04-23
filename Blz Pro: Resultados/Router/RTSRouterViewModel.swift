@preconcurrency import SwiftUI
import Combine

public enum RTSScene: Equatable {
    case loading
    case main
    case web(url: String)
}

@MainActor
public final class RTSRouterViewModel: ObservableObject {

    @Published public internal(set) var presented: RTSScene = .loading

    private var coordinator: RTSFlowCoordinator?
    private var fcmObserver: NSObjectProtocol?

    public init() {}

    deinit {
        if let obs = fcmObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    func begin(config: RTSConfiguration) {
        RTSLogger.log(.debug, "ViewModel: begin()")
        RTSLogger.mode = config.debugMode

        let coord = RTSFlowCoordinator(config: config)
        coord.viewModel = self
        self.coordinator = coord

//        setupFCMObserver(config: config)
        coord.start()
    }

    func setLoading() {
        RTSLogger.log(.debug, "ViewModel: → loading")
        presented = .loading
    }

    func setMain() {
        RTSLogger.log(.info, "ViewModel: → main")
        presented = .main
    }

    func setWeb(url: String) {
        RTSLogger.log(.info, "ViewModel: → web(\(url))")
        presented = .web(url: url)
    }

//    private func setupFCMObserver(config: RTSConfiguration) {
//        fcmObserver = NotificationCenter.default.addObserver(
//            forName: .wbcFCMTokenDidUpdate,
//            object: nil,
//            queue: nil
//        ) { [weak self] note in
//            guard let self else { return }
//
//            let token = (note.userInfo?["token"] as? String)
//                ?? UserDefaults.standard.string(forKey: "wbc.fcm.token")
//                ?? ""
//
//            guard !token.isEmpty else { return }
//
//            RTSLogger.log(.debug, "ViewModel: FCM updated — triggering refresh")
//            RTSLogger.logKey(.fcmRefresh, "fcm=\(String(token))")
//
//            RTSPushGate.shared.fcmToken = token
//
//            Task { @MainActor [weak self] in
//                guard let self, let coordinator = self.coordinator else { return }
//                let deviceID = UserDefaults.standard.string(forKey: "wbc.session.device") ?? ""
//                guard !deviceID.isEmpty else { return }
//                coordinator.tryRefreshIfNeeded(currentFCM: token, deviceID: deviceID)
//            }
//        }
//    }
}

public extension Notification.Name {
    static let wbcFCMTokenDidUpdate  = Notification.Name("wbc.fcm.token.didUpdate")
    static let wbcAPNSTokenDidUpdate = Notification.Name("wbc.apns.token.didUpdate")
}
