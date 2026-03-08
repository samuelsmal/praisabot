# Praisabot Design

## Overview

iOS app that manages a collection of praise messages and automatically sends one per day (between 8-9 AM local time) to a partner via a Telegram bot. Fully on-device, no server.

## Architecture

Three feature modules following the template's feature-module pattern (`Modules/<Feature>/{Views,Models,Services}/`):

### 1. Messages

CRUD list of praise messages stored in SwiftData. Tracks shuffle-bag rotation state (which messages have been sent in the current cycle).

**Data model:**

```swift
PraiseMessage {
    id: UUID
    text: String
    createdAt: Date
    sentInCurrentCycle: Bool
}
```

### 2. Settings

Configuration screen for Telegram bot token and chat ID.

- Bot token stored in Keychain (sensitive)
- Chat ID stored in UserDefaults
- "Send Test Message" button for verification

### 3. Scheduler

Registers a `BGAppRefreshTask` that fires daily.

On wake:
1. Pick the next unsent message from the shuffle bag
2. POST to `https://api.telegram.org/bot<token>/sendMessage` with `chat_id` and `text`
3. Mark message as sent in current cycle
4. When all messages sent, reset cycle (reshuffle)
5. Schedule next execution for tomorrow at a random minute between 8:00-9:00 AM

**Caveat:** iOS may delay background execution. Messages might arrive slightly outside the 8-9 AM window. This is inherent to the serverless on-device approach.

## Telegram Integration

Single HTTP POST via `URLSession`. No external dependencies.

## UI Screens

1. **Message List** - SwiftUI `List` with add/edit/delete. Shows sent status in current cycle.
2. **Settings** - Bot token field, chat ID field, test message button.

## Testing

- Unit tests for shuffle-bag logic (rotation, reshuffle after exhaustion)
- Unit tests for Telegram API request construction
- UI kept thin, logic in testable services

## Tech Stack

- Swift 6 / SwiftUI / iOS 26
- SwiftData for persistence
- BGTaskScheduler for scheduling
- URLSession for Telegram API
- Keychain for bot token storage
