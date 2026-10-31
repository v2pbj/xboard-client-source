import 'dart:async';

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

/// Every version keeps the `0.9.2` number and only the tag suffix moves, so the
/// `-tN` counter decides when both sides carry one; otherwise fall back to the
/// semantic comparison.
bool _isNewer(String latest, String current) {
  if (latest == current) return false;
  final left = _buildNumber(latest);
  final right = _buildNumber(current);
  if (left != null && right != null) return left > right;
  return compareVersions(latest, current) > 0;
}

int? _buildNumber(String version) =>
    int.tryParse(RegExp(r'-t(\d+)$').firstMatch(version)?.group(1) ?? '');

final panelUpdateProvider = NotifierProvider<PanelUpdateNotifier, PanelUpdate>(
  PanelUpdateNotifier.new,
);

class PanelUpdateNotifier extends Notifier<PanelUpdate> {
  PanelUpdateNotifier({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 6),
            ),
          );

  final Dio _dio;

  @override
  PanelUpdate build() {
    unawaited(refresh());
    return const PanelUpdate();
  }

  Future<void> refresh() async {
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
      _apply(body, seed);
      return;
    }
  }

  void _apply(dynamic body, String answered) {
    final data = body is Map ? body : const {};
    final latestBuild = '${data['latest_build'] ?? ''}'.trim();
    final downloadUrl = alignDownloadHost(
      '${data['download_url'] ?? ''}'.trim(),
      answered,
    );
    final namedHome = '${data['home_url'] ?? ''}'.trim();
    final homeUrl = namedHome.isNotEmpty ? namedHome : '$answered/';
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
}
