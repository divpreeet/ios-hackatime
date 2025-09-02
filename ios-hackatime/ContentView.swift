//
//  ContentView.swift
//  ios-hackatime
//
//  Created by divpreet on 01/09/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var apiKey: String = ""
    @State private var output: String = "no data"
    @State private var loading: Bool = false 
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Hackatime")
                .font(.title)
                .bold()

            TextField("enter api key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: fetch) {
                if loading {
                    ProgressView()
                } else {
                    Text("fetch")
                        .bold()
                }
            }
            .padding()
            .background(Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)

            ScrollView {
                Text(output)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
        }
        .padding()
    }

    func fetch() {
        let trimKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            output = "please enter an api key"
            return
        }

        loading = true
        output = "fetching"

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        let urlString = "https://hackatime.hackclub.com/api/hackatime/v1/users/current/statusbar/today"
        
        guard let url = URL(string: urlString) else {
                    output = "invalid url"
                    loading = false
                    return
                }

        var req = URLRequest(url: url)
                req.httpMethod = "GET"
                req.setValue("Bearer \(trimKey)", forHTTPHeaderField: "Authorization")
                req.timeoutInterval = 30
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            DispatchQueue.main.async {
                loading = false

                if let error = error {
                    output = "error: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    output = "no data"
                    return
                }

                if let jsonString = String(data: data, encoding: .utf8) {
                    output = jsonString

                } else {
                    output = "parsing error"

                }

            }
        }.resume()
    }
}

#Preview {
    ContentView()
}

