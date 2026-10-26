import AppKit
import UniformTypeIdentifiers

@MainActor
enum CSVExport {
    static func save(_ document: CSVDocument) async throws -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = document.filename
        let response = await withCheckedContinuation { continuation in
            panel.begin { continuation.resume(returning: $0) }
        }
        guard response == .OK, let url = panel.url else { return false }
        let granted = url.startAccessingSecurityScopedResource()
        defer {
            if granted {
                url.stopAccessingSecurityScopedResource()
            }
        }
        try document.contents.write(to: url, atomically: true, encoding: .utf8)
        return true
    }
}
