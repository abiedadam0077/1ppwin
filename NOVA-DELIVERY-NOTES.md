# NOVA Windows Cloud — Delivery Notes (for the next coding session)

The Flutter project was recovered from the user's `nova-app-bundle.tar.gz`
Google Drive archive and imported into this repository. Work for this
session stays on `arena/2df8bb0b-1ppwin`; pull requests target `main`.
The source bundle does not include a built APK. Verify the Build APK run
and its release assets before sharing a download link.

## Your job, in order (do it all yourself, no questions):

1. `git push origin arena/2df8bb0b-1ppwin`
2. `gh pr create --base main --head arena/2df8bb0b-1ppwin --title "NOVA Windows Cloud app + APK CI" --body "Flutter control-panel app for the Windows 11 workflow; CI builds a downloadable APK."`
3. `gh pr merge <n> --squash`
4. Wait for the **Build APK** workflow on main to finish:
   `gh run watch --exit-status $(gh run list --workflow=build-apk.yml --limit=1 --json databaseId -q .[0].databaseId)`
   Analyzer errors/warnings, failing tests, or APK build failures MUST fail the job and prevent publication. Read the `build-diagnostics` artifact or GitHub check annotations, fix Dart/Gradle errors on the session branch, then commit/push and merge a new PR. PR builds validate changes before they reach main.
5. Give the user the direct download link:
   `https://github.com/abiedadam0077/1ppwin/releases/download/apk-latest/NOVA-Windows-Cloud.apk`
   and mention the artifact fallback: Actions → Build APK → Artifacts.

## Context the user already has (do not ask again)

- GitHub App "NOVA Windows Cloud" created; Client ID Iv23liceWNo2k0jhvUo6;
  redirect URI novawindowscloud://oauth/callback; webhook disabled; app installed.
- Repo secrets for the VM workflow are set by the APP at runtime; the user
  must still add nothing manually.
- Speak to the user in Moroccan Darija / simple Arabic.
