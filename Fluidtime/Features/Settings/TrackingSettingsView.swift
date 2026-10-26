import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct TrackingSettingsView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Form {
            Section(.organization) {
                if store.isConnected {
                    Picker(
                        .trackTimeIn,
                        selection: $store.data.selectedMembershipId.sending(\.view.selectMembership)
                    ) {
                        ForEach(store.memberships) { membership in
                            Text(membership.organization.name).tag(membership.id)
                        }
                    }
                    .disabled(!store.canChangeAccount)
                    if store.showsProgress {
                        ProgressView().controlSize(.small).accessibilityLabel(.updatingSolidtime)
                    }
                } else {
                    Text(.connectYourAccountInTheAccountTabToChooseAnOrganization)
                        .foregroundStyle(.secondary)
                }
            }
            if store.isConnected {
                VisibleProjectsSettingsSection(store: store)
            }
            if let user = store.user {
                Section(.timeTotals) {
                    LabeledContent(String(localized: .timeZone), value: user.timezone)
                    LabeledContent(String(localized: .weekStartsOn), value: user.localizedWeekStart)
                    Text(.trackingTotalsHelp)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            if let error = store.error {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(.refreshTimeEntries) { send(.refreshTapped) }
                        .disabled(!store.isConfigured || !store.canChangeAccount)
                }
            }
        }
        .formStyle(.grouped)
    }
}
