import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pop_domain/pop_domain.dart';

import 'src/tokens.dart';
import 'src/components.dart';
export 'src/components.dart';

final appControllerProvider = Provider<AppController>(
  (ref) => throw UnimplementedError(),
);

class PopApp extends StatefulWidget {
  final AppController controller;
  const PopApp({super.key, required this.controller});
  @override
  State<PopApp> createState() => _PopAppState();
}

class _PopAppState extends State<PopApp> with WidgetsBindingObserver {
  String lang = 'en';
  final localeChanges = ValueNotifier<String>('en');
  Map<String, dynamic> words = {};
  bool ready = false;
  late GoRouter router;
  late SemanticsHandle semanticsHandle;
  AppController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    semanticsHandle = SemanticsBinding.instance.ensureSemantics();
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([
        'Noto Sans',
        'Noto Sans Devanagari',
      ], await rootBundle.loadString('packages/pop_ui/assets/fonts/OFL.txt'));
    });
    router = GoRouter(
      refreshListenable: localeChanges,
      routes: [
        GoRoute(path: '/', redirect: (context, state) => '/home'),
        GoRoute(
          path: '/:page',
          builder: (context, state) => shell(state.pathParameters['page']!),
        ),
        GoRoute(
          path: '/member/:id',
          builder: (context, state) =>
              shell('member', id: state.pathParameters['id']),
        ),
      ],
    );
    load();
  }

  Widget shell(String page, {String? id}) => ValueListenableBuilder<String>(
    valueListenable: localeChanges,
    builder: (context, currentLocale, child) => Consumer(
      builder: (context, ref, child) => DemoShell(
        c: ref.watch(appControllerProvider),
        page: page,
        memberId: id,
        lang: currentLocale,
        t: t,
        onLanguage: () => load(currentLocale == 'en' ? 'hi' : 'en'),
      ),
    ),
  );
  Future<void> load([String? next]) async {
    final chosen = next ?? lang;
    final content = jsonDecode(
      await rootBundle.loadString('packages/pop_ui/assets/ui_$chosen.arb'),
    ) as Map<String, dynamic>;
    if (mounted) {
      setState(() {
        lang = chosen;
        words = content;
        ready = true;
      });
      localeChanges.value = chosen;
    }
  }

  String t(String key) => words[key] as String? ?? key;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(c.sync(force: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    router.dispose();
    semanticsHandle.dispose();
    localeChanges.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [appControllerProvider.overrideWithValue(c)],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'PoP 2.0',
      locale: Locale(lang),
      supportedLocales: const [Locale('en'), Locale('hi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: lang == 'hi'
            ? 'packages/pop_ui/NotoSansDevanagari'
            : 'packages/pop_ui/NotoSans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: teal,
          primary: teal,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: canvas,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 17, height: 1.5, color: ink),
          bodyMedium: TextStyle(fontSize: 17, height: 1.5, color: ink),
          titleLarge: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
          titleMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      routerConfig: router,
      builder: (context, child) =>
          ready ? child! : const Center(child: CircularProgressIndicator()),
    ),
  );
}

class DemoShell extends StatefulWidget {
  final AppController c;
  final String page, lang;
  final String? memberId;
  final String Function(String) t;
  final VoidCallback onLanguage;
  const DemoShell({
    super.key,
    required this.c,
    required this.page,
    this.memberId,
    required this.lang,
    required this.t,
    required this.onLanguage,
  });
  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  AppController get c => widget.c;
  String t(String k) => widget.t(k);
  String money(int n) => NumberFormat.currency(
    locale: widget.lang == 'hi' ? 'hi_IN' : 'en_IN',
    symbol: '₹',
    decimalDigits: n % 100 == 0 ? 0 : 2,
  ).format(n / 100);
  String selectedRole = 'kavita',
      search = '',
      helpQuery = '',
      supportStatus = 'all',
      supportOwner = 'all',
      managerGroup = 'all';
  final access = TextEditingController();
  String? lastReference;
  String? simulatedId;
  String? simulatedRequestId;
  String? assignedName;
  List<Json> audit = [];
  bool auditLoaded = false;
  @override
  void initState() {
    super.initState();
    if (c.portal) selectedRole = 'arun';
  }

  @override
  void dispose() {
    access.dispose();
    super.dispose();
  }

  String errorText(String code) => t(
    const {
          'SESSION_EXPIRED': 'sessionExpired',
          'FORBIDDEN': 'forbidden',
          'VERSION_CONFLICT': 'versionConflict',
          'DATASET_MISMATCH': 'datasetMismatch',
          'MEETING_CLOSED': 'meetingClosed',
          'LOAN_BALANCE_EXCEEDED': 'loanBalanceExceeded',
          'INVALID_AMOUNT': 'invalidAmount',
          'POSSIBLE_DUPLICATE': 'possibleDuplicate',
          'SYNC_BEFORE_SUBMIT': 'syncBeforeSubmit',
          'TEMPORARILY_UNAVAILABLE': 'serverUnavailable',
          'PENDING_ACTOR_SWITCH': 'pendingActorSwitch',
          'RECONCILE_FIRST': 'reconcileFirst',
          'INVALID_PAYLOAD': 'invalidFields',
          'OPERATION_ID_REUSED': 'changedRetry',
          'TRANSACTION_ID_REUSED': 'changedRetry',
          'NOT_FOUND': 'recordUnavailable',
          'RATE_LIMITED': 'retryLater',
        }[code] ??
        'needsAttention',
  );
  Future<void> act(Future<void> Function() work) async {
    try {
      await work();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorText(
                e is ApiError
                    ? e.code
                    : e is FormatException
                    ? 'INVALID_AMOUNT'
                    : 'TEMPORARILY_UNAVAILABLE',
              ),
            ),
          ),
        );
      }
    }
  }

  Widget card(Widget child, {Color? color}) =>
      SurfaceCard(color: color, child: child);
  Widget title(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16, top: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
  Widget button(
    String text,
    VoidCallback? onPressed, {
    IconData icon = Icons.arrow_forward_rounded,
  }) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(text),
  );
  Widget empty() => EmptyState(t('noRecords'));
  Widget metric(String label, int amount, {bool currency = true}) =>
      MetricCard(label: label, value: currency ? money(amount) : '$amount');
  Widget chip(String label, {bool warning = false}) =>
      StatusChip(label, warning: warning);
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final manager = c.actor['role'] == 'manager';
      final wide = MediaQuery.sizeOf(context).width >= 1000 && manager;
      final labels = manager
          ? [
              'overview',
              'groups',
              'meetings',
              'support',
              'activity',
              'capabilities',
            ]
          : c.actor['role'] == 'participant'
          ? ['home', 'passbook', 'enterprise', 'help']
          : ['home', 'groups', 'work', 'help'];
      final pages = manager
          ? ['home', 'groups', 'meetings', 'work', 'activity', 'capabilities']
          : c.actor['role'] == 'participant'
          ? ['home', 'groups', 'enterprise', 'help']
          : ['home', 'groups', 'work', 'help'];
      final icons = manager
          ? [
              Icons.dashboard_outlined,
              Icons.groups_outlined,
              Icons.event_outlined,
              Icons.support_agent,
              Icons.history,
              Icons.tune,
            ]
          : [
              Icons.home_outlined,
              Icons.groups_outlined,
              Icons.work_outline,
              Icons.help_outline,
            ];
      final selected = pages.indexOf(widget.page);
      final body = c.busy
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(t('downloading')),
                ],
              ),
            )
          : !c.valid || c.data.isEmpty
          ? login()
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: ListView(
                  children: [
                    if (c.error != null)
                      card(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(errorText(c.error!)),
                            Text(t('staleData')),
                            TextButton(
                              onPressed: () => act(() => c.refresh()),
                              child: Text(t('retry')),
                            ),
                          ],
                        ),
                      ),
                    ...content(),
                  ],
                ),
              ),
            );
      return AppScaffold(
        appBar: AppBar(
          backgroundColor: canvas,
          leading: widget.page == 'member'
              ? IconButton(
                  tooltip: t('back'),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/groups');
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
          title: const Text(
            'PoP 2.0',
            style: TextStyle(fontWeight: FontWeight.w700, color: teal),
          ),
          actions: [
            if (c.valid && manager && !wide)
              PopupMenuButton<String>(
                tooltip: t('more'),
                onSelected: (value) {
                  if (value == 'logout') {
                    act(() => c.logout());
                  } else if (value == 'refresh') {
                    act(() => c.refresh());
                  } else {
                    context.go('/$value');
                  }
                },
                itemBuilder: (ctx) => [
                  for (final entry in {
                    'refresh': 'refresh',
                    'activity': 'activity',
                    'capabilities': 'capabilities',
                    'logout': 'extraLabel1',
                  }.entries)
                    PopupMenuItem(
                      value: entry.key,
                      child: Text(t(entry.value)),
                    ),
                ],
              ),
            LanguageSwitcher(
              onPressed: widget.onLanguage,
              label: widget.lang == 'en' ? 'हिन्दी' : 'English',
            ),
            if (widget.page == 'member')
              IconButton(
                tooltip: t('help'),
                onPressed: () => context.go('/help'),
                icon: const Icon(Icons.help_outline),
              ),
            if (c.valid && manager && wide)
              IconButton(
                tooltip: t('refresh'),
                onPressed: () => act(() => c.refresh()),
                icon: const Icon(Icons.refresh),
              ),
            if (c.valid && manager && wide)
              IconButton(
                tooltip: t('extraLabel1'),
                onPressed: () => act(() => c.logout()),
                icon: const Icon(Icons.logout),
              ),
          ],
        ),
        body: Column(
          children: [
            DemoBanner(t('demoBanner')),
            if (c.valid &&
                !(widget.page == 'home' && c.actor['role'] == 'sakhi'))
              SyncStatusBar(
                label:
                    '${c.syncing
                        ? t('syncing')
                        : c.error != null || !c.online
                        ? t('offline')
                        : t('online')} · ${c.unresolved.length} ${t('waitingToSync')}',
                actionLabel: t('syncCentre'),
                icon: c.syncing
                    ? Icons.sync
                    : c.error != null || !c.online
                    ? Icons.cloud_off
                    : Icons.cloud_done_outlined,
                onPressed: () => context.go('/sync'),
              ),
            Expanded(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 240,
                          child: NavigationRail(
                            extended: true,
                            selectedIndex: selected < 0 ? 0 : selected,
                            onDestinationSelected: (i) =>
                                context.go('/${pages[i]}'),
                            destinations: List.generate(
                              labels.length,
                              (i) => NavigationRailDestination(
                                icon: Icon(icons[i]),
                                label: Text(t(labels[i])),
                              ),
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: body),
                      ],
                    )
                  : body,
            ),
          ],
        ),
        bottomNavigationBar: c.valid && !wide
            ? NavigationBar(
                selectedIndex: selected < 0 || selected > 3 ? 0 : selected,
                onDestinationSelected: (i) => context.go('/${pages[i]}'),
                destinations: List.generate(
                  4,
                  (i) => NavigationDestination(
                    icon: Icon(icons[i]),
                    label: t(labels[i]),
                  ),
                ),
              )
            : null,
      );
    },
  );
  Future<void> signIn() async {
    await c.login(c.portal ? 'arun' : selectedRole, access.text);
    access.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  Widget login() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.spa_outlined, size: 48, color: teal),
          title(t('chooseRole')),
          Text(t('extraLabel2')),
          const SizedBox(height: 24),
          for (final role
              in c.portal ? ['arun'] : ['kavita', 'rani-user', 'arun'])
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                selected: selectedRole == role,
                leading: Icon(
                  selectedRole == role
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: teal,
                ),
                onTap: () => setState(() => selectedRole = role),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  t(
                    role == 'kavita'
                        ? 'sakhiRole'
                        : role == 'arun'
                        ? 'managerRole'
                        : 'participantRole',
                  ),
                ),
                subtitle: Text(
                  role == 'kavita'
                      ? 'Kavita Rao'
                      : role == 'arun'
                      ? 'Arun Sen'
                      : 'Rani Mahto',
                ),
              ),
            ),
          if (c.portal && selectedRole != 'arun')
            TextButton(
              onPressed: () => setState(() => selectedRole = 'arun'),
              child: Text(t('managerRole')),
            ),
          Text(t('firstLoginOnline')),
          const SizedBox(height: 12),
          TextField(
            controller: access,
            obscureText: true,
            decoration: InputDecoration(labelText: t('accessCode')),
            onSubmitted: (_) => act(() => signIn()),
          ),
          const SizedBox(height: 20),
          button(
            c.busy ? t('downloading') : t('signIn'),
            c.busy ? null : () => act(() => signIn()),
          ),
          if (c.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                c.error == 'TEMPORARILY_UNAVAILABLE' && c.data.isEmpty
                    ? t('firstLoginOnline')
                    : errorText(c.error!),
              ),
            ),
          if (c.identity != null && !c.valid) Text(t('sessionExpired')),
          if (c.unresolved.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('${c.unresolved.length} ${t('waitingToSync')}'),
            OutlinedButton(
              onPressed: localReset,
              child: Text(t('resetWarning')),
            ),
          ],
        ],
      ),
    ),
  );
  List<Widget> content() {
    switch (widget.page) {
      case 'groups':
        return groups();
      case 'member':
        return member();
      case 'meetings':
        return meetings();
      case 'sync':
        return sync();
      case 'enterprise':
        return enterprise();
      case 'work':
        return support();
      case 'help':
        return help();
      case 'activity':
        return activity();
      case 'capabilities':
        return capabilities();
      default:
        return c.actor['role'] == 'manager' ? overview() : home();
    }
  }

  List<Widget> home() => [
    title(
      t('greeting').replaceAll(
        '{name}',
        (c.actor['displayName'] ?? '').toString().split(' ').first,
      ),
    ),
    Text(
      DateFormat(
        'dd MMM yyyy',
        widget.lang,
      ).format(DateTime.parse(c.data['businessDate'] ?? '2026-11-05')),
    ),
    const SizedBox(height: 24),
    if (c.actor['role'] == 'participant')
      ...member()
    else ...[
      card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            chip(t('todaysMeeting')),
            const SizedBox(height: 20),
            Text(
              c.rows('groups').firstOrNull?['displayName'] ?? '',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(c.rows('groups').firstOrNull?['villageLabel'] ?? ''),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: button(t('openMeeting'), () => context.go('/meetings')),
            ),
          ],
        ),
        color: const Color(0xffe8f3ef),
      ),
      SurfaceCard(
        padding: EdgeInsets.zero,
        child: SyncStatusBar(
          label:
              '${c.syncing
                  ? t('syncing')
                  : c.error != null || !c.online
                  ? t('offline')
                  : t('online')} · ${c.unresolved.length} ${t('waitingToSync')}',
          actionLabel: t('syncCentre'),
          icon: c.syncing
              ? Icons.sync
              : c.error != null || !c.online
              ? Icons.cloud_off
              : Icons.cloud_done_outlined,
          onPressed: () => context.go('/sync'),
        ),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => context.go('/work'),
              child: metric(
                t('pendingRequests'),
                c
                    .rows('supportRequests')
                    .where((r) => r['status'] != 'resolved')
                    .length,
                currency: false,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => context.go('/groups'),
              child: metric(
                t('recentActivity'),
                c.rows('transactions').length,
                currency: false,
              ),
            ),
          ),
        ],
      ),
    ],
  ];
  List<Widget> overview() {
    final members = c
        .rows('members')
        .where((m) => managerGroup == 'all' || m['groupId'] == managerGroup)
        .toList();
    final metrics = [
      metric(t('memberCount'), members.length, currency: false),
      metric(
        t('confirmedSavings'),
        members.fold<int>(0, (n, m) => n + c.savings(m)),
      ),
      metric(
        t('loanPrincipal'),
        members.fold<int>(0, (n, m) => n + c.principal(m)),
      ),
      metric(
        t('openRequests'),
        c
            .rows('supportRequests')
            .where(
              (r) =>
                  r['status'] != 'resolved' &&
                  (managerGroup == 'all' || r['groupId'] == managerGroup),
            )
            .length,
        currency: false,
      ),
    ];
    final groupCard = card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('groups'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          for (final group
              in c
                  .rows('groups')
                  .where(
                    (g) => managerGroup == 'all' || g['id'] == managerGroup,
                  ))
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => context.go('/groups'),
              title: Text(group['displayName']),
              subtitle: Text(
                '${members.where((m) => m['groupId'] == group['id']).length} ${t('memberCount')} · ${t('lastAccepted')}: ${displayTime(c.groupLastAcceptedAt(group['id']))}',
              ),
              trailing: Text(
                money(
                  members
                      .where((m) => m['groupId'] == group['id'])
                      .fold<int>(0, (n, m) => n + c.savings(m)),
                ),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
    final supportCard = card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('pendingRequests'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          for (final r
              in c
                  .rows('supportRequests')
                  .where(
                    (r) =>
                        r['status'] != 'resolved' &&
                        (managerGroup == 'all' || r['groupId'] == managerGroup),
                  )
                  .take(3))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(r['reference']),
              subtitle: Text(r['description']),
              onTap: () => context.go('/work'),
            ),
          TextButton(
            onPressed: () => context.go('/work'),
            child: Text(t('support')),
          ),
        ],
      ),
    );
    return [
      title(t('overview')),
      Text(c.actor['displayName'] ?? ''),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        isExpanded: true,
        itemHeight: null,
        initialValue: managerGroup,
        decoration: InputDecoration(labelText: t('group')),
        items: [
          DropdownMenuItem(value: 'all', child: Text(t('allGroups'))),
          for (final group in c.rows('groups'))
            DropdownMenuItem(
              value: group['id'],
              child: Text(group['displayName']),
            ),
        ],
        onChanged: (value) => setState(() => managerGroup = value!),
      ),
      const SizedBox(height: 20),
      LayoutBuilder(
        builder: (context, box) {
          final columns = box.maxWidth > 850
              ? 4
              : box.maxWidth > 500
              ? 2
              : 1;
          return Wrap(
            spacing: 16,
            children: [
              for (var i = 0; i < metrics.length; i++)
                SizedBox(
                  width: (box.maxWidth - 16 * (columns - 1)) / columns,
                  child: InkWell(
                    onTap: () => context.go(i == 3 ? '/work' : '/groups'),
                    child: metrics[i],
                  ),
                ),
            ],
          );
        },
      ),
      Text(
        '${t('lastRefreshed')}: ${displayTime(c.lastContact)}',
        style: const TextStyle(fontSize: 14, color: muted),
      ),
      const SizedBox(height: 24),
      LayoutBuilder(
        builder: (context, box) => box.maxWidth > 850
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: groupCard),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: supportCard),
                ],
              )
            : Column(children: [groupCard, supportCard]),
      ),
      title(t('recentActivity')),
      if (c.rows('transactions').isEmpty) empty(),
      for (final tx in c.rows('transactions').reversed.take(5))
        transactionRow(tx),
      button(t('whatsappSimulation'), () => simulation()),
    ];
  }

  String displayTime(String? value) {
    if (value == null) return '—';
    final date = DateTime.parse(value)
        .toUtc()
        .add(const Duration(hours: 5, minutes: 30));
    return '${DateFormat.yMMMd(widget.lang).add_Hm().format(date)} IST';
  }

  List<Widget> groups({bool includeTitle = true}) => [
    if (includeTitle) title(t('groups')),
    if (c.rows('groups').isEmpty) empty(),
    TextField(
      decoration: InputDecoration(
        labelText: t('extraLabel4'),
        prefixIcon: const Icon(Icons.search),
      ),
      onChanged: (v) => setState(() => search = v),
    ),
    const SizedBox(height: 20),
    for (final group
        in c
            .rows('groups')
            .where(
              (g) =>
                  c.actor['role'] != 'manager' ||
                  managerGroup == 'all' ||
                  g['id'] == managerGroup,
            ))
      card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group['displayName'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              group['villageLabel'],
              style: const TextStyle(fontSize: 14, color: muted),
            ),
            const Divider(height: 32),
            for (final m
                in c
                    .rows('members')
                    .where(
                      (m) =>
                          m['groupId'] == group['id'] &&
                          m['displayName'].toString().toLowerCase().contains(
                            search.toLowerCase(),
                          ),
                    ))
              ListTile(
                contentPadding: EdgeInsets.zero,
                minVerticalPadding: 12,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xffe8f3ef),
                  child: Text(m['displayName'].toString().substring(0, 1)),
                ),
                title: Text(m['displayName']),
                subtitle: Text(
                  '${t('confirmedSavings')} ${money(c.savings(m))}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/member/${m['id']}'),
              ),
          ],
        ),
      ),
    if (c.actor['role'] == 'sakhi')
      button(t('addMember'), registration, icon: Icons.person_add_alt),
  ];
  Json? currentMember() =>
      c.rows('members').where((m) => m['id'] == widget.memberId).firstOrNull ??
      c
          .rows('members')
          .where((m) => m['id'] == c.actor['memberId'])
          .firstOrNull ??
      c.rows('members').firstOrNull;
  List<Widget> member() {
    final m = currentMember();
    if (m == null) return [empty()];
    final pending = c.pending(m['id'], 'savings_deposit');
    return [
      title(t('passbook')),
      card(
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xffe8f3ef),
              child: Text(m['displayName'].substring(0, 1)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['displayName'],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    c
                        .rows('groups')
                        .firstWhere(
                          (g) => g['id'] == m['groupId'],
                        )['displayName'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      metric(t('confirmedSavings'), c.savings(m)),
      if (pending != 0)
        card(
          chip('${money(pending)} · ${t('waitingToSync')}', warning: true),
          color: const Color(0xfffff4de),
        ),
      metric(t('loanPrincipal'), c.principal(m)),
      if (c.actor['role'] == 'sakhi')
        button(t('recordEntry'), () => entry(m, 'savings_deposit'))
      else if (c.actor['role'] == 'participant')
        button(t('requestHelp'), () => requestHelp(m)),
      const SizedBox(height: 24),
      title(t('recentActivity')),
      for (final tx
          in c
              .rows('transactions')
              .where((t) => t['memberId'] == m['id'])
              .toList()
              .reversed)
        transactionRow(tx),
      if (c.rows('transactions').where((t) => t['memberId'] == m['id']).isEmpty)
        empty(),
      for (final o in c.queue.where(
        (o) =>
            o['kind'] == 'transaction.post' &&
            o['payload']['memberId'] == m['id'] &&
            o['state'] != 'acknowledged' &&
            o['state'] != 'discarded',
      ))
        card(
          Text(
            '${money(o['payload']['amountPaise'])} · ${o['error'] == null ? t('savedOnPhone') : errorText(o['error'])}',
          ),
        ),
    ];
  }

  String typeLabel(String type) => t(
    {
          'savings_deposit': 'savingsContribution',
          'loan_principal_repayment': 'principalRepayment',
          'enterprise_sale': 'cashSales',
          'enterprise_expense': 'cashExpenses',
          'reversal': 'reversed',
        }[type] ??
        'type',
  );
  Widget transactionRow(Json tx) => TransactionRow(
    title: typeLabel(tx['type']),
    amount: money(tx['amountPaise']),
    date: tx['businessDate'],
    status: t(tx['reversedByTransactionId'] != null ? 'reversed' : 'confirmed'),
    correction:
        c.actor['role'] == 'manager' &&
            tx['type'] != 'reversal' &&
            tx['reversedByTransactionId'] == null
        ? TextButton(
            onPressed: () => reverse(tx),
            child: Text(t('reverseEntry')),
          )
        : null,
  );
  List<Widget> meetings() => [
    title(t('meetings')),
    if (c.rows('meetings').isEmpty) empty(),
    for (final meeting in c.rows('meetings'))
      card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c
                  .rows('groups')
                  .firstWhere(
                    (g) => g['id'] == meeting['groupId'],
                  )['displayName'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(meeting['businessDate']),
            chip(
              t(
                meeting['status'] == 'open' ? 'openStatus' : 'meetingSubmitted',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t('attendance'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final m
                in c
                    .rows('members')
                    .where((m) => m['groupId'] == meeting['groupId']))
              meetingMember(m, meeting),
            const Divider(),
            Text(
              '${t('meetingCashReceived')}: ${money(c.total(c.effective.where((t) => t['meetingId'] == meeting['id']).toList(), 'amountPaise'))}',
            ),
            const SizedBox(height: 16),
            if (meeting['status'] == 'open')
              button(t('submitMeeting'), () => submit(meeting)),
          ],
        ),
      ),
  ];
  Widget meetingMember(Json m, Json meeting) {
    final a = c
        .rows('attendance')
        .where(
          (a) => a['meetingId'] == meeting['id'] && a['memberId'] == m['id'],
        )
        .firstOrNull;
    final local = c.unresolved
        .where(
          (o) =>
              o['kind'] == 'meeting.attendance_set' &&
              o['payload']['memberId'] == m['id'] &&
              o['payload']['meetingId'] == meeting['id'],
        )
        .lastOrNull;
    final status = local?['payload']['status'] ?? a?['status'] ?? 'unmarked';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m['displayName'],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (c.actor['role'] == 'sakhi' && meeting['status'] == 'open') ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              itemHeight: null,
              initialValue: status,
              decoration: InputDecoration(labelText: t('attendance')),
              items: ['unmarked', 'present', 'absent']
                  .map((v) => DropdownMenuItem(value: v, child: Text(t(v))))
                  .toList(),
              onChanged: (value) => act(
                () => c.enqueue('meeting.attendance_set', {
                  'attendanceId': a?['id'] ?? const Uuid().v4(),
                  'meetingId': meeting['id'],
                  'memberId': m['id'],
                  'status': value,
                  'expectedVersion': a?['version'] ?? 0,
                }),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      entry(m, 'savings_deposit', meeting: meeting),
                  child: Text(t('savingsContribution')),
                ),
                if (c.rows('loans').any((l) => l['memberId'] == m['id']))
                  OutlinedButton(
                    onPressed: () =>
                        entry(m, 'loan_principal_repayment', meeting: meeting),
                    child: Text(t('principalRepayment')),
                  ),
              ],
            ),
          ] else
            Text(t(status)),
        ],
      ),
    );
  }

  Future<void> submit(Json meeting) async {
    await act(() async {
      if (c.unresolved.isNotEmpty) {
        throw ApiError('SYNC_BEFORE_SUBMIT', 409, {});
      }
      await c.refresh();
      final latest = c
          .rows('meetings')
          .firstWhere((m) => m['id'] == meeting['id']);
      final yes = await confirm(
        t('submitMeeting'),
        '${t('meetingCashReceived')}: ${money(c.total(c.effective.where((t) => t['meetingId'] == meeting['id']).toList(), 'amountPaise'))}\n${t('attendance')}: ${c.rows('attendance').where((a) => a['meetingId'] == meeting['id'] && a['status'] == 'present').length}',
      );
      if (yes) {
        await c.onlineMutation('meeting.submit', {
          'meetingId': latest['id'],
          'expectedVersion': latest['version'],
        });
      }
    });
  }

  Future<bool> confirm(String title, String text, {String? action}) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => ReviewSheet(
          title: title,
          summary: text,
          confirmLabel: action ?? t('save'),
          cancelLabel: t('cancel'),
          onConfirm: () => Navigator.pop(ctx, true),
          onCancel: () => Navigator.pop(ctx, false),
        ),
      ) ??
      false;
  Future<void> entry(
    Json m,
    String type, {
    Json? meeting,
    Json? enterprise,
  }) async {
    final amount = TextEditingController(), note = TextEditingController();
    String? validation;
    bool saving = false;
    final intent = const Uuid().v4(), transaction = const Uuid().v4();
    final route = DialogRoute<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(typeLabel(type)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m['displayName'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  c
                      .rows('groups')
                      .firstWhere(
                        (g) => g['id'] == m['groupId'],
                      )['displayName'],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontSize: 32),
                  decoration: InputDecoration(
                    labelText: t('amount'),
                    prefixText: '₹ ',
                    errorText: validation,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [50, 100, 200]
                      .map(
                        (n) => ActionChip(
                          label: Text('₹$n'),
                          onPressed: () => amount.text = '$n',
                        ),
                      )
                      .toList(),
                ),
                TextField(
                  controller: note,
                  maxLength: 280,
                  decoration: InputDecoration(labelText: t('noteOptional')),
                ),
                if (enterprise != null) Text('${t('category')}: ${t('seeds')}'),
                Text('${t('date')}: 05 Nov 2026'),
              ],
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
                      int paise;
                      try {
                        paise = parsePaise(amount.text);
                      } catch (_) {
                        set(() => validation = t('invalidAmount'));
                        return;
                      }
                      final yes = await confirm(
                        t('review'),
                        '${t('member')}: ${m['displayName']}\n${t('type')}: ${typeLabel(type)}\n${t('amount')}: ${money(paise)}\n${t('date')}: 05 Nov 2026',
                        action: t(
                          type == 'savings_deposit'
                              ? 'saveContribution'
                              : type == 'loan_principal_repayment'
                              ? 'saveRepayment'
                              : type == 'enterprise_expense'
                              ? 'confirmExpense'
                              : 'save',
                        ),
                      );
                      if (!yes || !ctx.mounted) return;
                      set(() => saving = true);
                      try {
                        final meet =
                            meeting ??
                            c
                                .rows('meetings')
                                .where(
                                  (r) =>
                                      r['groupId'] == m['groupId'] &&
                                      r['status'] == 'open',
                                )
                                .firstOrNull;
                        if (enterprise == null && meet == null) {
                          throw ApiError('MEETING_CLOSED', 409, {});
                        }
                        await c.enqueue('transaction.post', {
                          'transactionId': transaction,
                          'memberId': m['id'],
                          'type': type,
                          'amountPaise': paise,
                          'businessDate': '2026-11-05',
                          if (enterprise != null)
                            'enterpriseId': enterprise['id'],
                          if (enterprise != null) 'category': 'seeds',
                          if (enterprise == null) 'meetingId': meet!['id'],
                          if (type == 'loan_principal_repayment')
                            'loanId': c
                                .rows('loans')
                                .firstWhere(
                                  (l) => l['memberId'] == m['id'],
                                )['id'],
                          if (note.text.isNotEmpty) 'note': note.text,
                        }, intentId: intent);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t('savedOnPhone'))),
                          );
                        }
                      } catch (e) {
                        set(() {
                          saving = false;
                          validation = errorText(
                            e is ApiError ? e.code : 'TEMPORARILY_UNAVAILABLE',
                          );
                        });
                      }
                    },
              child: Text(saving ? t('loading') : t('review')),
            ),
          ],
        ),
      ),
    );
    await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
    amount.dispose();
    note.dispose();
  }

  List<Widget> sync() => [
    title(t('syncCentre')),
    if (c.error == 'SESSION_EXPIRED')
      TextButton(onPressed: reauthenticate, child: Text(t('signIn'))),
    Text('${t('lastContact')}: ${displayTime(c.lastContact)}'),
    Text('${t('lastAccepted')}: ${displayTime(c.lastAcceptedAt)}'),
    const SizedBox(height: 16),
    button(t('retry'), () => c.sync(force: true), icon: Icons.sync),
    const SizedBox(height: 20),
    if (c.queue.isEmpty) empty(),
    for (final o in c.queue.reversed)
      card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              o['kind'] == 'transaction.post'
                  ? typeLabel(o['payload']['type'])
                  : t(
                      {
                            'meeting.attendance_set': 'attendance',
                            'member.create': 'addMember',
                            'member.update': 'review',
                            'support.create': 'requestHelp',
                          }[o['kind']] ??
                          'type',
                    ),
            ),
            chip(
              t(
                o['state'] == 'discarded'
                    ? 'discarded'
                    : o['state'] == 'superseded'
                    ? 'superseded'
                    : o['state'] == 'acknowledged'
                    ? 'confirmed'
                    : o['state'] == 'pending' || o['state'] == 'retry_wait'
                    ? 'waitingToSync'
                    : 'needsAttention',
              ),
              warning: o['state'] != 'acknowledged',
            ),
            if (o['payload']['displayName'] != null)
              Text(o['payload']['displayName']),
            if (o['kind'] == 'member.create' &&
                ['conflict', 'rejected'].contains(o['state']))
              TextButton(
                onPressed: () => registration(
                  draft: o['payload'],
                  replaces: o['operationId'],
                ),
                child: Text(t('editDraft')),
              ),
            if (o['payload']['amountPaise'] != null)
              Text(money(o['payload']['amountPaise'])),
            if (o['error'] != null) Text(errorText(o['error'])),
            Text(
              o['operationId'],
              style: const TextStyle(fontSize: 12, color: muted),
            ),
            if (o['details']?['currentRecord'] != null)
              Text(
                '${t('review')}: ${o['details']['currentRecord']['displayName'] ?? t(o['details']['currentRecord']['status'] ?? 'review')}',
              ),
            if (o['state'] == 'conflict' &&
                o['details']?['currentRecord'] != null)
              TextButton(
                onPressed: () => resolveConflict(o),
                child: Text(t('review')),
              ),
            if (o['details']?['candidates'] != null)
              for (final candidate in o['details']['candidates'])
                TextButton(
                  onPressed: () => act(() async {
                    await c.discard(o);
                    if (mounted) context.go('/member/${candidate['id']}');
                  }),
                  child: Text(
                    '${t('useExisting')}: ${candidate['displayName']}',
                  ),
                ),
            if (![
              'acknowledged',
              'discarded',
              'superseded',
            ].contains(o['state']))
              TextButton(
                onPressed: () => act(() => c.discard(o)),
                child: Text(t('extraLabel5')),
              ),
          ],
        ),
      ),
  ];
  Future<void> resolveConflict(Json original) async {
    final current = original['details']['currentRecord'] as Map;
    final payload = original['payload'] as Map;
    String displayValue(String key, dynamic value) {
      if (value == null || value.toString().isEmpty) return '—';
      if (key == 'status') return t(value.toString());
      if (key == 'preferredLanguage') {
        return {
              'en': t('english'),
              'hi': t('hindi'),
              'or': 'Odia',
              'hoc': 'Ho',
              'sat': 'Santhali',
            }[value] ??
            value.toString();
      }
      return value.toString();
    }

    final changes = original['kind'] == 'member.update'
        ? Map<String, dynamic>.from(payload['patch'] as Map)
        : <String, dynamic>{'status': payload['status']};
    final comparison = changes.entries
        .map((entry) {
          final label = t(
            {
                  'displayName': 'name',
                  'preferredLanguage': 'preferredLanguage',
                  'livelihoodCategory': 'livelihood',
                  'contact': 'contactOptional',
                  'status': 'attendance',
                }[entry.key] ??
                'review',
          );
          return '$label\n${t('currentServerValue')}: ${displayValue(entry.key, current[entry.key])}\n${t('yourSavedChange')}: ${displayValue(entry.key, entry.value)}';
        })
        .join('\n\n');
    if (!await confirm(t('versionConflict'), comparison)) {
      return;
    }
    await act(() async {
      await c.discard(original);
      if (original['state'] == 'acknowledged') return;
      final payload = Map<String, dynamic>.from(original['payload']);
      payload['expectedVersion'] = current['version'];
      if (original['kind'] == 'meeting.attendance_set') {
        payload['attendanceId'] = current['id'];
      }
      await c.enqueue(
        original['kind'],
        payload,
        replacesOperationId: original['operationId'],
      );
    });
  }

  List<Widget> enterprise() => [
    title(t('enterprise')),
    if (c.rows('enterprises').isEmpty) empty(),
    for (final e in c.rows('enterprises')) ...[
      title(e['name']),
      Text(t('demoPeriod')),
      const SizedBox(height: 16),
      metric(t('cashSales'), c.enterpriseAmount(e, true)),
      metric(t('cashExpenses'), c.enterpriseAmount(e, false)),
      metric(
        t('cashSurplus'),
        c.enterpriseAmount(e, true) - c.enterpriseAmount(e, false),
      ),
      if (c.actor['role'] == 'sakhi')
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            button(
              t('recordSale'),
              () => entry(
                c.rows('members').firstWhere((m) => m['id'] == e['memberId']),
                'enterprise_sale',
                enterprise: e,
              ),
            ),
            button(
              t('recordExpense'),
              () => entry(
                c.rows('members').firstWhere((m) => m['id'] == e['memberId']),
                'enterprise_expense',
                enterprise: e,
              ),
            ),
          ],
        ),
      for (final o in c.unresolved.where(
        (o) => o['payload']['enterpriseId'] == e['id'],
      ))
        card(
          Text(
            '${typeLabel(o['payload']['type'])}: ${money(o['payload']['amountPaise'])} · ${t('waitingToSync')}',
          ),
        ),
      const SizedBox(height: 20),
      for (final tx
          in c.rows('transactions').where((t) => t['enterpriseId'] == e['id']))
        transactionRow(tx),
    ],
  ];
  Future<String?> input(String label, {bool secret = false}) async {
    final field = TextEditingController();
    final route = DialogRoute<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: field,
          obscureText: secret,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, field.text),
            child: Text(t('save')),
          ),
        ],
      ),
    );
    final result = await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
    field.dispose();
    return result;
  }

  Future<void> reverse(Json tx) async {
    final reason = await input(t('reversalReason'));
    if (reason != null && reason.trim().isNotEmpty) {
      await act(
        () => c.onlineMutation('transaction.reverse', {
          'transactionId': const Uuid().v4(),
          'originalTransactionId': tx['id'],
          'reason': reason.trim(),
        }),
      );
    }
  }

  Future<void> registration({Json? draft, String? replaces}) async {
    final name = TextEditingController(text: draft?['displayName']),
        contact = TextEditingController(text: draft?['contact']);
    String language = draft?['preferredLanguage'] ?? 'hi',
        livelihood = draft?['livelihoodCategory'] ?? 'tailoring';
    bool saving = false;
    final route = DialogRoute<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(t('addMember')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: t('name')),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  itemHeight: null,
                  initialValue: language,
                  decoration: InputDecoration(
                    labelText: t('preferredLanguage'),
                  ),
                  items: ['en', 'hi']
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v == 'en' ? t('english') : t('hindi')),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => language = v!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  itemHeight: null,
                  initialValue: livelihood,
                  decoration: InputDecoration(labelText: t('livelihood')),
                  items: ['tailoring', 'vegetable_sales', 'poultry']
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(
                            v == 'tailoring'
                                ? t('extraLabel6')
                                : v == 'poultry'
                                ? t('extraLabel7')
                                : t('extraLabel8'),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => livelihood = v!,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contact,
                  decoration: InputDecoration(labelText: t('contactOptional')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('cancel')),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (name.text.trim().isEmpty) return;
                      if (!await confirm(t('review'), name.text)) return;
                      set(() => saving = true);
                      await act(
                        () => c.enqueue('member.create', {
                          'memberId': const Uuid().v4(),
                          'groupId': c.rows('groups').first['id'],
                          'displayName': name.text.trim(),
                          'preferredLanguage': language,
                          'livelihoodCategory': livelihood,
                          if (contact.text.isNotEmpty) 'contact': contact.text,
                        }, replacesOperationId: replaces),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: Text(t('review')),
            ),
          ],
        ),
      ),
    );
    await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
    name.dispose();
    contact.dispose();
  }

  List<Widget> support({bool includeTitle = true}) => [
    if (includeTitle) title(t('support')),
    if (c.actor['role'] == 'sakhi' && c.rows('enterprises').isNotEmpty)
      card(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.storefront_outlined),
          title: Text(t('enterprise')),
          subtitle: Text(c.rows('enterprises').first['name']),
          onTap: () => context.go('/enterprise'),
        ),
      ),
    DropdownButtonFormField<String>(
      isExpanded: true,
      itemHeight: null,
      initialValue: supportStatus,
      decoration: InputDecoration(labelText: t('statusFilter')),
      items: ['all', 'open', 'in_progress', 'resolved']
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(
                t(
                  v == 'all'
                      ? 'allStatuses'
                      : v == 'open'
                      ? 'openStatus'
                      : v == 'in_progress'
                      ? 'inProgress'
                      : 'resolved',
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => supportStatus = v!),
    ),
    const SizedBox(height: 16),
    if (c.actor['role'] == 'manager')
      DropdownButtonFormField<String>(
        isExpanded: true,
        itemHeight: null,
        initialValue: supportOwner,
        decoration: InputDecoration(labelText: t('ownerFilter')),
        items: [
          DropdownMenuItem(value: 'all', child: Text(t('allOwners'))),
          for (final a in c.rows('actors').where((a) => a['role'] == 'sakhi'))
            DropdownMenuItem(value: a['id'], child: Text(a['displayName'])),
        ],
        onChanged: (v) => setState(() => supportOwner = v!),
      ),
    const SizedBox(height: 16),
    if (c.rows('supportRequests').isEmpty) empty(),
    for (final r
        in c
            .rows('supportRequests')
            .where(
              (r) =>
                  (supportStatus == 'all' || r['status'] == supportStatus) &&
                  (supportOwner == 'all' ||
                      r['assignedActorId'] == supportOwner),
            ))
      card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r['reference'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(r['description']),
            chip(
              t(
                r['source'] == 'whatsapp_simulation'
                    ? 'simulation'
                    : 'requestHelp',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t(
                r['status'] == 'open'
                    ? 'openStatus'
                    : r['status'] == 'in_progress'
                    ? 'inProgress'
                    : 'resolved',
              ),
            ),
            Text(
              t('assignedTo').replaceAll(
                '{name}',
                c
                        .rows('actors')
                        .where((a) => a['id'] == r['assignedActorId'])
                        .firstOrNull?['displayName'] ??
                    'Smart Sakhi',
              ),
            ),
            if (r['resolutionNote'] != null) Text(r['resolutionNote']),
            TextButton(
              onPressed: () => supportHistory(r),
              child: Text(t('activity')),
            ),
            if (c.actor['role'] == 'manager' && r['status'] != 'resolved')
              TextButton(
                onPressed: () => assignSupport(r),
                child: Text(t('reassign')),
              ),

            if (c.actor['role'] != 'participant' && r['status'] != 'resolved')
              TextButton(
                onPressed: () => act(() async {
                  final status = r['status'] == 'open'
                      ? 'in_progress'
                      : 'resolved';
                  final note = status == 'resolved'
                      ? await input(t('resolutionNote'))
                      : null;
                  if (status == 'resolved' &&
                      (note == null || note.trim().isEmpty)) {
                    return;
                  }
                  await c.onlineMutation('support.update', {
                    'requestId': r['id'],
                    'expectedVersion': r['version'],
                    'status': status,
                    'resolutionNote': ?note,
                  });
                }),
                child: Text(
                  t(r['status'] == 'open' ? 'inProgress' : 'resolved'),
                ),
              ),
          ],
        ),
      ),
  ];
  Future<void> supportHistory(Json request) async {
    await act(() async {
      final detail = await c.request(
        'GET',
        '/v1/support-requests/${request['id']}',
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(request['reference']),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final event in detail['audit'])
                  Text(
                    '${event['action']} · ${displayTime(event['timestamp'])}',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('back')),
            ),
          ],
        ),
      );
    });
  }

  Future<void> assignSupport(Json request) async {
    final owner = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(t('reassign')),
        children: [
          for (final a in c.rows('actors').where((a) => a['role'] == 'sakhi'))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, a['id']),
              child: Text(a['displayName']),
            ),
        ],
      ),
    );
    if (owner != null) {
      await act(
        () => c.onlineMutation('support.update', {
          'requestId': request['id'],
          'expectedVersion': request['version'],
          'assignedActorId': owner,
        }),
      );
    }
  }

  Future<void> requestHelp(Json m) async {
    final description = await input(t('requestDescription'));
    if (description != null && description.trim().isNotEmpty) {
      await act(
        () => c.enqueue('support.create', {
          'requestId': const Uuid().v4(),
          'memberId': m['id'],
          'category': 'app_help',
          'description': description.trim(),
        }),
      );
    }
  }

  List<Widget> help() => [
    title(t('demoHelp')),
    TextField(
      decoration: InputDecoration(
        labelText: t('searchHelp'),
        prefixIcon: const Icon(Icons.search),
      ),
      onChanged: (v) => setState(() => helpQuery = v),
    ),
    const SizedBox(height: 16),
    chip(t('draftContent'), warning: true),
    const SizedBox(height: 16),
    FutureBuilder<String>(
      future: rootBundle.loadString(
        'packages/pop_ui/assets/content_cards.json',
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Text(t('loading'));
        final cards = (jsonDecode(snapshot.data!)['cards'] as List)
            .where(
              (card) =>
                  helpQuery.trim().isEmpty ||
                  jsonEncode(card['locales'][widget.lang])
                      .toLowerCase()
                      .contains(helpQuery.toLowerCase()) ||
                  (card['keywords'] as List).any(
                    (k) => k.toString().toLowerCase().contains(
                      helpQuery.toLowerCase(),
                    ),
                  ),
            )
            .toList();
        return Column(
          children: [
            if (cards.isEmpty) card(Text(t('unsupportedHelp'))),
            for (final cardData in cards)
              card(
                ExpansionTile(
                  title: Text(cardData['locales'][widget.lang]['title']),
                  children: [
                    for (final step
                        in cardData['locales'][widget.lang]['steps'])
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(step),
                      ),
                    Text(t('demoInstructions')),
                    Text(
                      t('audioUnavailable'),
                      style: const TextStyle(fontSize: 14, color: muted),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
    button(t('requestHelp'), () => requestHelp(currentMember()!)),
    TextButton(
      onPressed: () => context.go('/enterprise'),
      child: Text(t('enterprise')),
    ),
    TextButton(
      onPressed: () => context.go('/capabilities'),
      child: Text(t('capabilities')),
    ),
  ];
  String auditSubject(Json event) {
    final records = c.rows(event['entityType']);
    final record = records
        .where((r) => r['id'] == event['entityId'])
        .firstOrNull;
    if (record == null) return event['entityId'];
    return record['displayName'] ??
        record['reference'] ??
        c
            .rows('members')
            .where((m) => m['id'] == record['memberId'])
            .firstOrNull?['displayName'] ??
        event['entityId'];
  }

  List<Widget> activity() {
    if (!auditLoaded) {
      auditLoaded = true;
      unawaited(
        act(() async {
          final r = await c.request('GET', '/v1/audit-events');
          if (mounted) {
            setState(
              () => audit = (r['events'] as List)
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList(),
            );
          }
        }),
      );
    }
    return [
      title(t('activity')),
      if (audit.isEmpty) empty(),
      for (final a in audit)
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a['action']),
              Text(
                '${t('actorLabel')}: ${c.rows('actors').where((actor) => actor['id'] == a['actorId']).firstOrNull?['displayName'] ?? a['actorId']}',
              ),
              Text('${t('subjectLabel')}: ${auditSubject(a)}'),
              if (a['clientCreatedAt'] != null)
                Text(
                  '${t('capturedAt')}: ${displayTime(a['clientCreatedAt'])}',
                ),
              Text('${t('receivedAt')}: ${displayTime(a['timestamp'])}'),
              if (a['entityType'] == 'transactions' &&
                  c
                      .rows('transactions')
                      .any(
                        (tx) =>
                            tx['id'] == a['entityId'] &&
                            tx['type'] != 'reversal' &&
                            tx['reversedByTransactionId'] == null,
                      ))
                TextButton(
                  onPressed: () => reverse(
                    c
                        .rows('transactions')
                        .firstWhere((tx) => tx['id'] == a['entityId']),
                  ),
                  child: Text(t('reverseEntry')),
                ),
              Text(a['operationId'], style: const TextStyle(fontSize: 12)),
              if (a['reason'] != null) Text(a['reason']),
            ],
          ),
        ),
    ];
  }

  List<Widget> capabilities() => [
    title(t('capabilities')),
    TextButton(
      onPressed: () => showLicensePage(
        context: context,
        applicationName: 'PoP 2.0',
        applicationVersion: '1.0.0 proposal demo',
      ),
      child: Text(t('openSourceNotices')),
    ),
    if (c.allowFaults && c.data['demoFaultsEnabled'] == true)
      DropdownButtonFormField<String>(
        isExpanded: true,
        itemHeight: null,
        initialValue: c.nextFault ?? 'none',
        decoration: InputDecoration(labelText: t('nextFault')),
        items: ['none', 'drop_after_commit', 'temporary_failure']
            .map(
              (v) => DropdownMenuItem(
                value: v,
                child: Text(
                  t(
                    v == 'none'
                        ? 'noFault'
                        : v == 'drop_after_commit'
                        ? 'dropAfterCommit'
                        : 'temporaryFailure',
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => c.nextFault = v == 'none' ? null : v),
      ),
    card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${t('datasetRevision')}: ${c.identity?['datasetId'] ?? '—'}'),
          Text(
            '${t('serviceAvailability')}: ${t(c.error == null ? 'online' : 'offline')}',
          ),
          Text('${t('date')}: 05 Nov 2026'),
        ],
      ),
    ),
    TextButton(
      onPressed: () => act(() => c.logout()),
      child: Text(t('extraLabel1')),
    ),
    OutlinedButton(onPressed: localReset, child: Text(t('resetWarning'))),
    card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('extraLabel9')),
          Text('${t('planned')}: Odia · Ho · Santhali'),
          Text(t('draftContent')),
          Text(t('audioUnavailable')),
          Text('${t('simulation')}: WhatsApp'),
          Text('${t('unavailable')}: Live AI'),
          Text(t('extraLabel10')),
        ],
      ),
    ),
    if (c.actor['role'] == 'manager')
      button(t('whatsappSimulation'), simulation),
    const SizedBox(height: 20),
    if (c.actor['role'] == 'manager')
      OutlinedButton(onPressed: reset, child: Text(t('resetDemo'))),
  ];
  Future<void> reauthenticate() async {
    final code = await input(t('accessCode'), secret: true);
    if (code != null) await act(() => c.login(c.actor['code'], code));
  }

  Future<void> localReset() async {
    final text = await input(
      '${t('confirmReset')}\n${c.unresolved.length} ${t('waitingToSync')}\n${t('resetWarning')}',
    );
    if (text == 'RESET DEMO') await act(() => c.resetLocal());
  }

  Future<void> simulation() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(t('whatsappSimulation')),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  chip(t('simulation'), warning: true),
                  const SizedBox(height: 20),
                  Text('Rani Mahto · ${t('fictionalContact')}'),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: card(
                      Text(t('expenseHelp')),
                      color: const Color(0xffe8f3ef),
                    ),
                  ),
                  if (c
                      .rows('supportRequests')
                      .any(
                        (r) =>
                            r['id'] == simulatedRequestId &&
                            r['status'] == 'resolved',
                      ))
                    card(
                      Text(
                        '${t('resolved')}: ${c.rows('supportRequests').firstWhere((r) => r['id'] == simulatedRequestId)['resolutionNote']}',
                      ),
                    ),
                  if (lastReference != null)
                    card(
                      Text(
                        '${t('requestRecorded').replaceAll('{reference}', lastReference!)}\n${t('assignedTo').replaceAll('{name}', assignedName ?? t('sakhiRole'))}',
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => set(() {
                simulatedId = null;
                lastReference = null;
                simulatedRequestId = null;
                assignedName = null;
              }),
              child: Text(t('newMessage')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('back')),
            ),
            FilledButton(
              onPressed: () => act(() async {
                simulatedId ??= const Uuid().v4();
                final r = await c.request('POST', '/v1/demo/whatsapp-events', {
                  'simulatedMessageId': simulatedId,
                  'demoContactCode': 'demo-contact-rani',
                  'topicCode': 'expense_help',
                });
                set(() {
                  lastReference = r['request']['reference'];
                  simulatedRequestId = r['request']['id'];
                  assignedName = c
                      .rows('actors')
                      .where((a) => a['id'] == r['assignedActorId'])
                      .firstOrNull?['displayName'];
                });
                await c.refresh();
                if (ctx.mounted) set(() {});
              }),
              child: Text(
                lastReference == null ? t('requestHelp') : t('retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> reset() async {
    final confirmation = await input(
      '${t('confirmReset')}\n${c.unresolved.length} ${t('waitingToSync')}',
    );
    if (confirmation != 'RESET DEMO') return;
    final code = await input(t('accessCode'), secret: true);
    if (code == null) return;
    await act(() async {
      await c.request('POST', '/v1/demo/reset', {
        'accessCode': code,
        'confirmation': confirmation,
      });
      await c.logout();
    });
  }
}

class SecureStartupFailure extends StatefulWidget {
  final VoidCallback onRetry;
  const SecureStartupFailure({super.key, required this.onRetry});
  @override
  State<SecureStartupFailure> createState() => _SecureStartupFailureState();
}

class _SecureStartupFailureState extends State<SecureStartupFailure> {
  String lang = 'en';
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: teal),
      fontFamily: 'packages/pop_ui/NotoSansDevanagari',
    ),
    home: Scaffold(
      body: SafeArea(
        child: FutureBuilder<String>(
          future: rootBundle.loadString('packages/pop_ui/assets/ui_$lang.arb'),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final words = jsonDecode(snapshot.data!) as Map<String, dynamic>;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PoP 2.0',
                        style: TextStyle(fontSize: 26, color: teal),
                      ),
                      DemoBanner(words['demoBanner']),
                      const SizedBox(height: 24),
                      Text(words['secureStorageUnavailable']),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: widget.onRetry,
                        child: Text(words['retry']),
                      ),
                      LanguageSwitcher(
                        label: lang == 'en' ? 'हिन्दी' : 'English',
                        onPressed: () =>
                            setState(() => lang = lang == 'en' ? 'hi' : 'en'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
