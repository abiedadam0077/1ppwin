import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nova_windows_cloud/core/const.dart';
import 'package:nova_windows_cloud/core/l10n.dart';
import 'package:nova_windows_cloud/services/github_service.dart';
import 'package:nova_windows_cloud/services/minecraft_versions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Minecraft feature labels are localized in all supported languages', () {
    expect(L10n('ar').t('minecraft_home_title'), 'Minecraft Java Cloud');
    expect(L10n('ar').t('minecraft_start'), 'بدء Minecraft Java Cloud');
    expect(L10n('en').t('minecraft_status_running'), 'Session is running');
    expect(L10n('fr').t('minecraft_status_running'), 'Session en cours');
    expect(L10n('fr').t('minecraft_github_required'), contains('GitHub'));
  });

  group('Mojang Java version manifest', () {
    const officialManifest = '''
      {
        "latest": {"release": "1.21.4", "snapshot": "25w02a"},
        "versions": [
          {"id":"1.21.4","type":"release","url":"https://piston-meta.mojang.com/v1/packages/abc/1.21.4.json","releaseTime":"2025-01-01T00:00:00+00:00"},
          {"id":"25w02a","type":"snapshot","url":"https://piston-meta.mojang.com/v1/packages/def/25w02a.json","releaseTime":"2025-01-08T00:00:00+00:00"},
          {"id":"1.2-old","type":"old_beta","url":"https://piston-meta.mojang.com/v1/packages/ghi/old.json"},
          {"id":"1.99.0","type":"release","url":"https://untrusted.example/version.json"}
        ]
      }
    ''';

    test('parses trusted releases and snapshots without a hard-coded catalogue', () {
      final manifest = MinecraftVersionManifest.parse(officialManifest);
      expect(manifest.latestRelease, '1.21.4');
      expect(manifest.latestSnapshot, '25w02a');
      expect(manifest.versions.map((version) => version.id), ['1.21.4', '25w02a']);
      expect(manifest.versions.first.releasedAt, DateTime.parse('2025-01-01T00:00:00+00:00'));
    });

    test('rejects a manifest whose latest release is not a trusted Java version', () {
      expect(
        () => MinecraftVersionManifest.parse('''
          {"latest":{"release":"2.0","snapshot":""},"versions":[]}
        '''),
        throwsFormatException,
      );
    });

    test('official manifest endpoint uses Mojang HTTPS metadata', () {
      expect(MinecraftVersionManifest.officialUri.scheme, 'https');
      expect(MinecraftVersionManifest.officialUri.host, 'piston-meta.mojang.com');
      expect(MinecraftVersionManifest.officialUri.path, '/mc/game/version_manifest_v2.json');
    });
  });

  group('Minecraft viewer URL validation', () {
    test('accepts only HTTPS Cloudflare tunnel origins', () {
      final uri = MinecraftSessionInfo.parseTrustedViewerUri(
        'https://quiet-frost-123.trycloudflare.com',
      );
      expect(uri?.host, 'quiet-frost-123.trycloudflare.com');
      expect(MinecraftSessionInfo.parseTrustedViewerUri('http://quiet-frost.trycloudflare.com'), isNull);
      expect(MinecraftSessionInfo.parseTrustedViewerUri('https://attacker.example'), isNull);
      expect(MinecraftSessionInfo.parseTrustedViewerUri('https://user@quiet-frost.trycloudflare.com'), isNull);
      expect(MinecraftSessionInfo.parseTrustedViewerUri('https://quiet-frost.trycloudflare.com:8443'), isNull);
      expect(MinecraftSessionInfo.parseTrustedViewerUri('https://quiet-frost.trycloudflare.com/path'), isNull);
    });
  });

  group('Minecraft world backup metadata', () {
    test('only COMPLETE releases are restorable and names come from metadata', () {
      final backup = MinecraftWorldBackup.fromRelease({
        'tag_name': 'minecraft-world-20261014-123456-123456789',
        'name': 'Minecraft worlds — 2 world(s)',
        'body': 'NOVA_MINECRAFT_VERSION=1.21.4\nNOVA_MINECRAFT_WORLDS=["Survival","Creative"]\nEncrypted snapshot',
        'published_at': '2026-10-14T12:34:56Z',
        'assets': [
          {'name': 'worlds.enc.part000', 'size': 1200},
          {'name': 'worlds.json', 'size': 90},
          {'name': 'COMPLETE', 'size': 80},
        ],
      });
      expect(backup.complete, isTrue);
      expect(backup.worldNames, ['Survival', 'Creative']);
      expect(backup.minecraftVersion, '1.21.4');
      expect(backup.worldCount, 2);
      expect(backup.totalBytes, 1290);
      expect(backup.tag, startsWith('minecraft-world-'));
    });

    test('incomplete release is never marked restorable', () {
      final backup = MinecraftWorldBackup.fromRelease({
        'tag_name': 'minecraft-world-20261014-123456-123456789',
        'assets': [
          {'name': 'worlds.enc.part000', 'size': 1200},
        ],
      });
      expect(backup.complete, isFalse);
    });
  });

  test('workflow is independent from Windows and never configures Tailscale', () async {
    final workflow = await rootBundle.loadString('assets/minecraft-cloud.yml');
    expect(workflow, contains('name: Minecraft Java Cloud'));
    expect(workflow, contains('minecraft-launcher-lib==8.0'));
    expect(workflow, contains("java-version: '8, 11, 17, 21, 25'"));
    expect(workflow, contains('MINECRAFT_ACCESS_PASSWORD'));
    expect(workflow, contains('MINECRAFT_BACKUP_PASSWORD'));
    expect(workflow, contains('MICROSOFT_CLIENT_ID'));
    expect(workflow, contains('minecraft-session-info'));
    expect(workflow, contains('NOVA_MINECRAFT_VERSION='));
    expect(workflow, contains('nova-minecraft-stop-'));
    expect(workflow, isNot(contains('TAILSCALE_AUTHKEY')));
    expect(workflow, isNot(contains('dockur/windows')));
  });

  test('viewer and encrypted-world actions remain separate from Windows constants', () {
    expect(Const.minecraftWorkflowFile, isNot(Const.workflowFile));
    expect(Const.minecraftBackupPrefix, 'minecraft-world-');
  });
}
