import Foundation
import Security

enum Keychain {
    static let account = "hackatime_api_key"
    static let slack = "slack_username"
    
    // api
    static func saveApi(_ apiKey: String) -> Bool {
        save(value: apiKey, for: account)
    }
    static func readApi() -> String? {
        read(for: account)
    }
    static func deleteApiKey() {
        delete(for: account)
    }
    
    // slack
    static func saveSlack(_ username: String) -> Bool {
        save(value: username, for: slack)
    }
    static func readSlack() -> String? {
        read(for: slack)
    }
    static func deleteSlack() {
        delete(for: slack)
    }
    
    static func save(value: String, for account: String) -> Bool {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        let status = SecItemAdd(add as CFDictionary, nil)
        return status == errSecSuccess
    }
    static func read(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
            let data = item as? Data,
            let s = String(data: data, encoding: .utf8) else { return nil }
        return s
    }
    static func delete(for account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
