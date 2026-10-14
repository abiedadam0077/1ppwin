# NOVA Minecraft Java Cloud

Minecraft Java Cloud is a separate, opt-in Linux session in NOVA. It does not reuse, replace, or change the Windows 11 workflow, its repository setting, Tailscale configuration, signing setup, or backups. Bedrock and other games are out of scope.

## What the feature does

- Uses a dedicated **private GitHub repository** and the independent `.github/workflows/minecraft-cloud.yml` workflow.
- Loads Java release and snapshot IDs from Mojang's official version manifest and checks the selected ID again on the runner.
- Authenticates through Microsoft's public-client OAuth authorization-code flow with PKCE and state. No Microsoft client secret is required. The Microsoft/Xbox/Minecraft services verify the account profile and Java ownership.
- Starts a Linux virtual display with Mesa software rendering, an authenticated HTTPS viewer tunnel, and a noVNC desktop for the official game client.
- Stores only Java world saves (`.minecraft/saves`) in encrypted GitHub Release assets. A completed snapshot is not offered for restore until all assets and its `COMPLETE` marker have uploaded.
- Supports explicit selection of a completed snapshot for restore, or a fresh worlds directory. Backup metadata includes the game version, and NOVA warns before restoring with a different version because Minecraft may convert world data. Earlier releases are not automatically deleted.

## One-time setup

1. Sign in to GitHub in NOVA and select a private repository dedicated to Minecraft, or create one from the Minecraft screen. The currently selected Windows repository is deliberately excluded from the picker.
2. Install the independent Minecraft workflow from the screen. Replacing an existing `minecraft-cloud.yml` requires confirmation; this does not touch the Windows workflow.
3. In Microsoft Entra, register an app that supports personal Microsoft accounts and add the **Mobile and desktop applications** platform with the loopback redirect URI `http://localhost`. Enable public-client flows. The workflow uses loopback port `47831` at runtime.
4. In NOVA, save these values as Actions secrets in the Minecraft repository:
   - `MICROSOFT_CLIENT_ID`: the public application (client) ID from the registration. Do not create or enter an app client secret.
   - `MINECRAFT_ACCESS_PASSWORD`: a strong password for the viewer. NOVA can generate one.
   - `MINECRAFT_BACKUP_PASSWORD`: a strong, unique encryption passphrase. Keep a separate offline copy; encrypted worlds cannot be recovered without it.
5. The Microsoft account used in the remote viewer must own Minecraft Java Edition and be eligible to sign in to the registered app.

GitHub confirms the **names** of configured secrets; it never returns their values. NOVA sends new values through GitHub's encrypted Actions Secrets API and does not persist these Minecraft passwords to local preferences. The viewer password is held in app memory only while needed for the current process; after a restart, enter it again when prompted.

## Starting and stopping a session

Choose a release or snapshot, session length, Java heap cap, display size, render distance, FPS request, and (optionally) a completed world backup. The workflow rechecks inputs, current runner memory and disk, and Mojang's version metadata before it installs or launches the client.

Microsoft sign-in opens in the session's graphical desktop. Complete the sign-in in the viewer within the displayed timeout. NOVA does not receive the Microsoft access token. The runner uses it in memory to start the official Minecraft client; it is not printed to the Actions log or saved in the world backup.

Use **Graceful stop and save worlds** from NOVA. It sends a run-specific stop signal without cancelling GitHub Actions, allowing the client to exit and the workflow to encrypt and upload the worlds. Do not cancel the run from GitHub while the game is open unless you accept losing changes made since the last completed snapshot. If a client, runner, upload, or network failure interrupts the process, a new complete backup is not guaranteed.

## Security and access boundaries

- The repository must be private; the workflow refuses to start in a public repository.
- The quick tunnel is reachable on the public internet, but the viewer is protected with HTTPS and Caddy Basic Authentication. The password is not embedded in the link, artifact, or workflow log. Do not share the URL and password together.
- The Android WebView accepts HTTPS only, restricts navigation to the expected `*.trycloudflare.com` host, rejects TLS errors, and supplies the viewer password only to that host. No public unauthenticated viewer is intended.
- Microsoft sign-in uses PKCE and state on a loopback callback. The workflow does not use stolen sessions, a Microsoft client secret, or token values in logs.
- Backups use GPG symmetric AES-256 encryption with GPG's integrity protection and a separate SHA-256 checksum. Only the `saves/` directory is included; launcher settings, resource packs, mods, and other `.minecraft` data are not part of world restore.

## Limits to plan for

- **No dedicated GPU is promised.** The hosted runner uses Mesa/llvmpipe software rendering; FPS and input latency can be substantially worse than a local gaming PC. The selected FPS is a request, not a guarantee. Cloud tunnel and remote desktop latency vary.
- Session choices are 1–4 hours. The Actions job has a separate hard deadline and reserves time for graceful close and backup upload. Java 8, 11, 17, 21, and 25 runtimes are provisioned; version metadata is matched to the next available compatible runtime, and a game version requiring a runtime above Java 25 is rejected.
- Heap options are 2/4/6/8 GiB, but the workflow rejects a selection when the live runner does not have the selected heap plus its Linux, graphics, and game overhead available. The desktop resolution and graphics options are not extra runner capacity.
- The workflow requires at least 8 GiB of free temporary runner storage before launch, but that does not guarantee room for a large world or its compressed and encrypted copies. Each encrypted Release asset is split into parts below GitHub's per-asset limit. GitHub repository/Release quotas and upload bandwidth still apply; old backups are intentionally retained until the user removes them in GitHub.
- A backup is restorable only when its Release contains the `COMPLETE` marker, metadata, checksum, and all expected encrypted parts. A failed upload may leave an incomplete Release visible, but it is not offered as a restore point.
- The embedded play/control surface currently uses Android's native WebView. Other platforms can manage a session but do not yet have this embedded viewer.

## Verification status

The repository includes local tests for Mojang-manifest parsing, backup metadata, trusted viewer URLs, and the workflow's independence from Windows. They must still be run with the repository's Flutter SDK. This checkout has not yet had `flutter analyze`, `flutter test`, an Android build, or a real GitHub Actions/Microsoft sign-in session executed. Treat the feature as unverified until those checks and an end-to-end private-repository session have been completed; the app does not claim that an untested run succeeded.
