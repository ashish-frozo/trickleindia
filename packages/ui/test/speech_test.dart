import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pop_ui/src/speech.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  late List<MethodCall> calls;
  late List<Map<String, dynamic>> voices;
  Completer<dynamic>? speaking;
  setUp(() {
    calls = [];
    voices = [];
    speaking = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'getVoices') return voices;
          if (call.method == 'speak' && speaking != null) {
            return speaking!.future;
          }
          return 1;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test('missing or network-only Android voice never speaks', () async {
    final speech = InstructionSpeech(offlineOnly: true);
    voices = [
      {'name': 'remote', 'locale': 'hi-IN', 'network_required': 'true'},
    ];
    await speech.read('help', 'hi', 'निर्देश');
    expect(speech.error, 'speechUnavailable');
    expect(calls.where((c) => c.method == 'speak'), isEmpty);
    speech.dispose();
  });
  test(
    'uses matching installed offline voice and handles completion',
    () async {
      final speech = InstructionSpeech(offlineOnly: true);
      voices = [
        {'name': 'English', 'locale': 'en-IN', 'network_required': 'false'},
        {'name': 'Hindi', 'locale': 'hi-IN', 'network_required': 'false'},
      ];
      await speech.read('help', 'hi', 'निर्देश');
      expect(
        calls.firstWhere((c) => c.method == 'setVoice').arguments['name'],
        'Hindi',
      );
      expect(calls.firstWhere((c) => c.method == 'speak').arguments, 'निर्देश');
      expect(speech.error, isNull);
      expect(speech.activeId, isNull);
      speech.dispose();
    },
  );
  test('stop invalidates pending completion', () async {
    final speech = InstructionSpeech(offlineOnly: true);
    voices = [
      {'name': 'English', 'locale': 'en-IN', 'network_required': false},
    ];
    speaking = Completer<dynamic>();
    final read = speech.read('help', 'en', 'Instructions');
    while (!calls.any((c) => c.method == 'speak')) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(speech.activeId, 'help');
    await speech.stop();
    speaking!.complete(1);
    await read;
    expect(speech.activeId, isNull);
    expect(speech.error, isNull);
    speech.dispose();
  });
}
