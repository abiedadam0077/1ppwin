# NOVA Windows Cloud — UI audit and redesign brief

**Audit date:** 2026-10-12

**Scope:** Current Flutter application in this working tree. This audit is intentionally read-only with respect to app behavior: it does not change `AppState`, GitHub/auth services, workflow YAML, Android identity, or release signing.

## Executive summary

The app already has a complete dark visual system and most of the requested user journeys. The redesign should improve information hierarchy, consistency, readability, and accessibility rather than replace the product or invent a new backend. All repositories, readiness checks, encrypted GitHub secrets, workflow runs, connection details, backups, and activity must continue to be driven by the existing providers/services.

The current worktree contains existing, uncommitted work in UI, services, Android resources, GitHub Actions, tests, docs, and assets. Those files are treated as user work and must be preserved. `designs/` also contains earlier, untracked generated images. They are not overwritten or presented as final: several have malformed Arabic and they do not provide A/B alternatives or state coverage.

## Repository and behavior map

| Area | Current implementation | Redesign constraint |
|---|---|---|
| App shell | `lib/main.dart`; `Provider<AppState>`; `MaterialApp`; named routes `/repos` and `/security`; AppLinks OAuth callback | Keep provider, routes, deep links, and existing app startup behavior. |
| Shared navigation | `HomeShell` in `lib/screens/home_shell.dart`; `IndexedStack` preserves five tabs | Preserve exactly five tabs: Home, Repositories, Backups/Restore, Activity, Settings. |
| State | `lib/state/app_state.dart` | Do not replace state with static/demo data. Preserve login, language, selected repo, readiness, secrets, session options, run polling, backup and activity state. |
| GitHub integration | `lib/services/github_service.dart` | Keep real repository, workflow, secret, Actions, run, session-info, Release/backup calls. |
| Authentication | `lib/services/auth_service.dart` and `onboarding.dart` | Keep device-code flow, browser OAuth PKCE/deep-link flow, PAT, optional client secret, manual callback fallback, secure token storage and retry paths. |
| Windows workflow | `assets/windows11.yml` and `.github/workflows/windows11.yml` | Keep dispatch inputs, access choices, graceful stop/backup, and repair of older workflows. Do not change the workflow/release pipeline as part of visual work. |
| Secrets | `SecurityScreen` plus GitHub public-key sealing in the service | Keep required `ACCESS_PASSWORD` and `BACKUP_PASSWORD`, optional `TAILSCALE_AUTHKEY`, verified upload, preserve-existing-on-blank behavior, and permission errors. Never expose secret values in activity or logs. |
| Backup and restore | `BackupsScreen`; GitHub Releases via `GitHubService.backups` | Keep complete/incomplete status, permissions/errors, refresh, restore confirmation, and restore dispatch. There is no backup-delete API in the current app; do not show a delete action. |
| Activity | `ActivityScreen`; sanitized local entries in SharedPreferences (maximum 100) | Preserve success/failure filters and local-only clearing. Add confirmation before clearing. |
| Device/package | `android/app/build.gradle`; current release workflow | Preserve `applicationId`, signing identity/secrets, and Release workflow. Never substitute a Debug APK for a signed release. |

### Existing state and product rules

- Default locale is Arabic; English and French are supported. `MaterialApp` gets its locale from `AppState`, so Flutter supplies RTL for Arabic. Repository names, GitHub handles, URLs, codes, IPs, and other protocol values must remain explicitly LTR inside RTL screens.
- `AppState.updateSessionOptions` clamps the session to **1–5 hours**. Web access and Tailscale/RDP are independent session options. Fresh install must remain visibly distinct from restoring a backup.
- OAuth tokens/client secret use secure storage. The Windows access password is intentionally held in memory only for the Ready screen. Secret values must remain masked unless the user explicitly chooses to reveal them.
- Repo readiness comes from actual workflow and secret inspection. The app can install/repair `.github/workflows/windows11.yml`; session dispatch also self-repairs an absent/outdated workflow.
- Live-run state is polled from GitHub Actions. The progress UI has run steps and failed-step context, not arbitrary raw runner logs; do not fabricate log output.
- Backup metadata comes from GitHub Releases. The latest complete backup is preferred; incomplete releases remain visibly incomplete.
- Activity is an app-local record of real operations and is sanitized before persistence.

## Screen and state inventory

The interactive preview at `designs/redesign/index.html` contains one full-screen mobile mockup at a time, with A/B direction and state selectors. It is a visual prototype only; all values shown there are explicitly illustrative and are not connected to GitHub.

| # | Current screen / surface | Real states and actions that must remain represented |
|---|---|---|
| 1 | Startup (`_StartupScreen`) | First-frame initialization / restoring saved language, user, and selected repository. Keep a branded loading state; do not imply a failed login while initialization is pending. |
| 2 | Onboarding / GitHub sign-in (`OnboardingScreen`) | Signed-out idle; device-code request and waiting; open/copy code; browser OAuth; PAT dialog; optional client secret; manual callback; loading, cancellation, expiry/API error, retry; successful token acceptance. |
| 3 | Device authorization | Device code, verification URL, copy/open actions, waiting indicator, cancel, success or failure. Never hide the code in an RTL text run. |
| 4 | Login success (`LoginSuccessScreen`) | Confirm the actual returned GitHub account and continue into the app. |
| 5 | Home dashboard (`HomeFlowScreen`) | No repository; selected repo requiring workflow/secrets; ready-to-start; queued/running session with time remaining; latest run success/failure; latest complete backup; status refresh; primary action routes to the correct setup/security/session flow. |
| 6 | Repositories (`RepoSelectorScreen`) | Loading, GitHub error/retry, no repositories, no search matches, search, filters (all/ready/not-ready/private/public), readiness probing, selected/unselected, public/private, install/repair workflow, open security/setup, start when ready, create repository. |
| 7 | Create repository (`CreateRepoScreen`) | Name input/validation, visibility, optional bundled workflow installation, busy, API/permission error, success selecting the new repository. |
| 8 | Repository setup (`RepoSetupScreen`) | Repository identity/default branch; workflow missing/repair/valid; secrets missing/ready; permission guidance; workflow install/repair busy/error/success; security route. |
| 9 | Security & secrets (`SecurityScreen`) | Required/optional secret status; masked inputs; generate/copy passwords; blank means retain an existing GitHub secret; verified save; loading, validation, network error, insufficient permission, success. |
| 10 | Session setup (`SessionSetupScreen`) | Duration 1–5 hours, restore vs fresh install (with warning), web access, RDP/Tailscale access, summary, missing requirements, busy/error, dispatch. |
| 11 | Workflow progress (`ProgressScreen`) | Queued/waiting, live step progression, success/ready transition, failure with failed step and GitHub run link, immediate run cancellation. Continue polling actual run state. |
| 12 | Windows ready / connection (`ReadyScreen`) | Running/countdown; web route loading/available; Tailscale/RDP available/waiting/permission or secret missing; no access enabled; copy/open info; password remains memory-only; graceful stop-and-save confirmation; force cancel choice; operation errors. |
| 13 | Backups & restore (`BackupsScreen`) | Not logged in; no selected repository; loading; permission denied with guide/retry; network/API error; empty; complete and incomplete release list; latest complete; refresh; restore confirmation and dispatch. |
| 14 | Activity (`ActivityScreen`) | Empty; real event list; all/success/failure filters; sanitized detail; clear action. Add a clear-confirmation dialog before deleting local history. |
| 15 | Settings (`SettingsScreen`) | GitHub profile/connected state; Arabic/English/French; selected repository; routes to security/repo/setup; PAT sign-in; expandable permissions and about; logout. Add logout confirmation. |
| 16 | Permission guide (`PermissionsGuideCard`) | GitHub App installation/access guidance, Actions/Secrets/Contents permissions, PAT alternative, open installations, retry. It is embedded in relevant errors/settings, not a new backend route. |
| 17 | PAT sign-in dialog | Masked token entry, create-PAT external link, busy/error, success; token is stored securely and never echoed into logs. |
| 18 | OAuth client-secret dialog | Optional value, secure-device storage, saved state, retry exchange after secret is supplied. |
| 19 | Manual OAuth callback dialog | Accept callback URL or bare code; preserve PAT-token fallback; validation/error/retry. |
| 20 | Backup details (proposed bottom sheet) | New presentation over existing `BackupInfo`: tag/date, total size, part count, complete/incomplete, restore action. No destructive API is implied. |
| 21 | Restore confirmation | Explain that the chosen encrypted snapshot will replace the current Windows state; confirm/cancel; busy/error feedback. |
| 22 | Stop/cancel confirmation | Distinguish graceful stop-and-save from immediate cancellation; explain backup implications; confirm/cancel. |
| 23 | Clear activity confirmation (proposed) | Clarify this only clears the local activity list, not GitHub workflow runs or backups. |
| 24 | Logout confirmation (proposed) | Warn that local authentication/selection state will be cleared; cancel or sign out. |

The last two dialogs and the backup-details sheet are intentional UX additions to existing real operations. They must not change the underlying service behavior.

## Audit findings and design implications

1. **Good foundation:** Cairo is bundled; the theme and shared widgets already centralize many colors, buttons, fields, status badges, cards, background, and the five-tab bar. The three supported locales currently have matching translation key counts.
2. **Visual hierarchy is inconsistent:** several screens repeat hard-coded paddings, text sizes, radii, and direct colors instead of sharing spacing/type/layout tokens. The existing glow/gradient language is strong enough that the redesign should reduce decorative emphasis and reserve accent color for active status and primary actions.
3. **Rendering cost:** `GlassCard` currently applies `BackdropFilter` blur and a shadow to every card. A flatter Design A and a limited-glass Design B should avoid placing many blurred surfaces in a long scrolling list, especially on lower-end Android devices.
4. **Navigation readability:** the existing bottom navigation has five destinations and a 66 px content height; Arabic labels are set to 8.5 px. The redesign must preserve the five destinations but target at least 10–12 px labels, 48 px touch targets, adequate contrast, screen-reader labels, and narrow-width behavior.
5. **LTR/RTL correctness:** repository, branch, login, URL, IP, OAuth code, and secret fields need isolated LTR direction. UI chrome and explanatory text remain locale-directed. Do not apply LTR to the whole page to “fix” a single GitHub value.
6. **Safety and trust:** Restore and graceful stop already have confirmation. Activity clearing currently happens immediately; logout is immediate; force-cancel is a secondary option inside the stop dialog. Add clear/logout confirmation and keep “force cancel” visually separate from the safe save path.
7. **Information density:** the repo list, session settings, workflow stepper, connection details, backup list, and activity list need consistent row height and metadata hierarchy. Use lazy list construction for long content, retain pull-to-refresh, and avoid truncating primary actions at 320–360 px.
8. **Truthful states:** loading, empty, no-permission, API failure, incomplete backup, no route, and live run are distinct states. Do not reuse a generic empty panel for a permission or network failure and do not show sample values in the actual Flutter app.
9. **Existing references:** preserve all images under the pre-existing untracked `designs/` directory. They are inspiration only, not final mockups; malformed generated Arabic makes them unsuitable as implementation acceptance screenshots.
10. **Local verification:** Flutter/Dart/Android tooling is absent in this sandbox. No analysis, widget test, or APK build is claimed until a suitable CI run succeeds.

## Two visual directions to compare

### Design A — Control Room

- Clear, operational, information-first dashboard; solid navy surfaces; thin structural dividers; cyan for the primary action and live state; violet used only for secondary emphasis.
- Compact, precise status bars, stepper/timeline rows, dense-but-readable repository and activity lists, and explicit labels beside each icon.
- Minimal gradients and no card-level blur; one accent panel per screen at most. More content remains visible above the fold.
- Best when the user values fast status scanning and predictable setup. This remains a premium dark theme, not a bare admin table.

### Design B — Aurora

- More expressive, layered dark experience; navy base with a restrained cyan-to-violet atmosphere behind the primary hero; rounded elevated panels; selective translucent/glass surfaces.
- Stronger visual focus for Windows state, session launch, restore, and connection success; lists still use compact rows so the experience does not become a wall of cards.
- Glow stays subtle and localized (no constant neon outlines); contrast and state colors remain accessible.
- Best when the user wants a more distinctive cloud-product feel without sacrificing clarity.

Both directions use the same semantic tokens, Cairo typography, 8 px spacing rhythm, explicit status icon + text (not color alone), minimum 48 px interactive targets, responsive scroll, safe areas, and correct RTL/LTR isolation. The A/B preview uses the same content and states so the choice is about visual hierarchy and layout—not different product capabilities.

## Shared component plan

| Component | A treatment | B treatment | Functional/accessibility contract |
|---|---|---|---|
| App header | Crisp title + contextual action | Soft tonal header panel | Back and action labels localized; no hidden icon-only action. |
| Bottom tabs | Flat active underline/tonal pill | Subtle raised selected item | Exactly five tabs, 48 px targets, selected semantics, 10–12 px label floor. |
| Card/surface | Solid navy + hairline separator | Selective translucent elevated panel | Use blur sparingly; preserve text contrast and reduce-motion behavior. |
| Primary/secondary button | Solid cyan / outlined neutral | Cyan-violet gradient primary / tonal secondary | Real callback, disabled/busy semantics, full-width on narrow layouts. |
| Text field | Flat outlined field and explicit helper/error line | Soft inset surface with limited accent focus | Label persists while typing, validation announced, secret obscured by default, correct keyboard/action/direction. |
| Status badge | Icon + word + color | Icon + word + subtle halo | Never rely on color alone; loading is announced. |
| Empty/loading/error | Simple icon and text, inline retry | Focused illustrated panel with same copy/action | Distinct data state and functional retry/next-step action. |
| Workflow stepper | Vertical line/checklist | Progress hero plus compact step list | Actual workflow step data only; accessible progress value and failure link. |
| Confirmation dialog | Plain severity/action hierarchy | Elevated modal with clear consequence | Safe action first; confirm/cancel; no ambiguous destructive default. |
| Repo/backup/activity row | Compact aligned metadata | Soft card row with prominent status | LTR code values, no decorative dead affordances, list virtualization when needed. |

## Acceptance checklist for implementation

- [ ] Select a global direction after comparing A and B; all screens use that coherent system.
- [ ] Keep all five tabs and all existing navigation/auth/repo/security/workflow/backup/activity/settings interactions.
- [ ] Do not replace a GitHub/API-backed field or status with a constant, fixture, or generated value in the app.
- [ ] Provide separate loading/empty/error/permission/success/confirmation states and accessible retry paths.
- [ ] Keep Arabic text RTL and protocol/repository values LTR; check Arabic, English, and French where layouts are shared.
- [ ] Validate at 320, 360, 390, and 430 logical px, text scaling, long repository names, and keyboard-open layouts.
- [ ] Verify screen-reader labels, focus order, semantic status/progress, contrast, and 48 px touch targets.
- [ ] Add regression/widget tests for dashboard, five-tab navigation, RTL/LTR repository values, confirmation actions, and key user flows.
- [ ] Run `flutter analyze`, `flutter test`, and the existing signed Release workflow. Report each result honestly; the signing config and workflow must remain unchanged.
- [ ] Capture actual Flutter screenshots only after the chosen Flutter design builds; do not describe this HTML visual prototype as an app screenshot or signed APK.
