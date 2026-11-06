import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pop_domain/pop_domain.dart';
import 'package:pop_ui/src/programme_reports.dart';

void main() {
  test(
    'snapshot exports preserve confirmed totals, scope and reversals',
    () async {
      final c = AppController(MemoryStore(), 'http://localhost');
      c.data = jsonDecode(
        await File('../../PoP_2_Demo_Coding_Pack/assets/demo_seed.json')
            .readAsString(),
      );
      c.lastContact = '2026-11-06T00:00:00Z';
      final rows = snapshotReport(c, 'balances', 'all');
      expect(rows.length, 7);
      expect(rows.skip(1).fold<int>(0, (n, r) => n + (r[3] as int)), 480000);
      expect(
        snapshotReport(c, 'balances', c.rows('groups').first['id']).length,
        5,
      );
      final enterprise = snapshotReport(c, 'enterprises', 'all');
      expect(enterprise[1][6], 120000);
      c.data['transactions'] = [
        ...c.rows('transactions'),
        {
          'id': 'reversed',
          'enterpriseId': c.rows('enterprises').first['id'],
          'type': 'enterprise_expense',
          'amountPaise': 35000,
          'reversedByTransactionId': 'correction',
        },
      ];
      expect(snapshotReport(c, 'enterprises', 'all')[1][6], 120000);
      expect(snapshotReport(c, 'visits', 'all'), hasLength(1));
      c.dispose();
    },
  );
}
