import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/panel_account.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
    }, '登录成功，订阅已导入');
  }

  Future<void> _updateSubscription() {
    return _run(() async {
      final accountAction = ref.read(panelAccountProvider.notifier);
      await accountAction.refresh();
      await accountAction.importProfile();
    }, '订阅已更新');
  }

  Future<void> _logout() {
    return _run(
      () => ref.read(panelAccountProvider.notifier).logout(),
      '已退出登录',
    );
  }

  List<Widget> _buildLoginForm() {
    return [
      const SizedBox(height: 8),
      TextField(
        controller: _baseUrlController,
        autocorrect: false,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          labelText: '面板地址',
          hintText: 'https://your-panel.example.com',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _emailController,
        autocorrect: false,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: '邮箱'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(labelText: '密码'),
      ),
      const SizedBox(height: 20),
      FilledButton(onPressed: _login, child: const Text('登录并导入订阅')),
      const SizedBox(height: 8),
      const Text(
        '登录后本机自动拉取你的订阅并导入为一个配置；账号密码只用于换取订阅地址，不会上传到别处。',
        textAlign: TextAlign.center,
      ),
    ];
  }

  List<Widget> _buildAccount(PanelAccountState account) {
    return [
      const SizedBox(height: 8),
      generateSection(
        title: '我的账号',
        items: [
          ListItem(title: const Text('邮箱'), subtitle: Text(account.email)),
          ListItem(
            title: const Text('套餐'),
            subtitle: Text(account.planName.isEmpty ? '—' : account.planName),
          ),
          ListItem(
            title: const Text('到期时间'),
            subtitle: Text(_formatTime(account.expiredAt)),
          ),
          ListItem(
            title: const Text('已用 / 总量'),
            subtitle: Text(
              '${_formatBytes(account.used)} / '
              '${_formatBytes(account.transferEnable)}',
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FilledButton(onPressed: _updateSubscription, child: const Text('更新订阅')),
      const SizedBox(height: 8),
      OutlinedButton(onPressed: _logout, child: const Text('退出登录')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(panelAccountProvider);
    return CommonScaffold(
      isLoading: account.isLoading,
      title: '账号',
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
