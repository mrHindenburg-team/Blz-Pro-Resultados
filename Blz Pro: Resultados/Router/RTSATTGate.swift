import AppTrackingTransparency

final class RTSATTGate: Sendable {

    private let handling: RTSATTHandling
    private let delay: TimeInterval

    init(handling: RTSATTHandling, delay: TimeInterval = 0.5) {
        self.handling = handling
        self.delay    = delay
    }

    func requestIfNeeded() async -> Bool {
        switch handling {

        case .skip:
            RTSLogger.log(.debug, "ATT: skip")
            return false

        case .managedByHost(let signal):
            RTSLogger.log(.debug, "ATT: waiting for host signal...")
            let authorized = await signal.wait()
            RTSLogger.log(.info, "ATT: host signaled — authorized=\(authorized)")
            return authorized

        case .managedByLibrary:
            RTSLogger.log(.debug, "ATT: requesting via library")

            let status = await MainActor.run {
                ATTrackingManager.trackingAuthorizationStatus
            }

            if status != .notDetermined {
                let authorized = (status == .authorized)
                RTSLogger.log(.info, "ATT: already determined — authorized=\(authorized)")
                return authorized
            }

            if delay > 0 {
                RTSLogger.log(.debug, "ATT: delaying request by \(delay)s")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            return await withCheckedContinuation { continuation in
                ATTrackingManager.requestTrackingAuthorization { status in
                    let authorized = (status == .authorized)
                    RTSLogger.log(.info, "ATT: response — authorized=\(authorized)")
                    continuation.resume(returning: authorized)
                }
            }
        }
    }
}
