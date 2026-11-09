import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class ClientNotice {
  const ClientNotice({
    this.enabled = false,
    this.title = '公告',
    this.body = '',
    this.linkUrl = '',
    this.linkLabel = '查看详情',
    this.homeUrl = '',
    this.panelUrls = const [],
    this.subscribeMirrors = const [],
  });

  final bool enabled;
  final String title;
  final String body;
  final String linkUrl;
  final String linkLabel;
  final String homeUrl;
  final List<String> panelUrls;
  final List<String> subscribeMirrors;

  bool get visible => enabled && (title.isNotEmpty || body.isNotEmpty);
}

String _noticeText(dynamic value, int limit) {
  final text = '$value'.trim();
  return text.length <= limit ? text : text.substring(0, limit);
}

String _noticeUrl(dynamic value) {
  final url = '$value'.trim();
  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return '';
  }
  return url;
}

/// A mirror carries only the origin; the current subscription path is appended
/// when the account asks for candidates, so the public notice never holds a
/// user's token.
String _mirrorOrigin(dynamic value) {
  final raw = '$value'.trim();
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.query.isNotEmpty ||
      uri.fragment.isNotEmpty) {
    return '';
  }
  if (uri.path.isNotEmpty && uri.path != '/') return '';
  final port = uri.port == 443 ? '' : ':${uri.port}';
  return 'https://${uri.host}$port';
}

final clientNoticeProvider =
    NotifierProvider<ClientNoticeNotifier, ClientNotice>(
      ClientNoticeNotifier.new,
    );

class ClientNoticeNotifier extends Notifier<ClientNotice> {
  ClientNoticeNotifier({
    Dio? dio,
    this.initialPanelUrls = const [],
    this.initialSubscribeMirrors = const [],
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 8),
               receiveTimeout: const Duration(seconds: 8),
             ),
           );

  final Dio _dio;
  final List<String> initialPanelUrls;
  final List<String> initialSubscribeMirrors;
  Completer<void>? _refresh;
  String? _refreshBase;

  @override
  ClientNotice build() => ClientNotice(
    panelUrls: initialPanelUrls,
    subscribeMirrors: initialSubscribeMirrors,
  );

  Future<void> refresh(String baseUrl) async {
    final normalized = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (_refresh != null) {
      if (_refreshBase == normalized) return _refresh!.future;
      await _refresh!.future;
      if (!ref.mounted) return;
      return refresh(baseUrl);
    }
    final completer = Completer<void>();
    _refresh = completer;
    _refreshBase = normalized;
    try {
      await _load(normalized);
    } finally {
      _refresh = null;
      _refreshBase = null;
      completer.complete();
    }
  }

  Future<void> _load(String baseUrl) async {
    final normalized = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final base = Uri.tryParse(normalized);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty) {
      return;
    }
    try {
      final response = await _dio.get<dynamic>(
        '$normalized/api/v1/guest/client/notice',
        options: Options(responseType: ResponseType.json),
      );
      if (!ref.mounted) return;
      final data = response.data;
      final body = data is Map ? data['data'] : null;
      if (body is! Map) return;
      state = ClientNotice(
        enabled: body['enabled'] == true,
        title: _noticeText(body['title'] ?? '', 80),
        body: _noticeText(body['body'] ?? '', 2000),
        linkUrl: _noticeUrl(body['link_url']),
        linkLabel: _noticeText(body['link_label'] ?? '', 30),
        homeUrl: _noticeUrl(body['home_url']),
        panelUrls: [
          for (final value
              in (body['panel_urls'] is List ? body['panel_urls'] : const []))
            if (_noticeUrl(value).isNotEmpty) _noticeUrl(value),
        ],
        subscribeMirrors: [
          for (final value
              in (body['subscribe_mirrors'] is List
                  ? body['subscribe_mirrors']
                  : const []))
            if (_mirrorOrigin(value).isNotEmpty) _mirrorOrigin(value),
        ],
      );
    } on DioException {
      return;
    }
  }
}
