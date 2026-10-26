import ComposableArchitecture
import SwiftUI

@ViewAction(for: EarningsFeature.self)
struct EarningsOverviewSection: View {
    let store: StoreOf<EarningsFeature>
    @Bindable var workspace: StoreOf<WorkspaceFeature>
    let analysis: TimeAnalysis
    let today: TimeAnalysis
    let isSynced: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            InfoLabel(title: .earningsEstimate, explanation: .earningsEstimateHelp).font(.headline)
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    if store.surface == .preview, let settings = store.settings {
                        HStack(alignment: .top, spacing: 12) {
                            ViewThatFits(in: .horizontal) {
                                HStack(alignment: .top, spacing: 24) { amounts(settings) }
                                    .frame(minWidth: 400)
                                VStack(alignment: .leading, spacing: 16) { amounts(settings) }
                            }
                            Button { send(.conceal(.preview)) } label: { Image(systemName: "eye.slash") }
                                .help(.earningsConceal)
                                .accessibilityLabel(.earningsConceal)
                        }
                        HStack {
                            Toggle(.earningsBillableOnly, isOn: $workspace.billableOnly)
                            InfoButton(title: .earningsBillableOnly, message: .earningsBillableHelp)
                        }
                    } else {
                        lockedContent
                    }
                    if let error = store.error {
                        Label(error, systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
            }
        }
        .onDisappear { send(.conceal(.preview)) }
    }

    @ViewBuilder
    private func amounts(_ settings: EarningsSettings) -> some View {
        amount(.analyticsSelectedPeriod, analysis: analysis, settings: settings)
        amount(.today, analysis: today, settings: settings)
    }

    private func amount(
        _ title: LocalizedStringResource,
        analysis: TimeAnalysis,
        settings: EarningsSettings
    ) -> some View {
        let value = EarningsCalculator.estimate(analysis, settings: settings, billableOnly: workspace.billableOnly)
        return VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value.formatted(.currency(code: settings.currency)))
                .font(.title2.monospacedDigit()).fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var lockedContent: some View {
        HStack(alignment: .top, spacing: 12) {
            Button { send(.reveal(.preview)) } label: {
                Image(systemName: "touchid").font(.title2).padding(6)
            }
            .buttonStyle(.plain).foregroundStyle(.tint)
            .help(.earningsReveal).accessibilityLabel(.earningsReveal)
            .disabled(cannotUnlock)
            VStack(alignment: .leading, spacing: 8) {
                Text(.earningsHidden).font(.headline)
                Text(.earningsPrivacyHelp).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Button(.earningsUnlockPreview) { send(.reveal(.preview)) }
                        .disabled(cannotUnlock)
                    if store.showsProgress {
                        ProgressView().controlSize(.small).accessibilityLabel(.earningsUnlocking)
                    }
                }
            }
        }
    }

    private var cannotUnlock: Bool {
        !isSynced || store.accountScope.isEmpty || store.operation != nil
    }
}
