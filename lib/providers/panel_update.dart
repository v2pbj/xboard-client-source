import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The front page is the one address that survives a panel move, so it also
/// announces which build is current. Nothing here talks to GitHub: a white
/// label build must never point its users at the upstream project.
///
/// The direct entrance is tried first because the proxied one is the address
/// that goes quiet for users on mainland networks.
const _endpointSeeds = ['https://f.xycould.top', 'https://app.xycould.top'];
const _endpointPath = '/client-endpoint.json';

/// Ed25519 public key for the update manifest, pinned at build time.
/// Empty means update prompts are disabled (fail closed).
const _updatePublicKeyDefault = 'tX2B9ZD1US6Wa1/cNqR2XjRn5pfWUtbnKKJGdVA9oN8=';

@immutable
class PanelUpdate {
  const PanelUpdate({
    this.latestBuild = '',
    this.downloadUrl = '',
    this.homeUrl = '',
  });

  final String latestBuild;
  final String downloadUrl;

  /// The front page of the host that answered, or the one that front page
  /// names, so the account view can always show users a way back.
  final String homeUrl;

  bool get hasUpdate =>
      latestBuild.isNotEmpty &&
      downloadUrl.isNotEmpty &&
      _isNewer(latestBuild, xbBuildTag);
}

/// A front page fetched from the direct entrance must not send the download
/// back through the proxied one, so an address announced on a sibling front
/// page host is rewritten to the host that actually answered.
String alignDownloadHost(String url, String answered) {
  final announced = Uri.tryParse(url);
  final base = Uri.tryParse(answered);
  if (announced == null || base == null || announced.host.isEmpty) return url;
  if (!_endpointSeeds.any((seed) => seed.endsWith('//${announced.host}'))) {
    return url;
  }
  final query = announced.query.isEmpty ? null : announced.query;
  return base.replace(path: announced.path, query: query).toString();
}

/// The `-tN` suffix advances a fixed semantic version; an absent tag is T0.
bool _isNewer(String latest, String current) {
  final valid = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:-t(\d+))?$');
  final left = valid.firstMatch(latest);
  final right = valid.firstMatch(current);
  if (left == null || right == null) return false;
  for (var i = 1; i <= 3; i++) {
    final a = int.tryParse(left.group(i)!);
    final b = int.tryParse(right.group(i)!);
    if (a == null || b == null) return false;
    if (a != b) return a > b;
  }
  final leftBuild = int.tryParse(left.group(4) ?? '0');
  final rightBuild = int.tryParse(right.group(4) ?? '0');
  if (leftBuild == null || rightBuild == null) return false;
  return leftBuild > rightBuild;
}

String _safeHttpsUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return '';
  }
  return url;
}

final panelUpdateProvider = NotifierProvider<PanelUpdateNotifier, PanelUpdate>(
  PanelUpdateNotifier.new,
);

class PanelUpdateNotifier extends Notifier<PanelUpdate> {
  PanelUpdateNotifier({Dio? dio, String? updatePublicKey})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 6),
            ),
          ),
      _updatePublicKey = updatePublicKey ?? _updatePublicKeyDefault;

  final Dio _dio;
  final String _updatePublicKey;
  Future<void>? _refreshing;

  @override
  PanelUpdate build() {
    unawaited(refresh());
    return const PanelUpdate();
  }

  Future<void> refresh() {
    if (_refreshing != null) return _refreshing!;
    final refreshing = _refresh();
    _refreshing = refreshing;
    return refreshing.whenComplete(() => _refreshing = null);
  }

  Future<void> _refresh() async {
    for (final seed in _endpointSeeds) {
      final dynamic body;
      try {
        final response = await _dio.get<dynamic>(
          '$seed$_endpointPath',
          options: Options(responseType: ResponseType.json),
        );
        body = response.data;
      } on DioException {
        continue;
      }
      if (!ref.mounted) return;
      await _apply(body, seed);
      return;
    }
  }

  Future<void> _apply(dynamic body, String answered) async {
    final data = body is Map ? body : const {};
    final latestBuild = '${data['latest_build'] ?? ''}'.trim();
    final rawDownload = _safeHttpsUrl('${data['download_url'] ?? ''}'.trim());
    final namedHome = _safeHttpsUrl('${data['home_url'] ?? ''}'.trim());
    final homeUrl = namedHome.isNotEmpty ? namedHome : '$answered/';
    final panelBaseUrl = _safeHttpsUrl(
      '${data['panel_base_url'] ?? ''}'.trim(),
    );
    if (!await _verifyManifest(
      panelBaseUrl: panelBaseUrl,
      latestBuild: latestBuild,
      downloadUrl: rawDownload,
      homeUrl: namedHome,
      signature: '${data['signature'] ?? ''}'.trim(),
      alg: '${data['sig_alg'] ?? ''}'.trim(),
    )) {
      return;
    }
    if (!ref.mounted) return;
    final downloadUrl = _safeHttpsUrl(alignDownloadHost(rawDownload, answered));
    if (latestBuild == state.latestBuild &&
        downloadUrl == state.downloadUrl &&
        homeUrl == state.homeUrl) {
      return;
    }
    state = PanelUpdate(
      latestBuild: latestBuild,
      downloadUrl: downloadUrl,
      homeUrl: homeUrl,
    );
  }

  Future<bool> _verifyManifest({
    required String panelBaseUrl,
    required String latestBuild,
    required String downloadUrl,
    required String homeUrl,
    required String signature,
    required String alg,
  }) async {
    if (_updatePublicKey.isEmpty ||
        alg != 'ed25519' ||
        signature.isEmpty ||
        panelBaseUrl.isEmpty ||
        latestBuild.isEmpty ||
        downloadUrl.isEmpty ||
        homeUrl.isEmpty) {
      return false;
    }
    try {
      final message = utf8.encode(
        '$panelBaseUrl\n$latestBuild\n$downloadUrl\n$homeUrl\n',
      );
      final publicKey = SimplePublicKey(
        base64Decode(_updatePublicKey),
        type: KeyPairType.ed25519,
      );
      return await Ed25519().verify(
        message,
        signature: Signature(base64Decode(signature), publicKey: publicKey),
      );
    } on FormatException {
      return false;
    }
  }
}
