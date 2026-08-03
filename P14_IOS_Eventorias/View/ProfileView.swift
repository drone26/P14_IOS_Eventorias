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
    @State private var viewModel: ProfileViewModel

    init(userRepository: UserRepositoryProtocol? = nil) {
        _viewModel = State(initialValue: ProfileViewModel(userRepository: userRepository))
    }

    var body: some View {
        @Bindable var authManager = authManager
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .accessibilityIdentifier("profile_loading_indicator")
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("User profile")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.white)

                        Spacer()

                        CreatorAvatarView(creatorId: authManager.currentUser?.uid ?? "", size: 56)
                            .accessibilityIdentifier("profile_avatar")
                    }
                    .padding(.top, 16)

                    field(title: "Name") {
                        Text(viewModel.profile?.name ?? authManager.currentUser?.displayName ?? "User")
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("profile_name_text")
                    }

                    field(title: "E-mail") {
                        Text(viewModel.profile?.email ?? authManager.currentUser?.email ?? "")
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("profile_email_text")
                    }

                    // Persists the preference only; wiring real push notifications requires
                    // an Apple Developer account and is left for a future implementation.
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { viewModel.profile?.notificationsEnabled ?? false },
                            set: { newValue in
                                Task { await viewModel.setNotificationsEnabled(newValue) }
                            }
                        ))
                        .labelsHidden()
                        .tint(AppTheme.accent)
                        .disabled(viewModel.profile == nil)

                        Text("Notifications")
                            .foregroundStyle(.white)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("profile_notifications_toggle")

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .accessibilityIdentifier("profile_error_text")
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
        }
        .navigationBarTitleDisplayMode(.inline)
        .task(id: authManager.currentUser?.uid) {
            await viewModel.loadProfile(
                uid: authManager.currentUser?.uid,
                displayName: authManager.currentUser?.displayName,
                email: authManager.currentUser?.email
            )
        }
        .alert("Error", isPresented: $authManager.isShowingSignOutError) {
        } message: {
            Text(authManager.signOutErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private func field<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.fieldBackground)
        .clipShape(.rect(cornerRadius: AppTheme.cornerRadiusSmall))
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(AuthManager())
}
