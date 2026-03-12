# Default Praises Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:executing-plans to implement this plan task-by-task.

**Goal:** Seed ~40 default praise messages on first launch so the app works out of the box.

**Architecture:** A bundled JSON file contains the default praises. On app launch, if the SwiftData store is empty, the JSON is loaded and each string is inserted as a `PraiseMessage`.

**Tech Stack:** SwiftData, Swift 6, Foundation (JSONDecoder, Bundle)

---

### Task 1: Create the JSON seed file

**Files:**
- Create: `Praisabot/Resources/DefaultPraises.json`

**Step 1: Create the seed file**

Create `Praisabot/Resources/DefaultPraises.json`:

```json
[
  "Du bist das Beste, was mir je passiert ist",
  "Ich liebe es, wie du lachst",
  "Du machst mein Leben so viel schöner",
  "Ich bin so dankbar, dass es dich gibt",
  "Du bist mein Lieblingsmensch",
  "Dein Lächeln erhellt meinen Tag",
  "Ich bewundere deine Stärke",
  "Du inspirierst mich jeden Tag aufs Neue",
  "Mit dir fühlt sich alles leichter an",
  "Du bist so wunderschön — innen und aussen",
  "Ich liebe deine Art, die Welt zu sehen",
  "Du bist mein sicherer Hafen",
  "Jeder Moment mit dir ist ein Geschenk",
  "Ich liebe es, wie du für andere da bist",
  "Du bist unglaublich mutig",
  "Deine Umarmungen sind die besten der Welt",
  "Ich bin so stolz auf dich",
  "Du bist mein Lieblingschaos",
  "Du hast das schönste Herz",
  "Mit dir kann ich einfach ich selbst sein",
  "Du bist mein Zuhause",
  "Ich liebe dich mehr als Worte sagen können",
  "Du machst aus jedem Tag ein kleines Abenteuer",
  "Deine Augen sind mein Lieblingspaar Sterne",
  "Du bist die beste Entscheidung meines Lebens",
  "Ich vermisse dich, auch wenn du neben mir sitzt",
  "Dein Lachen ist meine Lieblingsmelodie",
  "Du bist mein Sonnenschein an grauen Tagen",
  "Tu es la plus belle chose qui me soit arrivée",
  "Je t'aime plus que les mots ne peuvent le dire",
  "Tu illumines ma vie chaque jour",
  "Mon cœur est à toi pour toujours",
  "Sei la cosa più bella della mia vita",
  "Ti amo con tutto il cuore",
  "Ogni momento con te è un regalo",
  "Sei il mio sole nei giorni di pioggia",
  "Ti port en il cor — mintga di (Ich trage dich im Herzen — jeden Tag)",
  "Ti es mia steila — la pli clera (Du bist mein Stern — der hellste)",
  "Jau t'am — oz e adina (Ich liebe dich — heute und immer)",
  "Cun tai è tut pli bel (Mit dir ist alles schöner)"
]
```

**Step 2: Verify valid JSON**

Run: `python3 -c "import json; json.load(open('Praisabot/Resources/DefaultPraises.json')); print('Valid JSON,', len(json.load(open('Praisabot/Resources/DefaultPraises.json'))), 'entries')"`
Expected: `Valid JSON, 40 entries`

**Step 3: Commit**

```bash
git add Praisabot/Resources/DefaultPraises.json
git commit -m "feat: add default praises JSON seed file with 40 messages"
```

---

### Task 2: Write the failing test for seed loading

**Files:**
- Create: `PraisabotTests/DefaultPraisesTests.swift`

**Step 1: Write the test**

```swift
import Foundation
import Testing

@testable import Praisabot

@Test func defaultPraisesFileIsValidJSON() throws {
    let url = Bundle(for: PraiseMessage.self).url(
        forResource: "DefaultPraises", withExtension: "json"
    )
    let unwrappedURL = try #require(url, "DefaultPraises.json not found in bundle")
    let data = try Data(contentsOf: unwrappedURL)
    let praises = try JSONDecoder().decode([String].self, from: data)
    #expect(praises.count >= 30)
    #expect(praises.allSatisfy { !$0.isEmpty })
}
```

Note: `Bundle(for:)` requires a class. Since `PraiseMessage` is a `@Model final class`, this works. If not, use `Bundle.main` — but in test targets `Bundle.main` is the test runner, not the app. An alternative is `Bundle(for: PraiseMessage.self)`.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project Praisabot.xcodeproj -scheme PraisabotTests -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PraisabotTests/DefaultPraisesTests 2>&1 | tail -20`
Expected: FAIL (bundle resource not found or compile error — confirms test is wired up)

**Step 3: Commit**

```bash
git add PraisabotTests/DefaultPraisesTests.swift
git commit -m "test: add failing test for default praises JSON loading"
```

---

### Task 3: Make the test pass (regenerate project)

**Step 1: Regenerate the Xcode project**

Run: `make generate`

This picks up the new `Resources/` directory and the new test file.

**Step 2: Run the test again**

Run: `xcodebuild test -project Praisabot.xcodeproj -scheme PraisabotTests -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PraisabotTests/DefaultPraisesTests 2>&1 | tail -20`
Expected: PASS

**Step 3: Commit**

```bash
git add -A
git commit -m "chore: regenerate project to include seed file and test"
```

---

### Task 4: Implement seeding logic in PraisabotApp

**Files:**
- Modify: `Praisabot/App/PraisabotApp.swift`

**Step 1: Add the seeding function**

Add a `seedDefaultPraisesIfNeeded` method to `PraisabotApp` and call it from `init()`:

```swift
import SwiftData
import SwiftUI

@main
struct PraisabotApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let modelContainer: ModelContainer

    init() {
        let container = try! ModelContainer(for: PraiseMessage.self)
        self.modelContainer = container
        Self.seedDefaultPraisesIfNeeded(modelContainer: container)
        PraiseScheduler.register(modelContainer: container)
        PraiseScheduler.scheduleNext()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                PraiseScheduler.scheduleNext()
                retryIfNeeded()
            }
        }
    }

    private func retryIfNeeded() {
        guard !PraiseScheduler.hasSentToday() else { return }
        Task {
            try? await PraiseScheduler.sendPraise(modelContainer: modelContainer)
        }
    }

    @MainActor
    private static func seedDefaultPraisesIfNeeded(modelContainer: ModelContainer) {
        let context = modelContainer.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<PraiseMessage>())) ?? 0
        guard count == 0 else { return }

        guard let url = Bundle.main.url(forResource: "DefaultPraises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let texts = try? JSONDecoder().decode([String].self, from: data)
        else { return }

        for text in texts {
            context.insert(PraiseMessage(text: text))
        }
        try? context.save()
    }
}
```

**Step 2: Build**

Run: `make build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Run all tests**

Run: `xcodebuild test -project Praisabot.xcodeproj -scheme PraisabotTests -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20`
Expected: All tests pass

**Step 4: Commit**

```bash
git add Praisabot/App/PraisabotApp.swift
git commit -m "feat: seed default praises on first launch when store is empty"
```

---

### Task 5: Manual smoke test

**Step 1: Clean install on simulator**

Run: `xcrun simctl shutdown all && xcrun simctl erase all && make run`

**Step 2: Verify**

- Messages tab shows 40 praises
- All praises display correctly (German, French, Italian, Romansch)
- Romansch entries show German translations in parentheses
- Delete all messages, kill app, relaunch → messages stay deleted (no re-seeding)
