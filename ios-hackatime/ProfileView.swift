import SwiftUI
import Foundation

struct ProfileView: View {
    @State private var apiKey: String = Keychain.read() ?? ""
    @State private var todayT: String = "-"
    @State private var totalT: String = "-"
    @State private var langs: [(String, Int)] = []
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack {
                    TextField("enter API key", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button(action: {
                        let ok = Keychain.save(apiKey: apiKey)
                        if !ok {
                            error = "failed to save key"
                        } else {
                            error = nil
                        }
                    }) {
                        Image(systemName: "square.and.arrow.down.fill")
                    }
                }
                .padding(.horizontal)

                if loading {
                    ProgressView()
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today: \(todayT)")
                            .font(.headline)
                        Text("Total: \(totalT)")
                            .font(.subheadline)

                        if !langs.isEmpty {
                            Text("Today's top languages:")
                                .font(.subheadline).bold()

                            ForEach(langs.indices, id: \.self) { idx in
                                HStack {
                                    Text(langs[idx].0)
                                    Spacer()
                                    Text(timeString(from: langs[idx].1))
                                        .font(.caption)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding()
                }

                if let err = error {
                    Text(err)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button("Refresh") {
                        Task { await loadAll() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Logout") {
                        Keychain.delete()
                        apiKey = ""
                        todayT = "-"
                        totalT = "-"
                        langs = []
                        error = nil
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Hackatime")
        }
        .onAppear {
            Task { await loadAll() }
        }
    }
    
    func loadAll() async {
        await MainActor.run { error = nil }
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            await MainActor.run { error = "Enter an API Key" }
            return
        }

        await MainActor.run { loading = true }

        var todaySeconds = 0

        do {
            let todayData = try await API.shared.todayData(apiKey: key)
            let (text, secs) = try timeSeconds(from: todayData)
            await MainActor.run {
                todayT = text
                totalT = timeString(from: secs)
            }			
            todaySeconds = secs
        } catch let err {
            await MainActor.run { self.error = "today: \(err.localizedDescription)" }
        }

        do {
            let hbData = try await API.shared.heartbeatsData(apiKey: key, limit: 1000)
            do {
                let top = try topLangs(from: hbData, totalSeconds: todaySeconds)
                await MainActor.run { langs = top }
            } catch {
                #if DEBUG
                print("heartbeat parse failed:", error)
                if let s = String(data: hbData, encoding: .utf8) {
                    print("heartbeat raw:", s)
                }
                #endif
                await MainActor.run { self.error = "failed to parse heartbeats" }
            }
        } catch let err {
            await MainActor.run { self.error = "heartbeats fetch failed: \(err.localizedDescription)" }
        }

        await MainActor.run { loading = false }
    }

    func topLangs(from data: Data, totalSeconds: Int, topN: Int = 5) throws -> [(String, Int)] {
        let raw = try JSONSerialization.jsonObject(with: data, options: [])
        let arr: [[String: Any]]
        if let a = raw as? [[String: Any]] {
            arr = a
        } else if let dict = raw as? [String: Any] {
            if let d = dict["data"] as? [[String: Any]] {
                arr = d
            } else if let d = dict["heartbeats"] as? [[String: Any]] {
                arr = d
            } else {
                throw NSError(domain: "ParseError", code: 0)
            }
        } else {
            throw NSError(domain: "ParseError", code: 0)
        }

        let todayPrefix: String = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()

        var counts: [String: Int] = [:]
        var totalCount = 0

        for hb in arr {
            var timeStr: String?
            if let t = hb["time"] as? String { timeStr = t }
            else if let t = hb["timestamp"] as? String { timeStr = t }
            else if let t = hb["created_at"] as? String { timeStr = t }
            else if let t = hb["date"] as? String { timeStr = t }

            guard let ts = timeStr else { continue }

            var datePrefix: String?
            if let idx = ts.firstIndex(of: "T") {
                datePrefix = String(ts[..<idx])
            } else if ts.count >= 10 {
                datePrefix = String(ts.prefix(10))
            } else {
                datePrefix = nil
            }

            if datePrefix != todayPrefix { continue }

            let lang = (hb["language"] as? String) ??
                       (hb["lang"] as? String) ??
                       (hb["editor"] as? String) ??
                       (hb["entity"] as? String) ??
                       "Unknown"

            counts[lang, default: 0] += 1
            totalCount += 1
        }

        if totalCount == 0 { return [] }

        var pairs = counts.map { ($0.key, $0.value) }
        pairs.sort { $0.1 > $1.1 }

        var out: [(String, Int)] = []
        for (lang, count) in pairs.prefix(topN) {
            let seconds = totalSeconds > 0 ? Int(round(Double(totalSeconds) * (Double(count) / Double(totalCount)))) : 0
            out.append((lang, seconds))
        }
        return out
    }

    
    // today time with seconds
    func timeSeconds(from data: Data) throws -> (String, Int) {
        guard
            let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let d = obj["data"] as? [String: Any],
            let grand = d["grand_total"] as? [String: Any],
            let text = grand["text"] as? String,
            let secs = grand["total_seconds"] as? NSNumber
        else { throw NSError(domain: "ParseError", code: 0) }
        return (text, Int(round(secs.doubleValue)))
    }

    func timeString(from seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
