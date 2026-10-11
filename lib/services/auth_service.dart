import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/const.dart';

/// Access token (+ optional refresh token) returned by GitHub.
class TokenSet {
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;

  const TokenSet({required this.accessToken, this.refreshToken, this.expiresIn});
}

/// Bootstrap data for the OAuth device flow.
class DeviceCode {
  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final int interval;
  final int expiresIn;

  const DeviceCode({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.interval,
    required this.expiresIn,
  });
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// GitHub App user authorization.
///
/// Two flows are supported:
///
/// * **Device flow** (default) — no client secret, no redirect URI and no deep
///   link are needed. The user gets an 8-character code, confirms it in the
///   browser while the app polls GitHub in the background.
/// * **Web application flow with PKCE** (advanced) — GitHub *requires* the app
///   client secret when redeeming the code for this flow, so the secret is
///   read from the device keystore when the user has stored it and is never
///   embedded in the APK.
///
/// Both flows ask for `offline_access` so a refresh token is returned and the
/// session survives the 8-hour access token lifetime. Refresh tokens created
/// through the device flow can be renewed without a client secret.
class AuthService {
  static const _tokenKey = 'nova_gh_token';
  static const _refreshKey = 'nova_gh_refresh_token';
  static const _expiryKey = 'nova_gh_token_expiry';
  static const _secretKey = 'nova_gh_client_secret';
  static const _verifierKey = 'nova_gh_pkce_verifier';
  static const _stateKey = 'nova_gh_oauth_state';

  final FlutterSecureStorage _store = const FlutterSecureStorage();

  // ── stored state ──────────────────────────────────────────────────────────

  Future<String?> storedToken() => _store.read(key: _tokenKey);

  Future<String?> storedRefreshToken() => _store.read(key: _refreshKey);

  /// Unix epoch (seconds) when the access token stops working, if known.
  Future<int?> storedExpiry() async {
    final value = await _store.read(key: _expiryKey);
    return value == null ? null : int.tryParse(value);
  }

  Future<String?> storedClientSecret() => _store.read(key: _secretKey);

  Future<void> saveClientSecret(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await _store.delete(key: _secretKey);
    } else {
      await _store.write(key: _secretKey, value: trimmed);
    }
  }

  Future<void> saveTokenSet(TokenSet tokens) async {
    await _store.write(key: _tokenKey, value: tokens.accessToken);
    final refresh = tokens.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      await _store.write(key: _refreshKey, value: refresh);
    } else {
      await _store.delete(key: _refreshKey);
    }
    final expiresIn = tokens.expiresIn;
    if (expiresIn != null && expiresIn > 0) {
      final epoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + expiresIn;
      await _store.write(key: _expiryKey, value: '$epoch');
    } else {
      await _store.delete(key: _expiryKey);
    }
  }

  /// Removes the session (tokens + pending sign-in data). The optional client
  /// secret is kept, it belongs to the user and is only stored on this device.
  Future<void> clearAll() async {
    await _store.delete(key: _tokenKey);
    await _store.delete(key: _refreshKey);
    await _store.delete(key: _expiryKey);
    await clearPendingLogin();
  }

  // ── device flow ───────────────────────────────────────────────────────────

  Future<DeviceCode> requestDeviceCode() async {
    final res = await http.post(
      Uri.parse(Const.deviceCodeUrl),
      headers: const {'Accept': 'application/json'},
      body: const {'client_id': Const.githubClientId, 'scope': Const.offlineScope},
    );
    final body = _decode(res);
    _throwIfError(body);

    final deviceCode = body['device_code'] as String?;
    final userCode = body['user_code'] as String?;
    if (deviceCode == null || userCode == null) {
      throw AuthException('GitHub did not return a device code.');
    }
    return DeviceCode(
      deviceCode: deviceCode,
      userCode: userCode,
      verificationUri: body['verification_uri'] as String? ?? Const.deviceVerifyUrl,
      interval: _asInt(body['interval']) ?? 5,
      expiresIn: _asInt(body['expires_in']) ?? 900,
    );
  }

  /// Polls GitHub until the user approves [code]. Returns null when [cancelled].
  Future<TokenSet?> pollDeviceToken(
    DeviceCode code, {
    required bool Function() cancelled,
  }) async {
    var interval = code.interval <= 0 ? 5 : code.interval;
    final deadline = DateTime.now().add(Duration(seconds: code.expiresIn));

    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(Duration(seconds: interval));
      if (cancelled()) return null;

      final res = await http.post(
        Uri.parse(Const.tokenUrl),
        headers: const {'Accept': 'application/json'},
        body: {
          'client_id': Const.githubClientId,
          'device_code': code.deviceCode,
          'grant_type': Const.deviceGrantType,
        },
      );
      final body = _decode(res);
      final error = body['error'] as String?;

      if (error == 'authorization_pending') continue;
      if (error == 'slow_down') {
        interval += 5;
        continue;
      }
      _throwIfError(body);
      return _tokenSet(body);
    }
    throw AuthException('The sign-in code expired before it was approved. Please try again.');
  }

  // ── web application flow (advanced) ───────────────────────────────────────

  /// Creates a PKCE verifier/state and the URL the user has to open.
  Future<(Uri, String, String)> authorizeUrlWithVerifier() async {
    final verifier = _randomBase64Url(64);
    final state = _randomBase64Url(24);
    final challenge = await _s256(verifier);
    final uri = Uri.parse(Const.authorizeUrl).replace(queryParameters: {
      'client_id': Const.githubClientId,
      'redirect_uri': Const.redirectUri,
      'scope': Const.offlineScope,
      'state': state,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
    });
    return (uri, verifier, state);
  }

  /// Persisted so the callback still works when Android killed the app while
  /// the browser was in front and the deep link cold-starts it again.
  Future<void> savePendingLogin(String verifier, String state) async {
    await _store.write(key: _verifierKey, value: verifier);
    await _store.write(key: _stateKey, value: state);
  }

  Future<(String, String?)?> pendingLogin() async {
    final verifier = await _store.read(key: _verifierKey);
    if (verifier == null || verifier.isEmpty) return null;
    return (verifier, await _store.read(key: _stateKey));
  }

  Future<void> clearPendingLogin() async {
    await _store.delete(key: _verifierKey);
    await _store.delete(key: _stateKey);
  }

  Future<TokenSet> exchangeCode(String code, String verifier) async {
    final fields = <String, String>{
      'client_id': Const.githubClientId,
      'code': code,
      'code_verifier': verifier,
      'redirect_uri': Const.redirectUri,
    };
    final secret = await storedClientSecret();
    if (secret != null && secret.isNotEmpty) fields['client_secret'] = secret;
    return _tokenRequest(fields);
  }

  /// Renews an expiring access token. Device-flow tokens need no secret.
  Future<TokenSet> refresh(String refreshToken) async {
    final fields = <String, String>{
      'client_id': Const.githubClientId,
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    };
    final secret = await storedClientSecret();
    if (secret != null && secret.isNotEmpty) fields['client_secret'] = secret;
    return _tokenRequest(fields);
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Future<TokenSet> _tokenRequest(Map<String, String> fields) async {
    final res = await http.post(
      Uri.parse(Const.tokenUrl),
      headers: const {'Accept': 'application/json'},
      // A Map body is sent as application/x-www-form-urlencoded, which is what
      // GitHub parses. Sending a JSON *string* here (the previous bug) makes
      // GitHub answer HTTP 404 {"error":"Not Found"} and sign-in never
      // completes.
      body: fields,
    );
    final body = _decode(res);
    _throwIfError(body);
    return _tokenSet(body);
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } on FormatException {
      // handled below
    }
    throw AuthException('GitHub returned an unexpected response (HTTP ${res.statusCode}).');
  }

  void _throwIfError(Map<String, dynamic> body) {
    final error = body['error'] as String?;
    if (error == null || error.isEmpty) return;
    throw AuthException(friendlyAuthError(error, body['error_description'] as String?));
  }

  TokenSet _tokenSet(Map<String, dynamic> body) {
    final access = body['access_token'] as String?;
    if (access == null || access.isEmpty) {
      throw AuthException('GitHub did not return an access token.');
    }
    return TokenSet(
      accessToken: access,
      refreshToken: body['refresh_token'] as String?,
      expiresIn: _asInt(body['expires_in']),
    );
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<String> _s256(String verifier) async {
    final digest = await Sha256().hash(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  String _randomBase64Url(int bytes) {
    final rnd = Random.secure();
    final b = Uint8List(bytes);
    for (var i = 0; i < bytes; i++) {
      b[i] = rnd.nextInt(256);
    }
    return base64UrlEncode(b).replaceAll('=', '');
  }
}

/// Turns GitHub OAuth error codes into something the user can act on.
String friendlyAuthError(String code, String? description) {
  switch (code) {
    case 'device_flow_disabled':
      return 'Device flow is disabled for this GitHub App. Open the app settings on github.com, enable "Device flow" (or add the client secret from Advanced settings) and try again.';
    case 'expired_token':
      return 'The sign-in code expired. Tap the sign-in button to get a new one.';
    case 'access_denied':
      return 'The sign-in request was cancelled on GitHub.';
    case 'incorrect_client_credentials':
      return 'GitHub rejected the app credentials. The browser flow also needs the GitHub App client secret: add it from Advanced settings, or use the code sign-in.';
    case 'bad_verification_code':
      return 'The sign-in code is invalid or was already used. Please start the sign-in again.';
    case 'redirect_uri_mismatch':
      return 'The callback URL does not match the GitHub App settings. It must be exactly ${Const.redirectUri}.';
    case 'bad_refresh_token':
      return 'The stored sign-in expired. Please sign in again.';
    case 'unsupported_grant_type':
      return 'GitHub rejected the request type (unsupported_grant_type).';
    case 'authorization_pending':
    case 'slow_down':
      return 'Still waiting for the authorization on GitHub.';
    default:
      if (code.toLowerCase().contains('not found')) {
        return 'GitHub could not read the request. Please update the app and try again.';
      }
      return description == null || description.isEmpty ? code : '$code — $description';
  }
}
