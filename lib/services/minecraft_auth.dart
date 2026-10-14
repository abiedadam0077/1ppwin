/// Supported authentication modes for Minecraft Java Cloud.
class MinecraftAccountMode {
  static const String microsoft = 'microsoft';
  static const String offline = 'offline';

  static bool isValidMode(String value) => value == microsoft || value == offline;

  /// Mojang-style local names: 3–16 ASCII letters, digits, or underscores.
  static bool isValidOfflineUsername(String value) =>
      RegExp(r'^[A-Za-z0-9_]{3,16}$').hasMatch(value);

  /// Builds the explicit workflow_dispatch fields for the selected account.
  static Map<String, String> dispatchInputs({
    required String mode,
    required String offlineUsername,
  }) {
    if (!isValidMode(mode)) throw ArgumentError.value(mode, 'mode', 'Unsupported account mode.');
    final username = offlineUsername.trim();
    if (mode == offline && !isValidOfflineUsername(username)) {
      throw ArgumentError.value(offlineUsername, 'offlineUsername', 'Invalid local profile name.');
    }
    return {
      'auth_mode': mode,
      'offline_username': mode == offline ? username : '',
    };
  }
}
