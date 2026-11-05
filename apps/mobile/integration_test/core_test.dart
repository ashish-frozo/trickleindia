import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pop_domain/pop_domain.dart';
import 'package:pop_ui/pop_ui.dart';
import 'package:pop_mobile/store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const phase = String.fromEnvironment('PHASE', defaultValue: 'bootstrap');
  testWidgets('Android durable contribution: $phase', (tester) async {
    final c = AppController(
      EncryptedStore(),
      const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://127.0.0.1:3000',
      ),
      allowFaults: phase == 'lost_ack',
    );
    final start = Stopwatch()..start();
    await c.init(autoSync: false);
    debugPrint('CACHE_START_MS=${start.elapsedMilliseconds}');
    if (phase == 'bootstrap') {
      await c.login('kavita', const String.fromEnvironment('DEMO_ACCESS_CODE'));
      final m = c.rows('members').firstWhere((m) => m['code'] == 'rani');
      expect(c.savings(m), 120000);
    } else if (phase == 'second_device') {
      expect(c.identity, isNull);
      await c.login('kavita', const String.fromEnvironment('DEMO_ACCESS_CODE'));
      final m = c.rows('members').firstWhere((m) => m['code'] == 'rani');
      expect(c.savings(m), 140000);
      expect(c.queue, isEmpty);
      expect(
        c
            .rows('transactions')
            .where(
              (t) => t['operationId'] == 'ef96912c-f11d-41bb-84c2-e9c240c22a35',
            )
            .length,
        1,
      );
    } else if (phase == 'save_offline') {
      expect(c.identity, isNotNull);
      final m = c.rows('members').firstWhere((m) => m['code'] == 'rani');
      final meeting = c.rows('meetings').single;
      final stopwatch = Stopwatch()..start();
      await c.enqueue('transaction.post', {
        'transactionId': const Uuid().v4(),
        'memberId': m['id'],
        'meetingId': meeting['id'],
        'type': 'savings_deposit',
        'amountPaise': 20000,
        'businessDate': '2026-11-05',
      }, intentId: 'ef96912c-f11d-41bb-84c2-e9c240c22a35');
      stopwatch.stop();
      debugPrint('LOCAL_SAVE_MS=${stopwatch.elapsedMilliseconds}');
      while (c.syncing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(c.savings(m), 120000);
      expect(c.pending(m['id'], 'savings_deposit'), 20000);
    } else if (phase == 'recover_offline') {
      final m = c.rows('members').firstWhere((m) => m['code'] == 'rani');
      expect(c.savings(m), 120000);
      expect(c.pending(m['id'], 'savings_deposit'), 20000);
      expect(
        c.queue
            .where(
              (o) => o['operationId'] == 'ef96912c-f11d-41bb-84c2-e9c240c22a35',
            )
            .length,
        1,
      );
    } else if (phase == 'lost_ack') {
      final m = c.rows('members').firstWhere((m) => m['code'] == 'rani');
      c.nextFault = 'drop_after_commit';
      await c.enqueue('transaction.post', {
        'transactionId': '39758906-28d6-4b0e-af12-4ebc274f85e5',
        'memberId': m['id'],
        'meetingId': c.rows('meetings').single['id'],
        'loanId': c
            .rows('loans')
            .firstWhere((l) => l['memberId'] == m['id'])['id'],
        'type': 'loan_principal_repayment',
        'amountPaise': 10000,
        'businessDate': '2026-11-05',
      }, intentId: '67e24807-8d7f-4f0c-adb7-86bcf21cf8e6');
      while (c.syncing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      final op = c.queue.singleWhere(
        (o) => o['operationId'] == '67e24807-8d7f-4f0c-adb7-86bcf21cf8e6',
      );
      expect(op['lastAttemptError'], 'TEMPORARILY_UNAVAILABLE');
      expect(op['state'], 'acknowledged');
      expect(c.principal(m), 190000);
      expect(c.pending(m['id'], 'loan_principal_repayment'), 0);
      await c.sync(force: true);
      expect(
        c
            .rows('transactions')
            .where((t) => t['operationId'] == op['operationId'])
            .length,
        1,
      );
      debugPrint('LOST_ACK_ONE_EFFECT=true');
    } else if (phase == 'registration_save') {
      expect(c.identity, isNotNull);
      await c.enqueue('member.create', {
        'memberId': '20332a31-d6bf-48c9-a3aa-c74b2f020078',
        'groupId': c.rows('groups').single['id'],
        'displayName': 'Demo Sita Devi',
        'preferredLanguage': 'hi',
        'livelihoodCategory': 'tailoring',
      }, intentId: '0c2a528d-6cd1-4441-bc9a-e260620a5b0e');
      while (c.syncing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(c.unresolved.where((o) => o['kind'] == 'member.create').length, 1);
    } else if (phase == 'registration_recover_sync') {
      final op = c.unresolved.singleWhere((o) => o['kind'] == 'member.create');
      expect(op['operationId'], '0c2a528d-6cd1-4441-bc9a-e260620a5b0e');
      expect(op['payload']['displayName'], 'Demo Sita Devi');
      await c.sync(force: true);
      await c.refresh();
      final member = c
          .rows('members')
          .singleWhere(
            (m) => m['id'] == '20332a31-d6bf-48c9-a3aa-c74b2f020078',
          );
      expect(c.savings(member), 0);
      expect(c.principal(member), 0);
      expect(c.rows('members').length, 5);
      expect(
        c.rows('members').fold<int>(0, (sum, m) => sum + c.savings(m)),
        380000,
      );
    } else if (phase == 'sync') {
      await c.sync(force: true);
      await c.refresh();
      final m = c.rows('members').firstWhere((m) => m['code'] == 'rani');
      expect(c.savings(m), 140000);
      expect(c.pending(m['id'], 'savings_deposit'), 0);
      expect(
        c
            .rows('transactions')
            .where(
              (t) => t['operationId'] == 'ef96912c-f11d-41bb-84c2-e9c240c22a35',
            )
            .length,
        1,
      );
    }
    if (phase == 'save_offline' || phase == 'recover_offline') {
      final operation = c.queue.singleWhere(
        (o) => o['operationId'] == 'ef96912c-f11d-41bb-84c2-e9c240c22a35',
      );
      debugPrint(
        'DURABLE_ENVELOPE=${jsonEncode(operation['envelope'] ?? operation)}',
      );
    }
    await tester.pumpWidget(PopApp(controller: c));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
}
