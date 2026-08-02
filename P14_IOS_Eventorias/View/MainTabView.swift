//
//  MainTabView.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Events", systemImage: "calendar") {
                NavigationStack {
                    EventListView()
                }
            }
            .accessibilityIdentifier("events_tab")

            Tab("Profile", systemImage: "person.fill") {
                NavigationStack {
                    ProfileView()
                }
            }
            .accessibilityIdentifier("profile_tab")
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthManager())
}
