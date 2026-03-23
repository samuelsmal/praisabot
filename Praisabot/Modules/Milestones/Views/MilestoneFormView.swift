import SwiftData
import SwiftUI

struct MilestoneFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var milestone: DateMilestone?

    @State private var name: String = ""
    @State private var referenceDate: Date = .now
    @State private var direction: Direction = .countingUp
    @State private var triggerPreset: TriggerPreset = .everyNDays
    @State private var triggerInterval: Int = 100
    @State private var triggerDaysList: String = ""
    @State private var messageTemplates: [String] = [""]

    private var isEditing: Bool { milestone != nil }

    private var availablePresets: [TriggerPreset] {
        TriggerPreset.presetsFor(direction: direction)
    }

    private var validTemplates: [String] {
        messageTemplates
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var previewText: String {
        let checker = MilestoneChecker()
        let template = validTemplates.first ?? ""
        if let result = checker.evaluate(
            referenceDate: referenceDate,
            preset: triggerPreset,
            interval: triggerInterval,
            daysList: triggerPreset == .atSpecificDaysRemaining ? triggerDaysList : nil
        ) {
            return checker.renderTemplate(template, value: result.value, unit: result.unit)
        }
        let sampleValue = triggerPreset == .atSpecificDaysRemaining ? 50 : triggerInterval
        return checker.renderTemplate(template, value: sampleValue, unit: triggerPreset.unit)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    DatePicker("Date", selection: $referenceDate, displayedComponents: .date)
                }

                Section("Direction") {
                    Picker("Direction", selection: $direction) {
                        Text("Counting up").tag(Direction.countingUp)
                        Text("Counting down").tag(Direction.countingDown)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Trigger") {
                    Picker("Condition", selection: $triggerPreset) {
                        ForEach(availablePresets, id: \.self) { preset in
                            Text(preset.label).tag(preset)
                        }
                    }
                    if triggerPreset == .atSpecificDaysRemaining {
                        TextField("Days (comma-separated)", text: $triggerDaysList)
                            .keyboardType(.numbersAndPunctuation)
                    } else {
                        HStack {
                            Text("Interval")
                            Spacer()
                            TextField("N", value: $triggerInterval, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }
                }

                Section("Messages") {
                    ForEach(messageTemplates.indices, id: \.self) { index in
                        HStack(alignment: .top) {
                            TextField("Template \(index + 1)", text: $messageTemplates[index], axis: .vertical)
                                .lineLimit(2...4)
                            if messageTemplates.count > 1 {
                                Button(role: .destructive) {
                                    messageTemplates.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    Button {
                        messageTemplates.append("")
                    } label: {
                        Label("Add Message", systemImage: "plus.circle")
                    }
                    Text("A random message will be sent each time. Use {value} and {unit} as placeholders.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Preview") {
                    Text(previewText)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            .navigationTitle(isEditing ? "Edit Date" : "New Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || validTemplates.isEmpty)
                }
            }
            .onAppear {
                if let m = milestone {
                    name = m.name
                    referenceDate = m.referenceDate
                    direction = m.direction
                    triggerPreset = m.triggerPreset
                    triggerInterval = m.triggerInterval
                    triggerDaysList = m.triggerDaysList ?? ""
                    let existing = (m.messages ?? []).map(\.template)
                    if existing.isEmpty && !m.messageTemplate.isEmpty {
                        messageTemplates = [m.messageTemplate]
                    } else if !existing.isEmpty {
                        messageTemplates = existing
                    }
                }
            }
            .onChange(of: direction) {
                // Reset preset when direction changes
                let presets = availablePresets
                if !presets.contains(triggerPreset), let first = presets.first {
                    triggerPreset = first
                }
            }
        }
    }

    private func save() {
        let templates = validTemplates

        if let m = milestone {
            m.name = name.trimmingCharacters(in: .whitespaces)
            m.referenceDate = referenceDate
            m.direction = direction
            m.triggerPreset = triggerPreset
            m.triggerInterval = triggerInterval
            m.triggerDaysList = triggerPreset == .atSpecificDaysRemaining ? triggerDaysList : nil
            m.messageTemplate = templates.first ?? ""
            // Replace existing messages
            for msg in m.messages ?? [] {
                modelContext.delete(msg)
            }
            m.messages = templates.map { MilestoneMessage(template: $0, milestone: m) }
        } else {
            let m = DateMilestone(
                name: name.trimmingCharacters(in: .whitespaces),
                referenceDate: referenceDate,
                direction: direction,
                messageTemplate: templates.first ?? "",
                triggerPreset: triggerPreset,
                triggerInterval: triggerInterval,
                triggerDaysList: triggerPreset == .atSpecificDaysRemaining ? triggerDaysList : nil
            )
            modelContext.insert(m)
            m.messages = templates.map { MilestoneMessage(template: $0, milestone: m) }
        }
    }
}
