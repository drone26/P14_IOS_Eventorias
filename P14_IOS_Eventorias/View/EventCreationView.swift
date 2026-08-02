//
//  EventCreationView.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import SwiftUI

/// Placeholder destination for the event list's create button. The full creation flow
/// (form, image upload) is a separate piece of work not covered by this screen.
struct EventCreationView: View {
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            Text("Créer un événement — à venir")
                .foregroundStyle(.white)
        }
        .navigationTitle("Nouvel événement")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EventCreationView()
    }
}
