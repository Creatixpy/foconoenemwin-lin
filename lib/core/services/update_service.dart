import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';

import '../../config/app_config.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  final config = ref.watch(appConfigProvider);
  return UpdateService(
    repoFullName: config.githubRepo,
  );
});

class UpdateService {
  UpdateService({
    required this.repoFullName,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final String? repoFullName;
  final http.Client _client;

  Future<UpdateInfo?> checkForUpdates(String currentVersion) async {
    final repo = repoFullName;
    if (repo == null || repo.isEmpty) {
      debugPrint('UpdateService: nenhum repositório configurado.');
      return null;
    }

    final uri = Uri.https('api.github.com', '/repos/$repo/releases/latest');
    final response = await _client.get(uri, headers: {
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'foconoenem-app',
    });

    if (response.statusCode >= 400) {
      throw UpdateException(
        'Não foi possível consultar atualizações (HTTP ${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final latestTag =
        (decoded['tag_name'] ?? decoded['name'] ?? '').toString().trim();
    if (latestTag.isEmpty) {
      return null;
    }

    final latestVersion = _parseVersion(latestTag);
    final current = _parseVersion(currentVersion);
    if (latestVersion == null || current == null) {
      return null;
    }

    if (!latestVersion.isGreaterThan(current)) {
      return null;
    }

    final assets = (decoded['assets'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final asset = _selectAsset(assets);

    return UpdateInfo(
      version: latestVersion,
      releaseNotes: decoded['body']?.toString() ?? '',
      htmlUrl: decoded['html_url']?.toString(),
      assetName: asset?['name']?.toString(),
      downloadUrl: asset?['browser_download_url']?.toString(),
    );
  }

  Future<void> install(UpdateInfo info) async {
    final downloadUrl = info.downloadUrl;
    final assetName = info.assetName;
    if (downloadUrl == null || assetName == null) {
      throw UpdateException(
        'Nenhum pacote compatível encontrado no release.',
      );
    }
    final file = await _downloadAsset(downloadUrl, assetName);
    if (file == null) {
      throw UpdateException('Falha ao baixar atualização.');
    }

    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', file.path]);
    }

    await Process.start(
      file.path,
      [],
      mode: ProcessStartMode.detached,
    );
  }

  Future<File?> _downloadAsset(String url, String assetName) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode >= 400) {
      return null;
    }
    final dir = await Directory.systemTemp.createTemp('foconoenem-update');
    final file = File('${dir.path}/$assetName');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  Map<String, dynamic>? _selectAsset(List<Map<String, dynamic>> assets) {
    if (assets.isEmpty) return null;
    final platformKey = _platformKeyword();
    if (platformKey == null) return assets.first;
    final exact = assets.firstWhere(
      (asset) =>
          asset['name']?.toString().toLowerCase().contains(platformKey) ??
          false,
      orElse: () => assets.first,
    );
    return exact;
  }

  String? _platformKeyword() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'mac';
    return null;
  }

  Version? _parseVersion(String value) {
    final normalized = value.startsWith('v') ? value.substring(1) : value;
    try {
      final clean = normalized.split('+').first;
      return Version.parse(clean);
    } catch (_) {
      return null;
    }
  }
}

class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.releaseNotes,
    this.htmlUrl,
    this.assetName,
    this.downloadUrl,
  });

  final Version version;
  final String releaseNotes;
  final String? htmlUrl;
  final String? assetName;
  final String? downloadUrl;
}

class UpdateException implements Exception {
  UpdateException(this.message);
  final String message;

  @override
  String toString() => 'UpdateException: $message';
}
