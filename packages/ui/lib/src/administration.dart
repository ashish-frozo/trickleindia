import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pop_domain/pop_domain.dart';

import 'components.dart';

class AdministrationPanel extends StatefulWidget {
  const AdministrationPanel({
    super.key,
    required this.controller,
    required this.t,
  });
  final AppController controller;
  final String Function(String) t;
  @override
  State<AdministrationPanel> createState() => _AdministrationPanelState();
}

class _AdministrationPanelState extends State<AdministrationPanel> {
  AppController get c => widget.controller;
  String t(String key) => widget.t(key);
  List<Json> staff = [];
  bool loading = true, importing = false;
  String? error;
  final source = TextEditingController();
  Json? preview, reviewedPayload, frozenCommit;
  String? committedOperation, committedHash;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    source.dispose();
    super.dispose();
  }

  String failure(Object e) =>
      '${t('administrationFailed')} ${e is ApiError ? e.code : ''}';
  Future<void> load() async {
    if (c.actor['role'] != 'manager') {
      if (mounted) setState(() => loading = false);
      return;
    }
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final result = await c.request('GET', '/v1/staff');
      if (mounted) {
        setState(
          () => staff = (result['staff'] as List)
              .map((r) => Map<String, dynamic>.from(r))
              .toList(),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = failure(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit([Json? row]) async {
    final actor = row?['actor'] as Map?;
    final name = TextEditingController(text: actor?['displayName']);
    final issuer = TextEditingController(text: row?['issuer']);
    final subject = TextEditingController(text: row?['subject']);
    String role = actor?['role'] ?? 'sakhi';
    String? memberId = actor?['memberId'];
    bool enabled = actor?['enabled'] != false, saving = false;
    final groups = Set<String>.from(row?['groupIds'] ?? []);
    final operationId = const Uuid().v4(),
        actorId = actor?['id'] ?? const Uuid().v4();
    Json? frozen;
    String? formError;
    if (issuer.text.isEmpty) {
      try {
        final config = await c.request('GET', '/v1/auth/config');
        issuer.text = config['issuer'] ?? '';
      } catch (_) {}
    }
    if (!mounted) {
      name.dispose();
      issuer.dispose();
      subject.dispose();
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(t(actor == null ? 'addIdentity' : 'editIdentity')),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t('identityDisclosure')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: name,
                    enabled: !saving && frozen == null,
                    decoration: InputDecoration(labelText: t('name')),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: InputDecoration(labelText: t('role')),
                    items: ['manager', 'sakhi', 'participant']
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(t('identityRole_$r')),
                          ),
                        )
                        .toList(),
                    onChanged: saving || frozen != null
                        ? null
                        : (v) => update(() => role = v!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: issuer,
                    enabled: !saving && frozen == null,
                    decoration: InputDecoration(labelText: t('identityIssuer')),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: subject,
                    enabled: !saving && frozen == null,
                    decoration: InputDecoration(
                      labelText: t('identitySubject'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t('identityEnabled')),
                    value: enabled,
                    onChanged: saving || frozen != null
                        ? null
                        : (v) => update(() => enabled = v),
                  ),
                  if (role == 'participant')
                    DropdownButtonFormField<String>(
                      initialValue: memberId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: t('member')),
                      items: c
                          .rows('members')
                          .map(
                            (m) => DropdownMenuItem<String>(
                              value: m['id'],
                              child: Text(m['displayName']),
                            ),
                          )
                          .toList(),
                      onChanged: saving || frozen != null
                          ? null
                          : (v) => update(() => memberId = v),
                    ),
                  if (role == 'sakhi') ...[
                    Text(
                      t('assignedGroups'),
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    for (final group in c.rows('groups'))
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(group['displayName']),
                        value: groups.contains(group['id']),
                        onChanged: saving || frozen != null
                            ? null
                            : (v) => update(() {
                                if (v == true) {
                                  groups.add(group['id']);
                                } else {
                                  groups.remove(group['id']);
                                }
                              }),
                      ),
                  ],
                  if (formError != null)
                    Text(
                      formError!,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text(t('cancel')),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (name.text.trim().isEmpty ||
                          issuer.text.trim().isEmpty ||
                          subject.text.trim().isEmpty ||
                          (role == 'participant' && memberId == null)) {
                        update(() => formError = t('requiredIdentity'));
                        return;
                      }
                      update(() {
                        saving = true;
                        formError = null;
                      });
                      frozen ??= {
                        'datasetId': c.identity!['datasetId'],
                        'operationId': operationId,
                        'actorId': actorId,
                        'expectedVersion': actor?['version'] ?? 0,
                        'displayName': name.text.trim(),
                        'role': role,
                        'enabled': enabled,
                        'groupIds': role == 'sakhi' ? groups.toList() : [],
                        'mapping': {
                          'issuer': issuer.text.trim(),
                          'subject': subject.text.trim(),
                        },
                        if (role == 'participant') 'memberId': memberId,
                        'revokeSessions': true,
                      };
                      try {
                        await c.request('POST', '/v1/staff', frozen);
                        if (ctx.mounted) Navigator.pop(ctx);
                        await c.refresh();
                        await load();
                      } catch (e) {
                        if (ctx.mounted) {
                          update(() {
                            saving = false;
                            formError = failure(e);
                          });
                        }
                      }
                    },
              child: Text(t('saveIdentity')),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    issuer.dispose();
    subject.dispose();
  }

  Future<void> dryRun() async {
    if (importing) return;
    setState(() {
      importing = true;
      error = null;
      preview = null;
      reviewedPayload = null;
      frozenCommit = null;
    });
    try {
      final payload = jsonDecode(source.text) as Json;
      final result = await c.request('POST', '/v1/imports/dry-run', {
        'datasetId': c.identity!['datasetId'],
        'payload': payload,
      });
      if (mounted) {
        setState(() {
          preview = Map<String, dynamic>.from(result);
          if (result['valid'] == true) reviewedPayload = payload;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = failure(e));
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  Future<void> commitImport() async {
    if (importing || reviewedPayload == null || preview?['valid'] != true) {
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('commitImport')),
        content: Text(t('importConfirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('confirm')),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() {
      importing = true;
      error = null;
    });
    frozenCommit ??= {
      'datasetId': c.identity!['datasetId'],
      'operationId': const Uuid().v4(),
      'payload': reviewedPayload,
      'reviewedHash': preview!['reviewedHash'],
    };
    try {
      await c.request('POST', '/v1/imports/commit', frozenCommit);
      if (mounted) {
        setState(() {
          committedOperation = frozenCommit!['operationId'];
          committedHash = frozenCommit!['reviewedHash'];
          preview = null;
          reviewedPayload = null;
          source.clear();
        });
      }
      await c.refresh();
    } catch (e) {
      if (mounted) setState(() => error = failure(e));
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (c.actor['role'] != 'manager') return Text(t('forbidden'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t('administration'),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(t('identityDisclosure')),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.person_add_outlined),
              label: Text(t('addIdentity')),
            ),
            OutlinedButton(
              onPressed: loading ? null : load,
              child: Text(t('refresh')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (loading) const LinearProgressIndicator(),
        for (final row in staff)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SurfaceCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(row['actor']['displayName']),
                subtitle: Text(
                  '${t('identityRole_${row['actor']['role']}')} · ${t(row['actor']['enabled'] == false ? 'disabledIdentity' : 'identityEnabled')}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => edit(row),
              ),
            ),
          ),
        const SizedBox(height: 24),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t('openingImport'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(t('importDisclosure')),
              const SizedBox(height: 16),
              TextField(
                controller: source,
                enabled: !importing && frozenCommit == null,
                minLines: 5,
                maxLines: 10,
                decoration: InputDecoration(labelText: t('importPayload')),
                onChanged: (_) => setState(() {
                  preview = null;
                  reviewedPayload = null;
                }),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: importing || frozenCommit != null
                        ? null
                        : dryRun,
                    child: Text(t('validateImport')),
                  ),
                  FilledButton(
                    onPressed: importing || reviewedPayload == null
                        ? null
                        : commitImport,
                    child: Text(t('commitImport')),
                  ),
                ],
              ),
              if (preview != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert({
                      'valid': preview!['valid'],
                      'counts': preview!['counts'],
                      'totalsPaise': preview!['totals'],
                      'errors': preview!['errors'],
                    }),
                  ),
                ),
              if (committedOperation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SelectableText(
                    '${t('importCompleted')}\n${t('operation')}: $committedOperation\n${t('reviewHash')}: $committedHash',
                  ),
                ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Semantics(
              liveRegion: true,
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
      ],
    );
  }
}
