import Foundation

public enum RTSDebugMode: Sendable {
    case disabled
    case minimal
    case verbose
}

enum RTSLogLevel: Sendable {
    case error
    case warning
    case info
    case debug
    case network

    var icon: String {
        switch self {
        case .error:   return "❌"
        case .warning: return "⚠️"
        case .info:    return "✅"
        case .debug:   return "🔍"
        case .network: return "🌐"
        }
    }
}

enum RTSMinimalTag: String {
    case finalURL   = "FINAL_URL"
    case fcmFirst   = "FCM_FIRST"
    case fcmRefresh = "FCM_REFRESH"
    case deviceID   = "DEVICE_ID"
    case error      = "ERROR"
}

enum RTSLogger {

    static var mode: RTSDebugMode = .disabled

    static func log(
        _ level: RTSLogLevel,
        _ message: String,
        file: String = #fileID
    ) {
        switch mode {
        case .disabled:
            return
        case .minimal:
            guard level == .error else { return }
            print("[RTS] \(level.icon) \(message)")
        case .verbose:
            let filename = file.split(separator: "/").last.map(String.init) ?? file
            print("[RTS][\(level.icon)][\(filename)] \(message)")
        }
    }

    static func logKey(_ tag: RTSMinimalTag, _ message: String, file: String = #fileID) {
        switch mode {
        case .disabled:
            return
        case .minimal:
            print("[RTS] [\(tag.rawValue)] \(message)")
        case .verbose:
            let filename = file.split(separator: "/").last.map(String.init) ?? file
            print("[RTS][🔑][\(filename)][\(tag.rawValue)] \(message)")
        }
    }
}
