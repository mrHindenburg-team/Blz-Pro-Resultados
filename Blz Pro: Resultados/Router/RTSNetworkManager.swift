import Foundation

struct RTSSessionResponse: Decodable {
    let url: String
}

enum RTSAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    case noNetwork
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:         return "Invalid URL"
        case .invalidResponse:    return "Invalid server response"
        case .serverError(let c): return "Server error: \(c)"
        case .decodingError:      return "Response decoding error"
        case .noNetwork:          return "No internet connection"
        case .unknown(let e):     return e.localizedDescription
        }
    }
}

final class RTSNetworkManager: Sendable {

    private let config: RTSConfiguration

    init(config: RTSConfiguration) {
        self.config = config
    }

    func fetchRegister(
        fcmToken: String,
        deviceID: String,
        appsFlyerID: String
    ) async -> Result<RTSSessionResponse, RTSAPIError> {

        guard let url = URL(string: config.registerURL) else {
            RTSLogger.log(.error, "Register: invalid registerURL")
            return .failure(.invalidURL)
        }

        var body: [String: String] = [
            "bundle":    config.bundleID,
            "fcm_token": fcmToken,
            "device":    deviceID,
        ]

        if !appsFlyerID.isEmpty {
            body["appsFlyerId"] = appsFlyerID
        }

        RTSLogger.log(.network, "Register: POST \(config.registerURL)")
        RTSLogger.log(.network, "Register: bundle=\(config.bundleID) device=\(deviceID) fcm=\(fcmToken) af=\(appsFlyerID.isEmpty ? "none" : String(appsFlyerID))")

        return await performRequest(url: url, body: body, tag: "Install")
    }

    func refresh(
        fcmToken: String,
        deviceID: String,
        appsFlyerID: String
    ) async {

        guard let url = URL(string: config.syncURL) else {
            RTSLogger.log(.error, "Sync: invalid syncURL")
            return
        }

        var body: [String: String] = [
            "bundle":    config.bundleID,
            "fcm_token": fcmToken,
            "device":    deviceID,
        ]

        if !appsFlyerID.isEmpty {
            body["appsFlyerId"] = appsFlyerID
        }

        RTSLogger.log(.network, "Sync: POST \(config.syncURL)")

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                RTSLogger.log(.error, "Sync: invalid response")
                return
            }
            RTSLogger.log(.network, "Sync: status \(http.statusCode)")
            if let text = String(data: data, encoding: .utf8) {
                RTSLogger.log(.network, "Sync: response — \(text)")
            }
            if (200...299).contains(http.statusCode) {
                RTSLogger.log(.info, "Sync: success")
            } else {
                RTSLogger.log(.error, "Sync: server error \(http.statusCode)")
            }
        } catch {
            RTSLogger.log(.error, "Sync: error — \(error.localizedDescription)")
        }
    }

    private func performRequest<T: Decodable>(
        url: URL,
        body: [String: String],
        tag: String
    ) async -> Result<T, RTSAPIError> {

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return .failure(.unknown(error))
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            RTSLogger.log(.network, "\(tag): status \(http.statusCode)")

            if let text = String(data: data, encoding: .utf8) {
                RTSLogger.log(.network, "\(tag): response — \(text)")
            }

            guard (200...299).contains(http.statusCode) else {
                return .failure(.serverError(http.statusCode))
            }

            if http.statusCode == 204 || data.isEmpty {
                RTSLogger.log(.info, "\(tag): 204 / empty body → main")
                let emptyJSON = Data("{\"url\":\"\"}".utf8)
                if let result = try? JSONDecoder().decode(T.self, from: emptyJSON) {
                    return .success(result)
                }
            }

            do {
                return .success(try JSONDecoder().decode(T.self, from: data))
            } catch {
                RTSLogger.log(.error, "\(tag): decoding error — \(error)")
                return .failure(.decodingError)
            }

        } catch let urlError as URLError {
            if urlError.code == .notConnectedToInternet
                || urlError.code == .networkConnectionLost {
                return .failure(.noNetwork)
            }
            return .failure(.unknown(urlError))
        } catch {
            return .failure(.unknown(error))
        }
    }
}
