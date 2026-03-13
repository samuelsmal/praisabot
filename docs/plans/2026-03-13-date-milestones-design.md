# Date-Based Milestone Messages — Design

## Overview

A new feature allowing users to define date-based entries that trigger Telegram messages when specific time conditions are met. These are completely independent from the existing praise messages — separate model, separate scheduling logic, sent in addition to (not instead of) daily praises.

## Examples

- "Now we are 50k seconds together!"
- "Only 42 thousand days remaining until we are together for thirty years!"
- "Nur noch fünfmal schlafen und wir gehen in die Ferien"

## Data Model — `DateMilestone`

SwiftData `@Model`:

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| name | String | Human label (e.g. "Together", "Ferien") |
| referenceDate | Date | The anchor date to count from/to |
| direction | Direction enum | `.countingUp` or `.countingDown` |
| messageTemplate | String | Template with `{value}` and `{unit}` placeholders |
| triggerPreset | TriggerPreset enum | Which trigger condition to use |
| triggerInterval | Int | Interval parameter for the preset (e.g. 50000) |
| isEnabled | Bool | User can disable without deleting |
| createdAt | Date | When the entry was created |

For `atSpecificDaysRemaining`, the specific day values are stored as a comma-separated string in a separate field `triggerDaysList: String?` (e.g. "100,50,10").

## Direction Enum

```
enum Direction: String, Codable {
    case countingUp    // time since referenceDate (past date)
    case countingDown  // time until referenceDate (future date)
}
```

User picks direction per entry.

## Trigger Presets

| Preset | Direction | Parameter | Example |
|--------|-----------|-----------|---------|
| `everyNSeconds` | up | N = interval | fires at 50000, 100000, 150000… seconds |
| `everyNDays` | up | N = interval | fires at 100, 200, 300… days |
| `everyNMonths` | up | N = interval | fires at 6, 12, 18… months |
| `everyNYears` | up | N = interval | fires at 1, 2, 3… years |
| `dailyLastNDays` | down | N = interval | fires daily when ≤N days remain |
| `everyNDaysRemaining` | down | N = interval | fires at 300, 200, 100… days remaining |
| `atSpecificDaysRemaining` | down | list of days | fires at exactly 100, 50, 10 days remaining |

### Trigger Evaluation

The milestone checker runs once daily (during the 8-9 AM background task window). For second-based presets (`everyNSeconds`), the check determines whether a round-number boundary was crossed since the last check. For day/month/year presets, it checks whether today matches the condition.

## Service — `MilestoneChecker`

- Stateless service, called daily
- Iterates all enabled `DateMilestone` entries
- For each, evaluates whether the trigger condition is met today
- If met: renders the message template by substituting `{value}` and `{unit}`, sends via `TelegramService`
- Multiple milestones can fire on the same day
- Countdown milestones that have passed their reference date are auto-disabled

## Template Rendering

The template uses `{value}` and `{unit}` placeholders:

- `"Now we are {value} {unit} together!"` → `"Now we are 50000 seconds together!"`
- `"Nur noch {value} mal schlafen!"` → `"Nur noch 5 mal schlafen!"`

The user writes the template freely, including the language. No auto-generation.

## UI — New "Dates" Tab

Third tab in the tab bar alongside Messages and Settings.

### List View
- Shows all date milestones with name, reference date, and enabled toggle
- Swipe to delete

### Add/Edit Form
- Name text field
- Date picker for reference date
- Direction segmented picker (counting up / counting down)
- Preset picker (filtered by direction)
- Interval field (or day list for `atSpecificDaysRemaining`)
- Message template text area with placeholder hint
- Live preview of what the rendered message would look like today

## Scheduling

Piggybacks on the existing daily background task window (8-9 AM). The `PraiseScheduler.sendPraise()` flow is extended to also call `MilestoneChecker` after sending the praise. Both are independent — a praise failure does not block milestone checks, and vice versa.

## Testing

- `MilestoneChecker` unit tests for each trigger preset
- Template rendering tests
- Edge cases: milestone on exact boundary, just-passed countdown, disabled milestones
