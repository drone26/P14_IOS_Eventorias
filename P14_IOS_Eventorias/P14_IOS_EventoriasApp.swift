//
//  P14_IOS_EventoriasApp.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 27/07/2026.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    true
  }
}

@main
struct P14_IOS_EventoriasApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authManager: AuthManager

    init() {
        // Must happen before authManager touches Auth.auth() below.
        FirebaseApp.configure()
        _authManager = State(initialValue: AuthManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
        }
    }
}
