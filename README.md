# Tally

A calm personal debt tracker starter for Tanzania and East Africa. It tracks debts separately from any savings and never adjusts savings or goal balances.

## Run

Install the current stable Flutter SDK and Android Studio, enable USB debugging on your Android phone, then connect the phone and run:

```sh
flutter pub get
flutter devices
flutter run
```

Select your phone from the Flutter device list. The Android app label and in-app name are **Tally**, its application ID is `com.tally.app`, and its launcher icons are generated from `App icon.png`. The Home header has EN/SW, appearance, and profile photo controls. Amounts default to TSh with no decimals. Demo debts are seeded in debug builds; release builds start empty.

To build an APK on your own machine later, run `flutter build apk --debug`; the output will be at `build/app/outputs/flutter-apk/app-debug.apk`.

## Structure

- `lib/main.dart`: current UI prototype, derived debt status, in-session debt book, add debt and payment flows, payoff estimate.
- `assetsfonts`: bundled Poppins family and OFL license.
- `lib/core`, `lib/data`, `lib/features/*`: feature-first extension points for moving the prototype into repository-backed features.
- `l10n`: English and Swahili ARB catalogs.
- `test`: status, payment validation, and payoff estimate tests.

## Current prototype boundaries

Debt and payment data currently live in memory and reset on app restart. Language, theme, and the selected profile photo path are saved locally. Reminders, PDF/CSV export, backup/restore, biometrics, onboarding, and persistent local SQLite storage are not connected yet. The payoff estimate is a simple weekly calculator. These are starter flows with no backend or external messaging.

The data model has no savings coupling. A future `SavingsBridge` should be an optional interface with a no-op implementation; debt operations must not modify a savings or goal balance.
