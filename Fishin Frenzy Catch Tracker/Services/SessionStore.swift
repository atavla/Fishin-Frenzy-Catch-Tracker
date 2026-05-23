import Foundation

enum SessionStoreError: LocalizedError {
    case unreadableData
    case failedToSave

    var errorDescription: String? {
        switch self {
        case .unreadableData: "Saved expeditions could not be read. You can continue, but older records are temporarily unavailable."
        case .failedToSave: "Data could not be saved. Check available storage and try again."
        }
    }
}

final class SessionStore {
    private let sessionsURL: URL
    private let activeURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        sessionsURL = baseURL.appendingPathComponent("fishin-frenzy-sessions.json")
        activeURL = baseURL.appendingPathComponent("fishin-frenzy-active-session.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadSessions() async throws -> [FishingSession] {
        guard FileManager.default.fileExists(atPath: sessionsURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: sessionsURL)
            return try decoder.decode([FishingSession].self, from: data).sorted { $0.startedAt > $1.startedAt }
        } catch {
            throw SessionStoreError.unreadableData
        }
    }

    func saveSessions(_ sessions: [FishingSession]) async throws {
        do {
            let data = try encoder.encode(sessions)
            try data.write(to: sessionsURL, options: [.atomic])
        } catch {
            throw SessionStoreError.failedToSave
        }
    }

    func loadActiveSession() async throws -> ActiveFishingSession? {
        guard FileManager.default.fileExists(atPath: activeURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: activeURL)
            return try decoder.decode(ActiveFishingSession.self, from: data)
        } catch {
            throw SessionStoreError.unreadableData
        }
    }

    func saveActiveSession(_ session: ActiveFishingSession?) async throws {
        do {
            if let session {
                let data = try encoder.encode(session)
                try data.write(to: activeURL, options: [.atomic])
            } else if FileManager.default.fileExists(atPath: activeURL.path) {
                try FileManager.default.removeItem(at: activeURL)
            }
        } catch {
            throw SessionStoreError.failedToSave
        }
    }
}
