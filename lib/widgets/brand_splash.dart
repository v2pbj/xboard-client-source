import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:material_ui/material_ui.dart';

class BrandSplash extends StatefulWidget {
  const BrandSplash({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
  });

  final Widget child;
  final Duration duration;

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash> {
  var _visible = true;
  var _fading = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.duration, () {
      if (!mounted) return;
      setState(() => _fading = true);
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (mounted) {
          setState(() => _visible = false);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible)
          AnimatedOpacity(
            opacity: _fading ? 0 : 1,
            duration: const Duration(milliseconds: 260),
            child: const _BrandSplashBody(),
          ),
      ],
    );
  }
}

class _BrandSplashBody extends StatelessWidget {
  const _BrandSplashBody();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return AbsorbPointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.surface, scheme.primaryContainer],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                appName,
                style: AppTextStyle.title1
                    .of(context, emphasized: true)
                    .copyWith(color: scheme.primary),
              ),
              const SizedBox(height: 6),
              Text(
                appNameZh,
                style: AppTextStyle.headline
                    .of(context)
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 30),
              const SizedBox(
                width: 96,
                child: LinearProgressIndicator(minHeight: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
