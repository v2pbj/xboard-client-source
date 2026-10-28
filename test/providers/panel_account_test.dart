import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/panel_account.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_profiles.dart';

const _base = 'https://panel.example.com';
const _loginPath = '/api/v1/passport/auth/login';
const _subscribePath = '/api/v1/user/getSubscribe';
const _subscribeUrl =
    'https://panel.example.com/api/v1/client/subscribe?token=abc';

/// Answers every request from a closure, so a test can script a panel session.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, Object?> _subscribe({
  int upload = 1024,
  int download = 2048,
  int cap = 100000,
  int expired = 1700000000,
  String plan = '基础版',
}) => {
  'data': {
    'subscribe_url': _subscribeUrl,
    'transfer_enable': cap,
    'u': upload,
    'd': download,
    'expired_at': expired,
    'plan': {'name': plan},
  },
};

/// Records what the account page asked of the profile list, so a test can tell
/// an update of the imported profile from a second import.
class _RecordingProfilesAction extends ProfilesAction {
  final List<Profile> updated = [];
  final List<(String, String?)> added = [];
  final List<int> deleted = [];

  @override
  Future<void> updateProfile(
    Profile profile, {
    bool showLoading = false,
  }) async {
    updated.add(profile);
    ref.read(profilesProvider.notifier).put(profile);
  }

  @override
  Future<void> addProfileFromLink(
    String link, {
    String? label,
    String ageSecretKey = '',
  }) async {
    added.add((link, label));
  }

  @override
  Future<void> deleteProfile(int id) async {
    deleted.add(id);
    await ref.read(profilesProvider.notifier).del(id);
  }
}

void main() {
  setUpAll(() => AppLocalizations.load(const Locale('en')));
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWith(
    _ScriptedAdapter adapter, {
    List<Profile> profiles = const [],
    ProfilesAction Function()? profilesAction,
  }) {
    final container = ProviderContainer(
      overrides: [
        panelAccountProvider.overrideWith(
          () => PanelAccountNotifier(dio: Dio()..httpClientAdapter = adapter),
        ),
        profilesProvider.overrideWith(() => TestProfiles(profiles)),
        if (profilesAction != null)
          profilesActionProvider.overrideWith(profilesAction),
      ],
    );
    addTearDown(container.dispose);
    // The account page listens, so a subscribed provider is what the app has;
    // without a listener Riverpod disposes it before `_restore` can finish.
    container.listen(panelAccountProvider, (_, _) {});
    return container;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('state', () {
    test('starts logged out with nothing used', () {
      const state = PanelAccountState();
      expect(state.isLoggedIn, isFalse);
      expect(state.used, 0);
      expect(state.baseUrl, isEmpty, reason: 'tests set no PANEL_BASE_URL');
    });

    test('copyWith keeps every field it is not given', () {
      const state = PanelAccountState(
        baseUrl: _base,
        token: 'tok',
        email: 'me@example.com',
        upload: 3,
        download: 4,
      );
      expect(state.isLoggedIn, isTrue);
      expect(state.used, 7);

      final next = state.copyWith(upload: 10);
      expect(next.upload, 10);
      expect(next.download, 4);
      expect(next.email, 'me@example.com');
      expect(next.baseUrl, _base);
    });

    test('copyWith can narrow a value down to zero', () {
      const state = PanelAccountState(transferEnable: 1024, isLoading: true);
      expect(state.copyWith(transferEnable: 0).transferEnable, 0);
      expect(state.copyWith(isLoading: false).isLoading, isFalse);
    });
  });

  group('login', () {
    test('normalises the address, trims the email, then loads usage', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.uri.path == _loginPath) {
          return _json({
            'data': {'auth_data': 'tok-1'},
          });
        }
        return _json(_subscribe(cap: 0));
      });
      final container = containerWith(adapter);

      await container
          .read(panelAccountProvider.notifier)
          .login(
            baseUrl: 'panel.example.com/',
            email: ' me@example.com ',
            password: 'pw',
          );

      expect(adapter.requests.first.uri.toString(), '$_base$_loginPath');
      expect(adapter.requests.first.data, {
        'email': 'me@example.com',
        'password': 'pw',
      });
      expect(adapter.requests.last.uri.toString(), '$_base$_subscribePath');
      expect(adapter.requests.last.headers['Authorization'], 'tok-1');

      final state = container.read(panelAccountProvider);
      expect(state.baseUrl, _base);
      expect(state.email, 'me@example.com');
      expect(state.token, 'tok-1');
      expect(state.isLoggedIn, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.used, 3072);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('panel_account_token'), 'tok-1');
      expect(preferences.getString('panel_account_base_url'), _base);
      expect(preferences.getString('panel_account_email'), 'me@example.com');
    });

    test('accepts a token the panel returns at the top level', () async {
      final adapter = _ScriptedAdapter(
        (options) => options.uri.path == _loginPath
            ? _json({'token': 'tok-2'})
            : _json(_subscribe()),
      );
      final container = containerWith(adapter);

      await container
          .read(panelAccountProvider.notifier)
          .login(baseUrl: _base, email: 'me@example.com', password: 'pw');

      expect(container.read(panelAccountProvider).token, 'tok-2');
    });

    test('refuses an address it cannot use, without calling out', () async {
      final adapter = _ScriptedAdapter((_) => _json(const {}));
      final container = containerWith(adapter);

      await expectLater(
        container
            .read(panelAccountProvider.notifier)
            .login(baseUrl: '   ', email: 'me@example.com', password: 'pw'),
        throwsA(
          isA<MessageException>().having(
            (error) => error.message,
            'message',
            currentAppLocalizations.panelBaseUrlRequired,
          ),
        ),
      );
      expect(adapter.requests, isEmpty);
      expect(container.read(panelAccountProvider).isLoading, isFalse);
    });

    test('reports a panel that answers without a token', () async {
      final adapter = _ScriptedAdapter((_) => _json({'data': const {}}));
      final container = containerWith(adapter);

      await expectLater(
        container
            .read(panelAccountProvider.notifier)
            .login(baseUrl: _base, email: 'me@example.com', password: 'pw'),
        throwsA(
          isA<MessageException>().having(
            (error) => error.message,
            'message',
            currentAppLocalizations.panelLoginNoToken,
          ),
        ),
      );
      expect(container.read(panelAccountProvider).isLoading, isFalse);
    });

    test('surfaces the reason the panel gave', () async {
      final adapter = _ScriptedAdapter(
        (_) => _json({'message': '账号或密码错误'}, 401),
      );
      final container = containerWith(adapter);

      await expectLater(
        container
            .read(panelAccountProvider.notifier)
            .login(baseUrl: _base, email: 'me@example.com', password: 'bad'),
        throwsA(
          isA<MessageException>().having(
            (error) => error.message,
            'message',
            '账号或密码错误',
          ),
        ),
      );
      expect(container.read(panelAccountProvider).isLoading, isFalse);
    });
  });

  group('refresh', () {
    Future<ProviderContainer> loggedIn(_ScriptedAdapter adapter) async {
      final container = containerWith(adapter);
      await container
          .read(panelAccountProvider.notifier)
          .login(baseUrl: _base, email: 'me@example.com', password: 'pw');
      return container;
    }

    test('reads the plan, the cap and both counters', () async {
      final adapter = _ScriptedAdapter(
        (options) => options.uri.path == _loginPath
            ? _json({
                'data': {'auth_data': 'tok-1'},
              })
            : _json(_subscribe()),
      );
      final container = await loggedIn(adapter);

      final state = container.read(panelAccountProvider);
      expect(state.planName, '基础版');
      expect(state.subscribeUrl, _subscribeUrl);
      expect(state.transferEnable, 100000);
      expect(state.upload, 1024);
      expect(state.download, 2048);
      expect(state.expiredAt, 1700000000);
      expect(state.used, 3072);
    });

    test('keeps a zero cap, which is how the panel says unlimited', () async {
      final adapter = _ScriptedAdapter(
        (options) => options.uri.path == _loginPath
            ? _json({
                'data': {'auth_data': 'tok-1'},
              })
            : _json(_subscribe(cap: 0)),
      );
      final container = await loggedIn(adapter);

      expect(container.read(panelAccountProvider).transferEnable, 0);
    });

    test('reads a payload that is not wrapped in data', () async {
      final adapter = _ScriptedAdapter(
        (options) => options.uri.path == _loginPath
            ? _json({
                'data': {'auth_data': 'tok-1'},
              })
            : _json({
                'subscribe_url': _subscribeUrl,
                'transfer_enable': 512,
                'u': 7,
                'd': 11,
                'expired_at': 1800000000,
                'plan': {'name': '进阶版'},
              }),
      );
      final container = await loggedIn(adapter);

      final state = container.read(panelAccountProvider);
      expect(state.planName, '进阶版');
      expect(state.transferEnable, 512);
      expect(state.used, 18);
      expect(state.expiredAt, 1800000000);
    });

    test('does nothing while logged out', () async {
      final adapter = _ScriptedAdapter((_) => _json(const {}));
      final container = containerWith(adapter);

      await container.read(panelAccountProvider.notifier).refresh();

      expect(adapter.requests, isEmpty);
      expect(container.read(panelAccountProvider).isLoading, isFalse);
    });

    test('names a timeout instead of leaking the transport error', () async {
      final adapter = _ScriptedAdapter(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        ),
      );
      final container = containerWith(adapter);

      await expectLater(
        container
            .read(panelAccountProvider.notifier)
            .login(baseUrl: _base, email: 'me@example.com', password: 'pw'),
        throwsA(
          isA<MessageException>().having(
            (error) => error.message,
            'message',
            currentAppLocalizations.panelTimeout,
          ),
        ),
      );
      expect(container.read(panelAccountProvider).isLoading, isFalse);
    });
  });

  group('restore and logout', () {
    test('restores a stored session and refreshes it', () async {
      SharedPreferences.setMockInitialValues({
        'panel_account_token': 'tok-9',
        'panel_account_base_url': _base,
        'panel_account_email': 'me@example.com',
      });
      final adapter = _ScriptedAdapter((_) => _json(_subscribe()));
      final container = containerWith(adapter);

      await pumpEventQueue();

      final state = container.read(panelAccountProvider);
      expect(state.token, 'tok-9');
      expect(state.email, 'me@example.com');
      expect(state.baseUrl, _base);
      expect(state.subscribeUrl, _subscribeUrl);
      expect(adapter.requests.single.headers['Authorization'], 'tok-9');
    });

    test('keeps a rejected token from breaking the launch path', () async {
      SharedPreferences.setMockInitialValues({
        'panel_account_token': 'stale',
        'panel_account_base_url': _base,
      });
      final adapter = _ScriptedAdapter((_) => _json({'message': '未授权'}, 401));
      final container = containerWith(adapter);

      await pumpEventQueue();

      final state = container.read(panelAccountProvider);
      expect(state.token, 'stale');
      expect(state.isLoading, isFalse);
      expect(state.subscribeUrl, isEmpty);
    });

    test('logout forgets the session and what it remembered', () async {
      final adapter = _ScriptedAdapter(
        (options) => options.uri.path == _loginPath
            ? _json({
                'data': {'auth_data': 'tok-1'},
              })
            : _json(_subscribe()),
      );
      final container = containerWith(adapter);
      final notifier = container.read(panelAccountProvider.notifier);
      await notifier.login(
        baseUrl: _base,
        email: 'me@example.com',
        password: 'pw',
      );

      await notifier.logout();

      final state = container.read(panelAccountProvider);
      expect(state.token, isEmpty);
      expect(state.email, isEmpty);
      expect(state.subscribeUrl, isEmpty);
      expect(state.planName, isEmpty);
      expect(state.used, 0);
      expect(state.isLoggedIn, isFalse);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('panel_account_token'), isNull);
      expect(preferences.getString('panel_account_email'), isNull);
    });
  });

  group('import', () {
    test('refuses to import before an address is known', () async {
      final adapter = _ScriptedAdapter((_) => _json(const {}));
      final container = containerWith(adapter);

      await expectLater(
        container.read(panelAccountProvider.notifier).importProfile(),
        throwsA(
          isA<MessageException>().having(
            (error) => error.message,
            'message',
            currentAppLocalizations.panelNoSubscriptionUrl,
          ),
        ),
      );
    });

    test('updates the profile an earlier import created', () async {
      final previous = Profile.normal(
        label: 'me@example.com',
        url: '$_subscribeUrl&flag=clash',
      ).copyWith(id: 41);
      final action = _RecordingProfilesAction();
      final adapter = _ScriptedAdapter(
        (options) => options.uri.path == _loginPath
            ? _json({
                'data': {'auth_data': 'tok-1'},
              })
            : _json(_subscribe()),
      );
      final container = containerWith(
        adapter,
        profiles: [previous],
        profilesAction: () => action,
      );
      final notifier = container.read(panelAccountProvider.notifier);
      await notifier.login(
        baseUrl: _base,
        email: 'me@example.com',
        password: 'pw',
      );

      await notifier.importProfile();

      expect(action.added, isEmpty);
      expect(action.updated, hasLength(1));
      expect(action.updated.single.id, 41);
      expect(
        action.updated.single.url,
        '$_subscribeUrl&flag=clashmeta',
        reason: 'the surviving profile is re-pointed at the template it needs',
      );
      expect(action.deleted, isEmpty);
      expect(container.read(profilesProvider), hasLength(1));
    });

    test('keeps one profile when a copy piled up', () async {
      final copies = [
        for (final id in [41, 42, 43])
          Profile.normal(
            label: 'me@example.com',
            url: '$_subscribeUrl&flag=clash',
          ).copyWith(id: id),
      ];
      final action = _RecordingProfilesAction();
      final adapter = _ScriptedAdapter(
        (options) => options.uri.path == _loginPath
            ? _json({
                'data': {'auth_data': 'tok-1'},
              })
            : _json(_subscribe()),
      );
      final container = containerWith(
        adapter,
        profiles: copies,
        profilesAction: () => action,
      );
      final notifier = container.read(panelAccountProvider.notifier);
      await notifier.login(
        baseUrl: _base,
        email: 'me@example.com',
        password: 'pw',
      );

      await notifier.importProfile();

      expect(action.updated.single.id, 41);
      expect(action.deleted, [42, 43]);
      expect(container.read(profilesProvider).map((item) => item.id), [41]);
    });

    test('adds a profile the first time, then never again', () async {
      final action = _RecordingProfilesAction();
      final adapter = _ScriptedAdapter(
        (options) => options.uri.path == _loginPath
            ? _json({
                'data': {'auth_data': 'tok-1'},
              })
            : _json(_subscribe()),
      );
      final container = containerWith(adapter, profilesAction: () => action);
      final notifier = container.read(panelAccountProvider.notifier);
      await notifier.login(
        baseUrl: _base,
        email: 'me@example.com',
        password: 'pw',
      );

      await notifier.importProfile(label: 'me@example.com');

      expect(action.updated, isEmpty);
      expect(action.added.single.$1, '$_subscribeUrl&flag=clashmeta');
      expect(action.added.single.$2, 'me@example.com');
    });
  });
}
