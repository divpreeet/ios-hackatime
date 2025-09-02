import Foundation
import Security

enum Keychain {
        private static let account = "hackatime_api_key"
        static func save(apiKey: String) -> Bool {
                let data = Data(apiKey.utf8)
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
            static func read() -> String? {
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
                        let s = String(data: data, encoding: .utf8) else {return nil}
                    return s
                        
                }

                static func delete() {
                        let query: [String: Any] = [
                            kSecClass as String: kSecClassGenericPassword,
                            kSecAttrAccount as String: account
                        ]
                        SecItemDelete(query as CFDictionary)
                    }
    }
