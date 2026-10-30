import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:flutter_test/flutter_test.dart';

/// A white-label build must never hand its users to the upstream project: the
/// release page, the update check and the corresponding-source link all follow
/// [repository], so pointing it upstream would offer an unbranded client.
void main() {
  test('the repository constant names our own releases', () {
    expect(repository, 'v2pbj/xboard-client-source');
    expect(repository.contains('chen08209'), isFalse);
  });

  test('no source file still names the upstream repository', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      if (entity.path.contains('generated') || entity.path.contains('l10n')) {
        continue;
      }
      if (entity.readAsStringSync().contains('chen08209')) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty);
  });
}
