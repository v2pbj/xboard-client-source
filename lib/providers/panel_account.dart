import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fork ships the same sources to every panel, so the address is supplied at
/// build time (`--dart-define=PANEL_BASE_URL=https://...`) and stays editable
/// in the account page for a build that does not set it.
const _panelBaseUrlDefine = String.fromEnvironment('PANEL_BASE_URL');

const _tokenKey = 'panel_account_token';
const _baseUrlKey = 'panel_account_base_url';
const _emailKey = 'panel_account_email';

const _loginPath = '/api/v1/passport/auth/login';
const _subscribePath = '/api/v1/user/getSubscribe';

// The front page outlives a panel rename, so it publishes the panel address.
const _endpointSeed = 'https://app.xycould.top';
const _endpointPath = '/client-endpoint.json';
const _discoveredBaseUrlKey = 'panel_account_discovered_base_url';

@immutable
class PanelAccountState {
  const PanelAccountState({
    this.baseUrl = _panelBaseUrlDefine,
    this.token = '',
    this.email = '',
    this.subscribeUrl = '',
    this.planName = '',
    this.expiredAt = 0,
    this.transferEnable = 0,
    this.upload = 0,
    this.download = 0,
    this.isLoading = false,
  });

  final String baseUrl;
  final String token;
  final String email;
  final String subscribeUrl;
  final String planName;
  final int expiredAt;
  final int transferEnable;
  final int upload;
  final int download;
  final bool isLoading;

  bool get isLoggedIn => token.isNotEmpty;

  int get used => upload + download;

  PanelAccountState copyWith({
    String? baseUrl,
    String? token,
    String? email,
    String? subscribeUrl,
    String? planName,
    int? expiredAt,
    int? transferEnable,
    int? upload,
    int? download,
    bool? isLoading,
  }) {
    return PanelAccountState(
      baseUrl: baseUrl ?? this.baseUrl,
      token: token ?? this.token,
      email: email ?? this.email,
      subscribeUrl: subscribeUrl ?? this.subscribeUrl,
      planName: planName ?? this.planName,
      expiredAt: expiredAt ?? this.expiredAt,
      transferEnable: transferEnable ?? this.transferEnable,
      upload: upload ?? this.upload,
      download: download ?? this.download,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final panelAccountProvider =
    NotifierProvider<PanelAccountNotifier, PanelAccountState>(
      PanelAccountNotifier.new,
    );

class PanelAccountNotifier extends Notifier<PanelAccountState> {
  /// A test supplies its own client; the app gets the timeouts the panel needs.
  PanelAccountNotifier({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
            ),
          );

  final Dio _dio;

  @override
  PanelAccountState build() {
    unawaited(_restore());
    return const PanelAccountState();
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final token = preferences.getString(_tokenKey) ?? '';
    final baseUrl = preferences.getString(_baseUrlKey) ?? _panelBaseUrlDefine;
    final email = preferences.getString(_emailKey) ?? '';
    state = state.copyWith(baseUrl: baseUrl, token: token, email: email);
    if (token.isEmpty) return;
    try {
      await refresh();
    } on Exception {
      // A token the panel no longer accepts must not fail the launch path.
    }
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, state.token);
    await preferences.setString(_baseUrlKey, state.baseUrl);
    await preferences.setString(_emailKey, state.email);
  }

  Future<void> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final base = _normalizeBaseUrl(baseUrl);
    if (base.isEmpty) {
      throw MessageException(currentAppLocalizations.panelBaseUrlRequired);
    }
    state = state.copyWith(isLoading: true);
    try {
      final response = await _dio.post<dynamic>(
        '$base$_loginPath',
        data: {'email': email.trim(), 'password': password},
      );
      final data = _dataOf(response.data);
      final token = '${data['auth_data'] ?? data['token'] ?? ''}';
      if (token.isEmpty) {
        state = state.copyWith(isLoading: false);
        throw MessageException(currentAppLocalizations.panelLoginNoToken);
      }
      state = state.copyWith(
        baseUrl: base,
        email: email.trim(),
        token: token,
        isLoading: false,
      );
      await _persist();
      await refresh();
    } on DioException catch (error) {
      state = state.copyWith(isLoading: false);
      throw MessageException(_messageOf(error));
    }
  }

  Future<void> refresh() async {
    if (state.token.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final response = await _dio.get<dynamic>(
        '${state.baseUrl}$_subscribePath',
        options: Options(headers: {'Authorization': state.token}),
      );
      final data = _dataOf(response.data);
      if (!ref.mounted) return;
      state = state.copyWith(
        subscribeUrl: '${data['subscribe_url'] ?? ''}',
        planName: _planNameOf(data),
        transferEnable: _intOf(data['transfer_enable']),
        upload: _intOf(data['u']),
        download: _intOf(data['d']),
        expiredAt: _intOf(data['expired_at']),
        isLoading: false,
      );
    } on DioException catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isLoading: false);
      }
      throw MessageException(_messageOf(error));
    }
  }

  /// Only an empty base URL, or the one this method wrote last, is replaced.
  Future<void> syncBaseUrl() async {
    final preferences = await SharedPreferences.getInstance();
    final discovered = preferences.getString(_discoveredBaseUrlKey) ?? '';
    final current = _normalizeBaseUrl(state.baseUrl);
    if (current.isNotEmpty && current != discovered) return;
    String candidate;
    try {
      final response = await _dio.get<dynamic>(
        '$_endpointSeed$_endpointPath',
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      candidate = _normalizeBaseUrl(
        '${_dataOf(response.data)['panel_base_url'] ?? ''}',
      );
    } on DioException {
      return;
    }
    final uri = Uri.tryParse(candidate);
    final isUsable =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    if (!isUsable) return;
    await preferences.setString(_discoveredBaseUrlKey, candidate);
    if (!ref.mounted || candidate == current) return;
    state = state.copyWith(baseUrl: candidate);
    await _persist();
  }

  /// Importing twice must not leave two profiles behind: the panel hands out
  /// the same subscription every time, so an import updates the profile an
  /// earlier import created, and removes copies left by a build that did not
  /// keep track of it (an older build asked for the `clash` template).
  Future<void> importProfile({String? label}) async {
    final subscribeUrl = state.subscribeUrl;
    if (subscribeUrl.isEmpty) {
      throw MessageException(currentAppLocalizations.panelNoSubscriptionUrl);
    }
    final url = _withClashFlag(subscribeUrl);
    final actions = ref.read(profilesActionProvider.notifier);
    final matches = [
      for (final profile in ref.read(profilesProvider))
        if (profile.url.isNotEmpty && _isSameSubscription(profile.url, url))
          profile,
    ];
    if (matches.isEmpty) {
      await actions.addProfileFromLink(url, label: label);
      return;
    }
    final kept = matches.first.copyWith(
      url: url,
      label: label == null || label.isEmpty ? matches.first.label : label,
    );
    await actions.updateProfile(kept, showLoading: true);
    for (final duplicate in matches.skip(1)) {
      await actions.deleteProfile(duplicate.id);
    }
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_emailKey);
    state = state.copyWith(
      token: '',
      email: '',
      subscribeUrl: '',
      planName: '',
      expiredAt: 0,
      transferEnable: 0,
      upload: 0,
      download: 0,
    );
  }
}

/// The panel reads the requested format from `flag`, and only falls back to the
/// User-Agent, so a renamed client still gets the Clash template. It has to be
/// the Clash.Meta template: this panel serves VLESS nodes only, and the classic
/// `clash` template drops every VLESS proxy, which leaves an empty node list.
String _withClashFlag(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  return uri
      .replace(queryParameters: {...uri.queryParameters, 'flag': 'clashmeta'})
      .toString();
}

/// The panel reads `flag` to choose the template, so the same subscription gets
/// stored under different links across builds. Two links are that same
/// subscription when they point at the same place with the same token.
bool _isSameSubscription(String first, String second) {
  final left = Uri.tryParse(first);
  final right = Uri.tryParse(second);
  if (left == null || right == null) return first == second;
  return _subscriptionKey(left) == _subscriptionKey(right);
}

String _subscriptionKey(Uri uri) {
  final query = Map<String, String>.from(uri.queryParameters)..remove('flag');
  final keys = query.keys.toList()..sort();
  return '${uri.scheme}://${uri.host}${uri.path}'
      '?${[for (final key in keys) '$key=${query[key]}'].join('&')}';
}

String _normalizeBaseUrl(String value) {
  var url = value.trim();
  if (url.isEmpty) return url;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  return url;
}

Map<String, dynamic> _dataOf(dynamic body) {
  if (body is! Map) return const {};
  final data = body['data'];
  if (data is Map) return Map<String, dynamic>.from(data);
  return Map<String, dynamic>.from(body);
}

String _planNameOf(Map<String, dynamic> data) {
  final plan = data['plan'];
  if (plan is Map && plan['name'] != null) return '${plan['name']}';
  return '';
}

int _intOf(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

String _messageOf(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['message'] != null) return '${data['message']}';
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return currentAppLocalizations.panelTimeout;
  }
  return currentAppLocalizations.panelConnectFailed(
    error.message ?? error.type.name,
  );
}
