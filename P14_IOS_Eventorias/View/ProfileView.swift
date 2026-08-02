//
//  ProfileView.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        @Bindable var authManager = authManager
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                CreatorAvatarView(creatorId: authManager.currentUser?.uid ?? "", size: 96)
                    .padding(.top, 40)
                    .accessibilityIdentifier("profile_avatar")

                VStack(spacing: 4) {
                    Text(authManager.currentUser?.displayName ?? "User")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("profile_name_text")

                    Text(authManager.currentUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .accessibilityIdentifier("profile_email_text")
                }

                Spacer()

                Button {
                    authManager.signOut()
                } label: {
                    Text("Sign Out")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent)
                        .clipShape(.rect(cornerRadius: AppTheme.cornerRadiusSmall))
                }
                .accessibilityIdentifier("sign_out_button")
            }
            .padding()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $authManager.isShowingSignOutError) {
        } message: {
            Text(authManager.signOutErrorMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(AuthManager())
}
