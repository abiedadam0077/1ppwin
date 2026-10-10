# NOVA Windows Cloud — delivery context

## Source and Git workflow

The Flutter/Android source was recovered from the user's
`nova-app-bundle.tar.gz` Google Drive archive and imported at the repository
root. The original `.github/workflows/windows11.yml` is preserved.

This session uses `arena/2df8bb0b-1ppwin`, with squash-merged pull requests
into `main`. Keep fixes on that session branch; do not push directly to main
or delete the session branch. Downloaded archives, APKs, caches and CI logs
are intentionally excluded from Git.

## APK validation and publication

`.github/workflows/build-apk.yml` validates PRs and builds/publishes on main:

- Flutter 3.24.5, Java 17, Android compile SDK 35, AGP 8.6.1, Kotlin 2.1.10.
- Dependency versions and package hashes are pinned in `pubspec.lock`;
  CI uses `flutter pub get --enforce-lockfile`.
- Analyzer warnings/errors or failed tests fail the job and prevent APK
  compilation/publication. They must not be suppressed with `|| true`.
- Tests include independent PyNaCl/libsodium sealed-box vectors, message
  boundary cases, round trips, and rejection of tampered/invalid input.
- Encryption uses PineNaCl/TweetNaCl instead of hand-written cipher primitives.
- Detailed logs and the resolved lockfile are saved in `build-diagnostics`.
  Short diagnostic messages also appear in GitHub check annotations.
- Successful main builds publish the universal Android APK and its SHA-256
  checksum to the `apk-latest` prerelease; the APK artifact is retained 30 days.

Direct APK URL:
https://github.com/abiedadam0077/1ppwin/releases/download/apk-latest/NOVA-Windows-Cloud.apk

Verify a **successful main run** (not only a PR run) and the release asset
before sharing that URL. PR runs deliberately do not publish releases.

## App configuration

The public GitHub App client ID is in `lib/core/const.dart` and the callback
URI is `novawindowscloud://oauth/callback`. Do not embed a client secret or
access token in the APK. VM secrets are configured through the app at runtime.
CI compilation/unit tests do not replace testing GitHub login and a real
Windows VM session on an Android device.
