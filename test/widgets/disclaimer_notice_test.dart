import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

const _notice = 'Continuing to use the app means you have read the Disclaimer.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget app(AppSettingProps settings, {VoidCallback? onViewFull}) {
    return TestApp(
      locale: const Locale('en'),
      overrides: [appSettingProvider.overrideWithBuild((_, _) => settings)],
      child: DisclaimerNotice(onViewFull: onViewFull),
    );
  }

  testWidgets('shows the notice and records the version once agreed', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AppSettingProps()));

    expect(find.text(_notice), findsOneWidget);
    expect(find.text('Agree'), findsOneWidget);

    await tester.tap(find.text('Agree'));
    await tester.pumpAndSettle();

    expect(find.text(_notice), findsNothing);
    expect(find.text('Agree'), findsNothing);
  });

  testWidgets('stays away for a notice the user already accepted', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const AppSettingProps(acceptedDisclaimerVersion: disclaimerVersion)),
    );

    expect(find.text(_notice), findsNothing);
    expect(find.text('Agree'), findsNothing);
  });

  testWidgets('asks for the whole text from the link', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      app(const AppSettingProps(), onViewFull: () => opened++),
    );

    await tester.tap(find.text('View full text'));
    await tester.pump();

    expect(opened, 1);
    expect(find.text(_notice), findsOneWidget);
  });
}
