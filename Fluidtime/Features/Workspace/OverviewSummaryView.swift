import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkspaceFeature.self)
struct OverviewSummaryView: View {
    @Bindable var store: StoreOf<WorkspaceFeature>
    let earnings: StoreOf<EarningsFeature>
    let data: SessionData
    let preferences: WorkspacePreferences
    let analysis: TimeAnalysis
    let now: Date

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(.analyticsSelectedPeriod).font(.headline)
                metrics(analysis)
                if preferences.earningsEnabled {
                    EarningsOverviewSection(store: earnings, workspace: store, analysis: analysis,
                                            today: analysis(.day, at: now),
                                            isSynced: data.lastSynced != nil)
                }
                Text(.analyticsCurrentTotals).font(.headline)
                currentTotals(at: now)
                goals(at: now)

            }.padding(16)
        }
    }

    private func metrics(_ analysis: TimeAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            MetricGrid {
                metric(.analyticsWorkTime, analysis.work, explanation: .analyticsWorkHelp)
                metric(.analyticsLunchTime, analysis.lunch, explanation: .analyticsLunchHelp)
                metric(.analyticsTimeAtWork, analysis.timeAtWork, explanation: .analyticsAttendanceHelp)
                metric(.analyticsUntrackedGaps, analysis.gaps, explanation: .analyticsGapsHelp)
            }
        }
    }

    private func currentTotals(at now: Date) -> some View {
        MetricGrid {
            metric(.analyticsTodayWork, analysis(.day, at: now).work)
            metric(.analyticsWeekWork, analysis(.weekOfYear, at: now).work)
            metric(.analyticsMonthWork, analysis(.month, at: now).work)
            metric(.analyticsTodayAtWork, analysis(.day, at: now).timeAtWork)
        }
    }

    private func goals(at now: Date) -> some View {
        GroupBox {
            VStack(spacing: 14) {
                if preferences.dailyGoalHours > 0 {
                    goal(.goalsDaily, value: analysis(.day, at: now).work, hours: preferences.dailyGoalHours)
                }
                if preferences.weeklyGoalHours > 0 {
                    goal(.goalsWeekly, value: analysis(.weekOfYear, at: now).work, hours: preferences.weeklyGoalHours)
                }
                if preferences.dailyGoalHours == 0, preferences.weeklyGoalHours == 0 {
                    Text(.goalsDisabled).foregroundStyle(.secondary)
                }
            }.padding(6)
        } label: { Text(.goalsTitle) }
    }

    private func goal(_ title: LocalizedStringResource, value: TimeInterval, hours: Double) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                Spacer()
                Text(TrackedTime.clock(value, showsSeconds: false) + " / " + TrackedTime.clock(
                    hours * 3600,
                    showsSeconds: false
                ))
                .monospacedDigit()
            }
            ProgressView(value: min(value, hours * 3600), total: hours * 3600)
            HStack {
                Text(.goalsRemaining).font(.caption).foregroundStyle(.secondary)
                Text(TrackedTime.clock(max(0, hours * 3600 - value), showsSeconds: false))
                    .font(.caption.monospacedDigit())
            }
        }
    }

    private func metric(
        _ title: LocalizedStringResource,
        _ seconds: TimeInterval,
        explanation: LocalizedStringResource? = nil
    ) -> some View {
        MetricView(title: title, value: TrackedTime.clock(seconds), explanation: explanation)
    }

    private func analysis(_ component: Calendar.Component, at now: Date) -> TimeAnalysis {
        let interval = store.calendar.dateInterval(of: component, for: now) ?? DateInterval(start: now, duration: 0)
        return TimeAnalysis(entries: data.entries, calendar: store.calendar, interval: interval, now: now)
    }
}
