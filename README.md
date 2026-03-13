# Praisabot

An iOS app that sends daily praise messages to your loved ones via Telegram.

## Features

- **Daily praise delivery** — Sends a random praise message once a day (8–9 AM) via Telegram
- **Custom default messages** — Seed your own praise messages on first launch (see below)
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

3. Set up Telegram:

   1. Open Telegram and message [@BotFather](https://t.me/BotFather)
   2. Send `/newbot` and follow the prompts to create your bot
   3. Copy the bot token BotFather gives you
   4. Share your bot's handle (e.g. `@YourPraiseBot`) with your partner and ask them to tap **Start**
   5. In the app, go to **Settings**, paste your bot token, then tap **Fetch Recent Messages** to find your partner's Chat ID
   6. Tap **Test message** to verify it works

## Default Praise Messages

The app seeds messages from `Praisabot/Resources/DefaultPraises.json` on first launch. This file is not included in the repository — copy the example and add your own:

```bash
cp Praisabot/Resources/DefaultPraises.example.json Praisabot/Resources/DefaultPraises.json
```

Edit the JSON array with whatever messages you'd like. If the file is absent, the app starts with an empty message list and you can add messages manually.

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
