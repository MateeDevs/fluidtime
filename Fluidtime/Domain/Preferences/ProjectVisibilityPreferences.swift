import Foundation

struct ProjectVisibilityPreferences: Codable, Equatable, Sendable {
    private(set) var hiddenProjects: [String: Set<String>] = [:]

    func hiddenIDs(in scope: String) -> Set<String> {
        hiddenProjects[scope] ?? []
    }

    mutating func setVisible(_ visible: Bool, projectID: String, in scope: String) {
        setVisible(visible, projectIDs: [projectID], in: scope)
    }

    mutating func setVisible(_ visible: Bool, projectIDs: Set<String>, in scope: String) {
        let existing = hiddenIDs(in: scope)
        let hidden = visible ? existing.subtracting(projectIDs) : existing.union(projectIDs)
        hiddenProjects[scope] = hidden.isEmpty ? nil : hidden
    }
}
