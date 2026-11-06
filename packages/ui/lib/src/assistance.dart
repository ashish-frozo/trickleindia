import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pop_domain/pop_domain.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'components.dart';
import 'speech.dart';

/// Exact navigation commands only: never interpret amounts or execute a write.
String? commandRoute(String command, String role) {
  final normalized = command.trim().toLowerCase().replaceAll(
    RegExp(r'[.!?।]+$'),
    '',
  );
  final routes = <String, String>{
    'home': '/home',
    'open home': '/home',
    'होम': '/home',
    'help': '/help',
    'open help': '/help',
    'सहायता': '/help',
    'sync': '/sync',
    'open sync': '/sync',
    'सिंक': '/sync',
    if (role != 'participant') ...{
      'groups': '/groups',
      'open groups': '/groups',
      'समूह': '/groups',
      'meetings': '/meetings',
      'open meetings': '/meetings',
      'बैठक': '/meetings',
      'work': '/work',
      'open work': '/work',
      'काम': '/work',
    },
    if (role == 'manager') ...{
      'reports': '/reports',
      'open reports': '/reports',
      'रिपोर्ट': '/reports',
      'activity': '/activity',
      'open activity': '/activity',
      'गतिविधि': '/activity',
    },
  };
  return routes[normalized];
}

List<Json> localHelp(Json pack, String query, String language) {
  final words = query.toLowerCase().split(RegExp(r'[\s,.?!।]+')).toSet();
  final scored = <({Json card, int score})>[];
  for (final value in pack['cards'] as List) {
    final card = Map<String, dynamic>.from(value);
    final score = (card['keywords'] as List)
        .where(
          (word) =>
              word.toString().toLowerCase().split(' ').every(words.contains),
        )
        .length;
    if (score > 0) scored.add((card: card, score: score));
  }
  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored
      .take(2)
      .map(
        (item) => <String, dynamic>{
          'id': item.card['id'],
          'version': item.card['version'],
          ...Map<String, dynamic>.from(item.card['locales'][language]),
        },
      )
      .toList();
}

class AssistancePanel extends StatefulWidget {
  const AssistancePanel({
    super.key,
    required this.controller,
    required this.language,
    required this.t,
  });
  final AppController controller;
  final String language;
  final String Function(String) t;
  @override
  State<AssistancePanel> createState() => _AssistancePanelState();
}

class _AssistancePanelState extends State<AssistancePanel>
    with WidgetsBindingObserver {
  final question = TextEditingController(), command = TextEditingController();
  final recognition = SpeechToText(), speech = InstructionSpeech();
  int voiceGeneration = 0;
  bool busy = false, listening = false, remoteConsent = false;
  String? error, mode;
  List<Json> citations = [];
  String t(String key) => widget.t(key);
  AppController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant AssistancePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      unawaited(stop());
      citations = [];
      mode = null;
    }
  }

  Future<void> stop() async {
    voiceGeneration++;
    try {
      await recognition.cancel();
    } catch (_) {}
    await speech.stop();
    if (mounted) setState(() => listening = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(stop());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    voiceGeneration++;
    unawaited(recognition.cancel().catchError((Object _) {}));
    speech.dispose();
    question.dispose();
    command.dispose();
    super.dispose();
  }

  Future<void> listen() async {
    if (listening) {
      await stop();
      return;
    }
    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('voiceNavigation')),
        content: Text(t('microphoneDisclosure')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('startListening')),
          ),
        ],
      ),
    );
    if (agreed != true || !mounted) return;
    setState(() {
      error = null;
      listening = true;
    });
    final generation = ++voiceGeneration;
    bool current() => mounted && generation == voiceGeneration;
    try {
      final available = await recognition.initialize(
        onError: (_) {
          if (current()) {
            setState(() {
              listening = false;
              error = 'voiceUnavailable';
            });
          }
        },
        onStatus: (status) {
          if (current() && ['done', 'notListening'].contains(status)) {
            setState(() => listening = false);
          }
        },
        options: [SpeechToText.androidNoBluetooth],
      );
      if (!current()) return;
      if (!available) throw StateError('unavailable');
      final locales = await recognition.locales();
      final locale = locales
          .where(
            (l) => l.localeId
                .toLowerCase()
                .replaceAll('_', '-')
                .startsWith(widget.language),
          )
          .firstOrNull;
      if (!current()) return;
      if (locale == null) throw StateError('language');
      await recognition.listen(
        onResult: (result) {
          if (current()) setState(() => command.text = result.recognizedWords);
        },
        listenOptions: SpeechListenOptions(
          localeId: locale.localeId,
          onDevice: true,
          partialResults: false,
          cancelOnError: true,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      if (current()) {
        setState(() {
          error = 'voiceUnavailable';
          listening = false;
        });
      }
    }
  }

  Future<void> ask() async {
    if (busy || question.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      error = null;
      citations = [];
      mode = null;
    });
    try {
      final pack =
          c.contentPack ??
          jsonDecode(
            await rootBundle.loadString(
              'packages/pop_ui/assets/content_cards.json',
            ),
          ) as Json;
      Json answer;
      try {
        if (!c.online) throw StateError('offline');
        answer = Map<String, dynamic>.from(
          await c.request('POST', '/v1/assistant', {
            'question': question.text.trim(),
            'language': widget.language,
            'remoteConsent': remoteConsent,
          }),
        );
      } catch (e) {
        if (e is ApiError && [401, 403].contains(e.status)) {
          rethrow;
        }
        answer = {
          'mode': 'fallback',
          'citations': localHelp(pack, question.text.trim(), widget.language),
        };
      }
      if (mounted && c.valid) {
        setState(() {
          mode = answer['mode'];
          citations = (answer['citations'] as List)
              .map((x) => Map<String, dynamic>.from(x))
              .toList();
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = 'contentLoadFailed');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = commandRoute(command.text, c.actor['role'] ?? 'participant');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t('assistantTitle'),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(t('assistantDisclosure')),
        const SizedBox(height: 24),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t('voiceNavigation'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(t('voiceCommands')),
              const SizedBox(height: 16),
              TextField(
                controller: command,
                maxLength: 100,
                decoration: InputDecoration(labelText: t('command')),
                onChanged: (_) => setState(() {}),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: listen,
                    icon: Icon(listening ? Icons.stop : Icons.mic_none),
                    label: Text(
                      t(listening ? 'stopReading' : 'startListening'),
                    ),
                  ),
                  FilledButton(
                    onPressed: route == null
                        ? null
                        : () {
                            unawaited(stop());
                            context.go(route);
                          },
                    child: Text(t('openCommand')),
                  ),
                ],
              ),
              if (command.text.isNotEmpty && route == null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(t('unsupportedCommand')),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t('askHelp'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: question,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: t('helpQuestion')),
                enabled: !busy,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: remoteConsent,
                onChanged: busy
                    ? null
                    : (v) => setState(() => remoteConsent = v!),
                title: Text(t('remoteHelpConsent')),
                subtitle: Text(t('remoteHelpPrivacy')),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: busy ? null : ask,
                icon: Icon(busy ? Icons.hourglass_empty : Icons.search),
                label: Text(t(busy ? 'loading' : 'askHelp')),
              ),
              if (mode != null) ...[
                const SizedBox(height: 16),
                Text(
                  t(
                    mode == 'provider'
                        ? 'providerMatched'
                        : mode == 'fallback'
                        ? 'localFallback'
                        : 'localMatched',
                  ),
                ),
              ],
              if (mode != null && citations.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(t('unsupportedHelp')),
                ),
              for (final citation in citations)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        citation['title'],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final step in citation['steps'])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(step),
                        ),
                      Text(
                        '${t('source')}: ${citation['id']} · v${citation['version']}',
                      ),
                      SpeechControl(
                        speech: speech,
                        id: citation['id'],
                        language: widget.language,
                        text: (citation['steps'] as List).join(' '),
                        t: t,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (error != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                t(error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
      ],
    );
  }
}
