import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The front page is the one address that survives a panel move, so it also
/// announces which build is current. Nothing here talks to GitHub: a white
/// label build must never point its users at the upstream project.
const _endpointSeed = 'https://app.xycould.top';
const _endpointPath = '/client-endpoint.json';

@immutable
class PanelUpdate {
  const PanelUpdate({this.latestBuild = '', this.downloadUrl = ''});

  final String latestBuild;
  final String downloadUrl;

  bool get hasUpdate =>
      latestBuild.isNotEmpty &&
      downloadUrl.isNotEmpty &&
      _isNewer(latestBuild, xbBuildTag);
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
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );

  final Dio _dio;

  @override
  PanelUpdate build() {
    unawaited(refresh());
    return const PanelUpdate();
  }

  Future<void> refresh() async {
    final dynamic body;
    try {
      final response = await _dio.get<dynamic>(
        '$_endpointSeed$_endpointPath',
        options: Options(responseType: ResponseType.json),
      );
      body = response.data;
    } on DioException {
      return;
    }
    if (!ref.mounted) return;
    final data = body is Map ? body : const {};
    final latestBuild = '${data['latest_build'] ?? ''}'.trim();
    final downloadUrl = '${data['download_url'] ?? ''}'.trim();
    if (latestBuild == state.latestBuild && downloadUrl == state.downloadUrl) {
      return;
    }
    state = PanelUpdate(latestBuild: latestBuild, downloadUrl: downloadUrl);
  }
}
