import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pop_domain/pop_domain.dart';
import 'package:pop_ui/pop_ui.dart';

void main() {
  setUp(() {
    rootBundle.clear();
  });
  testWidgets(
    'English/Hindi login at 360px and 200% text has no layout exceptions',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = AppController(MemoryStore(), 'http://unused');
      await tester.pumpWidget(PopApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.text('Proposal demo • Fictional data'), findsOneWidget);
      expect(find.text('Choose a demo role'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Choose a demo role'), findsNothing);
      expect(find.text('English'), findsOneWidget);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a demo role'), findsOneWidget);
      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: PopApp(controller: c),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      c.dispose();
    },
  );

  testWidgets(
    'authenticated mobile and manager layouts remain usable with large text',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final seed = jsonDecode(
        File('../../PoP_2_Demo_Coding_Pack/assets/demo_seed.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final role in ['sakhi', 'participant', 'manager']) {
        tester.view.physicalSize = role == 'manager'
            ? const Size(1440, 1000)
            : const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        final c = AppController(MemoryStore(), 'http://unused')..online = false;
        c.identity = {
          'actor': (seed['actors'] as List).firstWhere(
            (a) => a['role'] == role,
          ),
          'offlineUntil': DateTime.now()
              .add(const Duration(hours: 1))
              .toIso8601String(),
          'datasetId': seed['dataset']['id'],
        };
        c.data = seed;
        await tester.pumpWidget(PopApp(key: ValueKey(role), controller: c));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: role);
        await tester.tap(find.text('हिन्दी'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Hindi $role');
        if (role == 'sakhi') {
          final router = GoRouter.of(tester.element(find.text('PoP 2.0')));
          for (final page in [
            'groups',
            'meetings',
            'enterprise',
            'sync',
            'work',
            'help',
          ]) {
            router.go('/$page');
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: 'Hindi $page at 200%',
            );
          }
        }

        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets(
    'Hindi amount review with keyboard and repeated confirmation saves one pending entry',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final seed = jsonDecode(
        File('../../PoP_2_Demo_Coding_Pack/assets/demo_seed.json')
            .readAsStringSync(),
      ) as Json;
      final hi =
          jsonDecode(File('assets/ui_hi.arb').readAsStringSync()) as Json;
      final c = AppController(MemoryStore(), 'http://unused')..online = false;
      c.identity = {
        'actor': seed['actors'].firstWhere((a) => a['role'] == 'sakhi'),
        'datasetId': seed['dataset']['id'],
        'offlineUntil': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      };
      c.data = seed;
      await tester.pumpWidget(PopApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.text('PoP 2.0')))
          .go('/member/5cc5cc24-7b28-522e-b444-a3be6b12c679');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(hi['recordEntry']), 200);
      await tester.tap(find.text(hi['recordEntry']));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '200');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(hi['review']));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final confirm = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, hi['saveContribution']),
      );
      confirm.onPressed!();
      confirm.onPressed!();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(c.queue.length, 1);
      expect(
        c.pending('5cc5cc24-7b28-522e-b444-a3be6b12c679', 'savings_deposit'),
        20000,
      );
      expect(
        c.savings(c.rows('members').firstWhere((m) => m['code'] == 'rani')),
        120000,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
  );

  testWidgets(
    'conflict review links replacement and preserves original intent',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final seed = jsonDecode(
        File('../../PoP_2_Demo_Coding_Pack/assets/demo_seed.json')
            .readAsStringSync(),
      ) as Json;
      final c = AppController(
        MemoryStore(),
        'http://api',
        client: MockClient((request) async {
          if (request.url.path.startsWith('/v1/operations/')) {
            return http.Response(
              jsonEncode({
                'error': {'code': 'OPERATION_NOT_FOUND'},
              }),
              404,
            );
          }
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({'records': [], 'nextCursor': '0', 'hasMore': false}),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'error': {'code': 'TEMPORARILY_UNAVAILABLE', 'retryable': true},
            }),
            503,
          );
        }),
      )..online = false;
      c.identity = {
        'actor': seed['actors'].firstWhere((a) => a['role'] == 'sakhi'),
        'token': 'test',
        'datasetId': seed['dataset']['id'],
        'offlineUntil': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      };
      c.data = seed;
      final a = c.rows('attendance').first;
      await c.enqueue('meeting.attendance_set', {
        'attendanceId': a['id'],
        'meetingId': a['meetingId'],
        'memberId': a['memberId'],
        'status': 'absent',
        'expectedVersion': 1,
      }, intentId: 'original');
      final original = c.queue.single;
      original.addAll({
        'state': 'conflict',
        'hasEverDispatched': true,
        'error': 'VERSION_CONFLICT',
        'details': {
          'currentRecord': {...a, 'version': 2, 'status': 'present'},
        },
      });
      c.online = true;
      await tester.pumpWidget(PopApp(controller: c));
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.text('PoP 2.0'))).go('/sync');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(TextButton, 'Review'),
        200,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Review'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(c.queue.length, 2);
      expect(original['state'], 'superseded');
      expect(original['payload']['expectedVersion'], 1);
      expect(c.queue.last['operationId'], isNot('original'));
      expect(c.queue.last['replacesOperationId'], 'original');
      expect(c.queue.last['payload']['expectedVersion'], 2);
      expect(c.queue.last['payload']['status'], 'absent');
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
  );

  testWidgets(
    'expired session retains a reachable counted local reset confirmation',
    (tester) async {
      final words =
          jsonDecode(File('assets/ui_en.arb').readAsStringSync()) as Json;
      final c = AppController(MemoryStore(), 'http://unused')..online = false;
      c.identity = {
        'actor': {'id': 'a', 'role': 'sakhi'},
        'datasetId': 'old',
        'offlineUntil': DateTime.now()
            .subtract(const Duration(seconds: 1))
            .toIso8601String(),
      };
      c.data = {
        'members': [
          {'displayName': 'Private cached member'},
        ],
      };
      c.queue = [
        {
          'operationId': 'retained',
          'state': 'blocked',
          'kind': 'transaction.post',
          'payload': {'amountPaise': 20000},
        },
      ];
      await tester.pumpWidget(PopApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.text('Private cached member'), findsNothing);
      await tester.scrollUntilVisible(
        find.text(words['resetWarning']),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(words['resetWarning']));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 Waiting to sync'), findsWidgets);
      await tester.enterText(find.byType(TextField).last, 'RESET DEMO');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(c.queue, isEmpty);
      expect(c.identity, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
  );

  testWidgets(
    'profile conflict compares every proposed field with current server values',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final seed = jsonDecode(
        File('../../PoP_2_Demo_Coding_Pack/assets/demo_seed.json')
            .readAsStringSync(),
      ) as Json;
      final c = AppController(MemoryStore(), 'http://unused')..online = false;
      c.identity = {
        'actor': seed['actors'].firstWhere((a) => a['role'] == 'sakhi'),
        'datasetId': seed['dataset']['id'],
        'offlineUntil': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      };
      c.data = seed;
      c.queue = [
        {
          'operationId': 'profile-conflict',
          'kind': 'member.update',
          'state': 'conflict',
          'payload': {
            'memberId': seed['members'][0]['id'],
            'expectedVersion': 1,
            'patch': {
              'displayName': 'Rani Local',
              'livelihoodCategory': 'tailoring',
            },
          },
          'details': {
            'currentRecord': {
              'id': seed['members'][0]['id'],
              'version': 2,
              'displayName': 'Rani Server',
              'livelihoodCategory': 'livestock',
            },
          },
        },
      ];
      await tester.pumpWidget(PopApp(controller: c));
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.text('PoP 2.0'))).go('/sync');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(TextButton, 'Review'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Review'));
      await tester.pumpAndSettle();
      for (final value in [
        'Rani Server',
        'Rani Local',
        'livestock',
        'tailoring',
      ]) {
        expect(find.descendant(of: find.byType(AlertDialog), matching: find.textContaining(value)), findsOneWidget);
      }
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(c.queue.single['state'], 'conflict');
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
  );
}
