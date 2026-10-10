import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:pinenacl/x25519.dart' as nacl;

/// Adapter for libsodium-compatible `crypto_box_seal`, as required by GitHub.
/// Use TweetNaCl's implementation instead of maintaining cipher primitives here.
class GitHubSeal {
  /// Encrypts [message] with the repository's base64-decoded public key.
  static Future<Uint8List> seal(Uint8List message, Uint8List recipientPkBytes) async {
    if (recipientPkBytes.length != 32) {
      throw ArgumentError('recipient public key must be 32 bytes');
    }
    return nacl.SealedBox(nacl.PublicKey(recipientPkBytes)).encrypt(message);
  }

  /// Counterpart of [seal], used by independent libsodium interoperability tests.
  static Future<Uint8List> open(Uint8List sealed, Uint8List recipientSeed) async {
    if (sealed.length < 48) throw ArgumentError('sealed message too short');
    if (recipientSeed.length != 32) {
      throw ArgumentError('recipient private key must be 32 bytes');
    }
    final recipient = nacl.PrivateKey(recipientSeed);
    final ephemeral = nacl.PublicKey(sealed.sublist(0, 32));
    final nonce = await Blake2b(hashLengthInBytes: 24).hash([
      ...ephemeral,
      ...recipient.publicKey,
    ]);
    final box = nacl.Box(myPrivateKey: recipient, theirPublicKey: ephemeral);
    try {
      // Box verifies the MAC even for an empty message. SealedBox.decrypt
      // in PineNaCl 0.6.0 skips authentication for that special case.
      return box.decrypt(nacl.EncryptedMessage(
        nonce: Uint8List.fromList(nonce.bytes),
        cipherText: sealed.sublist(32),
      ));
    } catch (_) {
      throw StateError('poly1305 tag mismatch');
    }
  }
}
