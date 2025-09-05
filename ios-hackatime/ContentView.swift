//
//  ContentView.swift
//  ios-hackatime
//
//  Created by divpreet on 01/09/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var apiKey: String? = Keychain.readApi()
    @State private var slack: String? = Keychain.readSlack()
    @State private var Login: Bool = (Keychain.readApi() != nil && Keychain.readSlack() != nil)

    var body: some View {
            Group {
                if Login {
                    ProfileView(onLogout: {
                        Keychain.deleteApiKey()
                        Keychain.deleteSlack()
                        apiKey = nil
                        slack = nil
                        withAnimation {
                            Login = false
                        }
                    })
                    .transition(.move(edge: .trailing))
                } else {
                    LoginView { key, username in
                        let savedApi = Keychain.saveApi(key)
                        let savedSlack = Keychain.saveSlack(username)
                        if savedApi && savedSlack {
                            apiKey = key
                            slack = username
                            withAnimation {
                                Login = true
                            }
                        }
                    }
                    .transition(.move(edge: .leading))
                }
            }
            .onAppear {
                apiKey = Keychain.readApi()
                slack = Keychain.readSlack()
                Login = (apiKey != nil && slack != nil)
            }
        }
    }
