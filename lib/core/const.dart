class Const {
  static const String appName = 'NOVA Windows Cloud';

  /// GitHub App Client ID (public, safe to embed).
  static const String githubClientId = 'Iv23liceWNo2k0jhvUo6';

  /// Custom-scheme callback registered in the GitHub App + AndroidManifest.
  static const String redirectUri = 'novawindowscloud://oauth/callback';

  static const String apiBase = 'https://api.github.com';
  static const String authorizeUrl = 'https://github.com/login/oauth/authorize';
  static const String tokenUrl = 'https://github.com/login/oauth/access_token';

  /// The workflow file this app drives (must exist in the selected repo).
  static const String workflowFile = 'windows11.yml';
  static const String backupPrefix = 'win11-backup';

  /// Secrets managed by the app.
  static const String secretAccess = 'ACCESS_PASSWORD';
  static const String secretBackup = 'BACKUP_PASSWORD';
  static const String secretTailscale = 'TAILSCALE_AUTHKEY';

  static const int maxSessionHours = 5;
}
