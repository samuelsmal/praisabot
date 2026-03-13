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
            }
            Spacer()
            Toggle("", isOn: $milestone.isEnabled)
                .labelsHidden()
        }
    }
}
