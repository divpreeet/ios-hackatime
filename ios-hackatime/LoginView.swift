//
//  LoginView.swift
//  ios-hackatime
//
//  Created by divpreet on 04/09/2025.
//

import SwiftUI

struct LoginView: View {
    @State private var inputKey = ""
    @State private var saving = false
    @State private var error: String?
    
    var login: (String) -> Void
    
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
            SecureField("enter your hackatime api key", text: $inputKey)
                .font(.custom("TRIALPhantomSans0.8-BoldItalic", size: 18))
                .frame(maxWidth: 320, maxHeight: 48)
                // .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(.black)
                .cornerRadius(12)
                .foregroundStyle(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color("hcBlue"))
                )
            
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
                    Text("Save and Continue")
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
        let trim = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trim.isEmpty else {
            await MainActor.run {
                error = "Enter the API Key"
                saving = false
            }
            return
        }
        let ok = Keychain.save(apiKey: trim)
        await MainActor.run {
            if ok {
                login(trim)
            } else {
                error = "Failed to save API Key"
            }
        }
    }
}
