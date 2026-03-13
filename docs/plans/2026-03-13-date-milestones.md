# Date-Based Milestone Messages — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:executing-plans to implement this plan task-by-task.

**Goal:** Let users define date entries with trigger conditions that send Telegram messages when milestones are hit, independent of the daily praise rotation.

**Architecture:** New `DateMilestone` SwiftData model with enums for direction and trigger presets. A `MilestoneChecker` service evaluates triggers daily and sends messages via the existing `TelegramService`. New "Dates" tab for CRUD.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Swift Testing

---

### Task 0: Create Direction and TriggerPreset enums

**Files:**
- Create: `Praisabot/Modules/Milestones/Models/Direction.swift`
- Create: `Praisabot/Modules/Milestones/Models/TriggerPreset.swift`

**Step 1: Create Direction enum**

```swift
// Praisabot/Modules/Milestones/Models/Direction.swift
import Foundation

enum Direction: String, Codable, CaseIterable {
    case countingUp
    case countingDown
}
```

**Step 2: Create TriggerPreset enum**

```swift
// Praisabot/Modules/Milestones/Models/TriggerPreset.swift
import Foundation

enum TriggerPreset: String, Codable, CaseIterable {
    case everyNSeconds
    case everyNDays
    case everyNMonths
    case everyNYears
    case dailyLastNDays
    case everyNDaysRemaining
    case atSpecificDaysRemaining

    var isCountingUp: Bool {
        switch self {
        case .everyNSeconds, .everyNDays, .everyNMonths, .everyNYears:
            true
        case .dailyLastNDays, .everyNDaysRemaining, .atSpecificDaysRemaining:
            false
        }
    }

    var label: String {
        switch self {
        case .everyNSeconds: "Every N seconds"
        case .everyNDays: "Every N days"
        case .everyNMonths: "Every N months"
        case .everyNYears: "Every N years"
        case .dailyLastNDays: "Daily in last N days"
        case .everyNDaysRemaining: "Every N days remaining"
        case .atSpecificDaysRemaining: "At specific days remaining"
        }
    }

    var unit: String {
        switch self {
        case .everyNSeconds: "seconds"
        case .everyNDays, .everyNDaysRemaining, .atSpecificDaysRemaining, .dailyLastNDays: "days"
        case .everyNMonths: "months"
        case .everyNYears: "years"
        }
    }

    static func presetsFor(direction: Direction) -> [TriggerPreset] {
        allCases.filter { $0.isCountingUp == (direction == .countingUp) }
    }
}
```

**Step 3: Commit**

```bash
git add Praisabot/Modules/Milestones/Models/Direction.swift Praisabot/Modules/Milestones/Models/TriggerPreset.swift
git commit -m "feat(milestones): add Direction and TriggerPreset enums"
```

---

### Task 1: Create DateMilestone SwiftData model

**Files:**
- Create: `Praisabot/Modules/Milestones/Models/DateMilestone.swift`
- Create: `PraisabotTests/DateMilestoneTests.swift`

**Step 1: Write the test**

```swift
// PraisabotTests/DateMilestoneTests.swift
import Foundation
import SwiftData
import Testing

@testable import Praisabot

@Test func dateMilestoneInitSetsDefaults() {
    let milestone = DateMilestone(
        name: "Together",
        referenceDate: Date.now,
        direction: .countingUp,
        messageTemplate: "We are {value} {unit} together!",
        triggerPreset: .everyNSeconds,
        triggerInterval: 50000
    )

    #expect(milestone.name == "Together")
    #expect(milestone.direction == .countingUp)
    #expect(milestone.triggerPreset == .everyNSeconds)
    #expect(milestone.triggerInterval == 50000)
    #expect(milestone.isEnabled == true)
    #expect(milestone.triggerDaysList == nil)
}

@Test func dateMilestoneWithSpecificDays() {
    let milestone = DateMilestone(
        name: "Countdown",
        referenceDate: Date.now,
        direction: .countingDown,
        messageTemplate: "Only {value} {unit} left!",
        triggerPreset: .atSpecificDaysRemaining,
        triggerInterval: 0,
        triggerDaysList: "100,50,10"
    )

    #expect(milestone.triggerDaysList == "100,50,10")
    #expect(milestone.triggerDaysArray == [100, 50, 10])
}
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `DateMilestone` not defined

**Step 3: Write the model**

```swift
// Praisabot/Modules/Milestones/Models/DateMilestone.swift
import Foundation
import SwiftData

@Model
final class DateMilestone {
    var id: UUID
    var name: String
    var referenceDate: Date
    var directionRaw: String
    var messageTemplate: String
    var triggerPresetRaw: String
    var triggerInterval: Int
    var triggerDaysList: String?
    var isEnabled: Bool
    var createdAt: Date

    var direction: Direction {
        get { Direction(rawValue: directionRaw) ?? .countingUp }
        set { directionRaw = newValue.rawValue }
    }

    var triggerPreset: TriggerPreset {
        get { TriggerPreset(rawValue: triggerPresetRaw) ?? .everyNDays }
        set { triggerPresetRaw = newValue.rawValue }
    }

    var triggerDaysArray: [Int] {
        guard let list = triggerDaysList else { return [] }
        return list.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }

    init(
        name: String,
        referenceDate: Date,
        direction: Direction,
        messageTemplate: String,
        triggerPreset: TriggerPreset,
        triggerInterval: Int,
        triggerDaysList: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.referenceDate = referenceDate
        self.directionRaw = direction.rawValue
        self.messageTemplate = messageTemplate
        self.triggerPresetRaw = triggerPreset.rawValue
        self.triggerInterval = triggerInterval
        self.triggerDaysList = triggerDaysList
        self.isEnabled = true
        self.createdAt = Date.now
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `make test`
Expected: PASS

**Step 5: Commit**

```bash
git add Praisabot/Modules/Milestones/Models/DateMilestone.swift PraisabotTests/DateMilestoneTests.swift
git commit -m "feat(milestones): add DateMilestone SwiftData model"
```

---

### Task 2: Create MilestoneChecker service — trigger evaluation

**Files:**
- Create: `Praisabot/Modules/Milestones/Services/MilestoneChecker.swift`
- Create: `PraisabotTests/MilestoneCheckerTests.swift`

**Step 1: Write tests for each trigger preset**

```swift
// PraisabotTests/MilestoneCheckerTests.swift
import Foundation
import Testing

@testable import Praisabot

@Test func everyNSecondsTriggersOnBoundary() {
    let checker = MilestoneChecker()
    let ref = Date.now.addingTimeInterval(-50000) // exactly 50k seconds ago
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .everyNSeconds,
        interval: 50000,
        daysList: nil,
        now: Date.now
    )
    #expect(result != nil)
    #expect(result?.value == 50000)
    #expect(result?.unit == "seconds")
}

@Test func everyNSecondsDoesNotTriggerOffBoundary() {
    let checker = MilestoneChecker()
    let ref = Date.now.addingTimeInterval(-50500) // 50.5k seconds, not on boundary
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .everyNSeconds,
        interval: 50000,
        daysList: nil,
        now: Date.now
    )
    // 50000 boundary was crossed yesterday (within last 24h window), so this should trigger
    // The checker uses a 24h window: did a boundary cross since yesterday?
    #expect(result != nil)
}

@Test func everyNDaysTriggersOnBoundary() {
    let checker = MilestoneChecker()
    let cal = Calendar.current
    let ref = cal.date(byAdding: .day, value: -100, to: Date.now)!
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .everyNDays,
        interval: 100,
        daysList: nil,
        now: Date.now
    )
    #expect(result != nil)
    #expect(result?.value == 100)
}

@Test func everyNDaysDoesNotTriggerOffBoundary() {
    let checker = MilestoneChecker()
    let cal = Calendar.current
    let ref = cal.date(byAdding: .day, value: -101, to: Date.now)!
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .everyNDays,
        interval: 100,
        daysList: nil,
        now: Date.now
    )
    #expect(result == nil)
}

@Test func everyNMonthsTriggersOnBoundary() {
    let checker = MilestoneChecker()
    let cal = Calendar.current
    let ref = cal.date(byAdding: .month, value: -6, to: Date.now)!
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .everyNMonths,
        interval: 6,
        daysList: nil,
        now: Date.now
    )
    #expect(result != nil)
    #expect(result?.value == 6)
}

@Test func everyNYearsTriggersOnBoundary() {
    let checker = MilestoneChecker()
    let cal = Calendar.current
    let ref = cal.date(byAdding: .year, value: -2, to: Date.now)!
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .everyNYears,
        interval: 1,
        daysList: nil,
        now: Date.now
    )
    #expect(result != nil)
    #expect(result?.value == 2)
}

@Test func dailyLastNDaysTriggersWhenWithinRange() {
    let checker = MilestoneChecker()
    let cal = Calendar.current
    let ref = cal.date(byAdding: .day, value: 5, to: Date.now)! // 5 days from now
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .dailyLastNDays,
        interval: 7,
        daysList: nil,
        now: Date.now
    )
    #expect(result != nil)
    #expect(result?.value == 5)
}

@Test func dailyLastNDaysDoesNotTriggerOutsideRange() {
    let checker = MilestoneChecker()
    let cal = Calendar.current
    let ref = cal.date(byAdding: .day, value: 10, to: Date.now)! // 10 days from now
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .dailyLastNDays,
        interval: 7,
        daysList: nil,
        now: Date.now
    )
    #expect(result == nil)
}

@Test func everyNDaysRemainingTriggers() {
    let checker = MilestoneChecker()
    let cal = Calendar.current
    let ref = cal.date(byAdding: .day, value: 200, to: Date.now)!
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .everyNDaysRemaining,
        interval: 100,
        daysList: nil,
        now: Date.now
    )
    #expect(result != nil)
    #expect(result?.value == 200)
}

@Test func atSpecificDaysRemainingTriggers() {
    let checker = MilestoneChecker()
    let cal = Calendar.current
    let ref = cal.date(byAdding: .day, value: 50, to: Date.now)!
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .atSpecificDaysRemaining,
        interval: 0,
        daysList: "100,50,10",
        now: Date.now
    )
    #expect(result != nil)
    #expect(result?.value == 50)
}

@Test func atSpecificDaysRemainingDoesNotTrigger() {
    let checker = MilestoneChecker()
    let cal = Calendar.current
    let ref = cal.date(byAdding: .day, value: 51, to: Date.now)!
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .atSpecificDaysRemaining,
        interval: 0,
        daysList: "100,50,10",
        now: Date.now
    )
    #expect(result == nil)
}

@Test func templateRendering() {
    let checker = MilestoneChecker()
    let rendered = checker.renderTemplate(
        "We are {value} {unit} together!",
        value: 50000,
        unit: "seconds"
    )
    #expect(rendered == "We are 50000 seconds together!")
}
```

**Step 2: Run tests to verify they fail**

Run: `make test`
Expected: FAIL — `MilestoneChecker` not defined

**Step 3: Implement MilestoneChecker**

```swift
// Praisabot/Modules/Milestones/Services/MilestoneChecker.swift
import Foundation
import SwiftData

struct MilestoneCheckerResult {
    let value: Int
    let unit: String
}

struct MilestoneChecker: Sendable {

    func evaluate(
        referenceDate: Date,
        preset: TriggerPreset,
        interval: Int,
        daysList: String?,
        now: Date = .now
    ) -> MilestoneCheckerResult? {
        let cal = Calendar.current

        switch preset {
        case .everyNSeconds:
            let elapsed = Int(now.timeIntervalSince(referenceDate))
            guard interval > 0, elapsed > 0 else { return nil }
            let currentMultiple = elapsed / interval
            let yesterdayElapsed = elapsed - 86400
            let previousMultiple = max(0, yesterdayElapsed / interval)
            guard currentMultiple > previousMultiple else { return nil }
            return MilestoneCheckerResult(value: currentMultiple * interval, unit: "seconds")

        case .everyNDays:
            let days = cal.dateComponents([.day], from: referenceDate, to: now).day ?? 0
            guard interval > 0, days > 0, days % interval == 0 else { return nil }
            return MilestoneCheckerResult(value: days, unit: "days")

        case .everyNMonths:
            let months = cal.dateComponents([.month], from: referenceDate, to: now).month ?? 0
            guard interval > 0, months > 0, months % interval == 0 else { return nil }
            // Only trigger on the actual day-of-month match
            let refDay = cal.component(.day, from: referenceDate)
            let nowDay = cal.component(.day, from: now)
            guard refDay == nowDay else { return nil }
            return MilestoneCheckerResult(value: months, unit: "months")

        case .everyNYears:
            let years = cal.dateComponents([.year], from: referenceDate, to: now).year ?? 0
            guard interval > 0, years > 0, years % interval == 0 else { return nil }
            let refComps = cal.dateComponents([.month, .day], from: referenceDate)
            let nowComps = cal.dateComponents([.month, .day], from: now)
            guard refComps.month == nowComps.month, refComps.day == nowComps.day else { return nil }
            return MilestoneCheckerResult(value: years, unit: "years")

        case .dailyLastNDays:
            let daysRemaining = cal.dateComponents([.day], from: now, to: referenceDate).day ?? 0
            guard daysRemaining > 0, daysRemaining <= interval else { return nil }
            return MilestoneCheckerResult(value: daysRemaining, unit: "days")

        case .everyNDaysRemaining:
            let daysRemaining = cal.dateComponents([.day], from: now, to: referenceDate).day ?? 0
            guard interval > 0, daysRemaining > 0, daysRemaining % interval == 0 else { return nil }
            return MilestoneCheckerResult(value: daysRemaining, unit: "days")

        case .atSpecificDaysRemaining:
            let daysRemaining = cal.dateComponents([.day], from: now, to: referenceDate).day ?? 0
            let specificDays = daysList?.split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) } ?? []
            guard specificDays.contains(daysRemaining) else { return nil }
            return MilestoneCheckerResult(value: daysRemaining, unit: "days")
        }
    }

    func renderTemplate(_ template: String, value: Int, unit: String) -> String {
        template
            .replacingOccurrences(of: "{value}", with: "\(value)")
            .replacingOccurrences(of: "{unit}", with: unit)
    }

    func checkAndSend(modelContainer: ModelContainer) async throws {
        let context = ModelContext(modelContainer)
        let telegram = TelegramService()
        let keychain = KeychainService()

        guard let botToken = keychain.load(key: "botToken"), !botToken.isEmpty else { return }
        let chatID = UserDefaults.standard.string(forKey: "telegramChatID") ?? ""
        guard !chatID.isEmpty else { return }

        let descriptor = FetchDescriptor<DateMilestone>(
            predicate: #Predicate<DateMilestone> { $0.isEnabled }
        )
        let milestones = try context.fetch(descriptor)

        for milestone in milestones {
            if let result = evaluate(
                referenceDate: milestone.referenceDate,
                preset: milestone.triggerPreset,
                interval: milestone.triggerInterval,
                daysList: milestone.triggerDaysList
            ) {
                let text = renderTemplate(milestone.messageTemplate, value: result.value, unit: result.unit)
                try await telegram.send(botToken: botToken, chatID: chatID, text: text)
            }
        }
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `make test`
Expected: PASS

**Step 5: Commit**

```bash
git add Praisabot/Modules/Milestones/Services/MilestoneChecker.swift PraisabotTests/MilestoneCheckerTests.swift
git commit -m "feat(milestones): add MilestoneChecker service with trigger evaluation"
```

---

### Task 3: Register DateMilestone in ModelContainer and integrate with scheduler

**Files:**
- Modify: `Praisabot/App/PraisabotApp.swift:10` — add `DateMilestone.self` to ModelContainer
- Modify: `Praisabot/Modules/Scheduler/Services/PraiseScheduler.swift:42-61` — call MilestoneChecker after praise

**Step 1: Update PraisabotApp to register DateMilestone**

In `PraisabotApp.swift`, change line 10:

```swift
// Before:
let container = try! ModelContainer(for: PraiseMessage.self)
// After:
let container = try! ModelContainer(for: PraiseMessage.self, DateMilestone.self)
```

**Step 2: Add milestone check to PraiseScheduler.sendPraise**

In `PraiseScheduler.swift`, add after line 60 (before the closing brace of `sendPraise`):

```swift
        // Check milestones independently
        let milestoneChecker = MilestoneChecker()
        try await milestoneChecker.checkAndSend(modelContainer: modelContainer)
```

**Step 3: Also call milestones from retryIfNeeded in PraisabotApp**

No change needed — `retryIfNeeded` calls `PraiseScheduler.sendPraise`, which now includes milestone checks.

**Step 4: Build to verify compilation**

Run: `make build`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Praisabot/App/PraisabotApp.swift Praisabot/Modules/Scheduler/Services/PraiseScheduler.swift
git commit -m "feat(milestones): register DateMilestone model and integrate with scheduler"
```

---

### Task 4: Create MilestoneListView

**Files:**
- Create: `Praisabot/Modules/Milestones/Views/MilestoneListView.swift`

**Step 1: Create the list view**

```swift
// Praisabot/Modules/Milestones/Views/MilestoneListView.swift
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
```

**Step 2: Build to verify**

Run: `make build`
Expected: BUILD SUCCEEDED (MilestoneFormView not yet created — will fail; that's Task 5)

**Note:** This task depends on Task 5 (MilestoneFormView) to compile. Build both together.

**Step 3: Commit** (after Task 5)

---

### Task 5: Create MilestoneFormView

**Files:**
- Create: `Praisabot/Modules/Milestones/Views/MilestoneFormView.swift`

**Step 1: Create the add/edit form**

```swift
// Praisabot/Modules/Milestones/Views/MilestoneFormView.swift
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
    @State private var messageTemplate: String = ""

    private var isEditing: Bool { milestone != nil }

    private var availablePresets: [TriggerPreset] {
        TriggerPreset.presetsFor(direction: direction)
    }

    private var previewText: String {
        let checker = MilestoneChecker()
        if let result = checker.evaluate(
            referenceDate: referenceDate,
            preset: triggerPreset,
            interval: triggerInterval,
            daysList: triggerPreset == .atSpecificDaysRemaining ? triggerDaysList : nil
        ) {
            return checker.renderTemplate(messageTemplate, value: result.value, unit: result.unit)
        }
        // Show a sample preview even when not triggering today
        let sampleValue = triggerPreset == .atSpecificDaysRemaining ? 50 : triggerInterval
        return checker.renderTemplate(messageTemplate, value: sampleValue, unit: triggerPreset.unit)
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

                Section("Message") {
                    TextField("Template", text: $messageTemplate, axis: .vertical)
                        .lineLimit(3...6)
                    Text("Use {value} and {unit} as placeholders")
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
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || messageTemplate.trimmingCharacters(in: .whitespaces).isEmpty)
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
                    messageTemplate = m.messageTemplate
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
        if let m = milestone {
            m.name = name.trimmingCharacters(in: .whitespaces)
            m.referenceDate = referenceDate
            m.direction = direction
            m.triggerPreset = triggerPreset
            m.triggerInterval = triggerInterval
            m.triggerDaysList = triggerPreset == .atSpecificDaysRemaining ? triggerDaysList : nil
            m.messageTemplate = messageTemplate
        } else {
            let m = DateMilestone(
                name: name.trimmingCharacters(in: .whitespaces),
                referenceDate: referenceDate,
                direction: direction,
                messageTemplate: messageTemplate,
                triggerPreset: triggerPreset,
                triggerInterval: triggerInterval,
                triggerDaysList: triggerPreset == .atSpecificDaysRemaining ? triggerDaysList : nil
            )
            modelContext.insert(m)
        }
    }
}
```

**Step 2: Build to verify**

Run: `make build`
Expected: BUILD SUCCEEDED

**Step 3: Commit (Tasks 4 + 5 together)**

```bash
git add Praisabot/Modules/Milestones/Views/MilestoneListView.swift Praisabot/Modules/Milestones/Views/MilestoneFormView.swift
git commit -m "feat(milestones): add MilestoneListView and MilestoneFormView"
```

---

### Task 6: Add Dates tab to ContentView

**Files:**
- Modify: `Praisabot/App/ContentView.swift`

**Step 1: Add the new tab**

Replace ContentView body:

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Messages", systemImage: "message") {
                MessageListView()
            }
            Tab("Dates", systemImage: "calendar") {
                MilestoneListView()
            }
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
    }
}
```

**Step 2: Build and run to verify**

Run: `make build`
Expected: BUILD SUCCEEDED with three tabs

**Step 3: Commit**

```bash
git add Praisabot/App/ContentView.swift
git commit -m "feat(milestones): add Dates tab to ContentView"
```

---

### Task 7: Add BGTaskScheduler identifier for milestones (optional separation)

**Decision:** Since milestones piggyback on the praise scheduler's `sendPraise` call, no separate background task identifier is needed. The milestone check runs as part of the same daily wake. No changes to `project.yml` or `Info.plist`.

This task is a no-op — skip it.

---

### Task 8: End-to-end verification

**Step 1: Run full test suite**

Run: `make test`
Expected: All tests PASS

**Step 2: Build for simulator**

Run: `make build`
Expected: BUILD SUCCEEDED

**Step 3: Manual verification checklist**

- [ ] App launches with three tabs: Messages, Dates, Settings
- [ ] Dates tab shows empty state, "+" button visible
- [ ] Add form: name, date picker, direction segmented control, preset picker, interval, template, preview
- [ ] Changing direction filters available presets
- [ ] Save creates milestone, visible in list
- [ ] Toggle enables/disables milestone
- [ ] Swipe to delete works
- [ ] Tap to edit loads form with existing values
- [ ] Preview renders template with sample values
