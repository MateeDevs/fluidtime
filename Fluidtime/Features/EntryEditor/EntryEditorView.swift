import ComposableArchitecture
import SwiftUI

@ViewAction(for: EntryEditorFeature.self)
struct EntryEditorView: View {
    @Bindable var store: StoreOf<EntryEditorFeature>
    @FocusState private var isDescriptionFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.editTimeEntry).font(.headline).fontWeight(.semibold)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Form {
                        TextField(.description, text: $store.draft.description, axis: .vertical).lineLimit(2 ... 5)
                            .focused($isDescriptionFocused)
                        DatePicker(.editorStart, selection: $store.draft.start, in: ...Date.now)
                        if store.draft.end != nil {
                            DatePicker(.editorEnd, selection: Binding(
                                get: { store.draft.end ?? store.draft.start }, set: { send(.binding(.set(
                                    \.draft.end,
                                    $0
                                ))) }
                            ), in: ...Date.now)
                        }
                        ProjectPicker(projects: store.selectableProjects, selected: Binding(
                            get: { store.draft.projectId }, set: { send(.projectChanged($0)) }
                        ), currentProject: store.projects.first { $0.id == store.draft.projectId })
                        Toggle(.historyBillable, isOn: Binding(
                            get: { store.billable }, set: { send(.billableChanged($0)) }
                        ))
                        Text(.editorBillableHelp).font(.callout).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let error = store.error {
                        Text(error).font(.callout).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            HStack {
                if store.showsProgress {
                    ProgressView().controlSize(.small).accessibilityLabel(.editorSaving)
                }
                Spacer()
                Button(.cancel) { send(.cancelTapped) }.keyboardShortcut(.cancelAction)
                Button(.saveChanges) { send(.saveTapped) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 320, maxHeight: .infinity)
        .disabled(store.isSaving)
        .interactiveDismissDisabled(store.isSaving)
        .onAppear { isDescriptionFocused = true }
    }
}
