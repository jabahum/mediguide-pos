import 'package:flutter/material.dart';
import 'package:user_app/core/widgets/app_skeleton.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({
    super.key,
    this.message,
    this.padding = const EdgeInsets.all(24),
  });

  final String? message;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = message?.trim().isNotEmpty == true
        ? message!.trim()
        : 'Loading content';
    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Center(
          child: Padding(
            padding: padding,
            child: AppShimmer(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSkeleton(height: 24, width: 220),
                    SizedBox(height: 12),
                    AppSkeleton(height: 14, width: 320),
                    SizedBox(height: 24),
                    _LoadingCardSkeleton(),
                    SizedBox(height: 12),
                    _LoadingCardSkeleton(),
                    SizedBox(height: 12),
                    _LoadingCardSkeleton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingCardSkeleton extends StatelessWidget {
  const _LoadingCardSkeleton();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 72,
    child: Row(
      children: [
        AppSkeleton(height: 48, width: 48),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(height: 16, width: 240),
              SizedBox(height: 10),
              AppSkeleton(height: 12, width: 160),
            ],
          ),
        ),
      ],
    ),
  );
}
