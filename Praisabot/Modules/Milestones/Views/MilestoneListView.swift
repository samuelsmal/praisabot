import SwiftData
import SwiftUI

struct MilestoneListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DateMilestone.createdAt) private var milestones: [DateMilestone]
    @State private var showingAddForm = false
    @State private var editingMilestone: DateMilestone?

    var body: some View {
        NavigationStack {
            List {
                ForEach(milestones) { milestone in
                    MilestoneRow(milestone: milestone)
                        .onTapGesture {
                            editingMilestone = milestone
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(milestone)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .navigationTitle("Dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddForm) {
                MilestoneFormView()
            }
            .sheet(item: $editingMilestone) { milestone in
                MilestoneFormView(milestone: milestone)
            }
        }
    }
}

struct MilestoneRow: View {
    @Bindable var milestone: DateMilestone

    private var upcomingTriggers: [MilestoneChecker.UpcomingTrigger] {
        MilestoneChecker().nextTriggerDates(
            referenceDate: milestone.referenceDate,
            preset: milestone.triggerPreset,
            interval: milestone.triggerInterval,
            daysList: milestone.triggerDaysList
        )
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.name)
                    .font(.headline)
                Text(milestone.referenceDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(milestone.triggerPreset.label)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if !upcomingTriggers.isEmpty {
                    Divider()
                    ForEach(Array(upcomingTriggers.enumerated()), id: \.offset) { _, trigger in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(trigger.date, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(exampleMessage(for: trigger))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .italic()
                        }
                    }
                }
            }
            Spacer()
            Toggle("", isOn: $milestone.isEnabled)
                .labelsHidden()
        }
    }

    private func exampleMessage(for trigger: MilestoneChecker.UpcomingTrigger) -> String {
        let templates = (milestone.messages ?? []).map(\.template)
        let pool = templates.isEmpty ? [milestone.messageTemplate] : templates
        let template = pool.first ?? ""
        return MilestoneChecker().renderTemplate(template, value: trigger.result.value, unit: trigger.result.unit)
    }
}
