import ComposableArchitecture
import Foundation

extension PreferencesClient: DependencyKey {
    static let liveValue = Self.live(store: PreferencesStore(defaults: .standard))

    static func live(store: PreferencesStore) -> Self {
        Self(
            load: { store.load() },
            setInstance: { store.setInstance($0) },
            setMembership: { store.setMembership($0) },
            setMenuBarUsesProjectColor: { store.setMenuBarUsesProjectColor($0) },
            setMenuBarShowsSeconds: { store.setMenuBarShowsSeconds($0) },
            setMenuBarDisplay: { store.setMenuBarDisplay($0) },
            setWorkspace: { store.setWorkspace($0) },
            setProjectVisibility: { store.setProjectVisibility($0) }
        )
    }
}
