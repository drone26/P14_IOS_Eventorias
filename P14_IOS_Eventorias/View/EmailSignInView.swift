//
//  EmailSignInView.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import SwiftUI

struct EmailSignInView: View {
    @State private var viewModel: UserSignInSignOutViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    init(authManager: AuthManager) {
        _viewModel = State(initialValue: UserSignInSignOutViewModel(authManager: authManager))
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }

            VStack(spacing: 24) {
                Text("Sign In")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)
                    .padding(.top, 40)

                VStack(spacing: 16) {
                    TextField("", text: $viewModel.email, prompt: Text("Email").foregroundStyle(.white.opacity(0.6)))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(AppTheme.rowBackground)
                        .clipShape(.rect(cornerRadius: 8))
                        .foregroundStyle(.white)
                        .tint(.red)
                        .accessibilityLabel("Email address")
                        .accessibilityIdentifier("email_field")
                        .submitLabel(.next)
                        .focused($focusedField, equals: .email)
                        .onSubmit {
                            focusedField = .password
                        }

                    SecureField("", text: $viewModel.password, prompt: Text("Password").foregroundStyle(.white.opacity(0.6)))
                        .padding()
                        .background(AppTheme.rowBackground)
                        .clipShape(.rect(cornerRadius: 8))
                        .foregroundStyle(.white)
                        .tint(.red)
                        .accessibilityLabel("Password")
                        .accessibilityIdentifier("password_field")
                        .submitLabel(.done)
                        .focused($focusedField, equals: .password)
                        .onSubmit {
                            focusedField = nil
                        }
                }
                .padding(.horizontal, 24)

                if viewModel.isShowingSignInError, let message = viewModel.signInErrorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .accessibilityIdentifier("error_message_text")
                }

                Button {
                    focusedField = nil
                    Task {
                        await viewModel.signIn()
                    }
                } label: {
                    if viewModel.isSigningIn {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.accent)
                .clipShape(.rect(cornerRadius: 4))
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .disabled(viewModel.isSigningIn || !viewModel.canSubmit)
                .accessibilityIdentifier("authenticate_button")

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    EmailSignInView(authManager: AuthManager())
}
