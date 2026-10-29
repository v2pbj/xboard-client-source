import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/account.dart';
import 'package:fl_clash/views/tools.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

void main() {
  testWidgets('the account entry leads the tools page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    addTearDown(container.dispose);
    globalState.container = container;
    container
        .read(viewSizeProvider.notifier)
        .update((_) => const Size(1400, 1000));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: ToolsView()),
      ),
    );
    await tester.pump();

    final account = find.text('Account');
    expect(account, findsOneWidget);
    expect(
      tester.getRect(account).top,
      lessThan(tester.getRect(find.text('Language')).top),
    );
    expect(
      tester.getRect(account).top,
      lessThan(tester.getRect(find.text('Settings')).top),
    );

    await tester.tap(account);
    await tester.pumpAndSettle();
    expect(find.byType(AccountView), findsOneWidget);
  });
}
