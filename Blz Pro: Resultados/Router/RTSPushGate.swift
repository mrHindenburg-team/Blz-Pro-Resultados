import UIKit
import UserNotifications

final class RTSPushGate: Sendable {

    static let shared = RTSPushGate(enabled: true)

    private let enabled: Bool

    private let _fcmToken   = RTSTokenBox()
    private let _apnsToken  = RTSTokenBox()

    var fcmToken: String? {
        get { _fcmToken.value }
        set { _fcmToken.value = newValue }
    }

    var apnsToken: String? {
        get { _apnsToken.value }
        set { _apnsToken.value = newValue }
    }

    init(enabled: Bool) {
        self.enabled = enabled
    }

    func requestAndCollect() async -> String? {
        if enabled {
            await requestPermission()
        } else {
            RTSLogger.log(.debug, "Push: permission request skipped (pushEnabled=false)")
        }

        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }

        return await waitForStableFCMToken()
    }

    func requestPermissionOnly() async {
        if enabled {
            await requestPermission()
        } else {
            RTSLogger.log(.debug, "Push: permission request skipped (pushEnabled=false)")
        }
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
        RTSLogger.log(.debug, "Push: permission requested — token will arrive async")
    }

    private func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        let current = await center.notificationSettings()

        guard current.authorizationStatus == .notDetermined else {
            RTSLogger.log(.debug, "Push: already authorized — status=\(current.authorizationStatus.rawValue)")
            return
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            RTSLogger.log(.info, "Push: user responded — granted=\(granted)")
        } catch {
            RTSLogger.log(.error, "Push: permission request error — \(error.localizedDescription)")
        }
    }

    private func waitForStableFCMToken(
        minWindowSeconds: Double = 4.0,
        debounceSeconds:  Double = 1.2,
        maxWindowSeconds: Double = 8.0
    ) async -> String? {

        RTSLogger.log(.debug, "Push: waiting for stable FCM token (min=\(minWindowSeconds)s, debounce=\(debounceSeconds)s, max=\(maxWindowSeconds)s)")

        let start    = Date()
        let deadline = start.addingTimeInterval(maxWindowSeconds)

        var latestToken: String? = nil
        var lastChange:  Date   = .distantPast

        if let existing = RTSPushGate.shared.fcmToken, !existing.isEmpty {
            latestToken = existing
            lastChange  = Date()
            RTSLogger.log(.debug, "Push: seeded token from shared: \(existing)")
        } else if let stored = UserDefaults.standard.string(forKey: "wbc.fcm.token"), !stored.isEmpty {
            latestToken = stored
            lastChange  = Date()
            RTSLogger.log(.debug, "Push: seeded token from UserDefaults")
        }

        while latestToken == nil || latestToken!.isEmpty {
            if Date() > deadline { break }

            if let t = RTSPushGate.shared.fcmToken, !t.isEmpty {
                latestToken = t
                lastChange  = Date()
                RTSLogger.log(.debug, "Push: first token captured from shared")
                break
            }

            if let t = UserDefaults.standard.string(forKey: "wbc.fcm.token"), !t.isEmpty {
                latestToken = t
                lastChange  = Date()
                RTSLogger.log(.debug, "Push: first token captured from UserDefaults")
                break
            }

            try? await Task.sleep(nanoseconds: 120_000_000)
        }

        guard let _ = latestToken else {
            RTSLogger.log(.warning, "Push: no FCM token received — sending empty")
            return nil
        }

        let firstTokenTime = Date()
        RTSLogger.log(.debug, "Push: first token captured — starting stability window")

        while Date() < deadline {
            try? await Task.sleep(nanoseconds: 150_000_000)

            let current = RTSPushGate.shared.fcmToken
                ?? UserDefaults.standard.string(forKey: "wbc.fcm.token")

            if let current, !current.isEmpty, current != latestToken {
                RTSLogger.log(.debug, "Push: FCM changed: \(latestToken ?? "nil") → \(current)")
                latestToken = current
                lastChange  = Date()
            }

            let sinceFirst  = Date().timeIntervalSince(firstTokenTime)
            let sinceChange = Date().timeIntervalSince(lastChange)

            if sinceFirst >= minWindowSeconds,
               let tok = latestToken, !tok.isEmpty,
               sinceChange >= debounceSeconds {
                RTSLogger.log(.info, "Push: stable FCM token accepted (sinceFirst=\(String(format: "%.1f", sinceFirst))s, sinceChange=\(String(format: "%.1f", sinceChange))s)")
                return tok
            }
        }

        let fallback = latestToken
            ?? RTSPushGate.shared.fcmToken
            ?? UserDefaults.standard.string(forKey: "wbc.fcm.token")

        if let fallback, !fallback.isEmpty {
            RTSLogger.log(.warning, "Push: stability timeout — using best available token")
            return fallback
        }

        RTSLogger.log(.warning, "Push: FCM token not received within \(maxWindowSeconds)s — sending empty")
        return nil
    }
}

final class RTSTokenBox: @unchecked Sendable {
    private var _value: String?
    private let lock = NSLock()

    var value: String? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
}
