import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reads only bundled instructions, never financial records or user input.
/// Android voices requiring a network are deliberately excluded.
class InstructionSpeech extends ChangeNotifier with WidgetsBindingObserver {
  InstructionSpeech({FlutterTts? engine, bool? offlineOnly})
    : _engine = engine ?? FlutterTts(),
      _offlineOnly =
          offlineOnly ??
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    WidgetsBinding.instance.addObserver(this);
  }
  final FlutterTts _engine;
  final bool _offlineOnly;
  String? activeId;
  String? error;
  bool preparing = false;
  bool _disposed = false;
  int _generation = 0;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> read(String id, String language, String text) async {
    if (_disposed) return;
    final generation = ++_generation;
    bool current() => !_disposed && generation == _generation;
    activeId = id;
    preparing = true;
    error = null;
    _notify();
    try {
      await _engine.stop();
      if (!current()) return;
      final voices = await _engine.getVoices.timeout(
        const Duration(seconds: 8),
      );
      if (!current()) return;
      final matches = (voices as List).whereType<Map>().where((voice) {
        final locale = '${voice['locale']}'.replaceAll('_', '-').toLowerCase();
        final offline =
            voice['network_required'] == false ||
            voice['network_required'] == 'false';
        return (locale == language || locale.startsWith('$language-')) &&
            (!_offlineOnly || offline);
      }).toList();
      if (matches.isEmpty) {
        error = 'speechUnavailable';
        return;
      }
      final voice = matches.first;
      await _engine.setLanguage('${voice['locale']}');
      if (!current()) return;
      await _engine.setVoice({
        'name': '${voice['name']}',
        'locale': '${voice['locale']}',
      });
      if (!current()) return;
      await _engine.setSpeechRate(0.45);
      if (!current()) return;
      await _engine.awaitSpeakCompletion(true);
      if (!current()) return;
      preparing = false;
      _notify();
      final result = await _engine.speak(text);
      if (current() && result == 0) error = 'speechFailed';
    } catch (_) {
      if (current()) error = 'speechFailed';
    } finally {
      if (current()) {
        activeId = null;
        preparing = false;
        _notify();
      }
    }
  }

  Future<void> stop() async {
    ++_generation;
    activeId = null;
    preparing = false;
    error = null;
    _notify();
    try {
      await _engine.stop();
    } catch (_) {
      /* no speech plugin on some hosts */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(stop());
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(stop());
    super.dispose();
  }
}

class SpeechControl extends StatelessWidget {
  const SpeechControl({
    super.key,
    required this.speech,
    required this.id,
    required this.language,
    required this.text,
    required this.t,
  });
  final InstructionSpeech speech;
  final String id, language, text;
  final String Function(String) t;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: speech,
    builder: (context, _) {
      final active = speech.activeId == id;
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  active ? speech.stop() : speech.read(id, language, text),
              icon: Icon(
                active ? Icons.stop_rounded : Icons.volume_up_outlined,
              ),
              label: Text(t(active ? 'stopReading' : 'listenInstructions')),
            ),
            if (active && speech.preparing) Text(t('speechLoading')),
            Text(
              t('speechDisclosure'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (speech.error != null)
              Semantics(liveRegion: true, child: Text(t(speech.error!))),
          ],
        ),
      );
    },
  );
}
