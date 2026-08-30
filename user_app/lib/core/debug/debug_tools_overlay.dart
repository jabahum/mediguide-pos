import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/core/config/app_config.dart';
import 'package:user_app/core/config/firebase_config.dart';
import 'package:user_app/core/debug/network_inspector.dart';
import 'package:user_app/core/services/firebase_service.dart';
import 'package:user_app/core/utils/app_message.dart';

enum _DebugPage { network, remoteConfig, buildConfig }

final class DebugToolsOverlay extends ConsumerStatefulWidget {
  const DebugToolsOverlay({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DebugToolsOverlay> createState() => _DebugToolsOverlayState();
}

final class _DebugToolsOverlayState extends ConsumerState<DebugToolsOverlay> {
  Offset? _position;
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version}+${info.buildNumber}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.current.debugToolsEnabled) return widget.child;
    return LayoutBuilder(
      builder: (context, constraints) {
        const badgeWidth = 96.0;
        const badgeHeight = 58.0;
        final safeTop = MediaQuery.paddingOf(context).top + 8;
        final safeBottom = MediaQuery.paddingOf(context).bottom + 8;
        final initial = Offset(
          constraints.maxWidth - badgeWidth - 4,
          (constraints.maxHeight - badgeHeight) * .48,
        );
        final current = _position ?? initial;
        final position = Offset(
          current.dx.clamp(4, constraints.maxWidth - badgeWidth - 4),
          current.dy.clamp(
            safeTop,
            constraints.maxHeight - badgeHeight - safeBottom,
          ),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            Positioned(
              left: position.dx,
              top: position.dy,
              width: badgeWidth,
              height: badgeHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) => setState(() {
                  _position = position + details.delta;
                }),
                onTap: () => _showDebugTools(context),
                child: Material(
                  elevation: 8,
                  color: const Color(0xffef3838),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(28),
                    right: Radius.circular(12),
                  ),
                  child: Semantics(
                    button: true,
                    label: 'Open ${AppConfig.current.flavor.label} debug tools',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppConfig.current.flavor.label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .4,
                            ),
                          ),
                          if (_version.isNotEmpty)
                            Text(
                              _version,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDebugTools(BuildContext context) {
    // MaterialApp.router.builder is outside the Router's Navigator. Resolve a
    // local Navigator for standalone use, then fall back to GoRouter's root
    // navigator and present from its overlay-owned context.
    final navigator =
        Navigator.maybeOf(context, rootNavigator: true) ??
        AppNavigator.navigatorKey.currentState;
    final navigatorContext = navigator?.overlay?.context;
    if (navigatorContext == null) return Future<void>.value();

    return showModalBottomSheet<void>(
      context: navigatorContext,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxWidth: 720,
        maxHeight: MediaQuery.sizeOf(navigatorContext).height * .9,
      ),
      builder: (_) => const _DebugToolsSheet(),
    );
  }
}

final class _DebugToolsSheet extends ConsumerStatefulWidget {
  const _DebugToolsSheet();

  @override
  ConsumerState<_DebugToolsSheet> createState() => _DebugToolsSheetState();
}

final class _DebugToolsSheetState extends ConsumerState<_DebugToolsSheet> {
  _DebugPage? _page;

  @override
  Widget build(BuildContext context) {
    final title = switch (_page) {
      _DebugPage.network => 'Network Inspector',
      _DebugPage.remoteConfig => 'Remote Config Inspector',
      _DebugPage.buildConfig => 'Build Config',
      null => 'Debug Tools',
    };
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .82,
      child: Column(
        children: [
          ListTile(
            leading: _page == null
                ? null
                : IconButton(
                    tooltip: 'Back to debug tools',
                    onPressed: () => setState(() => _page = null),
                    icon: const Icon(Icons.arrow_back),
                  ),
            title: Text(
              title,
              textAlign: _page == null ? TextAlign.center : TextAlign.start,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            subtitle: _page == null
                ? Text(
                    '${AppConfig.current.flavor.label.toUpperCase()} · '
                    '${AppConfig.current.apiBaseUrl}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: IconButton(
              tooltip: 'Close debug tools',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: switch (_page) {
              _DebugPage.network => const _NetworkInspectorPage(),
              _DebugPage.remoteConfig => const _RemoteConfigInspectorPage(),
              _DebugPage.buildConfig => const _BuildConfigPage(),
              null => ListView(
                children: [
                  _menuTile(
                    Icons.wifi_tethering,
                    'Network Inspector',
                    'Inspect redacted API requests, responses and timing',
                    _DebugPage.network,
                  ),
                  _menuTile(
                    Icons.tune,
                    'Remote Config Inspector',
                    'Review active Firebase values and fetch metadata',
                    _DebugPage.remoteConfig,
                  ),
                  _menuTile(
                    Icons.build_outlined,
                    'Build Config',
                    'Review flavor, package, version and endpoints',
                    _DebugPage.buildConfig,
                  ),
                  ListTile(
                    minTileHeight: 84,
                    leading: Icon(
                      Icons.bug_report_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 30,
                    ),
                    title: const Text(
                      'Send Crashlytics test',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Queue a non-fatal diagnostic report for this environment',
                    ),
                    onTap: _sendCrashlyticsTest,
                  ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    IconData icon,
    String title,
    String subtitle,
    _DebugPage page,
  ) => ListTile(
    minTileHeight: 84,
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 30),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => setState(() => _page = page),
  );

  Future<void> _sendCrashlyticsTest() async {
    final service = ref.read(firebaseServiceProvider);
    if (!service.crashReportingEnabled) {
      AppMessage.warning(
        context,
        'Crashlytics is not configured for this build.',
      );
      return;
    }
    try {
      await service.recordNonFatalError(
        StateError('MediGuide Crashlytics diagnostic test'),
        StackTrace.current,
        reason: 'Manual ${AppConfig.current.flavor.name} environment test',
      );
      if (!mounted) return;
      AppMessage.success(
        context,
        'Test report queued for ${AppConfig.current.flavor.label}. '
        'Restart the app to flush it.',
      );
    } catch (error) {
      if (!mounted) return;
      AppMessage.error(context, 'Could not queue the Crashlytics test: $error');
    }
  }
}

final class _NetworkInspectorPage extends ConsumerWidget {
  const _NetworkInspectorPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(networkInspectorProvider);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final entries = store.entries;
        if (entries.isEmpty) {
          return const _InspectorEmpty(
            icon: Icons.wifi_off,
            message: 'No API requests captured yet.',
          );
        }
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: store.clear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) =>
                    _NetworkEntryTile(entry: entries[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _NetworkEntryTile extends StatelessWidget {
  const _NetworkEntryTile({required this.entry});

  final NetworkLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.status) {
      NetworkLogStatus.pending => Colors.orange,
      NetworkLogStatus.success when (entry.statusCode ?? 0) < 400 =>
        Colors.green,
      _ => Colors.red,
    };
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .12),
        child: Text(
          entry.method.substring(
            0,
            entry.method.length < 3 ? entry.method.length : 3,
          ),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        entry.uri.path,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${entry.statusCode ?? '…'} · ${entry.duration?.inMilliseconds ?? 0} ms · '
        '${entry.uri.host}',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _copyableBlock('URL', entry.uri.toString()),
        _copyableBlock('Request headers', entry.requestHeaders.toString()),
        if (entry.requestBody != null)
          _copyableBlock('Request body', entry.requestBody!),
        if (entry.responseBody != null)
          _copyableBlock('Response', entry.responseBody!),
        if (entry.error != null) _copyableBlock('Error', entry.error!),
      ],
    );
  }
}

final class _RemoteConfigInspectorPage extends ConsumerStatefulWidget {
  const _RemoteConfigInspectorPage();

  @override
  ConsumerState<_RemoteConfigInspectorPage> createState() =>
      _RemoteConfigInspectorPageState();
}

final class _RemoteConfigInspectorPageState
    extends ConsumerState<_RemoteConfigInspectorPage> {
  bool _refreshing = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(firebaseServiceProvider);
    if (!service.enabled) {
      return const _InspectorEmpty(
        icon: Icons.cloud_off,
        message: 'Firebase is not configured for this build.',
      );
    }
    final entries = service.remoteConfigValues.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text('${service.remoteConfigLastFetchStatus}')),
            if (service.remoteConfigLastFetchTime case final fetchedAt?)
              Chip(label: Text('Fetched ${fetchedAt.toLocal()}')),
            FilledButton.icon(
              onPressed: _refreshing ? null : () => _refresh(service),
              icon: _refreshing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Fetch & activate'),
            ),
          ],
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_message!),
          ),
        const SizedBox(height: 12),
        for (final item in entries)
          Card(
            child: ListTile(
              title: Text(
                item.key,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${item.value.asString()}\nSource: ${_sourceLabel(item.value.source)}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'Copy value',
                onPressed: () => Clipboard.setData(
                  ClipboardData(text: item.value.asString()),
                ),
                icon: const Icon(Icons.copy),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _refresh(MediGuideFirebaseService service) async {
    setState(() {
      _refreshing = true;
      _message = null;
    });
    try {
      final changed = await service.refreshRemoteConfig();
      if (mounted) {
        setState(
          () => _message = changed
              ? 'New values activated.'
              : 'Values are already current.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _message = 'Fetch failed: $error');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String _sourceLabel(ValueSource source) => switch (source) {
    ValueSource.valueRemote => 'remote',
    ValueSource.valueDefault => 'default',
    ValueSource.valueStatic => 'static',
  };
}

final class _BuildConfigPage extends StatelessWidget {
  const _BuildConfigPage();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform(),
    builder: (context, snapshot) {
      final info = snapshot.data;
      final rows = <(String, String)>[
        ('Environment', AppConfig.current.flavor.label),
        ('API base URL', AppConfig.current.apiBaseUrl),
        ('Debug tools', '${AppConfig.current.debugToolsEnabled}'),
        (
          'Firebase project',
          MediGuideFirebaseConfig.projectId.isEmpty
              ? 'Not configured'
              : MediGuideFirebaseConfig.projectId,
        ),
        if (info != null) ...[
          ('Application name', info.appName),
          ('Package / bundle ID', info.packageName),
          ('Version', info.version),
          ('Build number', info.buildNumber),
          if (info.installerStore != null) ('Installer', info.installerStore!),
        ],
      ];
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) => ListTile(
          title: Text(rows[index].$1),
          subtitle: SelectableText(rows[index].$2),
          trailing: IconButton(
            tooltip: 'Copy',
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: rows[index].$2)),
            icon: const Icon(Icons.copy, size: 18),
          ),
        ),
      );
    },
  );
}

final class _InspectorEmpty extends StatelessWidget {
  const _InspectorEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

Widget _copyableBlock(String label, String value) => Builder(
  builder: (context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Copy $label',
              onPressed: () => Clipboard.setData(ClipboardData(text: value)),
              icon: const Icon(Icons.copy, size: 18),
            ),
          ],
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
      ],
    ),
  ),
);
