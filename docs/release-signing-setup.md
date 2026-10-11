# Persistent Android release signing — setup notes

**Do not generate or replace a key until you have checked whether a permanent NOVA key already exists.** GitHub Actions never reveals stored secret values, and replacing a signing key prevents Android from accepting future APKs as updates to apps signed with the old certificate.

## Required key identity

- Keystore filename for your private backup: `nova-release.jks`
- Keystore type: JKS
- Key alias: `nova_release`
- Keep the same keystore, alias, and passwords for every future release.
- The JKS file, its Base64 encoding, and both passwords are private signing credentials. Never commit or upload them as a workflow artifact.

## If there is no existing key

Create the key once on a trusted computer or Android device with a trusted Java/Termux installation. For Termux, install Java and GNU coreutils first, then run:

```sh
keytool -genkeypair -v \
  -keystore nova-release.jks \
  -storetype JKS \
  -alias nova_release \
  -keyalg RSA -keysize 2048 -validity 10000
```

Let `keytool` prompt for the keystore and key passwords; do not put passwords directly in the command or chat. Store those passwords in a password manager. Keep an encrypted/private backup of `nova-release.jks` in a private Google Drive location and a separate secure copy if possible. Do not make the Drive folder public.

Record the public certificate fingerprint (not the passwords) for later checks:

```sh
keytool -list -v -keystore nova-release.jks -alias nova_release
```

The `SHA256` certificate fingerprint is public and should match the fingerprint printed by the release workflow.

## Configure GitHub Actions

In the repository, open **Settings → Secrets and variables → Actions → New repository secret** and add these four names. Paste values directly into GitHub; never send them in chat.

| Secret name | Value |
| --- | --- |
| `NOVA_RELEASE_KEYSTORE_BASE64` | Base64 of the complete `nova-release.jks` file, on one line |
| `NOVA_RELEASE_STORE_PASSWORD` | Keystore password |
| `NOVA_RELEASE_KEY_ALIAS` | Exactly `nova_release` |
| `NOVA_RELEASE_KEY_PASSWORD` | Password for the `nova_release` private key |

On Termux with GNU coreutils, produce a one-line Base64 value with:

```sh
base64 -w 0 nova-release.jks
```

Copy that output directly into the GitHub secret field. Treat the output as equivalent to the private JKS file. Delete any temporary Base64 text file after use, and keep the original JKS only in private backup storage. The workflow decodes the key only into the ephemeral runner's temporary directory, verifies the certificate, signs the Release APK, and removes the temporary key in an always-run cleanup step.

If the four secrets already exist, do not overwrite them until you have confirmed that you possess the exact matching JKS and passwords. A mismatch stops the Release build; the workflow does not fall back to Debug signing or produce an unsigned Release APK.

## Upgrade warning

Android requires an update APK to be signed by the same certificate as the installed app. Earlier NOVA workflow builds used the runner's Debug signing configuration, which is not a persistent release identity. Until the installed APK's certificate is compared with the permanent key, an in-place update cannot be guaranteed. The app will not uninstall itself or clear local data. If Android later reports a signature conflict, back up anything needed first; uninstalling and reinstalling may be necessary and can remove local app data (GitHub repository secrets remain in GitHub).
