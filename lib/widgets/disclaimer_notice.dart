import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tells the user the notice applies without holding the app back: it sits at
/// the top of the home shell until "Agree" records the version, and anyone who
/// accepted one already never sees it. The full text is on the tools page.
class DisclaimerNotice extends ConsumerWidget {
  const DisclaimerNotice({super.key});

  static const _narrowWidth = 320.0;

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
    final foregroundColor = colorScheme.onSurfaceVariant;
    final glyph = GlyphIcon(
      AppGlyphs.gavel,
      size: 20.ap(context),
      color: foregroundColor,
    );
    final message = Text(
      appLocalizations.disclaimerAcceptContent,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyle.subheadline
          .of(context)
          .copyWith(color: foregroundColor),
    );
    final action = TextButton(
      onPressed: () {
        ref
            .read(appSettingProvider.notifier)
            .update(
              (state) =>
                  state.copyWith(acceptedDisclaimerVersion: disclaimerVersion),
            );
      },
      child: Text(appLocalizations.agree),
    );
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: ShapeDecoration(
            color: context.raisedSurfaceLevel.colorOf(colorScheme),
            shape: AppShape.xl,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Side by side needs the room a narrow window does not have, and
              // a squeezed button overflows its row, so it drops under the text.
              if (constraints.maxWidth < _narrowWidth) {
                return Column(
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
                    action,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  glyph,
                  Expanded(child: message),
                  action,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
