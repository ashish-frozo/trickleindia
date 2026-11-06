// Explicit UI preview, not a native-device acceptance test.
// Run: flutter test test/visual_preview_test.dart --dart-define=CAPTURE_UI=true
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pop_domain/pop_domain.dart';
import 'package:pop_ui/pop_ui.dart';

void main() {
  testWidgets('render app previews with bundled fonts and synthetic fixture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.runAsync(() async {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      for (final family in ['NotoSans', 'NotoSansDevanagari']) {
        final loader = FontLoader('packages/pop_ui/$family');
        for (final weight in ['Regular', 'SemiBold']) {
          loader.addFont(
            rootBundle.load('packages/pop_ui/assets/fonts/$family-$weight.ttf'),
          );
        }
        await loader.load();
      }
    });
    final seed = jsonDecode(
      File('../../PoP_2_Demo_Coding_Pack/assets/demo_seed.json')
          .readAsStringSync(),
    ) as Json;
    final c = AppController(MemoryStore(), 'http://unused');
    c.identity = {
      'actor': seed['actors'].firstWhere((a) => a['role'] == 'sakhi'),
      'datasetId': seed['dataset']['id'],
      'offlineUntil': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    };
    c.data = seed;
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: PopApp(controller: c),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../../output/blueprint/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('app-home-en-widget-preview');
    final router = GoRouter.of(tester.element(find.text('PoP 2.0')));
    router.go(
      '/member/${seed['members'].firstWhere((m) => m['code'] == 'rani')['id']}',
    );
    await tester.pumpAndSettle();
    await capture('app-passbook-en-widget-preview');
    await tester.tap(find.text('हिन्दी'));
    await tester.pumpAndSettle();
    await capture('app-passbook-hi-widget-preview');
    tester.view.physicalSize = const Size(360, 800);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    await capture('app-passbook-hi-200-widget-preview');
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  }, skip: !const bool.fromEnvironment('CAPTURE_UI'));
}
