//
//  FirebaseEmulatorTestSupport.swift
//  P14_IOS_EventoriasUITests
//
//  Created by Mathieu ARRIO on 03/08/2026.
//

import Foundation

/// Talks directly to the local Firebase Emulator Suite over its REST API so UI tests can seed
/// and reset Auth/Firestore state without going through the app under test. The app itself is
/// routed to the same emulators via the "UI_TESTING" launch argument (see
/// `P14_IOS_EventoriasApp.configureEmulatorsIfNeeded()`).
enum FirebaseEmulatorTestSupport {
    /// Must match `PROJECT_ID` in GoogleService-Info.plist / .firebaserc.
    static let projectId = "p14-eventorias-3818"

    /// Clears every Auth user and Firestore document so each test starts from a clean slate.
    static func resetState() async throws {
        try await clearAuthUsers()
        try await clearFirestoreDocuments()
    }

    /// Creates a confirmed email/password user directly in the Auth emulator, bypassing the UI.
    /// Returns the new user's uid, e.g. to read back documents Firestore rules key off it.
    @discardableResult
    static func createUser(email: String, password: String) async throws -> String {
        let url = URL(string: "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password,
            "returnSecureToken": true
        ])
        let data = try await sendExpectingSuccess(request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let uid = json["localId"] as? String else {
            throw NSError(domain: "FirebaseEmulatorTestSupport", code: -1, userInfo: [NSLocalizedDescriptionKey: "signUp response missing localId"])
        }
        return uid
    }

    /// Polls the Firestore emulator directly (bypassing the app) until `users/{uid}`'s
    /// `notificationsEnabled` field matches `expected`, or the timeout elapses. Use this instead
    /// of trusting the app's UI state before an action (like `app.terminate()`) that could race
    /// an in-flight write: `ProfileViewModel.setNotificationsEnabled` flips the toggle optimistically
    /// before its Firestore write resolves, so the UI can show the new value before it's persisted.
    static func waitForNotificationsEnabled(uid: String, expected: Bool, timeout: TimeInterval = 5) async throws -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if try await fetchNotificationsEnabled(uid: uid) == expected {
                return true
            }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        return try await fetchNotificationsEnabled(uid: uid) == expected
    }

    private static func fetchNotificationsEnabled(uid: String) async throws -> Bool? {
        let url = URL(string: "http://127.0.0.1:8080/v1/projects/\(projectId)/databases/(default)/documents/users/\(uid)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer owner", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let fields = json["fields"] as? [String: Any],
              let notificationsEnabled = fields["notificationsEnabled"] as? [String: Any] else {
            return nil
        }
        return notificationsEnabled["booleanValue"] as? Bool
    }

    /// Creates an `events` document directly in the Firestore emulator via REST, bypassing the
    /// UI entirely. Uses the `owner` bearer token, which the emulator (only) recognizes as a
    /// bypass for security rules, since these documents aren't written by a signed-in app user.
    static func createEvent(title: String, description: String, date: Date, address: String, creatorId: String) async throws {
        let url = URL(string: "http://127.0.0.1:8080/v1/projects/\(projectId)/databases/(default)/documents/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer owner", forHTTPHeaderField: "Authorization")

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "fields": [
                "title": ["stringValue": title],
                "description": ["stringValue": description],
                "date": ["timestampValue": formatter.string(from: date)],
                "address": ["stringValue": address],
                "creatorId": ["stringValue": creatorId],
                // `Event.createdAt` is `@ServerTimestamp`; despite being `Date?`, Firestore's
                // Codable decoding throws if the key is missing entirely rather than defaulting
                // to nil, which silently drops the whole document via `compactMap { try? ... }`
                // in `FirebaseEventRepository.events(forceRefresh:)`.
                "createdAt": ["timestampValue": formatter.string(from: date)]
            ]
        ])
        try await sendExpectingSuccess(request)
    }

    private static func clearAuthUsers() async throws {
        let url = URL(string: "http://127.0.0.1:9099/emulator/v1/projects/\(projectId)/accounts")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        try await sendExpectingSuccess(request)
    }

    private static func clearFirestoreDocuments() async throws {
        let url = URL(string: "http://127.0.0.1:8080/emulator/v1/projects/\(projectId)/databases/(default)/documents")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        try await sendExpectingSuccess(request)
    }

    @discardableResult
    private static func sendExpectingSuccess(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(
                domain: "FirebaseEmulatorTestSupport",
                code: status,
                userInfo: [NSLocalizedDescriptionKey: "Request to \(request.url?.absoluteString ?? "?") failed (\(status)): \(body). Is `firebase emulators:start` running?"]
            )
        }
        return data
    }
}
