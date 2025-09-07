import SwiftUI
import Foundation

struct ProfileView: View {
    @State private var apiKey: String = Keychain.readApi() ?? ""
    @State private var slack: String = Keychain.readSlack() ?? ""
    @State private var todayT: String = "-"
    @State private var totalT: String = "-"
    @State private var loading = false
    @State private var error: String?
    @State private var todayS: Int = 0
    @State private var stats: UserStats?
    @State private var recentP: String = "-"
    @State private var trustF: trustFactor?
    var onLogout: () -> Void
    var body: some View {
        VStack(alignment:.leading, spacing: 0) {
            HStack{
                HStack {
                    Text("Keep")
                        .font(.custom("TRIALPhantomSans0.8-Bold", size: 32))
                        .foregroundStyle(.white)
                    Text("Track")
                        .font(.custom("TRIALPhantomSans0.8-Bold", size: 32))
                        .foregroundStyle(.white)
                    Text("Keep")
                        .font(.custom("TRIALPhantomSans0.8-Bold", size: 32))
                        .foregroundStyle(.white)
                    Text("Of")
                        .font(.custom("TRIALPhantomSans0.8-Bold", size: 32))
                        .foregroundStyle(.white)
                    Text("Your")
                        .font(.custom("TRIALPhantomSans0.8-Bold", size: 32))
                        .foregroundStyle(.hcRed)
                    Text("Coding")
                        .font(.custom("TRIALPhantomSans0.8-Bold", size: 32))
                        .foregroundStyle(.white)
                    Text("Time")
                        .font(.custom("TRIALPhantomSans0.8-Bold", size: 32))
                        .foregroundStyle(.white)

                    
                }
                Spacer()
                
                Button {
                    Task { await loadAll() }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.custom("TRIALPhantomSans0.8-Bold", size: 18))
                        .foregroundStyle(.hcRed)
                }
                .buttonStyle(.borderedProminent)
                .tint(.hcBg)
            }
            .padding(.top, 24)
            .padding(.horizontal, 16)
            
            if loading {
                ProgressView()
            } else {
                VStack(alignment:.leading) {
                    if todayS == 0 {
                        Text("no time logged in today, but you can change that!")
                            .font(.custom("TRIALPhantomSans0.8-BookItalic", size: 14))
                            .foregroundStyle(.hcMuted)
                            .padding(.bottom, 8)
                    } else {
                        Text("\(timeString(from: todayS)) logged today!")
                            .font(.custom("TRIALPhantomSans0.8-BookItalic", size: 14))
                            .foregroundStyle(.hcMuted)
                            .padding(.bottom, 8)
                    }
                    
                    if let stats = stats {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            VStack {
                                Text("total time")
                                    .font(.caption)
                                    .foregroundColor(.hcMuted)
                                let totalSeconds = Int(stats.total_seconds ?? 0)
                                let hours = totalSeconds / 3600
                                let minutes = (totalSeconds % 3600) / 60
                                Text("\(hours)h \(minutes)m")
                                    .font(.headline)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.hcBlue, lineWidth: 2)
                            )
                            VStack {
                                Text("top language")
                                    .font(.caption)
                                    .foregroundColor(.hcMuted)
                                Text(stats.languages?.first?.name ?? "-")
                                    .font(.headline)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.hcRed, lineWidth: 2)
                            )
                            VStack {
                                Text("recent project")
                                    .font(.caption)
                                    .foregroundColor(.hcMuted)
                                Text(recentP)
                                    .font(.headline)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.hcGreen, lineWidth: 2)
                            )
                            
                            if let trust = trustF {
                                VStack {
                                    Text("trust factor")
                                        .font(.caption)
                                        .foregroundColor(.hcMuted)
                                    Text(trust.trust_level)
                                        .font(.headline)
                                        
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.hcYellow, lineWidth: 2)
                                )
                            }
                            
                        }
                        .padding(.vertical, 24)
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

                
                Button("Logout") {
                    Keychain.deleteApiKey()
                    Keychain.deleteSlack()
                    apiKey = ""
                    todayT = "-"
                    totalT = "-"
                    error = nil
                    onLogout()
                }
                .buttonStyle(.borderedProminent)
                .tint(.hcRed)
                .font(.custom("TRIALPhantomSans0.8-Bold", size: 18))
                
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("hcBg"))
        .edgesIgnoringSafeArea(.all)
        .task {
            await loadAll()
        }
    }
    
    func loadAll() async {
        await MainActor.run { error = nil }
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            await MainActor.run { error = "Enter an API Key" }
            await MainActor.run { loading = false }
            return
        }
        await MainActor.run { loading = true }
        
        // today time
        do {
            let todayData = try await API.shared.todayData(apiKey: key)
            let todayResponse = try JSONDecoder().decode(TodayResponse.self, from: todayData)
            let totalSeconds = todayResponse.data.grand_total.total_seconds
            let totalText = todayResponse.data.grand_total.text
            await MainActor.run {
                todayS = Int(totalSeconds)
                todayT = totalText
            }
        } catch let err {
            await MainActor.run { self.error = "Today's stats: \(err.localizedDescription)" }
        }
        
        // total stats
        do {
            let userStats = try await API.shared.totalStats(apiKey: key, slackUsername: slack)
            await MainActor.run { stats = userStats }
        } catch let err {
            await MainActor.run { self.error = "user stats: \(err.localizedDescription)" }
        }
        
        // recent project
        do {
            let hbData = try await API.shared.heartbeatsData(apiKey: key, limit: 1)
            if let s = String(data: hbData, encoding: .utf8) {
                print("raw response:", s)
            }
            let wrapper = try JSONDecoder().decode(HeartbeatResp.self, from: hbData)
            let recentProj = wrapper.heartbeats.first?.project ?? "-"
            await MainActor.run { recentP = recentProj }
        } catch {
            await MainActor.run { recentP = "-" }
        }
        await MainActor.run { loading = false }
        
        // total stats
        do {
            let trust = try await API.shared.trustFactor(apiKey: key, slackUsername: slack)
            let decoded = try JSONDecoder().decode(trustFactor.self, from: trust)
            await MainActor.run { trustF = decoded}
        } catch {
            await MainActor.run {trustF = nil }
        }
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
