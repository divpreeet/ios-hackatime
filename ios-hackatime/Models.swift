import Foundation

// today 
struct today: Codable {
        let data: totalContainer 
}

struct totalContainer: Codable {
        let grand_total: grandTotal
}

struct grandTotal: Codable {
        let text: String
        let total_s: Double
}


// stats

struct userStats: Codable {
        let user: String?
        let total_s: Int?
        let lang: [langStat]?
        let projects: [projectStat]?
}

struct langStat: Codable {
        let name: String
        let sec: Int
}

struct projectStat: Codable {
        let name: String
        let sec: Int
}


// raw data
struct heartbeat: Codable, Identifiable {
    let id: String
    let time: String?
    let project: String?
    let lang: String?
    let entity: String?

    enum codingKeys: String, CodingKey {
            case id, time, project, lang, entity
        }
        
}
