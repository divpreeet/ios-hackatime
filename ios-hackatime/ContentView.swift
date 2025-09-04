//
//  ContentView.swift
//  ios-hackatime
//
//  Created by divpreet on 01/09/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var apiKey: String? = Keychain.read()
    @State private var Login: Bool = Keychain.read() != nil

    var body: some View {
        Group {
            if Login {
                ProfileView()
                    .transition(.move(edge: .trailing))
            } else {
                LoginView { key in
                    let saved = Keychain.save(apiKey: key)
                    if saved {
                        apiKey = key
                        withAnimation {
                            Login = true
                        }
                    }
                }
                .transition(.move(edge: .leading))
            }
        }
        .onAppear {
            apiKey = Keychain.read()
            Login = apiKey != nil
        }
    }
}
