//
//  P14_IOS_EventoriasApp.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 27/07/2026.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

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
        Self.configureEmulatorsIfNeeded()
        _authManager = State(initialValue: AuthManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
        }
    }

    /// Routes Auth/Firestore/Storage to the local Firebase Emulator Suite when launched by UI
    /// tests (via the "UI_TESTING" launch argument), so tests never touch production data.
    /// `#if DEBUG` keeps this whole path, including the SSL downgrade below, out of Release
    /// builds regardless of the runtime check.
    private static func configureEmulatorsIfNeeded() {
        #if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("UI_TESTING") else { return }

        // Must match the host/ports FirebaseEmulatorTestSupport (UI test target) uses to seed
        // and reset the emulators; both sides need the same values since it's the same suite.
        let host = "127.0.0.1"
        Auth.auth().useEmulator(withHost: host, port: 9099)
        Storage.storage().useEmulator(withHost: host, port: 9199)

        // Firestore's `useEmulator(withHost:port:)` only overrides the host; it leaves SSL
        // enabled, which fails to handshake with the emulator's plaintext gRPC server. Configure
        // the host/SSL settings directly instead.
        let firestore = Firestore.firestore()
        let settings = firestore.settings
        settings.host = "\(host):8080"
        settings.isSSLEnabled = false
        // UI tests reset/seed Firestore directly over REST, bypassing the SDK entirely, so its
        // on-disk cache never learns the server data changed underneath it; a `.default` read
        // would otherwise silently serve a stale snapshot left over from a previous test run.
        // An in-memory-only cache is wiped on every fresh launch, forcing a real server fetch.
        settings.cacheSettings = MemoryCacheSettings()
        firestore.settings = settings

        // The Auth SDK caches the signed-in session on disk independently of the emulator, which
        // UI tests reset between runs; force a clean, signed-out start every launch.
        try? Auth.auth().signOut()
        #endif
    }
}
