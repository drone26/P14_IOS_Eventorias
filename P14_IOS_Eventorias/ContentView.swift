//
//  ContentView.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 31/07/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                EmailSignInView(authManager: authManager)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
