import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_windows_cloud/services/github_service.dart';
import 'package:nova_windows_cloud/services/seal.dart';
import 'package:nova_windows_cloud/state/app_state.dart';

import 'fixtures/sodium_sealed_vectors.dart';

void main() {
  test('X25519 recipient public key matches libsodium', () async {
    final pair = await X25519().newKeyPairFromSeed(base64Decode(sodiumRecipientSeed));
    expect((await pair.extractPublicKey()).bytes, base64Decode(sodiumRecipientPublicKey));
  });

  test('24-byte Blake2b sealed-box nonce matches libsodium', () async {
    final sealed = base64Decode(sodiumSealedVectors[0]!);
    final digest = await Blake2b(hashLengthInBytes: 24).hash([
      ...sealed.sublist(0, 32),
      ...base64Decode(sodiumRecipientPublicKey),
    ]);
    expect(digest.bytes, base64Decode(sodiumEmptyMessageNonce));
  });

  for (final entry in sodiumSealedVectors.entries) {
    test('opens libsodium sealed box (${entry.key} message bytes)', () async {
      final opened = await GitHubSeal.open(
        base64Decode(entry.value),
        base64Decode(sodiumRecipientSeed),
      );
      expect(opened, List.generate(entry.key, (i) => i % 256));
    });
  }

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

  test('open rejects a forged empty-message authentication tag', () async {
    final forged = base64Decode(sodiumSealedVectors[0]!);
    forged[32] ^= 0xFF;
    expect(
      () => GitHubSeal.open(forged, base64Decode(sodiumRecipientSeed)),
      throwsStateError,
    );
  });

  test('seal rejects an invalid recipient key length', () async {
    expect(() => GitHubSeal.seal(Uint8List(0), Uint8List(31)), throwsArgumentError);
  });

  test('open rejects a truncated sealed message', () async {
    expect(() => GitHubSeal.open(Uint8List(47), Uint8List(32)), throwsArgumentError);
  });

  test('assets/windows11.yml and .github/workflows/windows11.yml are valid and identical', () {
    final assetYaml = File('assets/windows11.yml').readAsStringSync();
    final repoYaml = File('.github/workflows/windows11.yml').readAsStringSync();
    expect(assetYaml, repoYaml);
    expect(WorkflowInspection.yamlNeedsRepair(assetYaml), isFalse);
  });

  test('WorkflowInspection.yamlNeedsRepair detects direct secrets in if condition', () {
    const brokenYaml = '''
      - name: Connect Tailscale (optional, for RDP)
        env:
          TS_KEY: \${{ secrets.TAILSCALE_AUTHKEY }}
        if: \${{ secrets.TAILSCALE_AUTHKEY != '' }}
        run: |
          sudo tailscale up --authkey "\$TS_KEY"
      - name: Upload session info artifact
        uses: actions/upload-artifact@v4
''';
    expect(WorkflowInspection.yamlNeedsRepair(brokenYaml), isTrue);
  });

  test('BackupInfo.parseTagTimestamp extracts exact UTC time from release tag', () {
    final dt = BackupInfo.parseTagTimestamp('win11-backup-20261011-053916');
    expect(dt, DateTime.utc(2026, 10, 11, 5, 39, 16));
  });

  test('Repo and ActivityEntry serialize and deserialize cleanly', () {
    final r = Repo(
      fullName: 'abiedadam0077/1ppwin',
      name: '1ppwin',
      isPrivate: false,
      description: 'Windows 11 Cloud',
      defaultBranch: 'main',
    );
    final copy = Repo.fromJson(r.toJson());
    expect(copy.fullName, r.fullName);
    expect(copy.defaultBranch, 'main');

    final entry = ActivityEntry(DateTime.utc(2026, 10, 11), 'act_save_secrets', true, detail: 'abiedadam0077/1ppwin');
    final parsed = ActivityEntry.fromJson(entry.toJson());
    expect(parsed.type, 'act_save_secrets');
    expect(parsed.detail, 'abiedadam0077/1ppwin');
    expect(parsed.ok, isTrue);
  });
}
