import 'package:fl_clash/providers/panel_update.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
