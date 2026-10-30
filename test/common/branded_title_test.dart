import 'package:fl_clash/common/l10n_labels.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a Chinese title joins the brand without a space', () {
    expect(
      brandedPageTitle(
        label: '仪表盘',
        brandEn: 'Bear Booster',
        brandZh: '白熊加速',
        locale: const Locale('zh', 'CN'),
      ),
      '白熊加速仪表盘',
    );
  });

  test('any other language joins the brand with a space', () {
    expect(
      brandedPageTitle(
        label: 'Dashboard',
        brandEn: 'Bear Booster',
        brandZh: '白熊加速',
        locale: const Locale('en'),
      ),
      'Bear Booster Dashboard',
    );
  });

  test('an empty brand leaves the plain label', () {
    expect(
      brandedPageTitle(
        label: 'Dashboard',
        brandEn: '',
        brandZh: '',
        locale: const Locale('en'),
      ),
      'Dashboard',
    );
  });
}
