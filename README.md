# Backstreet Pilates

A Flutter blueprint for a Pilates app, starting with login and signup.
Authentication is a local UI demo: no account is created, authenticated, or saved.

## Run

Flutter 3.47.5 is installed at `/Users/mutic/develop/flutter`.
The SDK is configured for new zsh/bash login shells and VS Code.
Xcode 27 and an iPhone 17 simulator with iOS 26.5 are available.
From this folder:

```sh
flutter pub get
open /Applications/Xcode.app/Contents/Applications/DeviceHub.app
flutter devices
flutter run -d C9F6A868-3B6F-4E6B-9531-69F4480BB6E7
```

The generated iOS platform project is included in `ios/`.
Reopen your terminal or VS Code if `flutter` is not found in an existing session.
Web entry files are included for optional browser development.

```sh
dart format lib test
flutter analyze
flutter test
```

Verification on 2026-09-27: code formatted, analyzer passed, and all three widget tests passed.
The iOS debug build launched successfully on iPhone 17; the login screen was visually checked.
See [Flutter's iOS setup](https://docs.flutter.dev/platform-integration/ios/setup).

## Review one page at a time

Start with [the project plan](docs/BLUEPRINT.md), then [login](docs/reviews/01-login.md)
and [signup](docs/reviews/02-signup.md). Track decisions in [progress](docs/PROGRESS.md).
Markdown files provide development context; they are not runtime app content.

Database design draft: [DATABASE.md](docs/DATABASE.md).

Backend setup: [SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md). Review the real login/signup connection in [03-supabase-auth.md](docs/reviews/03-supabase-auth.md).
