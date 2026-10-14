import 'dart:convert';

import 'package:http/http.dart' as http;

/// A version published in Mojang's official Java Edition version manifest.
class MinecraftVersion {
  final String id;
  final String type;
  final DateTime? releasedAt;
  final String metadataUrl;

  const MinecraftVersion({
    required this.id,
    required this.type,
    required this.metadataUrl,
    this.releasedAt,
  });

  bool get isSnapshot => type == 'snapshot';

  factory MinecraftVersion.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final type = json['type'] as String? ?? '';
    final metadataUrl = json['url'] as String? ?? '';
    final uri = Uri.tryParse(metadataUrl);
    if (!RegExp(r'^[A-Za-z0-9._+-]{1,40}$').hasMatch(id) ||
        (type != 'release' && type != 'snapshot') ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'piston-meta.mojang.com') {
      throw const FormatException('Unexpected Minecraft version manifest entry.');
    }
    return MinecraftVersion(
      id: id,
      type: type,
      metadataUrl: metadataUrl,
      releasedAt: DateTime.tryParse(json['releaseTime'] as String? ?? ''),
    );
  }
}

class MinecraftVersionManifest {
  final String latestRelease;
  final String latestSnapshot;
  final List<MinecraftVersion> versions;

  const MinecraftVersionManifest({
    required this.latestRelease,
    required this.latestSnapshot,
    required this.versions,
  });

  static const Uri officialUri = Uri(
    scheme: 'https',
    host: 'piston-meta.mojang.com',
    path: '/mc/game/version_manifest_v2.json',
  );

  static MinecraftVersionManifest parse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Minecraft version manifest is not an object.');
    }
    final latest = decoded['latest'];
    final rawVersions = decoded['versions'];
    if (latest is! Map<String, dynamic> || rawVersions is! List) {
      throw const FormatException('Minecraft version manifest is missing required fields.');
    }
    final versions = <MinecraftVersion>[];
    for (final item in rawVersions) {
      if (item is! Map<String, dynamic>) continue;
      try {
        versions.add(MinecraftVersion.fromJson(item));
      } on FormatException {
        // Ignore unknown entry types and URLs outside Mojang's trusted metadata host.
      }
    }
    if (versions.isEmpty) {
      throw const FormatException('Minecraft version manifest contains no supported releases.');
    }
    final ids = versions.map((version) => version.id).toSet();
    final latestRelease = latest['release'] as String? ?? '';
    final latestSnapshot = latest['snapshot'] as String? ?? '';
    if (!ids.contains(latestRelease)) {
      throw const FormatException('The latest official release is missing from the manifest.');
    }
    return MinecraftVersionManifest(
      latestRelease: latestRelease,
      latestSnapshot: ids.contains(latestSnapshot) ? latestSnapshot : '',
      versions: List.unmodifiable(versions),
    );
  }
}

class MinecraftVersionService {
  Future<MinecraftVersionManifest> fetch() async {
    final response = await http
        .get(
          MinecraftVersionManifest.officialUri,
          headers: const {'User-Agent': 'NOVA-Minecraft-Java-Cloud'},
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw Exception('Official Minecraft version service returned HTTP ${response.statusCode}.');
    }
    return MinecraftVersionManifest.parse(response.body);
  }
}
