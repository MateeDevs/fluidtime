import Foundation

extension SolidtimeAPI {
    func projects(organization: String) async throws -> [Project] {
        var projects: [Project] = []
        var page = 1
        while true {
            try Task.checkCancellation()
            let response: CollectionPage<Project> = try await request(
                "organizations/\(organization)/projects",
                query: [
                    URLQueryItem(name: "archived", value: "all"), URLQueryItem(name: "page", value: String(page))
                ]
            )
            projects += response.data
            if page >= (response.meta?.lastPage ?? 1) {
                break
            }
            page += 1
        }
        return projects.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
