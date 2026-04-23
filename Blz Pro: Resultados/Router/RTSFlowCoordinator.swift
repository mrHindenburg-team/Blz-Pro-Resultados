import Foundation
import Network

enum RTSRoute: String {
    case main
    case web
}

@MainActor
final class RTSFlowCoordinator {

    private let config: RTSConfiguration
    private let attGate: RTSATTGate
    private let pushGate: RTSPushGate
    private let networkManager: RTSNetworkManager

    weak var viewModel: RTSRouterViewModel?

    private var resolved        = false
    private var refreshInFlight = false
    private var lastRefreshFCM: String?

    private let routeLockKey     = "wbc.flow.lock"
    private let storedURLKey     = "wbc.flow.url"
    private let sessionDoneKey   = "wbc.session.done"
    private let sessionFCMKey    = "wbc.session.fcm"
    private let sessionDeviceKey = "wbc.session.device"
    private let attAuthorizedKey = "wbc.att.authorized"
    private let stableUUIDKey    = "wbc.stable.uuid"

    init(config: RTSConfiguration) {
        self.config         = config
        self.attGate        = RTSATTGate(handling: config.attHandling)
        self.pushGate       = RTSPushGate(enabled: config.pushEnabled)
        self.networkManager = RTSNetworkManager(config: config)
    }

    func start() {
        guard !resolved else {
            RTSLogger.log(.debug, "Coordinator: already resolved — start() ignored")
            return
        }

        RTSLogger.log(.debug, "Coordinator: start()")

        if let lock = loadRouteLock() {
            RTSLogger.log(.info, "Coordinator: found lock=\(lock.rawValue)")
            applyRoute(lock, url: UserDefaults.standard.string(forKey: storedURLKey))
            resolved = true
            return
        }

        Task { await runPipeline() }
    }

    private func runPipeline() async {
        RTSLogger.log(.debug, "Coordinator: pipeline start")
        viewModel?.setLoading()

        guard await waitForNetwork() else {
            RTSLogger.log(.info, "Coordinator: no network → main (no lock)")
            viewModel?.setMain()
            resolved = true
            return
        }

        RTSLogger.log(.debug, "Coordinator: step 2 — ATT")
        let attAuthorized = await attGate.requestIfNeeded()
        UserDefaults.standard.set(attAuthorized, forKey: attAuthorizedKey)
        RTSLogger.log(.info, "Coordinator: ATT authorized=\(attAuthorized)")

        if config.pushEnabled {
            await pushGate.requestPermissionOnly()
        }

        let deviceID = resolveDeviceID(attAuthorized: attAuthorized)
        RTSLogger.log(.debug, "Coordinator: deviceID=\(deviceID)")
        RTSLogger.logKey(.deviceID, "device=\(deviceID)")
        startFCMTokenObserver(deviceID: deviceID) // observ fcm

        let appsFlyerID = config.appsFlyerIDProvider?() ?? ""
        if appsFlyerID.isEmpty {
            RTSLogger.log(.debug, "Coordinator: AppsFlyer not connected or UID unavailable")
        } else {
            RTSLogger.log(.info, "Coordinator: appsFlyerID=\(appsFlyerID)")
        }

        RTSLogger.log(.debug, "Coordinator: step 6 — /install + splash in parallel")

        async let installResult = networkManager.fetchRegister(
            fcmToken:    "",
            deviceID:    deviceID,
            appsFlyerID: appsFlyerID
        )
        async let splashWait: Void = waitForSplash()

        let (result, _) = await (installResult, splashWait)

        RTSLogger.log(.debug, "Coordinator: splash done + /install returned — applying route")
        RTSLogger.logKey(.fcmFirst, "fcm_at_register=(empty by design)")

        switch result {
        case .success(let response):
            let raw = response.url.trimmingCharacters(in: .whitespacesAndNewlines)
            RTSLogger.log(.info, "Coordinator: register success — url=\(raw)")
            let urlLog = raw.isEmpty ? "(empty — will show main)" : raw
            RTSLogger.logKey(.finalURL, "url=\(urlLog)")

            UserDefaults.standard.set(true,     forKey: sessionDoneKey)
            UserDefaults.standard.set("",        forKey: sessionFCMKey)
            UserDefaults.standard.set(deviceID,  forKey: sessionDeviceKey)

            if isValidWebURL(raw) {
                saveAndApply(.web, url: raw)
            } else {
                RTSLogger.log(.warning, "Coordinator: invalid URL → main")
                saveAndApply(.main, url: nil)
            }

        case .failure(let error):
            RTSLogger.log(.error, "Coordinator: register error — \(error.localizedDescription)")
            RTSLogger.logKey(.error, "register failed: \(error.localizedDescription)")

            if error == .noNetwork {
                viewModel?.setMain()
                resolved = true
            } else {
                saveAndApply(.main, url: nil)
            }
        }
    }

    private func waitForSplash() async {
        RTSLogger.log(.debug, "Coordinator: waiting for splash signal")
        await RTSScreenRouterKit.shared.splashSignal.wait()
        RTSLogger.log(.debug, "Coordinator: splash signal received")
    }

    private func startFCMTokenObserver(deviceID: String) {
        Task {
            RTSLogger.log(.debug, "Coordinator: Background FCM observer started")
            
            while !Task.isCancelled {
                let currentFCM = RTSPushGate.shared.fcmToken ?? UserDefaults.standard.string(forKey: "wbc.fcm.token") ?? ""
                
                // Якщо є токен, він відрізняється від останнього відправленого і сесія /install вже завершена
                let sessionDone = UserDefaults.standard.bool(forKey: sessionDoneKey)
                
                if sessionDone, !currentFCM.isEmpty, currentFCM != self.lastRefreshFCM, !self.refreshInFlight {
                    
                    RTSLogger.log(.info, "Coordinator: New stable FCM detected — triggering /sync")
                    await MainActor.run {
                        self.tryRefreshIfNeeded(currentFCM: currentFCM, deviceID: deviceID)
                    }
                }
                
                // Перевіряємо кожну секунду (цього достатньо, щоб не грузити систему і ловити зміни)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func waitForNetwork(timeoutSeconds: Double = 10.0) async -> Bool {
        RTSLogger.log(.debug, "Coordinator: checking network")

        let monitor = NWPathMonitor()
        let queue   = DispatchQueue(label: "wbc.network.check")

        return await withCheckedContinuation { continuation in
            var resumed = false

            monitor.pathUpdateHandler = { path in
                guard !resumed else { return }
                resumed = true
                monitor.cancel()
                let ok = (path.status == .satisfied)
                RTSLogger.log(.debug, "Coordinator: connected=\(ok)")
                continuation.resume(returning: ok)
            }

            monitor.start(queue: queue)

            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                guard !resumed else { return }
                resumed = true
                monitor.cancel()
                RTSLogger.log(.warning, "Coordinator: network timeout")
                continuation.resume(returning: false)
            }
        }
    }

    private func resolveDeviceID(attAuthorized: Bool) -> String {
        if attAuthorized,
           let idfa = UserDefaults.standard.string(forKey: "wbc.device.idfa"),
           !idfa.isEmpty,
           idfa != "00000000-0000-0000-0000-000000000000" {
            RTSLogger.log(.debug, "Coordinator: using IDFA")
            return idfa
        }

        if let existing = UserDefaults.standard.string(forKey: stableUUIDKey) {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: stableUUIDKey)
        RTSLogger.log(.debug, "Coordinator: new stableUUID generated")
        return new
    }

    private func isValidWebURL(_ string: String) -> Bool {
        guard !string.isEmpty,
              let url = URL(string: string),
              let scheme = url.scheme else { return false }
        return scheme == "http" || scheme == "https"
    }

    private func loadRouteLock() -> RTSRoute? {
        guard let raw = UserDefaults.standard.string(forKey: routeLockKey) else { return nil }
        return RTSRoute(rawValue: raw)
    }

    private func saveAndApply(_ route: RTSRoute, url: String?) {
        UserDefaults.standard.set(route.rawValue, forKey: routeLockKey)
        if let url { UserDefaults.standard.set(url, forKey: storedURLKey) }
        applyRoute(route, url: url)
        resolved = true
    }

    private func applyRoute(_ route: RTSRoute, url: String?) {
        switch route {
        case .main:
            viewModel?.setMain()
        case .web:
            guard !config.nativeOnly else {
                RTSLogger.log(.info, "Coordinator: nativeOnly=true — suppressing WebView, showing main")
                viewModel?.setMain()
                return
            }
            let finalURL = url
                ?? UserDefaults.standard.string(forKey: storedURLKey)
                ?? config.fallbackURL
                ?? config.registerURL
            viewModel?.setWeb(url: finalURL)
        }
    }

    func tryRefreshIfNeeded(currentFCM: String, deviceID: String) {
        guard !currentFCM.isEmpty else { return }

        let sessionDone = UserDefaults.standard.bool(forKey: sessionDoneKey)
        guard sessionDone else {
            RTSLogger.log(.debug, "Sync: skip — session not done")
            return
        }

        let sessionFCM = UserDefaults.standard.string(forKey: sessionFCMKey) ?? ""
        guard currentFCM != sessionFCM,
              currentFCM != lastRefreshFCM,
              !refreshInFlight else {
            RTSLogger.log(.debug, "Sync: skip — token unchanged or in flight")
            return
        }

        refreshInFlight = true
        lastRefreshFCM  = currentFCM
        RTSLogger.log(.info, "Sync: new FCM → POST /sync")
        RTSLogger.logKey(.fcmRefresh, "fcm_refresh=\(currentFCM)")

        Task {
            let appsFlyerID = config.appsFlyerIDProvider?() ?? ""
            await networkManager.refresh(
                fcmToken: currentFCM,
                deviceID: deviceID,
                appsFlyerID: appsFlyerID
            )
            await MainActor.run {
                UserDefaults.standard.set(currentFCM, forKey: self.sessionFCMKey)
                self.refreshInFlight = false
            }
        }
    }
}

extension RTSAPIError: Equatable {
    static func == (lhs: RTSAPIError, rhs: RTSAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.noNetwork, .noNetwork),
             (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.decodingError, .decodingError):
            return true
        case (.serverError(let a), .serverError(let b)):
            return a == b
        default:
            return false
        }
    }
}
