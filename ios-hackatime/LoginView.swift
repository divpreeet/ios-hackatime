//
//  LoginView.swift
//  ios-hackatime
//
//  Created by divpreet on 04/09/2025.
//

import SwiftUI

struct LoginView: View {
    @State private var inputKey = ""
    @State private var inputSlack = ""
    @State private var saving = false
    @State private var error: String?
    @State private var step: Int = 1
    
    var login: (String, String) -> Void
    
    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 2) {
                Text("Hackatime")
                    .font(.custom("TRIALPhantomSans0.8-Bold", size: 42))
                    .foregroundStyle(.hcRed)
                
                Text("an ios client for hackatime")
                    .font(.custom("TRIALPhantomSans0.8-BookItalic", size: 14))
                    .foregroundStyle(.hcMuted)
            }
            
            if step == 1{
                SecureField("enter your hackatime api key", text: $inputKey)
                    .font(.custom("TRIALPhantomSans0.8-BoldItalic", size: 18))
                    .frame(maxWidth: 320, maxHeight: 48)
                    .padding(.horizontal, 24)
                    .background(.black)
                    .cornerRadius(12)
                    .foregroundStyle(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color("hcBlue"))
                    )
            } else {
                TextField("enter your slack username", text: $inputSlack)
                    .font(.custom("TRIALPhantomSans0.8-BoldItalic", size: 18))
                    .frame(maxWidth: 320, maxHeight: 48)
                    .padding(.horizontal, 24)
                    .background(.black)
                    .cornerRadius(12)
                    .foregroundStyle(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color("hcGreen"))
                    )
            }
            
            if let error {
                Text(error)
                    .font(.custom("TRIALPhantomSans0.8-Book", size: 16))
                    .foregroundStyle(.hcMuted)
                    .padding(.top, 4)
            }
            
            Button {
                Task { await save() }
            } label: {
                HStack {
                    if saving {
                        ProgressView().scaleEffect(0.8)
                    }
                    Text(step == 1 ? "Save API Key": "Save Username and Continue")
                        .font(.custom("TRIALPhantomSans0.8-Bold", size: 18))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .frame(maxWidth: 280, maxHeight: 36)
                .background(Color("hcRed"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("hcBg"))
        .edgesIgnoringSafeArea(.all)
    }
    
    func save() async {
        await MainActor.run {
            saving = true
            error = nil
        }
        if step == 1 {
            let trim = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trim.isEmpty else {
                await MainActor.run {
                    error = "Enter your API Key"
                    saving = false
                }
                return
            }
            let ok = Keychain.saveApi(trim)
            
            await MainActor.run {
                saving = false
                if ok {
                    step = 2
                } else {
                    error = "Failed to save API Key"
                }
            }
        } else {
            let trim = inputSlack.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trim.isEmpty else {
                await MainActor.run {
                    error = "Enter your slack username"
                    saving = false
                }
                return
            }
            let ok = Keychain.saveSlack(trim)
            await MainActor.run {
                saving = false
                if ok {
                    login(inputKey, trim)
                } else {
                    error = "Failed to save Slack Username"
                }
            }
        }

    }
}
