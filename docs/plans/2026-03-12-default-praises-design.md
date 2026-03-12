# Default Praises Seed Data

## Goal

Provide ~40 default praise messages on first launch so the app works out of the box without requiring manual data entry.

## Content

- **~28 German** — mix of romantic, appreciative, and playful
- **~4 French**
- **~4 Italian**
- **~4 Romansch** — each with German translation in parentheses

## Implementation

### Seed File

Bundled JSON file at `Praisabot/Resources/DefaultPraises.json`:

```json
[
  "Du bist wunderbar",
  "Ti amo (Ich liebe dich)",
  ...
]
```

Plain string array — each entry becomes a `PraiseMessage`.

### Seeding Logic

On app launch in `PraisabotApp`:

1. Query SwiftData for count of `PraiseMessage`
2. If count == 0, load `DefaultPraises.json` from bundle
3. Decode as `[String]`, create a `PraiseMessage` for each entry
4. Save to SwiftData model context

One-time operation. If the user later deletes all messages, they stay deleted (respects user intent).

### File Changes

| File | Change |
|------|--------|
| `Praisabot/Resources/DefaultPraises.json` | New — seed data |
| `Praisabot/App/PraisabotApp.swift` | Add seeding call on launch |
| `project.yml` | Add Resources directory to sources if needed |
