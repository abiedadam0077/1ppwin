# NOVA Minecraft Java Cloud

Minecraft Java Cloud is a separate, opt-in Linux session in NOVA. It does not reuse, replace, or change the Windows 11 workflow, its repository setting, Tailscale configuration, signing setup, or backups. Bedrock and other games are out of scope.

## What the feature does

- Uses a dedicated **private GitHub repository** and the independent `.github/workflows/minecraft-cloud.yml` workflow.
- Loads Java release and snapshot IDs from Mojang's official version manifest and checks the selected ID again on the runner.
- Offers two clearly separate account modes: official Microsoft sign-in with PKCE and Java-ownership verification, or a local Offline profile that uses only a chosen player name and does not contact Microsoft.
- Offline usernames are validated and can be saved on the phone for later selection. The selected name is sent as a declared GitHub Actions input and used to build the game's launch arguments; it is not an official Mojang/Microsoft identity.
- Starts a Linux virtual display with Mesa software rendering, an authenticated HTTPS viewer tunnel, and a noVNC desktop for the official game client.
- Stores only Java world saves (`.minecraft/saves`) in encrypted GitHub Release assets. A completed snapshot is not offered for restore until all assets and its `COMPLETE` marker have uploaded.
- Supports explicit selection of a completed snapshot for restore, or a fresh worlds directory. Backup metadata includes the game version, and NOVA warns before restoring with a different version because Minecraft may convert world data. Earlier releases are not automatically deleted.

## One-time setup

1. Sign in to GitHub in NOVA and select a private repository dedicated to Minecraft, or create one from the Minecraft screen. The currently selected Windows repository is deliberately excluded from the picker.
2. Install the independent Minecraft workflow from the screen. Replacing an existing `minecraft-cloud.yml` requires confirmation; this does not touch the Windows workflow.
3. Choose **Microsoft Account** or **Offline Account** in NOVA. Microsoft mode requires an Entra public-client app that supports personal accounts, the **Mobile and desktop applications** platform with loopback redirect URI `http://localhost`, and public-client flows. The workflow uses loopback port `47831`. Do not create or enter an app client secret. Offline mode needs no Microsoft registration or sign-in.
4. In NOVA, save these Actions secrets in the Minecraft repository:
   - `MINECRAFT_ACCESS_PASSWORD`: required in both modes; a strong password for the protected viewer. NOVA can generate one.
   - `MINECRAFT_BACKUP_PASSWORD`: required in both modes; a strong, unique encryption passphrase. Keep a separate offline copy; encrypted worlds cannot be recovered without it.
   - `MICROSOFT_CLIENT_ID`: required only in Microsoft mode. It is the public application ID from the registration; do not create or enter an app client secret. Existing values are retained when switching to Offline and are not used by that mode.
5. For Microsoft mode, the account used in the remote viewer must own Minecraft Java Edition and be eligible to sign in to the registered app. Offline mode performs no ownership check.

GitHub confirms the **names** of configured secrets; it never returns their values. NOVA sends new values through GitHub's encrypted Actions Secrets API and does not persist these Minecraft passwords to local preferences. The viewer password is held in app memory only while needed for the current process; after a restart, enter it again when prompted.


## Offline profile model and compatibility research

Before this change, NOVA's screen required the Microsoft Client ID and dispatched only game/resource/restore inputs; the workflow always called its Microsoft OAuth function. The installed `minecraft-launcher-lib` 8.0 command builder also hard-codes `msa` for `${user_type}`. Simply adding a UI toggle would therefore neither pass the profile name nor make the launch local, and existing installed workflow copies would reject undeclared input names. The updated app inspects the installed Minecraft workflow schema, prompts before updating an older copy, sends the explicit mode/name inputs, and the workflow selects the matching code path.

Mojo Launcher separates `AuthType.LOCAL` from Microsoft authentication, persists local account names, and supplies local launch arguments. Its local `Account` uses `accessToken = "0"` as a sentinel, while its game argument builder selects `userType=mojang` for versions before 22w43a and `msa` from that transition onward. NOVA follows the separate local-vs-Microsoft flow and version-aware `userType` behavior, but deliberately passes an **empty** access-token argument, not a fabricated Microsoft credential. The deterministic local UUID is derived from `OfflinePlayer:<username>` so a saved name remains the same local identity.

The selected launcher dependency is `minecraft-launcher-lib` 8.0. Its test launch options explicitly permit `token: ""`, but its command builder currently substitutes `msa` for `${user_type}` regardless of the supplied option. NOVA therefore patches only the generated `--userType` argument for Offline launches of older versions, using Mojang's official manifest release timestamp; Microsoft mode continues to use the existing official PKCE/ownership-verification flow. This is a source-level compatibility implementation, not a claim that an offline multiplayer server or live Actions session was tested.

Sources: [Mojo `LocalLoginFragment`](https://github.com/MojoLauncher/MojoLauncher/blob/v3_openjdk/app_mojo/src/main/java/git/artdeell/mojo/fragments/LocalLoginFragment.java), [`AuthType`](https://github.com/MojoLauncher/MojoLauncher/blob/v3_openjdk/app_mojo/src/main/java/git/artdeell/mojo/authenticator/AuthType.java), [`Account`](https://github.com/MojoLauncher/MojoLauncher/blob/v3_openjdk/app_mojo/src/main/java/git/artdeell/mojo/authenticator/accounts/Account.java), and [`GameRunner`](https://github.com/MojoLauncher/MojoLauncher/blob/v3_openjdk/app_mojo/src/main/java/git/artdeell/mojo/utils/jre/GameRunner.java); [`minecraft-launcher-lib` 8.0 `command.py`](https://github.com/JakobDev/minecraft-launcher-lib/blob/8.0/minecraft_launcher_lib/command.py) and [`utils.py`](https://github.com/JakobDev/minecraft-launcher-lib/blob/8.0/minecraft_launcher_lib/utils.py).


## Starting and stopping a session

Choose an account mode, release or snapshot, session length, Java heap cap, display size, render distance, FPS request, and (optionally) a completed world backup. Offline mode requires a local name of 3–16 ASCII letters, digits, or underscores. Saved names stay in the app's local preferences; choosing one sends it to the workflow as an input, visible in the GitHub Actions run record. The workflow validates the mode/name and rechecks current runner memory, disk, and Mojang's version metadata before installing or launching the client.

In Microsoft mode, sign-in opens in the session's graphical desktop. Complete it in the viewer within the displayed timeout. NOVA does not receive the Microsoft access token; the runner uses it in memory to start the official Minecraft client and does not print it or save it in world backups. In Offline mode there is no Microsoft sign-in, ownership validation, or Microsoft access token. The workflow builds a deterministic local `OfflinePlayer:<name>` UUID and passes an empty token argument; the version-specific `userType` value is a launch-compatibility field, not proof of Microsoft authentication. Multiplayer servers that require official online authentication can reject an Offline profile.

Use **Graceful stop and save worlds** from NOVA. It sends a run-specific stop signal without cancelling GitHub Actions, allowing the client to exit and the workflow to encrypt and upload the worlds. Do not cancel the run from GitHub while the game is open unless you accept losing changes made since the last completed snapshot. If a client, runner, upload, or network failure interrupts the process, a new complete backup is not guaranteed.

## Security and access boundaries

- The repository must be private; the workflow refuses to start in a public repository.
- The quick tunnel is reachable on the public internet, but the viewer is protected with HTTPS and Caddy Basic Authentication. The password is not embedded in the link, artifact, or workflow log. Do not share the URL and password together.
- The Android WebView accepts HTTPS only, restricts navigation to the expected `*.trycloudflare.com` host, rejects TLS errors, and supplies the viewer password only to that host. No public unauthenticated viewer is intended.
- Microsoft sign-in uses PKCE and state on a loopback callback. The workflow does not use stolen sessions, a Microsoft client secret, or token values in logs. Offline mode never calls the Microsoft login function and never fabricates a Microsoft credential.
- Offline account names are not authentication secrets, but GitHub records dispatch input values in the run history. The app warns before this mode is started.
- Backups use GPG symmetric AES-256 encryption with GPG's integrity protection and a separate SHA-256 checksum. Only the `saves/` directory is included; launcher settings, resource packs, mods, and other `.minecraft` data are not part of world restore.

## Limits to plan for

- **No dedicated GPU is promised.** The hosted runner uses Mesa/llvmpipe software rendering; FPS and input latency can be substantially worse than a local gaming PC. The selected FPS is a request, not a guarantee. Cloud tunnel and remote desktop latency vary.
- Session choices are 1–4 hours. The Actions job has a separate hard deadline and reserves time for graceful close and backup upload. Java 8, 11, 17, 21, and 25 runtimes are provisioned; version metadata is matched to the next available compatible runtime, and a game version requiring a runtime above Java 25 is rejected.
- Heap options are 2/4/6/8 GiB, but the workflow rejects a selection when the live runner does not have the selected heap plus its Linux, graphics, and game overhead available. The desktop resolution and graphics options are not extra runner capacity.
- The workflow requires at least 8 GiB of free temporary runner storage before launch, but that does not guarantee room for a large world or its compressed and encrypted copies. Each encrypted Release asset is split into parts below GitHub's per-asset limit. GitHub repository/Release quotas and upload bandwidth still apply; old backups are intentionally retained until the user removes them in GitHub.
- A backup is restorable only when its Release contains the `COMPLETE` marker, metadata, checksum, and all expected encrypted parts. A failed upload may leave an incomplete Release visible, but it is not offered as a restore point.
- The embedded play/control surface currently uses Android's native WebView. Other platforms can manage a session but do not yet have this embedded viewer.

## Verification status

The APK CI run [38630858042](https://github.com/abiedadam0077/1ppwin/actions/runs/38630858042) passed Flutter analyze, all 41 Flutter tests, Debug and signed Release packaging, `applicationId` validation, and Release certificate matching. Its 30-day Actions artifact contains `NOVA-Windows-Cloud.apk` and the SHA-256 sidecar: [download artifact](https://github.com/abiedadam0077/1ppwin/actions/runs/38630858042/artifacts/11927457126). No phone installation, Microsoft sign-in, or live Minecraft workflow was run. A successful build does not prove that a particular runner, game version, account, viewer tunnel, or multiplayer server will work.
