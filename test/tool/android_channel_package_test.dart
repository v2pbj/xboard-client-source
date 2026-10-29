import 'dart:io';

import 'package:fl_clash/common/constant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the Dart package name keeps up with the Android application id', () {
    final applicationId = RegExp(r'applicationId = "([^"]+)"')
        .firstMatch(File('android/app/build.gradle.kts').readAsStringSync())!
        .group(1);

    expect(packageName, applicationId);
  });

  test('the native plugins register the channels Dart sends on', () {
    final components = File(
      'android/common/src/main/java/com/follow/clash/common/Components.kt',
    ).readAsStringSync();
    final channelPackage = RegExp(r'const val CHANNEL_PACKAGE = "([^"]+)"')
        .firstMatch(components)!
        .group(1);

    expect(channelPackage, packageName);

    final plugins = Directory('android/app/src/main/kotlin/com/follow/clash/plugins')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.kt'));

    expect(plugins, isNotEmpty);
    for (final plugin in plugins) {
      expect(
        plugin.readAsStringSync(),
        isNot(contains(r'${Components.PACKAGE_NAME}/')),
        reason: '${plugin.path} addresses a channel by the namespace',
      );
    }
  });
}
