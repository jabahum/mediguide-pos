import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/core/config/app_config.dart';
import 'package:user_app/core/config/flavor.dart';
import 'package:user_app/core/debug/debug_tools_overlay.dart';
import 'package:user_app/core/debug/network_inspector.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'MediGuide Staging',
      packageName: 'com.mediguide.ug.staging',
      version: '2.0.24',
      buildNumber: '51',
      buildSignature: '',
    );
    AppConfig.configure(Flavor.staging, debugToolsEnabled: true);
  });

  tearDown(() {
    AppConfig.configure(Flavor.production);
  });

  testWidgets('staging badge opens all three inspector destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkInspectorProvider.overrideWithValue(NetworkInspectorStore()),
        ],
        child: const MaterialApp(
          home: DebugToolsOverlay(child: Scaffold(body: Text('Application'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('STAGING'), findsOneWidget);
    await tester.tap(find.text('STAGING'));
    await tester.pumpAndSettle();

    expect(find.text('Debug Tools'), findsOneWidget);
    expect(find.text('Network Inspector'), findsOneWidget);
    expect(find.text('Remote Config Inspector'), findsOneWidget);
    expect(find.text('Build Config'), findsOneWidget);
  });

  testWidgets('badge opens when mounted by MaterialApp builder', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkInspectorProvider.overrideWithValue(NetworkInspectorStore()),
        ],
        child: MaterialApp(
          navigatorKey: AppNavigator.navigatorKey,
          builder: (context, child) => DebugToolsOverlay(child: child!),
          home: const Scaffold(body: Text('Application')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('STAGING'));
    await tester.pumpAndSettle();

    expect(find.text('Debug Tools'), findsOneWidget);
    expect(find.text('Network Inspector'), findsOneWidget);
  });

  testWidgets('production never renders the debug badge', (tester) async {
    AppConfig.configure(Flavor.production, debugToolsEnabled: true);
    await tester.pumpWidget(
      const MaterialApp(
        home: DebugToolsOverlay(child: Scaffold(body: Text('Application'))),
      ),
    );

    expect(find.text('PRODUCTION'), findsNothing);
    expect(find.text('Application'), findsOneWidget);
  });
}
