import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/shared/providers/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(connectivityProvider).valueOrNull;
    if (connected != false) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: 'Offline. Showing downloaded or cached content.',
      child: Material(
        color: colors.secondaryContainer,
        child: const SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.cloudOff, size: 18),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Offline — showing saved content where available',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
