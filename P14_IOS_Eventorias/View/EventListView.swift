//
//  EventListView.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import SwiftUI

struct EventListView: View {
    @State private var viewModel: EventListViewModel
    @State private var showCreateEvent = false

    init(viewModel: EventListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            content
        }
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchQuery, prompt: "Search")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                sortMenu
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreateEvent = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create new event")
                .accessibilityIdentifier("create_event_button")
            }
        }
        .task {
            await viewModel.loadEvents()
        }
        .onChange(of: showCreateEvent) { wasPresented, isPresented in
            // The list view isn't recreated when navigating back from the create screen, so
            // `.task` won't refire on its own; force a refresh here to pick up the new event.
            if wasPresented && !isPresented {
                Task { await viewModel.loadEvents(forceRefresh: true) }
            }
        }
        .navigationDestination(isPresented: $showCreateEvent) {
            EventCreationView(viewModel: EventCreationViewModel())
        }
        .navigationDestination(for: Event.self) { event in
            EventDetailView(event: event)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.events.isEmpty {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView {
                Label("Error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Try again") {
                    Task { await viewModel.loadEvents(forceRefresh: true) }
                }
                .accessibilityIdentifier("error_retry_button")
            }
            .accessibilityIdentifier("error_state_view")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.events.isEmpty {
            ContentUnavailableView(
                "No event found.",
                systemImage: "calendar.badge.exclamationmark"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.events) { event in
                        NavigationLink(value: event) {
                            EventRowView(event: event)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .accessibilityIdentifier("event_row_\(event.title)")
                    }
                }
            }
            .refreshable {
                await viewModel.loadEvents(forceRefresh: true)
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button {
                    viewModel.sortOption = option
                } label: {
                    HStack {
                        Text(option.rawValue)
                        if viewModel.sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Sort events")
        .accessibilityIdentifier("sort_menu")
    }
}

#Preview {
    NavigationStack {
        EventListView(viewModel: EventListViewModel())
    }
}
