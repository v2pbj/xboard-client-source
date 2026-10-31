import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/panel_account.dart';
import 'package:fl_clash/providers/panel_update.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountView extends ConsumerStatefulWidget {
  const AccountView({super.key});

  @override
  ConsumerState<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends ConsumerState<AccountView> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final account = ref.read(panelAccountProvider);
    _baseUrlController = TextEditingController(text: account.baseUrl);
    _emailController = TextEditingController(text: account.email);
    _passwordController = TextEditingController();
    unawaited(ref.read(panelAccountProvider.notifier).syncBaseUrl());
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String tip) async {
    try {
      await action();
      if (!mounted) return;
      context.showNotifier(tip, level: MessageLevel.success);
    } on Exception catch (error) {
      if (!mounted) return;
      context.showNotifier('$error', level: MessageLevel.error);
    }
  }

  Future<void> _login() {
    return _run(() async {
      final accountAction = ref.read(panelAccountProvider.notifier);
      await accountAction.login(
        baseUrl: _baseUrlController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      await accountAction.importProfile(label: _emailController.text.trim());
    }, context.appLocalizations.accountLoginSuccess);
  }

  Future<void> _updateSubscription() {
    return _run(() async {
      final accountAction = ref.read(panelAccountProvider.notifier);
      await accountAction.refresh();
      await accountAction.importProfile();
    }, context.appLocalizations.accountSubscriptionUpdated);
  }

  Future<void> _openRenew() async {
    final renewUrl = ref.read(panelAccountProvider).renewUrl;
    if (renewUrl.isEmpty) return;
    await launchUrl(Uri.parse(renewUrl), mode: LaunchMode.externalApplication);
  }

  String _renewLabel() => Localizations.localeOf(context).languageCode == 'zh'
      ? '立即续费'
      : 'Renew now';

  Future<void> _logout() {
    return _run(
      () => ref.read(panelAccountProvider.notifier).logout(),
      context.appLocalizations.accountLoggedOut,
    );
  }

  List<Widget> _buildLoginForm() {
    final appLocalizations = context.appLocalizations;
    return [
      const SizedBox(height: 8),
      TextField(
        controller: _baseUrlController,
        autocorrect: false,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: appLocalizations.panelBaseUrl,
          hintText: 'https://your-panel.example.com',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _emailController,
        autocorrect: false,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(labelText: appLocalizations.email),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _passwordController,
        obscureText: true,
        decoration: InputDecoration(labelText: appLocalizations.password),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _login,
        child: Text(appLocalizations.accountLoginAndImport),
      ),
      const SizedBox(height: 8),
      Text(appLocalizations.accountLoginFormDesc, textAlign: TextAlign.center),
    ];
  }

  List<Widget> _buildAccount(PanelAccountState account) {
    final appLocalizations = context.appLocalizations;
    return [
      const SizedBox(height: 8),
      generateSection(
        title: appLocalizations.myAccount,
        items: [
          ListItem(
            title: Text(appLocalizations.email),
            subtitle: Text(account.email),
          ),
          ListItem(
            title: Text(appLocalizations.plan),
            subtitle: Text(account.planName.isEmpty ? '—' : account.planName),
          ),
          ListItem(
            title: Text(appLocalizations.panelBaseUrl),
            subtitle: Text(account.baseUrl),
          ),
          if (ref.watch(panelUpdateProvider).homeUrl.isNotEmpty)
            ListItem(
              title: Text(appLocalizations.permanentHome),
              subtitle: Text(ref.watch(panelUpdateProvider).homeUrl),
              onTap: () => launchUrl(
                Uri.parse(ref.read(panelUpdateProvider).homeUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ListItem(
            title: Text(appLocalizations.expireTime),
            subtitle: Text(_formatTime(account.expiredAt)),
          ),
          ListItem(
            title: Text(appLocalizations.usedOfTotal),
            subtitle: Text(
              '${_formatBytes(account.used)} / '
              '${account.transferEnable <= 0 ? appLocalizations.unlimited : _formatBytes(account.transferEnable)}',
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FilledButton(onPressed: _openRenew, child: Text(_renewLabel())),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: _updateSubscription,
        child: Text(appLocalizations.updateSubscription),
      ),
      const SizedBox(height: 8),
      OutlinedButton(onPressed: _logout, child: Text(appLocalizations.logout)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(panelAccountProvider);
    ref.listen(panelAccountProvider.select((state) => state.baseUrl), (
      previous,
      next,
    ) {
      if (next.isNotEmpty && _baseUrlController.text.trim().isEmpty) {
        _baseUrlController.text = next;
      }
    });
    return CommonScaffold(
      isLoading: account.isLoading,
      title: context.appLocalizations.account,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.contentTopPadding,
          bottom: 32 + context.bottomInset,
        ),
        children: account.isLoggedIn
            ? _buildAccount(account)
            : _buildLoginForm(),
      ),
    );
  }
}

/// Opens the panel account page; the page itself reads the account state.
void openAccountView(BuildContext context) {
  showExtend(
    context,
    props: const ExtendProps(forceFull: true),
    builder: (_) => const AccountView(),
  );
}

/// The panel sign-in an empty profile list offers, at [size].
class AccountLoginButton extends StatelessWidget {
  const AccountLoginButton({super.key, this.size = TonalButtonSize.bar});

  final TonalButtonSize size;

  @override
  Widget build(BuildContext context) {
    return TonalButton(
      size: size,
      glyph: AppGlyphs.cloudSync,
      label: context.appLocalizations.accountLogin,
      onPressed: () => openAccountView(context),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var index = 0;
  while (value >= 1024 && index < units.length - 1) {
    value /= 1024;
    index++;
  }
  final digits = value >= 100 || index == 0 ? 0 : 2;
  return '${value.toStringAsFixed(digits)} ${units[index]}';
}

String _formatTime(int seconds) {
  if (seconds <= 0) return '—';
  final time = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '${time.year}-$month-$day';
}
