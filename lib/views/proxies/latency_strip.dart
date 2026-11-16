import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/color.dart';
import 'package:fl_clash/ui/context.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:fl_clash/ui/typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Compact, real delay strip for the current proxy group.
///
/// It only displays the delay values produced by the existing delay test.
/// There is no bandwidth test and no artificial reduction of the numbers.
class LatencyStrip extends ConsumerWidget {
  const LatencyStrip({super.key, required this.onTest});

  final VoidCallback onTest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(visibleGroupsStateProvider).value;
    final currentGroupName = ref.watch(
      proxiesTabControllerStateProvider.select(
        (state) => state.currentGroupName,
      ),
    );
    Group? group;
    for (final item in groups) {
      if (item.name == currentGroupName) {
        group = item;
        break;
      }
    }
    if (group == null || group.all.isEmpty) {
      return const SizedBox.shrink();
    }

    final testing = ref.watch(currentGroupDelayTestingProvider);
    final colorScheme = context.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceContainerLow,
        shape: AppShape.md.copyWith(
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.appLocalizations.delayTest,
                  style: AppTextStyle.subheadline.of(context, emphasized: true),
                ),
              ),
              Text(
                '${group.all.length}',
                style: AppTextStyle.footnote
                    .of(context)
                    .copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: context.appLocalizations.delayTest,
                onPressed: testing ? null : onTest,
                icon: testing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const GlyphIcon(AppGlyphs.bolt, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final proxy in group.all)
                  _DelayChip(proxy: proxy, testUrl: group.testUrl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DelayChip extends ConsumerWidget {
  const _DelayChip({required this.proxy, required this.testUrl});

  final Proxy proxy;
  final String? testUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delay = ref.watch(
      delayProvider(proxyName: proxy.name, testUrl: testUrl),
    );
    final colorScheme = context.colorScheme;
    final (label, color) = delay == null
        ? ('--', colorScheme.onSurfaceVariant)
        : (
            delay > 0
                ? '$delay ms'
                : delayFailureText(delay, context.appLocalizations),
            colorScheme.delayColor(delay),
          );
    return Semantics(
      label: '${proxy.name}, $label',
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: ShapeDecoration(
          color: colorScheme.surface,
          shape: AppShape.sm.copyWith(
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Tooltip(
                message: proxy.name,
                child: Text(
                  proxy.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.footnote.of(context),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyle.footnote
                  .of(context, emphasized: true)
                  .copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
