import 'package:flutter/material.dart';
import 'package:user_app/core/constants/app_dimensions.dart';

/// Applies one shared shimmer animation to a tree of skeleton placeholders.
class AppShimmer extends StatefulWidget {
  const AppShimmer({required this.child, super.key});

  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget shimmer;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      shimmer = widget.child;
    } else {
      shimmer = AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) =>
            _AppShimmerScope(progress: _controller.value, child: child!),
      );
    }

    return Semantics(
      container: true,
      label: 'Loading content',
      child: ExcludeSemantics(child: shimmer),
    );
  }
}

class _AppShimmerScope extends InheritedWidget {
  const _AppShimmerScope({required this.progress, required super.child});

  final double progress;

  static double? maybeProgressOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppShimmerScope>()?.progress;

  @override
  bool updateShouldNotify(_AppShimmerScope oldWidget) =>
      progress != oldWidget.progress;
}

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.height = 16,
    this.width = double.infinity,
  });

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = _AppShimmerScope.maybeProgressOf(context);
    final baseColor = colors.surfaceContainerHighest;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: progress == null ? baseColor : null,
        gradient: progress == null
            ? null
            : LinearGradient(
                begin: Alignment(-3 + (progress * 6), 0),
                end: Alignment(-1 + (progress * 6), 0),
                colors: [baseColor, colors.surfaceContainerLow, baseColor],
                stops: const [0.25, 0.5, 0.75],
              ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
    );
  }
}
