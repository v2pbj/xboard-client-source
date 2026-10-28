import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tells the user the notice applies without holding the app back: it floats
/// over the top of the home shell until "Agree" records the version, and anyone
/// who accepted one already never sees it. [onViewFull] opens the whole text.
class DisclaimerNotice extends ConsumerWidget {
  const DisclaimerNotice({super.key, this.onViewFull});

  final VoidCallback? onViewFull;

  static const _margin = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acceptedVersion = ref.watch(
      appSettingProvider.select((state) => state.acceptedDisclaimerVersion),
    );
    if (acceptedVersion >= disclaimerVersion) {
      return const SizedBox.shrink();
    }
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final level = SurfaceLevel.floatingOf(colorScheme);
    final foregroundColor = colorScheme.onSurfaceVariant;
    // The float covers the page's first strip, so the text and the fill stay
    // out of hit testing and only the actions below take a tap.
    final message = IgnorePointer(
      child: Text(
        appLocalizations.disclaimerNotice,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.subheadline
            .of(context)
            .copyWith(color: foregroundColor),
      ),
    );
    final glyph = IgnorePointer(
      child: GlyphIcon(
        AppGlyphs.gavel,
        size: 20.ap(context),
        color: foregroundColor,
      ),
    );
    final actions = <Widget>[
      if (onViewFull != null)
        TextButton(
          onPressed: onViewFull,
          child: Text(appLocalizations.disclaimerViewFull),
        ),
      TextButton(
        onPressed: () {
          ref
              .read(appSettingProvider.notifier)
              .update(
                (state) => state.copyWith(
                  acceptedDisclaimerVersion: disclaimerVersion,
                ),
              );
        },
        child: Text(appLocalizations.agree),
      ),
    ];
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              glyph,
              Expanded(child: message),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: actions,
          ),
        ],
      ),
    );
    final background = LiquidGlassScope.of(context)
        ? LiquidGlass(
            style: LiquidGlassStyle.regular(colorScheme),
            child: const SizedBox.expand(),
          )
        : DecoratedBox(
            decoration: ShapeDecoration(
              color: level.colorOf(colorScheme),
              shape: AppShape.xl,
              shadows: dockShadows(colorScheme),
            ),
            child: const SizedBox.expand(),
          );
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_margin, 8, _margin, 0),
        child: SurfaceScope(
          level: level,
          child: Stack(
            children: [
              Positioned.fill(child: IgnorePointer(child: background)),
              content,
            ],
          ),
        ),
      ),
    );
  }
}
