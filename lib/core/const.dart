class Const {
  static const String appName = 'NOVA Windows Cloud';

  /// GitHub App Client ID (public, safe to embed).
  static const String githubClientId = 'Iv23liceWNo2k0jhvUo6';

  /// Custom-scheme callback registered in the GitHub App + AndroidManifest.
  static const String redirectUri = 'novawindowscloud://oauth/callback';

  static const String apiBase = 'https://api.github.com';
  static const String authorizeUrl = 'https://github.com/login/oauth/authorize';
  static const String tokenUrl = 'https://github.com/login/oauth/access_token';

  /// OAuth device flow (RFC 8628). This flow needs **no** client secret and no
  /// redirect URI, so it is the default sign-in method on Android.
  static const String deviceCodeUrl = 'https://github.com/login/device/code';
  static const String deviceVerifyUrl = 'https://github.com/login/device';
  static const String deviceGrantType = 'urn:ietf:params:oauth:grant-type:device_code';

  /// Requesting `offline_access` makes GitHub return an 8h access token plus a
  /// rotating 6-month refresh token, so the app does not sign the user out.
  static const String offlineScope = 'offline_access';

  /// The workflow file this app drives (must exist in the selected repo).
  static const String workflowFile = 'windows11.yml';
  static const String backupPrefix = 'win11-backup';

  /// Secrets managed by the app.
  static const String secretAccess = 'ACCESS_PASSWORD';
  static const String secretBackup = 'BACKUP_PASSWORD';
  static const String secretTailscale = 'TAILSCALE_AUTHKEY';

  static const int maxSessionHours = 5;
}
