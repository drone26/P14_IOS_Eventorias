//
//  ProfileView.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel: ProfileViewModel
    @State private var showAvatarOptions = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?

    private let isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)

    init(userRepository: UserRepositoryProtocol? = nil, storageService: ImageStorageServiceProtocol? = nil) {
        _viewModel = State(initialValue: ProfileViewModel(userRepository: userRepository, storageService: storageService))
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

                        Button {
                            showAvatarOptions = true
                        } label: {
                            avatarView
                        }
                        .accessibilityLabel("Change profile photo")
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
        .confirmationDialog("Change Profile Photo", isPresented: $showAvatarOptions, titleVisibility: .visible) {
            if isCameraAvailable {
                Button("Take Photo") {
                    showCamera = true
                }
            }
            Button("Choose from Library") {
                showPhotoLibrary = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoLibrary, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await viewModel.updateAvatar(image)
                }
                selectedPhotoItem = nil
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(selectedImage: $capturedImage, sourceType: .camera)
                .ignoresSafeArea()
        }
        .onChange(of: capturedImage) { _, newImage in
            if let newImage {
                Task { await viewModel.updateAvatar(newImage) }
                capturedImage = nil
            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let selectedAvatarImage = viewModel.selectedAvatarImage {
                    Image(uiImage: selectedAvatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } else {
                    CreatorAvatarView(creatorId: authManager.currentUser?.uid ?? "", size: 56)
                }
            }
            .overlay {
                if viewModel.isUpdatingAvatar {
                    Circle()
                        .fill(.black.opacity(0.4))
                        .overlay {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                }
            }

            Image(systemName: "camera.fill")
                .font(.system(size: 10))
                .foregroundStyle(.white)
                .padding(5)
                .background(AppTheme.accent)
                .clipShape(Circle())
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
