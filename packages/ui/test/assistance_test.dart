import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pop_ui/src/assistance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('voice commands only navigate to exact role-allowed screens', () {
    expect(commandRoute('Open groups', 'sakhi'), '/groups');
    expect(commandRoute('समूह', 'participant'), isNull);
    expect(commandRoute('रिपोर्ट', 'manager'), '/reports');
    expect(commandRoute('reports', 'sakhi'), isNull);
    for (final text in [
      'save 500',
      'transfer money',
      'delete member',
      'open groups and save 200',
      '/member/123',
      'home; reset',
    ]) {
      expect(commandRoute(text, 'manager'), isNull);
    }
  });
  test(
    'offline help uses original source text and does not guess answers',
    () async {
      final pack = jsonDecode(
        await rootBundle.loadString(
          'packages/pop_ui/assets/content_cards.json',
        ),
      ) as Map<String, dynamic>;
      final answer = localHelp(pack, 'बचत जमा', 'hi');
      expect(answer.first['id'], 'save-contribution');
      expect(answer.first['steps'], pack['cards'][0]['locales']['hi']['steps']);
      expect(localHelp(pack, 'weather tomorrow', 'en'), isEmpty);
    },
  );
}
