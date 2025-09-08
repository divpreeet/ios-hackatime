import Foundation

final class API {
    static let shared = API()
    private init() {}

    private let base = "https://hackatime.hackclub.com"

    private func makeReq(path: String, apiKey: String) -> URLRequest? {
        guard let url = URL(string: base + path) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 30

        #if DEBUG
        print("req url \(req.url?.absoluteString ?? "nil")")
        print("auth header \(req.value(forHTTPHeaderField: "Authorization") ?? "nil")")
        #endif

        return req
    }

    func todayData(apiKey: String) async throws -> Data {
        guard let req = makeReq(path: "/api/hackatime/v1/users/current/statusbar/today", apiKey: apiKey) else {
            throw APIError.badURL
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validateHTTP(resp: resp, data: data)
        return data
    }


    func heartbeatsData(apiKey: String, limit: Int = 1) async throws -> Data {
        let path = "/api/v1/my/heartbeats?limit=\(limit)"
        guard let req = makeReq(path: path, apiKey: apiKey) else { throw APIError.badURL }
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validateHTTP(resp: resp, data: data)
        return data
    }
    
    func totalStats(apiKey: String, slackUsername: String) async throws -> UserStats {
        let path = "/api/v1/users/\(slackUsername)/stats"
        guard let req = makeReq(path: path, apiKey: apiKey) else {
            throw APIError.badURL
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validateHTTP(resp: resp, data: data)
        return try JSONDecoder().decode(UserStatsResponse.self, from: data).data
    }

    func trustFactor(apiKey: String, slackUsername: String) async throws -> Data {
        let path = "/api/v1/users/\(slackUsername)/trust_factor"
        guard let req = makeReq(path: path, apiKey: apiKey) else {
            throw APIError.badURL
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validateHTTP(resp: resp, data: data)
        return data
    }
    
    func getEditor(from heartbeats: [Heartbeat]) -> [EditorStat] {
        let counts = Dictionary(grouping: heartbeats, by: { $0.editor ?? "Unknown" })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(5)
        return counts.map { EditorStat(editor: $0.key, count: $0.value) }
    }
    
    private func validateHTTP(resp: URLResponse?, data: Data) throws {
        guard let http = resp as? HTTPURLResponse else { throw APIError.invalidResponse }
        #if DEBUG
        print("http \(http.statusCode)")
        if let body = String(data: data, encoding: .utf8) {
            print(body)
        }
        print("heaeer")
        for (k,v) in http.allHeaderFields {
            print("   \(k): \(v)")
        }
        #endif
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw APIError.httpError(statusCode: http.statusCode, body: body)
        }
    }

    enum APIError: LocalizedError {
        case badURL
        case invalidResponse
        case httpError(statusCode: Int, body: String?)

        var errorDescription: String? {
            switch self {
            case .badURL: return "bad url"
            case .invalidResponse: return "invalid response"
            case .httpError(let status, let body): return "HTTP \(status). \(body ?? "")"
            }
        }
    }
}
