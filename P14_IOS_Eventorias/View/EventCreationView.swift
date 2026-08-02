//
//  EventCreationView.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct EventCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel: EventCreationViewModel
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private let isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)

    init(eventRepository: EventRepositoryProtocol? = nil, storageService: ImageStorageServiceProtocol? = nil) {
        _viewModel = State(initialValue: EventCreationViewModel(eventRepository: eventRepository, storageService: storageService))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        field(title: "Title") {
                            TextField("New event", text: $viewModel.title)
                                .foregroundStyle(.white)
                                .accessibilityLabel("Event title")
                                .accessibilityIdentifier("event_title_field")
                        }

                        field(title: "Description") {
                            TextField("Description", text: $viewModel.description, axis: .vertical)
                                .lineLimit(5...)
                                .foregroundStyle(.white)
                                .accessibilityLabel("Event description")
                                .accessibilityIdentifier("event_description_field")
                        }

                        field(title: "Date") {
                            DatePicker("", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .colorScheme(.dark)
                                .accessibilityLabel("Event date")
                                .accessibilityIdentifier("event_date_picker")
                        }

                        field(title: "Address") {
                            TextField("Enter full address", text: $viewModel.address)
                                .foregroundStyle(.white)
                                .accessibilityLabel("Event address")
                                .accessibilityIdentifier("event_address_field")
                        }

                        imagePickerRow

                        if let image = viewModel.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .clipShape(.rect(cornerRadius: AppTheme.cornerRadiusLarge))
                                .clipped()
                                .accessibilityLabel("Selected cover photo")
                                .accessibilityAddTraits(.isImage)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .accessibilityIdentifier("error_message_text")
                        }
                    }
                    .padding()
                }

                saveButton
                    .padding()
            }
        }
        .navigationTitle("Create Event")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.selectedImage = image
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: .camera)
                .ignoresSafeArea()
        }
    }

    private var imagePickerRow: some View {
        HStack(spacing: 16) {
            Button {
                showCamera = true
            } label: {
                Image(systemName: "camera")
                    .font(.system(size: 24))
                    .foregroundStyle(.black)
                    .frame(width: 60, height: 60)
                    .background(Color.white)
                    .clipShape(.rect(cornerRadius: AppTheme.cornerRadiusLarge))
            }
            .disabled(!isCameraAvailable)
            .opacity(isCameraAvailable ? 1 : 0.4)
            .accessibilityLabel("Take photo")
            .accessibilityIdentifier("camera_button")

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(AppTheme.accent)
                    .clipShape(.rect(cornerRadius: AppTheme.cornerRadiusLarge))
            }
            .accessibilityLabel("Choose from library")
            .accessibilityIdentifier("photo_library_button")
        }
        .padding(.top, 8)
    }

    private var saveButton: some View {
        Button {
            Task {
                if await viewModel.createEvent(creatorId: authManager.currentUser?.uid) {
                    dismiss()
                }
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Save")
                        .font(.headline)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.accent)
            .clipShape(.rect(cornerRadius: AppTheme.cornerRadiusSmall))
        }
        .disabled(viewModel.isLoading)
        .accessibilityIdentifier("save_event_button")
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
        .background(AppTheme.fieldBackground)
        .clipShape(.rect(cornerRadius: AppTheme.cornerRadiusSmall))
    }
}

#Preview {
    NavigationStack {
        EventCreationView()
    }
    .environment(AuthManager())
}
