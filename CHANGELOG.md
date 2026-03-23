# Changelog

All notable changes to Praisabot will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [0.4.0] - 2026-03-23

### Added
- Local notification when a praise or milestone message is sent

## [0.3.0] - 2026-03-13

### Changed
- Move default praise messages to a private, gitignored file (`DefaultPraises.json`)
- Add `DefaultPraises.example.json` as a template for public users

## [0.2.0] - 2026-03-13

### Added
- README with setup instructions and build commands
- GPLv3 license
- Setup guide in Settings explaining how to create a bot via BotFather and obtain a Chat ID

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
