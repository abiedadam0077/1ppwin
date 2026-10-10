import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_windows_cloud/services/seal.dart';

void main() {
  test('sealed layout: 32-byte ephemeral pubkey + 16-byte tag + ciphertext', () async {
    final seed = Uint8List.fromList(List.generate(32, (i) => i + 1));
    final recipient = await X25519().newKeyPairFromSeed(seed);
    final recipientPub = Uint8List.fromList((await recipient.extractPublicKey()).bytes);

    final msg = Uint8List.fromList(utf8.encode('NOVA-secret-value-1234'));
    final sealed = await GitHubSeal.seal(msg, recipientPub);

    expect(sealed.length, 32 + 16 + msg.length);
  });

  test('seal → open round-trip returns the original secret', () async {
    final seed = Uint8List.fromList(List.generate(32, (i) => (i * 7 + 3) % 256));
    final recipient = await X25519().newKeyPairFromSeed(seed);
    final recipientPub = Uint8List.fromList((await recipient.extractPublicKey()).bytes);

    final msg = Uint8List.fromList(utf8.encode('BACKUP_PASSWORD-super-secret-42!'));
    final sealed = await GitHubSeal.seal(msg, recipientPub);
    final opened = await GitHubSeal.open(sealed, seed);

    expect(utf8.decode(opened), utf8.decode(msg));
  });

  test('open fails on tampered ciphertext', () async {
    final seed = Uint8List.fromList(List.generate(32, (i) => 255 - i));
    final recipient = await X25519().newKeyPairFromSeed(seed);
    final recipientPub = Uint8List.fromList((await recipient.extractPublicKey()).bytes);

    final msg = Uint8List.fromList(utf8.encode('tamper-test'));
    final sealed = await GitHubSeal.seal(msg, recipientPub);
    final tampered = Uint8List.fromList(sealed);
    tampered[tampered.length - 1] ^= 0xFF;

    expect(() => GitHubSeal.open(tampered, seed), throwsStateError);
  });
}
