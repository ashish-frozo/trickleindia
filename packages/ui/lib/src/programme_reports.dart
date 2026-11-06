import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pop_domain/pop_domain.dart';

import 'components.dart';
import 'download.dart';
import 'reports.dart';

List<List<Object?>> snapshotReport(
  AppController c,
  String kind,
  String groupId,
) {
  final groups = {for (final g in c.rows('groups')) g['id']: g['displayName']};
  final members = {for (final m in c.rows('members')) m['id']: m};
  bool included(dynamic id) => groupId == 'all' || id == groupId;
  final stamp = c.lastContact;
  if (kind == 'balances') {
    return [
      [
        'member_id',
        'member',
        'group',
        'confirmed_savings_paise',
        'outstanding_principal_paise',
        'last_refreshed_utc',
      ],
      for (final m in members.values.where((m) => included(m['groupId'])))
        [
          m['id'],
          m['displayName'],
          groups[m['groupId']],
          c.savings(m),
          c.principal(m),
          stamp,
        ],
    ];
  }
  if (kind == 'meetings') {
    return [
      [
        'meeting_id',
        'group',
        'business_date',
        'status',
        'present',
        'absent',
        'unmarked',
        'last_refreshed_utc',
      ],
      for (final meeting
          in c.rows('meetings').where((m) => included(m['groupId'])))
        [
          meeting['id'],
          groups[meeting['groupId']],
          meeting['businessDate'],
          meeting['status'],
          for (final state in ['present', 'absent', 'unmarked'])
            c
                .rows('attendance')
                .where(
                  (a) =>
                      a['meetingId'] == meeting['id'] && a['status'] == state,
                )
                .length,
          stamp,
        ],
    ];
  }
  if (kind == 'visits') {
    return [
      [
        'visit_id',
        'member',
        'group',
        'sakhi',
        'business_date',
        'topic',
        'status',
        'next_visit_date',
        'last_refreshed_utc',
      ],
      for (final visit
          in c.rows('sakhiVisits').where((v) => included(v['groupId'])))
        [
          visit['id'],
          members[visit['memberId']]?['displayName'],
          groups[visit['groupId']],
          c
              .rows('actors')
              .where((a) => a['id'] == visit['sakhiId'])
              .firstOrNull?['displayName'],
          visit['businessDate'],
          visit['topic'],
          visit['status'],
          visit['nextVisitDate'],
          stamp,
        ],
    ];
  }
  if (kind == 'support') {
    return [
      [
        'reference',
        'member',
        'group',
        'status',
        'assigned_sakhi',
        'created_at_utc',
        'resolved_at_utc',
        'last_refreshed_utc',
      ],
      for (final request
          in c.rows('supportRequests').where((r) => included(r['groupId'])))
        [
          request['reference'],
          members[request['memberId']]?['displayName'],
          groups[request['groupId']],
          request['status'],
          c
              .rows('actors')
              .where((a) => a['id'] == request['assignedActorId'])
              .firstOrNull?['displayName'],
          request['createdAt'],
          request['resolvedAt'],
          stamp,
        ],
    ];
  }
  if (kind == 'enterprises') {
    final effective = c
        .rows('transactions')
        .where(
          (t) =>
              t['type'] != 'reversal' && t['reversedByTransactionId'] == null,
        );
    int amount(Json e, String type, String opening) =>
        (e[opening] as int? ?? 0) +
        effective
            .where((t) => t['enterpriseId'] == e['id'] && t['type'] == type)
            .fold<int>(0, (n, t) => n + (t['amountPaise'] as int));
    return [
      [
        'enterprise_id',
        'enterprise',
        'member',
        'group',
        'sales_paise',
        'expenses_paise',
        'cash_surplus_paise',
        'last_refreshed_utc',
      ],
      for (final e
          in c
              .rows('enterprises')
              .where((e) => included(members[e['memberId']]?['groupId'])))
        [
          e['id'],
          e['name'],
          members[e['memberId']]?['displayName'],
          groups[members[e['memberId']]?['groupId']],
          amount(e, 'enterprise_sale', 'openingCashSalesPaise'),
          amount(e, 'enterprise_expense', 'openingCashExpensesPaise'),
          amount(e, 'enterprise_sale', 'openingCashSalesPaise') -
              amount(e, 'enterprise_expense', 'openingCashExpensesPaise'),
          stamp,
        ],
    ];
  }
  throw ArgumentError.value(kind, 'kind');
}

class ProgrammeReports extends StatefulWidget {
  const ProgrammeReports({
    super.key,
    required this.controller,
    required this.t,
    this.initialGroup = 'all',
  });
  final AppController controller;
  final String Function(String) t;
  final String initialGroup;
  @override
  State<ProgrammeReports> createState() => _ProgrammeReportsState();
}

class _ProgrammeReportsState extends State<ProgrammeReports> {
  String kind = 'balances';
  int page = 0;
  late String group = widget.initialGroup;
  String t(String k) => widget.t(k);
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (c.actor['role'] != 'manager') return Text(t('forbidden'));
    final rows = snapshotReport(c, kind, group);
    final pageCount = ((rows.length - 1) / 50).ceil();
    if (page >= pageCount) page = pageCount > 0 ? pageCount - 1 : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t('reports'), style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(t('snapshotReportDisclosure')),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 320,
              child: DropdownButtonFormField<String>(
                initialValue: kind,
                isExpanded: true,
                decoration: InputDecoration(labelText: t('reportType')),
                items:
                    ['balances', 'meetings', 'enterprises', 'visits', 'support']
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(t('report_$v')),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() {
                  kind = v!;
                  page = 0;
                }),
              ),
            ),
            SizedBox(
              width: 320,
              child: DropdownButtonFormField<String>(
                initialValue: group,
                isExpanded: true,
                decoration: InputDecoration(labelText: t('group')),
                items: [
                  DropdownMenuItem(value: 'all', child: Text(t('allGroups'))),
                  for (final g in c.rows('groups'))
                    DropdownMenuItem<String>(
                      value: g['id'],
                      child: Text(g['displayName']),
                    ),
                ],
                onChanged: (v) => setState(() {
                  group = v!;
                  page = 0;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () async {
                try {
                  await exportReport('pop-$kind.csv', reportCsv(rows));
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(t('exportFailed'))));
                  }
                }
              },
              icon: const Icon(Icons.download_outlined),
              label: Text(t(kIsWeb ? 'downloadCsv' : 'copyCsv')),
            ),
            OutlinedButton(
              onPressed: () async {
                try {
                  await c.refresh();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(t('refreshFailed'))));
                  }
                }
              },
              child: Text(t('refresh')),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('${t('reportRecords')}: ${rows.length - 1}'),
        const SizedBox(height: 12),
        if (rows.length > 51)
          Wrap(
            spacing: 12,
            children: [
              TextButton(
                onPressed: page > 0 ? () => setState(() => page--) : null,
                child: Text(t('previousPage')),
              ),
              Text('${page + 1} / $pageCount'),
              TextButton(
                onPressed: page + 1 < pageCount
                    ? () => setState(() => page++)
                    : null,
                child: Text(t('nextPage')),
              ),
            ],
          ),
        if (rows.length == 1) EmptyState(t('noRecords')),
        if (rows.length > 1)
          SurfaceCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  for (final h in rows.first)
                    DataColumn(label: Text(t('column_$h'))),
                ],
                rows: [
                  for (final row in rows.skip(1 + page * 50).take(50))
                    DataRow(
                      cells: [
                        for (final cell in row)
                          DataCell(Text(cell?.toString() ?? '—')),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
