import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_clash/providers/panel_update.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body) => ResponseBody.fromString(
  jsonEncode(body),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  group('alignDownloadHost', () {
    test('moves an announced download onto the host that answered', () {
      expect(
        alignDownloadHost('https://app.xycould.top/', 'https://f.xycould.top'),
        'https://f.xycould.top/',
      );
    });

    test('keeps the path and query of the announced address', () {
      expect(
        alignDownloadHost(
          'https://app.xycould.top/page?v=1',
          'https://f.xycould.top',
        ),
        'https://f.xycould.top/page?v=1',
      );
    });

    test('leaves a third party address untouched', () {
      expect(
        alignDownloadHost(
          'https://mirror.example.com/dl',
          'https://f.xycould.top',
        ),
        'https://mirror.example.com/dl',
      );
    });

    test('leaves an empty announcement untouched', () {
      expect(alignDownloadHost('', 'https://f.xycould.top'), '');
    });
  });

  group('PanelUpdate.hasUpdate', () {
    test('accepts a leading v in the announced build', () {
      const update = PanelUpdate(
        latestBuild: 'v0.9.2-t16',
        downloadUrl: 'https://f.xycould.top/download',
      );
      expect(update.hasUpdate, isTrue);
    });

    test('rejects a malformed announced build', () {
      const update = PanelUpdate(
        latestBuild: 'vv0.9.2-t16',
        downloadUrl: 'https://f.xycould.top/download',
      );
      expect(update.hasUpdate, isFalse);
    });
  });

  group('PanelUpdateNotifier', () {
    test('tries the direct endpoint before its fallback', () async {
      var calls = 0;
      final adapter = _Adapter((options) {
        calls++;
        if (calls == 1) {
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'fixture unavailable',
          );
        }
        return _json({
          'latest_build': '0.9.2-t99',
          'download_url': 'https://app.xycould.top/download',
          'home_url': '',
        });
      });
      final container = ProviderContainer(
        overrides: [
          panelUpdateProvider.overrideWith(
            () => PanelUpdateNotifier(dio: Dio()..httpClientAdapter = adapter),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(panelUpdateProvider, (_, _) {});
      await container.read(panelUpdateProvider.notifier).refresh();
      expect(container.read(panelUpdateProvider).latestBuild, '0.9.2-t99');
      expect(
        container.read(panelUpdateProvider).downloadUrl,
        'https://app.xycould.top/download',
      );
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests[0].uri.host, 'f.xycould.top');
      expect(adapter.requests[1].uri.host, 'app.xycould.top');
    });

    test('rejects non-HTTPS and user-info download URLs', () async {
      final adapter = _Adapter(
        (_) => _json({
          'latest_build': '0.9.2-t99',
          'download_url': 'https://user@f.xycould.top/download',
          'home_url': 'javascript:alert(1)',
        }),
      );
      final container = ProviderContainer(
        overrides: [
          panelUpdateProvider.overrideWith(
            () => PanelUpdateNotifier(dio: Dio()..httpClientAdapter = adapter),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(panelUpdateProvider, (_, _) {});
      await container.read(panelUpdateProvider.notifier).refresh();
      expect(container.read(panelUpdateProvider).hasUpdate, isFalse);
      expect(container.read(panelUpdateProvider).downloadUrl, isEmpty);
      expect(
        container.read(panelUpdateProvider).homeUrl,
        'https://f.xycould.top/',
      );
    });
  });
}
