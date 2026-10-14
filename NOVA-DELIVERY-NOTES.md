# NOVA Windows Cloud — delivery context

## Source and Git workflow

The Flutter/Android source was recovered from the user's
`nova-app-bundle.tar.gz` Google Drive archive and imported at the repository
root. The original `.github/workflows/windows11.yml` is preserved.

This session uses `arena/2ea97602-1ppwin`, with pull requests from that branch
into `main`. Keep fixes on that session branch; do not push directly to main
or delete the session branch. Downloaded archives, APKs, caches and CI logs
are intentionally excluded from Git.

## APK validation and publication

`.github/workflows/build-apk.yml` validates PRs and builds on main/session branches:

- Flutter 3.24.5, Java 17, Android compile SDK 35, NDK 26.1.10909125, AGP 8.6.1,
  and Kotlin 2.1.10.
- CI runs `flutter pub get`, analyzer, tests, and a non-published Debug APK
  validation build. Pub's resolved lockfile is included in build diagnostics.
- A Release APK requires the same persistent `nova-release.jks`, alias
  `nova_release`, and four `NOVA_RELEASE_*` Actions secrets for every build.
  Missing secrets fail Release packaging; there is no Debug/unsigned fallback.
  CI checks `applicationId`, APK signature and certificate SHA-256, then
  calculates the APK SHA-256 before publishing. The JKS exists only in the
  runner's temporary directory and is removed after the job.
- Analyzer/test/build diagnostics are retained for seven days; only a
  signature-verified Release APK artifact is retained for 30 days. Successful
  main builds publish the APK and checksum to the `apk-latest` prerelease.

Direct APK URL from the **previous** main release:
https://github.com/abiedadam0077/1ppwin/releases/download/apk-latest/NOVA-Windows-Cloud.apk

That is not the new signed release. The older Gradle configuration used Debug
signing, and its certificate could not be downloaded from this sandbox for
comparison; do not assume it can be upgraded in place. A new public link should
be shared only after a successful signature-verified build. PR runs deliberately
do not publish APKs.

## Sign-in

Sign-in never completed before; two independent causes were found and fixed:

- The token exchange posted `jsonEncode(...)` through `http.post` without a JSON
  content type, so the request went out as `text/plain` and GitHub answered
  **HTTP 404** `{"error":"Not Found"}`. The exchange now sends a form-encoded
  body (`Map<String, String>`). Verified against github.com: form bodies are
  parsed (HTTP 200), `text/plain` JSON bodies 404.
- GitHub **requires the app client secret** to redeem a web-flow code for a
  GitHub App — PKCE is additive, not a replacement — so the browser flow can
  never complete from an APK that embeds no secret.

The app therefore signs in with the **OAuth device flow** (RFC 8628) by
default: no secret, no redirect URI, no deep link. Device flow is confirmed
enabled for client ID `Iv23liceWNo2k0jhvUo6` (`POST /login/device/code`
returns a real `user_code`). `offline_access` is requested so GitHub returns an
8 h access token plus a rotating 6-month refresh token, and device-flow refresh
tokens need no client secret, so the app renews silently on 401.

The web flow is kept as an advanced fallback for users who paste their app
client secret (stored only in the Android keystore). The PKCE verifier is now
persisted before the browser opens, so a callback that cold-starts the app
still completes, and the callback URL/code can also be pasted manually.

## App configuration

The public GitHub App client ID is in `lib/core/const.dart` and the callback
URI is `novawindowscloud://oauth/callback`. Do not embed a client secret or
access token in the APK. VM secrets are configured through the app at runtime.
CI compilation/unit tests do not replace testing GitHub login and a real
Windows VM session on an Android device.
