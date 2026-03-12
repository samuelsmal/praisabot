# Changelog View Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:executing-plans to implement this plan task-by-task.

**Goal:** Add an in-app changelog view accessible from Settings, reading CHANGELOG.md from the app bundle at build time.

**Architecture:** CHANGELOG.md lives at the project root. A XcodeGen `preBuildScripts` entry copies it into `Praisabot/Resources/` before compilation so it gets bundled. A new `ChangelogView` loads and renders it with native SwiftUI markdown. A `NavigationLink` in `SettingsView` provides access.

**Tech Stack:** SwiftUI native markdown (`Text` with `LocalizedStringKey`), XcodeGen build scripts, `Bundle.main.url(forResource:withExtension:)`

---

### Task 0: Create CHANGELOG.md at project root

**Files:**
- Create: `CHANGELOG.md`

**Step 1: Create the changelog file**

Use [Keep a Changelog](https://keepachangelog.com) format. Populate from git history:

```markdown
# Changelog

All notable changes to Praisabot will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [0.1.0] - 2026-03-12

### Added
- Seed 40+ default praise messages on first launch (multilingual: DE, FR, IT, RM)
- Prevent re-seeding after user deletes all messages
- App icon with purple diagonal bands and white heart
- Background praise scheduling via BGAppRefreshTask (daily 8-9 AM)
- Shuffle-bag message rotation (no repeats until all sent)
- Message list with add, edit, and delete
- Settings view for Telegram bot token and chat ID
- Test message button to verify Telegram connectivity
- Portrait-only, full-screen layout
- In-app changelog viewer
```

**Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: add CHANGELOG.md with initial release history"
```

---

### Task 1: Add build script to copy CHANGELOG.md into app bundle

**Files:**
- Modify: `project.yml`
- Modify: `.gitignore` (add `Praisabot/Resources/CHANGELOG.md`)

**Step 1: Add preBuildScripts to project.yml**

Add under the `Praisabot` target, after `entitlements`:

```yaml
    preBuildScripts:
      - script: cp "${PROJECT_DIR}/CHANGELOG.md" "${PROJECT_DIR}/Praisabot/Resources/CHANGELOG.md"
        name: Copy Changelog
        inputFiles:
          - $(PROJECT_DIR)/CHANGELOG.md
        outputFiles:
          - $(PROJECT_DIR)/Praisabot/Resources/CHANGELOG.md
```

**Step 2: Add to .gitignore**

The copied file is a build artifact. Add to `.gitignore`:

```
Praisabot/Resources/CHANGELOG.md
```

**Step 3: Regenerate Xcode project**

```bash
make generate
```

**Step 4: Verify build**

```bash
make build
```

Expected: Build succeeds with `CHANGELOG.md` copied into the bundle.

**Step 5: Commit**

```bash
git add project.yml .gitignore
git commit -m "build: copy CHANGELOG.md into app bundle via pre-build script"
```

---

### Task 2: Create ChangelogView with markdown rendering

**Files:**
- Create: `Praisabot/Modules/Settings/Views/ChangelogView.swift`

**Step 1: Create the view**

```swift
import SwiftUI

struct ChangelogView: View {
    private let markdown: String

    init() {
        guard let url = Bundle.main.url(forResource: "CHANGELOG", withExtension: "md"),
              let content = try? String(contentsOf: url)
        else {
            markdown = "Changelog not available."
            return
        }
        markdown = content
    }

    var body: some View {
        ScrollView {
            Text(LocalizedStringKey(markdown))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Changelog")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

**Step 2: Verify build**

```bash
make build
```

Expected: Builds without errors.

**Step 3: Commit**

```bash
git add Praisabot/Modules/Settings/Views/ChangelogView.swift
git commit -m "feat: add ChangelogView with native markdown rendering"
```

---

### Task 3: Add NavigationLink in SettingsView

**Files:**
- Modify: `Praisabot/Modules/Settings/Views/SettingsView.swift`

**Step 1: Add a new section with NavigationLink**

After the test-message section (closing `}`), add:

```swift
Section {
    NavigationLink("Changelog") {
        ChangelogView()
    }
}
```

**Step 2: Verify build**

```bash
make build
```

Expected: Builds without errors.

**Step 3: Commit**

```bash
git add Praisabot/Modules/Settings/Views/SettingsView.swift
git commit -m "feat: add changelog link in settings"
```

---

### Task 4: Test and verify

**Step 1: Run tests**

```bash
make build
```

Expected: All builds pass.

**Step 2: Run on simulator**

```bash
make run
```

Expected: Navigate to Settings > Changelog and see the rendered markdown.

**Step 3: Visual verification**

- Changelog text renders with proper headings, bullets, and links
- Scrolling works for long changelogs
- Navigation title shows "Changelog"
- Back button returns to Settings
