# Log Tab Design

## Overview

Add a read-only "Log" tab showing a chronological history of all sent messages (praises and milestones) with delivery status.

## Data Model

New SwiftData model `SentMessageLog`:

- `id: UUID`
- `text: String` — the actual message sent
- `sentAt: Date` — timestamp
- `type: MessageType` — enum: `.praise` or `.milestone`
- `success: Bool` — whether Telegram API returned success
- `errorMessage: String?` — error detail on failure

Register `SentMessageLog` in the `ModelContainer` in `PraisabotApp.swift`.

## Logging Integration

Capture log entries at the two existing send points:

1. **PraiseScheduler** — after `TelegramService.send()` returns or throws, create a `SentMessageLog` entry with type `.praise`
2. **MilestoneChecker** — after milestone send succeeds or fails, create a `SentMessageLog` entry with type `.milestone`

## UI

- New tab at 3rd position: Messages, Dates, **Log**, Settings
- System image: `clock.arrow.circlepath`
- Flat `List` sorted by `sentAt` descending (newest first)
- Each row shows:
  - Message text (line-limited to ~2 lines)
  - Relative timestamp for recent entries, absolute date for older ones
  - Small badge/icon distinguishing praise vs milestone
  - Subtle red indicator if delivery failed, with error message shown inline or on tap

## Scope exclusions

- No resend, delete, or filtering actions
- No grouping or sections
- No export functionality
