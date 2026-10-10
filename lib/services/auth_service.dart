import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/const.dart';

/// GitHub App user authorization flow with PKCE (S256).
/// No client secret is used or stored anywhere.
class AuthService {
  static const _tokenKey = 'nova_gh_token';
  final FlutterSecureStorage _store = const FlutterSecureStorage();

  Future<String?> storedToken() => _store.read(key: _tokenKey);

  Future<void> saveToken(String token) => _store.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _store.delete(key: _tokenKey);

  /// Builds a fresh PKCE verifier/challenge pair and the authorize URL.
  Future<(Uri, String)> authorizeUrlWithVerifier() async {
    final verifier = _randomBase64Url(64);
    final challenge = await _s256(verifier);
    final uri = Uri.parse(Const.authorizeUrl).replace(queryParameters: {
      'client_type': 'github_app',
      'client_id': Const.githubClientId,
      'redirect_uri': Const.redirectUri,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
    });
    return (uri, verifier);
  }

  /// Exchanges the callback `code` for a user access token using the verifier.
  Future<String> exchangeCode(String code, String verifier) async {
    final res = await http.post(
      Uri.parse(Const.tokenUrl),
      headers: {'Accept': 'application/json'},
      body: jsonEncode({
        'client_id': Const.githubClientId,
        'code': code,
        'code_verifier': verifier,
        'redirect_uri': Const.redirectUri,
      }),
    );
    if (res.statusCode != 200) {
      throw AuthException('token exchange failed (${res.statusCode}): ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final token = body['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw AuthException('no access_token in response');
    }
    return token;
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

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
