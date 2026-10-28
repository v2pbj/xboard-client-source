import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget app(AppSettingProps settings) {
    return TestApp(
      locale: const Locale('en'),
      overrides: [appSettingProvider.overrideWithBuild((_, _) => settings)],
      child: const DisclaimerNotice(),
    );
  }

  testWidgets('shows the notice and records the version once agreed', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AppSettingProps()));

    expect(find.text('Agree'), findsOneWidget);
    expect(find.textContaining('By installing, copying'), findsOneWidget);

    await tester.tap(find.text('Agree'));
    await tester.pumpAndSettle();

    expect(find.text('Agree'), findsNothing);
    expect(find.textContaining('By installing, copying'), findsNothing);
  });

  testWidgets('stays away for a notice the user already accepted', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const AppSettingProps(acceptedDisclaimerVersion: disclaimerVersion)),
    );

    expect(find.text('Agree'), findsNothing);
    expect(find.textContaining('By installing, copying'), findsNothing);
  });
}
