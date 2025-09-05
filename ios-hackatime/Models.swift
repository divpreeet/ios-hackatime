import Foundation

// today
struct TodayResponse: Codable {
    let data: TodayData
}

struct TodayData: Codable {
    let grand_total: GrandTotal
}

struct GrandTotal: Codable {
    let text: String
    let total_seconds: Double
}

// endpoint wrapper
struct UserStatsResponse: Codable {
    let data: UserStats
}

// stats
struct UserStats: Codable {
    let username: String?
    let total_seconds: Double?
    let languages: [LangStat]?
    let projects: [ProjectStat]?
    let os: [OSStat]?
}

struct LangStat: Codable {
    let name: String
    let total_seconds: Double
    let text: String?
}

struct ProjectStat: Codable {
    let name: String
    let total_seconds: Double
}


struct OSStat: Codable {
    let name: String
    let total_seconds: Double
}


struct HeartbeatResp: Codable {
    let heartbeats: [Heartbeat]
}

struct Heartbeat: Codable, Identifiable {
    let id: Int
    let project: String?

    }
    enum CodingKeys: String, CodingKey {
        case id, time, project, language, entity
}

