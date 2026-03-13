# Praisabot

An iOS app that sends daily praise messages to your loved ones via Telegram.

## Features

- **Daily praise delivery** — Sends a random praise message once a day (8–9 AM) via Telegram
- **40+ default messages** — Ships with multilingual praise messages (DE, FR, IT, RM), ready to use out of the box
- **Shuffle-bag rotation** — No repeats until every message has been sent
- **Date-based milestones** — Trigger special messages on anniversaries, birthdays, or custom dates
- **Full message control** — Add, edit, and delete messages from your collection
- **Telegram integration** — Configure your bot token and chat ID in settings, with a test button to verify connectivity

## Requirements

- iOS 26.0+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- A [Telegram Bot](https://core.telegram.org/bots#how-do-i-create-a-bot) token

## Getting Started

1. Clone the repo and generate the Xcode project:

   ```bash
   make generate
   ```

2. Open `Praisabot.xcodeproj` in Xcode, or build and run on the simulator:

   ```bash
   make run
   ```

3. In the app, go to **Settings** and enter your Telegram bot token and chat ID. Tap **Test message** to verify it works.

## Build Commands

| Command        | Description                                    |
|----------------|------------------------------------------------|
| `make generate`| Generate Xcode project from `project.yml`      |
| `make build`   | Build for simulator                            |
| `make run`     | Build, install, and launch on simulator        |
| `make deploy`  | Build and install on a physical device         |
| `make tag`     | Create a git tag matching the current version  |
| `make clean`   | Clean build artifacts                          |

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
