// Rewrites the fork's app identity: display name, application id and URL scheme.
//
// Usage:
//   dart tool/rebrand.dart --name "示例加速" --id com.example.accel --bin Example
//   dart tool/rebrand.dart --name "示例加速" --id com.example.accel --dry-run
//
// Only dart:io is imported so the script runs without the package's build hooks.

import 'dart:io';

const _usage = '''
Rewrites this fork's identity.

  --name      Display name, as the launcher, window title and about page show it.
  --id        Android application id and Dart package name, e.g. com.example.accel.
  --bin       ASCII product name for the Windows and Linux binaries. Defaults to
              the last segment of --id, capitalized.
  --scheme    URL scheme for install-config links. Defaults to the last segment
              of --id, lower case. clash and clashmeta stay registered as well.
  --company   Company name for the Windows version resource. Defaults to --id.
  --dry-run   Report the edits without writing them.
''';

/// From the script location, so the tool runs from any directory.
final _root = File.fromUri(Platform.script).parent.parent.path;

void main(List<String> args) {
  final options = _Options.parse(args);
  if (options == null) {
    stdout.writeln(_usage);
    exitCode = 1;
    return;
  }
  final plan = _buildPlan(options);
  var changedFiles = 0;
  var changedEdits = 0;
  for (final entry in plan) {
    final file = File('$_root/${entry.path}');
    if (!file.existsSync()) {
      stdout.writeln('skip  ${entry.path} (missing)');
      continue;
    }
    final previous = file.readAsStringSync();
    var content = previous;
    var edits = 0;
    for (final edit in entry.edits) {
      final hits = edit.from.allMatches(content).length;
      if (hits == 0) continue;
      content = content.replaceAll(edit.from, edit.to);
      edits += hits;
    }
    if (edits == 0 || content == previous) {
      stdout.writeln('keep  ${entry.path}');
      continue;
    }
    changedFiles++;
    changedEdits += edits;
    stdout.writeln('write ${entry.path} ($edits)');
    if (!options.dryRun) file.writeAsStringSync(content);
  }
  final mode = options.dryRun ? 'dry-run' : 'applied';
  stdout.writeln('$mode: $changedEdits edits in $changedFiles files');
}

class _Edit {
  const _Edit(this.from, this.to);

  final Pattern from;
  final String to;
}

class _FilePlan {
  const _FilePlan(this.path, this.edits);

  final String path;
  final List<_Edit> edits;
}

class _Options {
  const _Options({
    required this.name,
    required this.id,
    required this.bin,
    required this.scheme,
    required this.company,
    required this.dryRun,
  });

  final String name;
  final String id;
  final String bin;
  final String scheme;
  final String company;
  final bool dryRun;

  static _Options? parse(List<String> args) {
    final values = <String, String>{};
    var dryRun = false;
    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      if (arg == '--dry-run') {
        dryRun = true;
        continue;
      }
      if (!arg.startsWith('--') || index + 1 >= args.length) return null;
      values[arg.substring(2)] = args[++index];
    }
    final name = values['name']?.trim() ?? '';
    final id = values['id']?.trim() ?? '';
    if (name.isEmpty || id.isEmpty) return null;
    final segments = id.split('.');
    final last = segments.isEmpty ? id : segments.last;
    final brand = segments.length >= 2 ? segments[segments.length - 2] : last;
    final bin = values['bin']?.trim();
    final scheme = values['scheme']?.trim();
    return _Options(
      name: name,
      id: id,
      bin: bin == null || bin.isEmpty
          ? '${brand[0].toUpperCase()}${brand.substring(1)}'
          : bin,
      scheme: scheme == null || scheme.isEmpty ? brand.toLowerCase() : scheme,
      company: values['company']?.trim() ?? brand,
      dryRun: dryRun,
    );
  }
}

List<_FilePlan> _buildPlan(_Options options) {
  return [
    _FilePlan('android/common/src/main/res/values/strings.xml', [
      _Edit('>FlClash<', '>${options.name}<'),
      _Edit('>FlClash Service<', '>${options.name} Service<'),
    ]),
    _FilePlan('android/app/build.gradle.kts', [
      _Edit('com.follow.clash', options.id),
    ]),
    _FilePlan('lib/common/constant.dart', [
      _Edit("const appName = 'FlClash';", "const appName = '${options.name}';"),
      _Edit(
        "const packageName = 'com.follow.clash';",
        "const packageName = '${options.id}';",
      ),
    ]),
    _FilePlan('lib/common/protocol.dart', [
      _Edit(
        "const protocolSchemes = ['clash', 'clashmeta', 'flclash'];",
        "const protocolSchemes = ['clash', 'clashmeta', '${options.scheme}'];",
      ),
      _Edit("'Name=FlClash',", "'Name=${options.name}',"),
      _Edit(
        "'flclash-url-handler.desktop'",
        "'${options.scheme}-url-handler.desktop'",
      ),
    ]),
    _FilePlan('distribute_options.yaml', [
      _Edit("app_name: 'FlClash'", "app_name: '${options.name}'"),
    ]),
    _FilePlan('windows/CMakeLists.txt', [
      _Edit('project(FlClash', 'project(${options.bin}'),
      _Edit('set(BINARY_NAME "FlClash")', 'set(BINARY_NAME "${options.bin}")'),
    ]),
    _FilePlan('windows/runner/Runner.rc', [
      _Edit(
        'VALUE "CompanyName", "com.follow"',
        'VALUE "CompanyName", "${options.company}"',
      ),
      _Edit(
        'VALUE "FileDescription", "FlClash"',
        'VALUE "FileDescription", "${options.bin}"',
      ),
      _Edit(
        'VALUE "ProductName", "clash"',
        'VALUE "ProductName", "${options.bin}"',
      ),
      _Edit(
        RegExp(r'VALUE "LegalCopyright", "[^"]*"'),
        'VALUE "LegalCopyright", "Copyright (C) ${options.company}. '
        'Licensed under GPL-3.0."',
      ),
      _Edit(
        RegExp(r'VALUE "InternalName", "[^"]*"'),
        'VALUE "InternalName", "${options.bin}"',
      ),
      _Edit(
        RegExp(r'VALUE "OriginalFilename", "[^"]*"'),
        'VALUE "OriginalFilename", "${options.bin}.exe"',
      ),
    ]),
    _FilePlan('linux/CMakeLists.txt', [
      _Edit(
        'set(BINARY_NAME "FlClash")',
        'set(BINARY_NAME "${options.bin.toLowerCase()}")',
      ),
      _Edit(
        'set(APPLICATION_ID "com.follow.clash")',
        'set(APPLICATION_ID "${options.id}")',
      ),
    ]),
    _FilePlan('macos/Runner/Configs/AppInfo.xcconfig', [
      _Edit('PRODUCT_NAME = FlClash', 'PRODUCT_NAME = ${options.name}'),
      _Edit(
        'PRODUCT_BUNDLE_IDENTIFIER = com.follow.clash',
        'PRODUCT_BUNDLE_IDENTIFIER = ${options.id}',
      ),
            _Edit(
        RegExp(r'PRODUCT_COPYRIGHT = [^\n]*'),
        'PRODUCT_COPYRIGHT = ${options.company}',
      ), 2025 com.follow',
        'PRODUCT_COPYRIGHT = ${options.company}',
      ),
    ]),
    _FilePlan('test/common/protocol_test.dart', [
      _Edit('flclash', options.scheme),
    ]),
    _FilePlan('test/common/link_test.dart', [_Edit('flclash', options.scheme)]),
  ];
}
