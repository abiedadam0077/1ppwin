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

## Minecraft Offline profiles — 2026-10-14

- Added an explicit Microsoft/Offline account choice to Minecraft Java Cloud. Offline mode takes a 3–16 character local name, saves selectable profiles in app preferences, and sends `auth_mode` plus `offline_username` through GitHub workflow dispatch.
- The workflow never invokes Microsoft OAuth in Offline mode and passes an empty access-token argument. It computes the standard deterministic local `OfflinePlayer:<name>` UUID and patches the `userType` argument for legacy client versions at the 22w43a boundary. The UI and docs state that this is not an official Java account and official online-authentication servers can reject it.
- Older installed Minecraft workflows are detected by schema/input inspection and require confirmation before updating. Only `.github/workflows/minecraft-cloud.yml` in the selected Minecraft repository is touched; Windows Cloud, Tailscale, `applicationId`, and signing configuration remain unchanged.
- Source comparison: MojoLauncher separates local accounts from Microsoft authentication and uses `userType=mojang` before 22w43a / `msa` afterward; `minecraft-launcher-lib` 8.0 allows empty test tokens but hard-codes the MSA launch placeholder. NOVA keeps the flows separate, uses an empty token rather than Mojo's `0` sentinel, and patches only the local launch argument. See `docs/MINECRAFT_CLOUD.md` for source links.
- Local checks: workflow YAML parsed; all 8 embedded Bash blocks passed `bash -n`; all 6 embedded Python heredocs parsed; offline UUID, empty token, and the `22w43a` type boundary were exercised with local Python checks. No Minecraft Actions workflow was started.
- GitHub APK CI [run 38630858042](https://github.com/abiedadam0077/1ppwin/actions/runs/38630858042) passed Analyze, all 41 Flutter tests, Debug/Release builds, package ID (`app.nova.windowscloud`) and release-certificate checks. The Release APK is 56.4 MB; build version is `1.0.2+3`.
- Download the 30-day Actions artifact [NOVA-Windows-Cloud-APK](https://github.com/abiedadam0077/1ppwin/actions/runs/38630858042/artifacts/11927457126); it contains the signed APK and `NOVA-Windows-Cloud.apk.sha256`. The sandbox could not download the archive itself because GitHub redirects it to an artifact-storage host outside the sandbox's outbound allowlist; the artifact remains available from the run link.
- Neither a phone installation nor a live Minecraft/Microsoft session was executed. CI signature verification checks the configured persistent release keystore, but does not independently compare against the certificate of every older APK.
