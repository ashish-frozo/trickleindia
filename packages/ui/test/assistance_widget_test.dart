import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pop_domain/pop_domain.dart';
import 'package:pop_ui/src/assistance.dart';

void main() {
  testWidgets('voice listeners survive repeat sessions and page reentry', (
    tester,
  ) async {
    const channel = MethodChannel('plugin.csdcorp.com/speech_to_text');
    final messenger = tester.binding.defaultBinaryMessenger;
    int initializations = 0, listens = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'initialize') initializations++;
      if (call.method == 'listen') listens++;
      if (call.method == 'locales') return ['en_US:English'];
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    Future<void> event(String method, String value) async {
      await messenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(MethodCall(method, value)),
        (_) {},
      );
      await tester.pumpAndSettle();
    }

    final words =
        jsonDecode(File('assets/ui_en.arb').readAsStringSync()) as Map;
    final c = AppController(MemoryStore(), 'http://unused');
    Widget page() => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AssistancePanel(
            controller: c,
            language: 'en',
            t: (k) => words[k] ?? k,
          ),
        ),
      ),
    );
    Future<void> start() async {
      await tester.ensureVisible(find.text(words['startListening']));
      await tester.tap(find.text(words['startListening']));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, words['startListening']),
      );
      await tester.pumpAndSettle();
      await event('notifyStatus', 'listening');
      expect(find.text(words['stopReading']), findsOneWidget);
    }

    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    await start();
    await event('notifyStatus', 'notListening');
    expect(find.text(words['stopReading']), findsNothing);
    await start();
    await event('notifyError', '{"errorMsg":"network","permanent":true}');
    expect(find.text(words['voiceUnavailable']), findsOneWidget);
    expect(find.text(words['stopReading']), findsNothing);
    // Disposal invalidates old callbacks; reopening uses the same singleton.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await event('notifyStatus', 'notListening');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    await start();
    await event('notifyStatus', 'notListening');
    expect(find.text(words['stopReading']), findsNothing);
    expect(initializations, 1);
    expect(listens, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    c.dispose();
  });
  testWidgets(
    'help is offline, command review cannot post money and large text fits',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final words =
          jsonDecode(File('assets/ui_en.arb').readAsStringSync()) as Map;
      final c = AppController(MemoryStore(), 'http://unused')..online = false;
      c.identity = {
        'actor': {'id': 'test', 'role': 'participant'},
        'datasetId': 'test',
        'offlineUntil': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      };
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AssistancePanel(
                    controller: c,
                    language: 'en',
                    t: (k) => words[k] ?? k,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final command = find.byType(TextField).first;
      await tester.enterText(command, 'save 500');
      await tester.pumpAndSettle();
      final open = find.widgetWithText(FilledButton, 'Open selected screen');
      expect(tester.widget<FilledButton>(open).onPressed, isNull);
      expect(c.queue, isEmpty);
      await tester.ensureVisible(find.text('Use microphone'));
      await tester.tap(find.text('Use microphone'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(words['microphoneDisclosure']), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField).last);
      await tester.enterText(find.byType(TextField).last, 'save savings');
      final ask = find.widgetWithText(FilledButton, 'Find instructions');
      await tester.ensureVisible(ask);
      await tester.tap(ask);
      await tester.pumpAndSettle();
      expect(find.text('Save a contribution'), findsOneWidget);
      expect(c.queue, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
