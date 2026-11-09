import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_clash/providers/client_notice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _NoticeAdapter implements HttpClientAdapter {
  _NoticeAdapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object value) => ResponseBody.fromString(
  jsonEncode(value),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer container(_NoticeAdapter adapter) {
    final c = ProviderContainer(
      overrides: [
        clientNoticeProvider.overrideWith(
          () => ClientNoticeNotifier(dio: Dio()..httpClientAdapter = adapter),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.listen(clientNoticeProvider, (_, _) {});
    return c;
  }

  test('loads only public notice fields and accepts HTTPS links', () async {
    final adapter = _NoticeAdapter(
      (_) => _json({
        'data': {
          'enabled': true,
          'title': '维护通知',
          'body': '今晚升级',
          'link_url': 'https://f.xycould.top/notice',
          'link_label': '详情',
          'home_url': 'https://f.xycould.top/',
          'subscribe_mirrors': [
            'https://a.example.com',
            'https://b.example.com/',
            'https://c.example.com/sub',
            'http://d.example.com',
          ],
        },
      }),
    );
    final c = container(adapter);
    await c
        .read(clientNoticeProvider.notifier)
        .refresh('https://p.xycould.top');
    final notice = c.read(clientNoticeProvider);
    expect(notice.visible, isTrue);
    expect(notice.title, '维护通知');
    expect(notice.body, '今晚升级');
    expect(notice.linkUrl, 'https://f.xycould.top/notice');
    expect(notice.subscribeMirrors, [
      'https://a.example.com',
      'https://b.example.com',
    ]);
    expect(adapter.requests.single.uri.path, '/api/v1/guest/client/notice');
    expect(adapter.requests.single.uri.host, 'p.xycould.top');
  });

  test('rejects unsafe links and invalid panel addresses', () async {
    final adapter = _NoticeAdapter(
      (_) => _json({
        'data': {
          'enabled': true,
          'body': 'notice',
          'link_url': 'javascript:alert(1)',
        },
      }),
    );
    final c = container(adapter);
    await c.read(clientNoticeProvider.notifier).refresh('not a URL');
    expect(c.read(clientNoticeProvider).visible, isFalse);
    expect(adapter.requests, isEmpty);
    await c
        .read(clientNoticeProvider.notifier)
        .refresh('http://p.xycould.top/');
    expect(adapter.requests, isEmpty);
    await c
        .read(clientNoticeProvider.notifier)
        .refresh('https://p.xycould.top/');
    expect(c.read(clientNoticeProvider).linkUrl, isEmpty);
    expect(c.read(clientNoticeProvider).visible, isTrue);
  });

  test('coalesces concurrent refreshes', () async {
    final adapter = _NoticeAdapter(
      (_) => _json({
        'data': {'enabled': false},
      }),
    );
    final c = container(adapter);
    final first = c
        .read(clientNoticeProvider.notifier)
        .refresh('https://p.xycould.top');
    final second = c
        .read(clientNoticeProvider.notifier)
        .refresh('https://p.xycould.top');
    await Future.wait([first, second]);
    expect(adapter.requests, hasLength(1));
  });

  test(
    'a panel change cannot reuse another endpoint in-flight refresh',
    () async {
      final pending = Completer<ResponseBody>();
      final adapter = _NoticeAdapter((options) {
        if (options.uri.host == 'old.example.com') return pending.future;
        return _json({
          'data': {'enabled': true, 'body': 'new panel'},
        });
      });
      final c = container(adapter);
      final first = c
          .read(clientNoticeProvider.notifier)
          .refresh('https://old.example.com');
      await Future<void>.delayed(Duration.zero);
      final second = c
          .read(clientNoticeProvider.notifier)
          .refresh('https://new.example.com');
      pending.complete(
        _json({
          'data': {'enabled': true, 'body': 'old panel'},
        }),
      );
      await Future.wait([first, second]);
      expect(adapter.requests, hasLength(2));
      expect(c.read(clientNoticeProvider).body, 'new panel');
    },
  );
}
