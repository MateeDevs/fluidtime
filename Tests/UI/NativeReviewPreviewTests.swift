import AppKit
@testable import FluidtimeCore
import Testing

/// Explicitly opt-in visual review. Static stores cannot execute effects or mutate system services.
@MainActor
struct NativeReviewPreviewTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["FLUIDTIME_CAPTURE_REVIEW"] == "1"))
    func `capture review matrix`() throws {
        #expect(Bundle.main.bundleIdentifier != "cz.matee.fluidtime")
        if let language = ProcessInfo.processInfo.environment["FLUIDTIME_PREVIEW_LANGUAGE"] {
            print("Preview language: \(language), Settings: \(String(localized: .settings))")
            print("Preferred languages: \(Locale.preferredLanguages), locale: \(Locale.current.identifier)")
            // A localized host must also declare this language for Foundation-based labels.
            let expected = ["cs": "Nastavení", "sk": "Nastavenia"][language]
            if let expected {
                try #require(String(localized: .settings) == expected)
            }
        }
        NSApplication.shared.setActivationPolicy(.accessory)
        let fixtures = try ReviewPreviewFixtures()
        var cases = fixtures.menuCases() + fixtures.overviewCases() + fixtures.historyCases()
            + fixtures.earningsCases() + fixtures.accountCases() + fixtures.trackingCases()
            + fixtures.menuSettingsCases() + fixtures.generalCases() + fixtures.workspaceSettingsCases()
            + fixtures.rateSettingsCases() + fixtures.labelCases()
        cases += try fixtures.editorCases() + fixtures.feedbackCases()
        cases += try fixtures.runtimeCases()
        cases += fixtures.stressCases()
        cases += fixtures.navigationCases()
        cases += fixtures.generalBottomCases()
        cases += fixtures.readmeCases()
        cases += variations(cases)
        if let names = ProcessInfo.processInfo.environment["FLUIDTIME_PREVIEW_NAMES"] {
            let names = Set(names.split(separator: ",").map(String.init))
            cases = cases.filter { names.contains($0.name) }
        }
        if let limit = ProcessInfo.processInfo.environment["FLUIDTIME_PREVIEW_LIMIT"].flatMap(Int.init) {
            cases = Array(cases.prefix(limit))
        }
        let capture = try ReviewPreviewCapture()
        for item in cases {
            try capture.capture(item)
        }
        try capture.finish()
        print("Review captures: \(cases.count), saved to \(capture.directory.path)")
    }

    private func variations(_ cases: [ReviewPreviewCase]) -> [ReviewPreviewCase] {
        let darkNames = [
            "menu-running", "menu-idle", "settings-tracking", "settings-menubar-elapsed", "settings-general",
            "settings-workspace", "settings-earnings-unlocked", "editor-completed", "feedback-started",
            "feedback-stopped", "feedback-failed"
        ]
        var result = cases.filter { darkNames.contains($0.name) }.map { item in
            var dark = ReviewPreviewCase(item.name + "-dark", item.screen, state: item.state)
            dark.editor = item.editor
            dark.dark = true
            return dark
        }
        if let base = cases.first(where: { $0.name == "main-history-minimum" }) {
            var contrast = ReviewPreviewCase("main-history-high-contrast", .main, state: base.state)
            contrast.size = base.size
            contrast.increasedContrast = true
            result.append(contrast)
        }
        if let base = cases.first(where: { $0.name == "main-overview-minimum" }) {
            var rtl = ReviewPreviewCase("main-overview-right-to-left", .main, state: base.state)
            rtl.size = base.size
            rtl.rightToLeft = true
            result.append(rtl)
        }
        return result
    }
}
