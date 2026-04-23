import SwiftUI
import Combine

public struct RTSTransitionConfig: Sendable {

    public let animation: Animation
    public let type: RTSTransitionType

    public init(
        type:      RTSTransitionType = .fade,
        animation: Animation         = .easeInOut(duration: 0.6)
    ) {
        self.type      = type
        self.animation = animation
    }

    public static let fade      = RTSTransitionConfig(type: .fade,           animation: .easeInOut(duration: 0.6))
    public static let slideUp   = RTSTransitionConfig(type: .slide(.up),     animation: .easeInOut(duration: 0.5))
    public static let slideDown = RTSTransitionConfig(type: .slide(.down),   animation: .easeInOut(duration: 0.5))
    public static let scale     = RTSTransitionConfig(type: .scale,          animation: .easeInOut(duration: 0.5))

    public static func custom(type: RTSTransitionType, animation: Animation) -> RTSTransitionConfig {
        RTSTransitionConfig(type: type, animation: animation)
    }
}

public enum RTSTransitionType: Sendable {
    case fade
    case slide(Edge)
    case scale

    public enum Edge: Sendable {
        case up, down, left, right
    }
}

@MainActor
public final class RTSScreenRouterKit {

    public static let shared = RTSScreenRouterKit()
    private init() {}

    private(set) var config: RTSConfiguration?
    private(set) var transitionConfig: RTSTransitionConfig = .fade
    private(set) var mainViewProvider: RTSMainViewProvider?
    private var viewModel: RTSRouterViewModel?
    private var started = false

    weak var _appDelegate: RTSAppDelegate?

    private(set) var splashSignal = RTSSplashSignal()

    public func present(
        transition: RTSTransitionConfig = .fade,
        splash: @escaping RTSSplashProvider,
        mainView: @escaping RTSMainViewProvider,
        debugMode: RTSDebugMode = .disabled,
        attHandling: RTSATTHandling,
        attDelay: TimeInterval = 0.5,
        defaultOrientations: UIInterfaceOrientationMask = .portrait,
        webOrientations: UIInterfaceOrientationMask = .all
    ) -> some View {

        mainViewProvider    = mainView
        transitionConfig    = transition

        let config = RTSConfiguration(
            splash:              splash,
            debugMode:           debugMode,
            attHandling:         attHandling,
            attDelay:            attDelay,
            defaultOrientations: defaultOrientations,
            webOrientations:     webOrientations
        )

        configure(config)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startSimple()
        }

        return makeRootView()
    }

    public func start(
        host: String,
        bundleID: String,
        splash: RTSSplashProvider?,
        mainView: RTSMainViewProvider?,
        debugMode: RTSDebugMode = .disabled,
        pushEnabled: Bool = true,
        attHandling: RTSATTHandling = .managedByLibrary,
        attDelay: TimeInterval = 0.5,
        fallbackURL: String? = nil,
        nativeOnly: Bool = false,
        defaultOrientations: UIInterfaceOrientationMask = .portrait,
        webOrientations: UIInterfaceOrientationMask = .all
    ) -> some View {
        let base = "https://\(host.trimmingCharacters(in: .init(charactersIn: "/")))"
        return start(
            registerURL:         "\(base)/v1/public/install",
            syncURL:             "\(base)/v1/public/refresh",
            bundleID:            bundleID,
            splash:              splash,
            mainView:            mainView,
            debugMode:           debugMode,
            pushEnabled:         pushEnabled,
            attHandling:         attHandling,
            attDelay:            attDelay,
            fallbackURL:         fallbackURL,
            nativeOnly:          nativeOnly,
            defaultOrientations: defaultOrientations,
            webOrientations:     webOrientations
        )
    }

    public func start(
        registerURL: String,
        syncURL: String,
        bundleID: String,
        splash: RTSSplashProvider?,
        mainView: RTSMainViewProvider?,
        debugMode: RTSDebugMode = .disabled,
        pushEnabled: Bool = true,
        attHandling: RTSATTHandling = .managedByLibrary,
        attDelay: TimeInterval = 0.5,
        fallbackURL: String? = nil,
        nativeOnly: Bool = false,
        defaultOrientations: UIInterfaceOrientationMask = .portrait,
        webOrientations: UIInterfaceOrientationMask = .all
    ) -> some View {

        mainViewProvider = mainView

        let config = RTSConfiguration(
            registerURL:         registerURL,
            syncURL:             syncURL,
            bundleID:            bundleID,
            attHandling:         attHandling,
            attDelay:            attDelay,
            splash:              splash,
            debugMode:           debugMode,
            pushEnabled:         pushEnabled,
            fallbackURL:         fallbackURL,
            defaultOrientations: defaultOrientations,
            webOrientations:     webOrientations,
            nativeOnly:          nativeOnly
        )

        configure(config)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.start()
        }

        return makeRootView()
    }

    public func startWithTracking(
        host: String,
        bundleID: String,
        splash: RTSSplashProvider?,
        mainView: RTSMainViewProvider?,
        debugMode: RTSDebugMode = .disabled,
        pushEnabled: Bool = true,
        attDelay: TimeInterval = 0.5,
        fallbackURL: String? = nil,
        nativeOnly: Bool = false,
        defaultOrientations: UIInterfaceOrientationMask = .portrait,
        webOrientations: UIInterfaceOrientationMask = .all
    ) -> some View {
        let base = "https://\(host.trimmingCharacters(in: .init(charactersIn: "/")))"
        return startWithTracking(
            registerURL:         "\(base)/v1/public/install",
            syncURL:             "\(base)/v1/public/refresh",
            bundleID:            bundleID,
            splash:              splash,
            mainView:            mainView,
            debugMode:           debugMode,
            pushEnabled:         pushEnabled,
            attDelay:            attDelay,
            fallbackURL:         fallbackURL,
            nativeOnly:          nativeOnly,
            defaultOrientations: defaultOrientations,
            webOrientations:     webOrientations
        )
    }

    public func startWithTracking(
        registerURL: String,
        syncURL: String,
        bundleID: String,
        splash: RTSSplashProvider?,
        mainView: RTSMainViewProvider?,
        debugMode: RTSDebugMode = .disabled,
        pushEnabled: Bool = true,
        attDelay: TimeInterval = 0.5,
        fallbackURL: String? = nil,
        nativeOnly: Bool = false,
        defaultOrientations: UIInterfaceOrientationMask = .portrait,
        webOrientations: UIInterfaceOrientationMask = .all
    ) -> some View {

        mainViewProvider = mainView

        let signal = RTSATTSignal()

        if let delegate = _appDelegate {
            delegate.attSignal        = signal
            delegate.appsFlyerEnabled = true
        } else {
            RTSLogger.log(.warning, "startWithTracking: _appDelegate not set yet")
        }

        let config = RTSConfiguration(
            registerURL:          registerURL,
            syncURL:              syncURL,
            bundleID:             bundleID,
            attSignal:            signal,
            appsFlyerIDProvider:  {
                UserDefaults.standard.string(forKey: "wbc.appsflyer.id")
            },
            attDelay:             attDelay,
            splash:               splash,
            debugMode:            debugMode,
            pushEnabled:          pushEnabled,
            fallbackURL:          fallbackURL,
            defaultOrientations:  defaultOrientations,
            webOrientations:      webOrientations,
            nativeOnly:           nativeOnly
        )

        configure(config)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.start()

            if let delegate = self._appDelegate {
                delegate.attSignal        = signal
                delegate.appsFlyerEnabled = true
                delegate.performATTForAppsFlyer()
            } else {
                RTSLogger.log(.warning, "startWithTracking asyncAfter: _appDelegate not found — completing ATT signal as false")
                signal.complete(authorized: false)
            }
        }

        return makeRootView()
    }

    public func configure(_ config: RTSConfiguration) {
        self.config = config
        RTSLogger.mode = config.debugMode
        RTSLogger.log(.info, "ScreenRouterKit: configure() bundleID=\(config.bundleID)")
    }

    public func makeRootView() -> some View {
        let vm = getOrCreateViewModel()
        return RTSRouterRootView().environmentObject(vm)
    }

    public func start() {
        guard let config else {
            RTSLogger.log(.error, "ScreenRouterKit: start() called before configure()")
            return
        }
        guard !started else {
            RTSLogger.log(.debug, "ScreenRouterKit: start() already called")
            return
        }
        started = true
        RTSLogger.log(.info, "ScreenRouterKit: start()")

        guard let vm = viewModel else {
            RTSLogger.log(.error, "ScreenRouterKit: ViewModel not found")
            return
        }
        vm.begin(config: config)
    }

    func startSimple() {
        guard let config, !started else { return }
        started = true
        RTSLogger.mode = config.debugMode
        RTSLogger.log(.info, "ScreenRouterKit: startSimple()")

        Task { @MainActor in
            let attGate = RTSATTGate(handling: config.attHandling, delay: config.attDelay)
            let attAuthorized = await attGate.requestIfNeeded()
            UserDefaults.standard.set(attAuthorized, forKey: "wbc.att.authorized")
            RTSLogger.log(.info, "ScreenRouterKit: startSimple — ATT authorized=\(attAuthorized)")
            viewModel?.setMain()
        }
    }

    public func handleAPNSToken(_ data: Data) {
        let hex = data.map { String(format: "%02.2hhx", $0) }.joined()
        RTSLogger.log(.info, "ScreenRouterKit: APNs (\(hex)")
        UserDefaults.standard.set(true, forKey: "wbcApnsReady")
        UserDefaults.standard.set(hex,  forKey: "wbcApnsTokenHex")
        RTSPushGate.shared.apnsToken = hex
        NotificationCenter.default.post(name: .wbcAPNSTokenDidUpdate, object: nil,
                                        userInfo: ["wbc_apns": hex])
    }

    public func handleFCMToken(_ token: String) {
        guard !token.isEmpty else { return }

        let isRefresh = started

        if isRefresh {
            RTSLogger.logKey(.fcmRefresh, "fcm_refresh=\(token)")
        } else {
            RTSLogger.logKey(.fcmFirst, "fcm_early=\(token)")
        }

        UserDefaults.standard.set(token, forKey: "wbc.fcm.token")
        RTSPushGate.shared.fcmToken = token
        NotificationCenter.default.post(name: .wbcFCMTokenDidUpdate, object: nil,
                                        userInfo: ["token": token])
    }

    public var currentOrientations: UIInterfaceOrientationMask {
        config?.defaultOrientations ?? .portrait
    }

    public var presented: RTSScene {
        viewModel?.presented ?? .loading
    }

    public var presentedPublisher: Published<RTSScene>.Publisher? {
        viewModel?.$presented
    }

    public func reset() {
        RTSLogger.log(.info, "ScreenRouterKit: reset()")
        [
            "wbc.flow.lock", "wbc.flow.url",
            "wbc.session.done", "wbc.session.fcm", "wbc.session.device",
            "wbc.att.authorized", "wbc.stable.uuid",
            "wbc.device.idfa", "wbc.appsflyer.id"
        ].forEach { UserDefaults.standard.removeObject(forKey: $0) }
        started          = false
        viewModel        = nil
        mainViewProvider = nil
        splashSignal     = RTSSplashSignal()
    }

    private func getOrCreateViewModel() -> RTSRouterViewModel {
        if let existing = viewModel { return existing }
        let vm = RTSRouterViewModel()
        viewModel = vm
        return vm
    }
}
