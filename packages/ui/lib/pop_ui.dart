/*
Blue/white structural redesign: task-led mobile, top-navigation programme portal,
white passbooks and an explicit savings summary. See docs/design/BLUEPRINT_UI.md.
VengeanceUI-derived primitives retain MIT attribution; domain behaviour is preserved.
*/
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
import 'src/theme.dart';
import 'src/workspace.dart';
import 'src/speech.dart';
import 'src/auth.dart';
import 'src/assistance.dart';
import 'src/administration.dart';
import 'src/programme_reports.dart';
import 'src/vengeance.dart';
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
  SemanticsHandle? semanticsHandle;
  AppController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    captureAuthCallback();
    if (kIsWeb) semanticsHandle = SemanticsBinding.instance.ensureSemantics();
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(
        ['VengeanceUI (Flutter adaptations)'],
        await rootBundle.loadString(
          'packages/pop_ui/assets/licenses/VengeanceUI-MIT.txt',
        ),
      );
    });
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
    final stored = c.formDrafts['_preferences']?['language'];
    final chosen =
        next ?? (['en', 'hi'].contains(stored) ? stored as String : lang);
    if (next != null && c.valid) {
      await c.saveFormDraft('_preferences', {'language': chosen});
    }
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
    semanticsHandle?.dispose();
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
      theme: createPopTheme(language: lang, portal: c.portal),
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
  final speech = InstructionSpeech();
  final access = TextEditingController();
  String? lastReference;
  String? simulatedId;
  String? simulatedRequestId;
  String? assignedName;
  List<Json> audit = [];
  bool auditLoaded = false, auditLoading = false, auditMore = true;
  String? auditError;
  int helpRevision = 0;
  String businessDate(String iso) =>
      DateFormat.yMMMd(widget.lang == 'hi' ? 'hi_IN' : 'en_IN')
          .format(DateTime.parse(iso));
  String actionLabel(String action) =>
      t('action_${action.replaceAll('.', '_')}');
  @override
  void initState() {
    super.initState();
    if (c.portal) selectedRole = 'arun';
    if (const String.fromEnvironment('AUTH_MODE') == 'cognito' &&
        hasAuthCallback()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(signInOrganisation());
      });
    }
  }

  @override
  void didUpdateWidget(covariant DemoShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lang != widget.lang || oldWidget.page != widget.page) {
      unawaited(speech.stop());
    }
  }

  @override
  void dispose() {
    speech.dispose();
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
  String get pageTitle => t(
    {
          'home': c.actor['role'] == 'manager' ? 'overview' : 'home',
          'groups': 'groups',
          'member': 'passbook',
          'meetings': 'meetings',
          'enterprise': 'enterprise',
          'work': c.actor['role'] == 'manager' ? 'support' : 'work',
          'monitoring': 'sakhiMonitoring',
          'help': 'help',
          'activity': 'activity',
          'capabilities': 'capabilities',
          'sync': 'syncCentre',
        }[widget.page] ??
        'home',
  );
  Widget syncIndicator() => SyncStatusBar(
    label:
        '${c.syncing
            ? t('syncing')
            : c.error != null || !c.online
            ? t('offline')
            : t('online')} · ${c.unresolved.length} ${t('waitingToSync')}',
    actionLabel: t('syncCentre'),
    icon: c.syncing
        ? Icons.sync_rounded
        : c.error != null || !c.online
        ? Icons.cloud_off_outlined
        : Icons.cloud_done_outlined,
    onPressed: () => context.go('/sync'),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final manager = c.actor['role'] == 'manager';
      final participant = c.actor['role'] == 'participant';
      final authenticated = c.valid && c.data.isNotEmpty;
      final desktop =
          manager && authenticated && MediaQuery.sizeOf(context).width >= 720;
      final labels = manager
          ? [
              'overview',
              'groups',
              'meetings',
              'support',
              'activity',
              'capabilities',
            ]
          : participant
          ? ['home', 'passbook', 'enterprise', 'help']
          : ['home', 'groups', 'work', 'help'];
      final pages = manager
          ? ['home', 'groups', 'meetings', 'work', 'activity', 'capabilities']
          : participant
          ? ['home', 'member/${c.actor['memberId']}', 'enterprise', 'help']
          : ['home', 'groups', 'work', 'help'];
      final icons = manager
          ? [
              Icons.space_dashboard_outlined,
              Icons.groups_outlined,
              Icons.event_note_outlined,
              Icons.support_agent_outlined,
              Icons.history_rounded,
              Icons.tune_rounded,
            ]
          : participant
          ? [
              Icons.home_outlined,
              Icons.account_balance_wallet_outlined,
              Icons.storefront_outlined,
              Icons.help_outline_rounded,
            ]
          : [
              Icons.home_outlined,
              Icons.groups_outlined,
              Icons.work_outline_rounded,
              Icons.help_outline_rounded,
            ];
      var selected = pages.indexOf(widget.page);
      if (widget.page == 'member') selected = 1;
      if (widget.page == 'enterprise' && !participant) selected = 2;
      if (['administration', 'reports', 'assistant'].contains(widget.page)) {
        selected = pages.indexOf(manager ? 'capabilities' : 'help');
      }
      if (selected < 0) selected = 0;
      final expandedTitle =
          authenticated &&
          widget.page != 'home' &&
          (MediaQuery.textScalerOf(context).scale(1) > 1.4 ||
              MediaQuery.sizeOf(context).width < 380);
      Widget pageBody;
      if (c.busy) {
        pageBody = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 20),
              Text(t('downloading')),
            ],
          ),
        );
      } else if (!authenticated) {
        pageBody = login();
      } else {
        pageBody = Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: ListView(
              padding: EdgeInsets.all(desktop ? 32 : 20),
              children: [
                if (!desktop) ...[
                  if (const String.fromEnvironment('AUTH_MODE') != 'cognito')
                    DemoBanner(t('demoBanner')),
                  if (!(widget.page == 'home' && !participant && !manager))
                    syncIndicator(),
                  const SizedBox(height: 16),
                ],
                if (expandedTitle)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        header: true,
                        child: Text(
                          pageTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ),
                if (c.error != null && c.error != 'TEMPORARILY_UNAVAILABLE')
                  ErrorState(
                    message: errorText(c.error!),
                    retryLabel: t('retry'),
                    onRetry: () => act(() => c.refresh()),
                  ),
                ...content(),
              ],
            ),
          ),
        );
      }
      final language = LanguageSwitcher(
        onPressed: widget.onLanguage,
        label: widget.lang == 'en' ? 'हिन्दी' : 'English',
      );
      if (!authenticated &&
          c.portal &&
          MediaQuery.sizeOf(context).width >= 900) {
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: WelcomePanel(
                    title: t('welcomeHeadline'),
                    description: t('welcomeDescription'),
                    offline: t('welcomeOffline'),
                    sync: t('welcomeSync'),
                    review: t('welcomeReview'),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [language],
                        ),
                      ),
                      if (const String.fromEnvironment('AUTH_MODE') !=
                          'cognito')
                        DemoBanner(t('demoBanner')),
                      Expanded(child: pageBody),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
      if (desktop) {
        return ProgrammeWorkspace(
          pageTitle: pageTitle,
          programmeLabel: t('programmePortal'),
          demoLabel: t('demoBanner'),
          name: c.actor['displayName'] ?? '',
          role: t('managerRole'),
          refreshLabel: t('refresh'),
          signOutLabel: t('extraLabel1'),
          destinations: labels.map(t).toList(),
          icons: icons,
          selected: selected,
          onNavigate: (i) => context.go('/${pages[i]}'),
          refresh: () => act(() => c.refresh()),
          signOut: () => act(() => c.logout()),
          languageControl: language,
          refreshing: c.refreshing,
          body: Column(
            children: [
              syncIndicator(),
              Expanded(child: pageBody),
            ],
          ),
        );
      }
      final memberAction = authenticated && widget.page == 'member' && !manager;
      return AppScaffold(
        appBar: AppBar(
          toolbarHeight: MediaQuery.textScalerOf(context).scale(1) > 1.4
              ? 80
              : 64,
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
                  icon: const Icon(Icons.arrow_back_rounded),
                )
              : null,
          title: expandedTitle
              ? null
              : widget.page == 'home' || !authenticated
              ? const PopWordmark()
              : Text(pageTitle),
          actions: [
            if (authenticated && manager)
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
            language,
            if (widget.page == 'member')
              IconButton(
                tooltip: t('help'),
                onPressed: () => context.go('/help'),
                icon: const Icon(Icons.help_outline_rounded),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: authenticated
            ? pageBody
            : Column(
                children: [
                  if (const String.fromEnvironment('AUTH_MODE') != 'cognito')
                    DemoBanner(t('demoBanner')),
                  Expanded(child: pageBody),
                ],
              ),
        bottomNavigationBar:
            authenticated && MediaQuery.viewInsetsOf(context).bottom == 0
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (memberAction)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: button(
                          t(participant ? 'requestHelp' : 'recordEntry'),
                          () => participant
                              ? requestHelp(currentMember()!)
                              : entry(currentMember()!, 'savings_deposit'),
                          icon: participant
                              ? Icons.support_agent_outlined
                              : Icons.add_rounded,
                        ),
                      ),
                    ),
                  SafeArea(
                    top: false,
                    child: VengeanceNavigation(
                      selected: selected.clamp(0, 3),
                      onSelected: (i) => context.go('/${pages[i]}'),
                      labels: labels.take(4).map(t).toList(),
                      icons: icons.take(4).toList(),
                    ),
                  ),
                ],
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

  Future<void> signInOrganisation() => act(() async {
    final config = await c.request('GET', '/v1/auth/config');
    if (config['mode'] != 'cognito') {
      throw ApiError('TEMPORARILY_UNAVAILABLE', 503, {});
    }
    final token = await organisationSignIn(config);
    if (token != null) await c.login('', '', accessToken: token);
  });
  Widget organisationLogin() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PopWordmark(size: 32),
          const SizedBox(height: 24),
          Text(t('organisationSignIn')),
          const SizedBox(height: 20),
          button(t('signIn'), signInOrganisation),
          if (c.identity != null && !c.valid) Text(t('sessionExpired')),
        ],
      ),
    ),
  );
  Widget login() => const String.fromEnvironment('AUTH_MODE') == 'cognito'
      ? organisationLogin()
      : Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  c.portal ? t('programmePortal') : t('chooseRole'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  t('extraLabel2'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 28),
                for (final role
                    in c.portal ? ['arun'] : ['kavita', 'rani-user', 'arun'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: selectedRole == role
                          ? PopColors.primaryTint
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: selectedRole == role ? teal : PopColors.border,
                          width: selectedRole == role ? 1.5 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        selected: selectedRole == role,
                        onTap: () => setState(() => selectedRole = role),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selectedRole == role
                                ? Colors.white
                                : PopColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            role == 'kavita'
                                ? Icons.badge_outlined
                                : role == 'arun'
                                ? Icons.admin_panel_settings_outlined
                                : Icons.person_outline_rounded,
                            size: 22,
                            color: teal,
                          ),
                        ),
                        title: Text(
                          t(
                            role == 'kavita'
                                ? 'sakhiRole'
                                : role == 'arun'
                                ? 'managerRole'
                                : 'participantRole',
                          ),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          role == 'kavita'
                              ? 'Kavita Rao'
                              : role == 'arun'
                              ? 'Arun Sen'
                              : 'Rani Mahto',
                        ),
                        trailing: Icon(
                          selectedRole == role
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 22,
                          color: selectedRole == role ? teal : muted,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: access,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: t('accessCode'),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 21,
                    ),
                  ),
                  onSubmitted: (_) => act(() => signIn()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: button(
                    c.busy ? t('downloading') : t('signIn'),
                    c.busy ? null : () => act(() => signIn()),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.cloud_download_outlined,
                      size: 18,
                      color: muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t('firstLoginOnline'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                if (c.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      c.error == 'TEMPORARILY_UNAVAILABLE' && c.data.isEmpty
                          ? t('firstLoginOnline')
                          : errorText(c.error!),
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: PopColors.error),
                    ),
                  ),
                if (c.identity != null && !c.valid)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(t('sessionExpired')),
                  ),
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
      case 'reports':
        return reports();
      case 'monitoring':
        return monitoring();
      case 'work':
        return support();
      case 'administration':
        return [AdministrationPanel(controller: c, t: t)];
      case 'assistant':
        return [AssistancePanel(controller: c, language: widget.lang, t: t)];
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

  List<Widget> home() {
    final firstName = (c.actor['displayName'] ?? '')
        .toString()
        .split(' ')
        .first;
    final date = DateFormat(
      'dd MMM yyyy',
      widget.lang,
    ).format(DateTime.parse(c.data['businessDate'] ?? '2026-11-05'));
    if (c.actor['role'] == 'participant') {
      return [
        Text(
          t('greeting').replaceAll('{name}', firstName),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(date, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        ...member(includeTitle: false),
      ];
    }
    final group = c.rows('groups').firstOrNull;
    final members = c
        .rows('members')
        .where((m) => m['groupId'] == group?['id'])
        .toList();
    final requests = c
        .rows('supportRequests')
        .where((r) => r['status'] != 'resolved')
        .length;
    return [
      LayoutBuilder(
        builder: (context, box) {
          final greeting = Text(
            t('greeting').replaceAll('{name}', firstName),
            style: Theme.of(context).textTheme.headlineMedium,
          );
          final dateLabel = Text(
            date,
            style: Theme.of(context).textTheme.bodySmall,
          );
          if (box.maxWidth >= 340 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.2) {
            return Row(
              children: [
                Expanded(child: greeting),
                const SizedBox(width: 12),
                dateLabel,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [greeting, const SizedBox(height: 7), dateLabel],
          );
        },
      ),
      const SizedBox(height: 24),
      if (group != null)
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: PopColors.primaryTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: teal,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('todaysMeeting'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group['displayName'],
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      group['villageLabel'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${members.length} ${t('memberCount')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/meetings'),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(t('openMeeting')),
                ),
              ),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: syncIndicator(),
        ),
      ),
      LayoutBuilder(
        builder: (context, box) {
          final cards = [
            (
              Icons.account_balance_wallet_outlined,
              t('confirmedSavings'),
              money(members.fold<int>(0, (n, m) => n + c.savings(m))),
              '/groups',
            ),
            (
              Icons.support_agent_outlined,
              t('pendingRequests'),
              '$requests',
              '/work',
            ),
          ];
          final columns = MediaQuery.textScalerOf(context).scale(1) > 1.4
              ? 1
              : 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < cards.length; i++)
                SizedBox(
                  width: (box.maxWidth - (columns - 1) * 12) / columns,
                  child: VengeanceSurface(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () => context.go(cards[i].$4),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              cards[i].$1,
                              color: i == 0 ? teal : PopColors.warning,
                              size: 24,
                            ),
                            const SizedBox(height: 18),
                            MoneyAmount(cards[i].$3, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              cards[i].$2,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 22),
      SectionHeading(
        t('groups'),
        trailing: TextButton(
          onPressed: () => context.go('/groups'),
          child: Text(t('viewAllGroups')),
        ),
      ),
      if (group != null)
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            onTap: () => context.go('/groups'),
            leading: const Icon(Icons.groups_outlined),
            title: Text(group['displayName']),
            subtitle: Text(group['villageLabel'] ?? ''),
            trailing: const Icon(Icons.arrow_forward_rounded),
          ),
        ),
    ];
  }

  void openGroup(Json group) {
    setState(() => managerGroup = group['id']);
    context.go('/groups');
  }

  Widget groupFilter() => Semantics(
    container: true,
    child: DropdownButtonFormField<String>(
      isExpanded: true,
      itemHeight: null,
      initialValue: managerGroup,
      decoration: InputDecoration(
        labelText: t('group'),
        prefixIcon: const Icon(Icons.filter_list_rounded, size: 19),
      ),
      items: [
        DropdownMenuItem(value: 'all', child: Text(t('allGroups'))),
        for (final g in c.rows('groups'))
          DropdownMenuItem(value: g['id'], child: Text(g['displayName'])),
      ],
      onChanged: (value) => setState(() => managerGroup = value!),
    ),
  );
  List<Widget> overview() {
    final groups = c
        .rows('groups')
        .where((g) => managerGroup == 'all' || g['id'] == managerGroup)
        .toList();
    final members = c
        .rows('members')
        .where((m) => managerGroup == 'all' || m['groupId'] == managerGroup)
        .toList();
    final requests = c
        .rows('supportRequests')
        .where(
          (r) =>
              r['status'] != 'resolved' &&
              (managerGroup == 'all' || r['groupId'] == managerGroup),
        )
        .toList();
    final records = c
        .rows('transactions')
        .where((tx) => members.any((m) => m['id'] == tx['memberId']))
        .toList()
        .reversed
        .take(3)
        .toList();
    final stats = [
      (t('memberCount'), '${members.length}', Icons.groups_outlined),
      (
        t('confirmedSavings'),
        money(members.fold<int>(0, (n, m) => n + c.savings(m))),
        Icons.account_balance_wallet_outlined,
      ),
      (
        t('loanPrincipal'),
        money(members.fold<int>(0, (n, m) => n + c.principal(m))),
        Icons.account_balance_outlined,
      ),
      (t('openRequests'), '${requests.length}', Icons.support_agent_outlined),
    ];
    final groupPanel = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            '${t('groupsAtGlance')} (${groups.length})',
            trailing: TextButton(
              onPressed: () {
                setState(() => managerGroup = 'all');
                context.go('/groups');
              },
              child: Text(t('viewAllGroups')),
            ),
          ),
          LayoutBuilder(
            builder: (context, box) {
              if (box.maxWidth >= 850 &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.35) {
                Widget heading(String value, double width) =>
                    SizedBox(width: width, child: Text(value, maxLines: 2));
                return SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    showCheckboxColumn: false,
                    columnSpacing: 16,
                    horizontalMargin: 12,
                    columns: [
                      DataColumn(label: heading(t('group'), 210)),
                      DataColumn(
                        label: heading(t('memberCount'), 64),
                        numeric: true,
                      ),
                      DataColumn(
                        label: heading(t('confirmedSavings'), 122),
                        numeric: true,
                      ),
                      DataColumn(
                        label: heading(t('loanPrincipal'), 142),
                        numeric: true,
                      ),
                      DataColumn(label: heading(t('lastAccepted'), 172)),
                    ],
                    rows: [
                      for (final g in groups)
                        DataRow(
                          onSelectChanged: (_) => openGroup(g),
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 210,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: PopColors.primaryTint,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.groups_outlined,
                                        color: teal,
                                        size: 19,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            g['displayName'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            g['villageLabel'] ?? '',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${members.where((m) => m['groupId'] == g['id']).length}',
                              ),
                            ),
                            DataCell(
                              Text(
                                money(
                                  members
                                      .where((m) => m['groupId'] == g['id'])
                                      .fold<int>(0, (n, m) => n + c.savings(m)),
                                ),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            DataCell(
                              Text(
                                money(
                                  members
                                      .where((m) => m['groupId'] == g['id'])
                                      .fold<int>(
                                        0,
                                        (n, m) => n + c.principal(m),
                                      ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                displayTime(c.groupLastAcceptedAt(g['id'])),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (final g in groups)
                    Semantics(
                      container: true,
                      button: true,
                      child: InkWell(
                        onTap: () => openGroup(g),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 2,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.groups_outlined,
                                    color: teal,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      g['displayName'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: teal,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${members.where((m) => m['groupId'] == g['id']).length} ${t('memberCount')} · ${g['villageLabel'] ?? ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 9),
                              Text(
                                '${t('confirmedSavings')}: ${money(members.where((m) => m['groupId'] == g['id']).fold<int>(0, (n, m) => n + c.savings(m)))}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${t('loanPrincipal')}: ${money(members.where((m) => m['groupId'] == g['id']).fold<int>(0, (n, m) => n + c.principal(m)))}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${t('lastAccepted')}: ${displayTime(c.groupLastAcceptedAt(g['id']))}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
    final activityPanel = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            t('recentFinancialActivity'),
            trailing: IconButton(
              tooltip: t('activity'),
              onPressed: () => context.go('/activity'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 21),
            ),
          ),
          if (records.isEmpty) ...[
            empty(),
            Text(
              t('activityEmptyHint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          for (final tx in records) transactionRow(tx),
        ],
      ),
    );
    final supportPanel = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            t('supportPreview'),
            trailing: TextButton(
              onPressed: () {
                setState(() => supportStatus = 'active');
                context.go('/work');
              },
              child: Text(t('viewAllRequests')),
            ),
          ),
          if (requests.isEmpty) EmptyState(t('noFollowupNeeded')),
          for (final r in requests.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: () => context.go('/work'),
                borderRadius: BorderRadius.circular(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r['reference'],
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        StatusChip(
                          t(
                            r['status'] == 'open' ? 'openStatus' : 'inProgress',
                          ),
                          warning: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      r['description'],
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          const Divider(),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: simulation,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: Text(t('whatsappSimulation')),
          ),
        ],
      ),
    );
    return [
      LayoutBuilder(
        builder: (context, box) {
          final heading = Semantics(
            container: true,
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('programmeOverview'),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 7),
                Text(
                  t('programmeOverviewHint'),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: muted),
                ),
              ],
            ),
          );
          if (box.maxWidth > 720 &&
              MediaQuery.textScalerOf(context).scale(1) < 1.4) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: heading),
                const SizedBox(width: 24),
                SizedBox(width: 235, child: groupFilter()),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [heading, const SizedBox(height: 20), groupFilter()],
          );
        },
      ),
      const SizedBox(height: 24),
      LayoutBuilder(
        builder: (context, box) {
          Widget savings = InkWell(
            onTap: () => context.go('/groups'),
            child: VengeanceSurface(
              dark: true,
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          stats[1].$1,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  MoneyAmount(stats[1].$2, size: 46, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    t('programmeOverviewHint'),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: PopColors.forestMuted),
                  ),
                ],
              ),
            ),
          );
          Widget details = VengeanceSurface(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
            child: Column(
              children: [
                for (final i in [0, 2, 3]) ...[
                  if (i != 0) const Divider(),
                  InkWell(
                    onTap: () {
                      if (i == 3) setState(() => supportStatus = 'active');
                      context.go(i == 3 ? '/work' : '/groups');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Icon(stats[i].$3, color: teal, size: 22),
                          const SizedBox(width: 12),
                          Expanded(child: Text(stats[i].$1)),
                          const SizedBox(width: 12),
                          Flexible(
                            child: MoneyAmount(
                              stats[i].$2,
                              size: 24,
                              align: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child:
                box.maxWidth >= 780 &&
                    MediaQuery.textScalerOf(context).scale(1) < 1.4
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: savings),
                      const SizedBox(width: 20),
                      Expanded(flex: 6, child: details),
                    ],
                  )
                : Column(
                    children: [savings, const SizedBox(height: 16), details],
                  ),
          );
        },
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, size: 15, color: muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${t('lastRefreshed')}: ${displayTime(c.lastContact)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      LayoutBuilder(
        builder: (context, box) =>
            box.maxWidth >= 1000 &&
                MediaQuery.textScalerOf(context).scale(1) < 1.4
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: groupPanel),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: supportPanel),
                ],
              )
            : Column(children: [groupPanel, supportPanel]),
      ),
      activityPanel,
    ];
  }

  String displayTime(String? value) {
    if (value == null) return '—';
    final date = DateTime.parse(value)
        .toUtc()
        .add(const Duration(hours: 5, minutes: 30));
    return '${DateFormat.yMMMd(widget.lang).add_Hm().format(date)} IST';
  }

  List<Widget> groups({bool includeTitle = true}) {
    final visible = c
        .rows('groups')
        .where(
          (g) =>
              c.actor['role'] != 'manager' ||
              managerGroup == 'all' ||
              g['id'] == managerGroup,
        )
        .toList();
    final members = c
        .rows('members')
        .where(
          (m) =>
              visible.any((g) => g['id'] == m['groupId']) &&
              m['displayName'].toString().toLowerCase().contains(
                search.toLowerCase(),
              ),
        )
        .toList();
    Widget searchField() => TextField(
      decoration: InputDecoration(
        labelText: t('extraLabel4'),
        prefixIcon: const Icon(Icons.search_rounded, size: 22),
      ),
      onChanged: (value) => setState(() => search = value),
    );
    return [
      if (includeTitle && c.portal) ...[
        Text(t('groups'), style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 7),
        Text(
          t('memberDirectoryHint'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: 24),
      ],
      LayoutBuilder(
        builder: (context, box) {
          if (c.actor['role'] == 'manager' &&
              box.maxWidth > 650 &&
              MediaQuery.textScalerOf(context).scale(1) < 1.4) {
            return Row(
              children: [
                Expanded(child: searchField()),
                const SizedBox(width: 16),
                SizedBox(width: 235, child: groupFilter()),
              ],
            );
          }
          return Column(
            children: [
              searchField(),
              if (c.actor['role'] == 'manager') ...[
                const SizedBox(height: 16),
                groupFilter(),
              ],
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      if (c.actor['role'] == 'manager')
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            button(t('createGroup'), () => manageRecord('group')),
            for (final g in c.rows('groups'))
              TextButton(
                onPressed: () => manageRecord('group', existing: g),
                child: Text('${t('editGroup')}: ${g['displayName']}'),
              ),
            TextButton(
              onPressed: () => context.go('/enterprise'),
              child: Text(t('enterprise')),
            ),
          ],
        ),
      if (c.rows('groups').isEmpty) empty(),
      LayoutBuilder(
        builder: (context, box) {
          if (c.actor['role'] == 'manager' &&
              box.maxWidth > 850 &&
              MediaQuery.textScalerOf(context).scale(1) < 1.4) {
            return SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (members.isEmpty)
                    EmptyState(t('noMatchingMembers'))
                  else
                    SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        showCheckboxColumn: false,
                        columns: [
                          DataColumn(label: Text(t('member'))),
                          DataColumn(label: Text(t('group'))),
                          DataColumn(
                            label: Text(t('confirmedSavings')),
                            numeric: true,
                          ),
                          DataColumn(
                            label: Text(t('loanPrincipal')),
                            numeric: true,
                          ),
                        ],
                        rows: [
                          for (final m in members)
                            DataRow(
                              onSelectChanged: (_) =>
                                  context.push('/member/${m['id']}'),
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 240,
                                    child: Row(
                                      children: [
                                        IdentityAvatar(
                                          m['displayName'],
                                          size: 34,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            m['displayName'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    visible.firstWhere(
                                      (g) => g['id'] == m['groupId'],
                                    )['displayName'],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    money(c.savings(m)),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                ),
                                DataCell(Text(money(c.principal(m)))),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }
          return Column(
            children: [
              for (final g in visible)
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g['displayName'],
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  g['villageLabel'] ?? '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: PopColors.primaryTint,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              '${c.rows('members').where((m) => m['groupId'] == g['id']).length}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),
                      const Divider(),
                      const SizedBox(height: 5),
                      if (members.where((m) => m['groupId'] == g['id']).isEmpty)
                        EmptyState(t('noMatchingMembers')),
                      for (final m in members.where(
                        (m) => m['groupId'] == g['id'],
                      ))
                        MemberRow(
                          name: m['displayName'],
                          summary:
                              '${t('confirmedSavings')} ${money(c.savings(m))}',
                          onTap: () => context.push('/member/${m['id']}'),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      if (c.actor['role'] == 'sakhi')
        SizedBox(
          width: double.infinity,
          child: button(
            t('addMember'),
            registration,
            icon: Icons.person_add_alt_outlined,
          ),
        ),
    ];
  }

  Json? currentMember() =>
      c.rows('members').where((m) => m['id'] == widget.memberId).firstOrNull ??
      c
          .rows('members')
          .where((m) => m['id'] == c.actor['memberId'])
          .firstOrNull ??
      c.rows('members').firstOrNull;
  List<Widget> member({bool includeTitle = true}) {
    final m = currentMember();
    if (m == null) return [empty()];
    final pending = c.pending(m['id'], 'savings_deposit');
    final group = c
        .rows('groups')
        .where((g) => g['id'] == m['groupId'])
        .firstOrNull;
    final records = c
        .rows('transactions')
        .where((tx) => tx['memberId'] == m['id'])
        .toList()
        .reversed
        .toList();
    return [
      if (c.portal && includeTitle) title(t('passbook')),
      if (c.actor['role'] == 'sakhi')
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => registration(memberToEdit: m),
            icon: const Icon(Icons.edit_outlined),
            label: Text(t('editProfile')),
          ),
        ),
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IdentityAvatar(m['displayName'], size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['displayName'],
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group?['displayName'] ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: teal,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PopColors.primaryTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('confirmedSavings'),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: teal),
                  ),
                  const SizedBox(height: 10),
                  MoneyAmount(money(c.savings(m)), size: 40, color: teal),
                ],
              ),
            ),
          ],
        ),
      ),
      if (pending != 0)
        Semantics(
          liveRegion: true,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PopColors.warningTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: PopColors.warning,
                  size: 22,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    '${money(pending)} · ${t('waitingToSync')}',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: PopColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ),
      SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PopColors.primaryTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                size: 23,
                color: teal,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('loanPrincipal'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  MoneyAmount(money(c.principal(m)), size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      if (widget.page != 'member' && c.actor['role'] == 'participant') ...[
        SizedBox(
          width: double.infinity,
          child: button(
            t('requestHelp'),
            () => requestHelp(m),
            icon: Icons.support_agent_outlined,
          ),
        ),
        const SizedBox(height: 20),
      ],
      SectionHeading(t('recentActivity')),
      if (records.isEmpty) empty(),
      for (final tx in records) transactionRow(tx),
      for (final o in c.queue.where(
        (o) =>
            o['kind'] == 'transaction.post' &&
            o['payload']['memberId'] == m['id'] &&
            !['acknowledged', 'discarded', 'superseded'].contains(o['state']),
      ))
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            '${money(o['payload']['amountPaise'])} · ${o['error'] == null ? t('savedOnPhone') : errorText(o['error'])}',
            style: Theme.of(context).textTheme.bodySmall,
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
    date: businessDate(tx['businessDate']),
    status: t(tx['reversedByTransactionId'] != null ? 'reversed' : 'confirmed'),
    subject: widget.page == 'member'
        ? null
        : c
              .rows('members')
              .where((m) => m['id'] == tx['memberId'])
              .firstOrNull?['displayName'],
    icon:
        ['enterprise_expense', 'loan_principal_repayment'].contains(tx['type'])
        ? Icons.north_east_rounded
        : Icons.south_west_rounded,
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
    if (c.actor['role'] != 'participant')
      button(t('scheduleMeeting'), () => manageRecord('meeting')),
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
            Text(businessDate(meeting['businessDate'])),
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
    final selectedMeeting =
        meeting ??
        c
            .rows('meetings')
            .where((r) => r['groupId'] == m['groupId'] && r['status'] == 'open')
            .firstOrNull;
    final entryDate = enterprise == null
        ? (selectedMeeting?['businessDate'] ??
              c.data['businessDate'] ??
              '2026-11-05')
        : (c.data['businessDate'] ?? '2026-11-05');
    final draftKey =
        'entry/${m['id']}/$type/${meeting?['id'] ?? enterprise?['id'] ?? ''}';
    final savedDraft = c.formDrafts[draftKey] as Map? ?? {};
    final amount = TextEditingController(text: savedDraft['amount']),
        note = TextEditingController(text: savedDraft['note']);
    String category = savedDraft['category'] ?? 'seeds';
    bool submitted = false;
    Timer? draftTimer;
    final intent = savedDraft['intentId'] as String? ?? const Uuid().v4(),
        transaction =
            savedDraft['transactionId'] as String? ?? const Uuid().v4();
    Future<void> retainDraft() => c.saveFormDraft(draftKey, {
      'amount': amount.text,
      'note': note.text,
      'category': category,
      'intentId': intent,
      'transactionId': transaction,
    });
    String? validation;
    bool saving = false;
    void changed() {
      draftTimer?.cancel();
      draftTimer = Timer(
        const Duration(milliseconds: 300),
        () => unawaited(act(retainDraft)),
      );
    }

    amount.addListener(changed);
    note.addListener(changed);
    final route = DialogRoute<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          scrollable: true,
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
                if (enterprise != null)
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: t('category')),
                    items: ['seeds', 'supplies', 'transport', 'sales', 'other']
                        .map(
                          (v) => DropdownMenuItem(value: v, child: Text(t(v))),
                        )
                        .toList(),
                    onChanged: (v) {
                      set(() => category = v!);
                      changed();
                    },
                  ),
                Text('${t('date')}: ${businessDate(entryDate)}'),
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
                        '${t('member')}: ${m['displayName']}\n${t('group')}: ${c.rows('groups').firstWhere((g) => g['id'] == m['groupId'])['displayName']}\n${t('type')}: ${typeLabel(type)}\n${t('amount')}: ${money(paise)}\n${t('date')}: ${businessDate(entryDate)}',
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
                        final meet = selectedMeeting;
                        if (enterprise == null && meet == null) {
                          throw ApiError('MEETING_CLOSED', 409, {});
                        }
                        await c.enqueue('transaction.post', {
                          'transactionId': transaction,
                          'memberId': m['id'],
                          'type': type,
                          'amountPaise': paise,
                          'businessDate': entryDate,
                          if (enterprise != null)
                            'enterpriseId': enterprise['id'],
                          if (enterprise != null) 'category': category,
                          if (enterprise == null) 'meetingId': meet!['id'],
                          if (type == 'loan_principal_repayment')
                            'loanId': c
                                .rows('loans')
                                .firstWhere(
                                  (l) => l['memberId'] == m['id'],
                                )['id'],
                          if (note.text.isNotEmpty) 'note': note.text,
                        }, intentId: intent);
                        submitted = true;
                        draftTimer?.cancel();
                        await c.saveFormDraft(draftKey, null);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
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
    draftTimer?.cancel();
    if (!submitted && c.valid) await act(retainDraft);
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
                            'visit.create': 'recordVisit',
                          }[o['kind']] ??
                          'type',
                    ),
            ),
            chip(
              t(
                o['state'] == 'sending'
                    ? 'syncing'
                    : o['state'] == 'blocked'
                    ? 'blockedState'
                    : o['state'] == 'conflict'
                    ? 'conflictState'
                    : o['state'] == 'rejected'
                    ? 'rejectedState'
                    : o['state'] == 'discarded'
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
    if (c.actor['role'] != 'participant' && c.rows('members').isNotEmpty)
      button(t('createEnterprise'), () => manageRecord('enterprise')),
    if (c.rows('enterprises').isEmpty) empty(),
    for (final e in c.rows('enterprises')) ...[
      title(e['name']),
      if (c.actor['role'] != 'participant')
        TextButton(
          onPressed: () => manageRecord('enterprise', existing: e),
          child: Text(t('editEnterprise')),
        ),
      if ((e['businessPlan'] as String? ?? '').isNotEmpty)
        Text(e['businessPlan']),
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
  Future<void> manageRecord(String kind, {Json? existing}) async {
    final name = TextEditingController(
      text: existing?[kind == 'group' ? 'displayName' : 'name'],
    );
    final village = TextEditingController(text: existing?['villageLabel']);
    final code = TextEditingController(text: existing?['code']);
    final plan = TextEditingController(text: existing?['businessPlan']);
    String groupId =
        existing?['groupId'] ?? c.rows('groups').firstOrNull?['id'] ?? '';
    String memberId =
        existing?['memberId'] ?? c.rows('members').firstOrNull?['id'] ?? '';
    String ownerId =
        c
            .rows('actors')
            .where((a) => a['role'] == 'sakhi')
            .firstOrNull?['id'] ??
        '';
    DateTime date = DateTime.now();
    bool saving = false;
    String? failure;
    final id = existing?['id'] ?? const Uuid().v4();
    final route = DialogRoute<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          scrollable: true,
          title: Text(
            t(
              kind == 'group'
                  ? existing == null
                        ? 'createGroup'
                        : 'editGroup'
                  : kind == 'meeting'
                  ? 'scheduleMeeting'
                  : existing == null
                  ? 'createEnterprise'
                  : 'editEnterprise',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kind != 'meeting')
                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: t('name')),
                  maxLength: 100,
                ),
              if (kind == 'group') ...[
                if (existing == null)
                  TextField(
                    controller: code,
                    decoration: InputDecoration(labelText: t('groupCode')),
                    maxLength: 40,
                  ),
                TextField(
                  controller: village,
                  decoration: InputDecoration(labelText: t('village')),
                  maxLength: 100,
                ),
                if (existing == null)
                  DropdownButtonFormField<String>(
                    initialValue: ownerId.isEmpty ? null : ownerId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: t('sakhiOwner')),
                    items: c
                        .rows('actors')
                        .where((a) => a['role'] == 'sakhi')
                        .map(
                          (a) => DropdownMenuItem<String>(
                            value: a['id'],
                            child: Text(a['displayName']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => ownerId = v!,
                  ),
              ],
              if (kind == 'meeting') ...[
                DropdownButtonFormField<String>(
                  initialValue: groupId.isEmpty ? null : groupId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: t('group')),
                  items: c
                      .rows('groups')
                      .map(
                        (g) => DropdownMenuItem<String>(
                          value: g['id'],
                          child: Text(g['displayName']),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => groupId = v!,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    businessDate(date.toIso8601String().substring(0, 10)),
                  ),
                  onPressed: () async {
                    final next = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (next != null) set(() => date = next);
                  },
                ),
              ],
              if (kind == 'enterprise') ...[
                DropdownButtonFormField<String>(
                  initialValue: memberId.isEmpty ? null : memberId,
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
                  onChanged: existing == null ? (v) => memberId = v! : null,
                ),
                TextField(
                  controller: plan,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: InputDecoration(labelText: t('businessPlan')),
                ),
              ],
              if (failure != null)
                Text(failure!, style: const TextStyle(color: PopColors.error)),
            ],
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
                      set(() => saving = true);
                      try {
                        await c.onlineMutation(
                          '$kind.${existing == null ? 'create' : 'update'}',
                          {
                            if (kind == 'group') ...{
                              'groupId': id,
                              'displayName': name.text.trim(),
                              'villageLabel': village.text.trim(),
                              if (existing == null) ...{
                                'code': code.text.trim(),
                                'assignedActorId': ownerId,
                              },
                            },
                            if (kind == 'meeting') ...{
                              'meetingId': id,
                              'groupId': groupId,
                              'businessDate': date.toIso8601String().substring(
                                0,
                                10,
                              ),
                            },
                            if (kind == 'enterprise') ...{
                              'enterpriseId': id,
                              'name': name.text.trim(),
                              'businessPlan': plan.text.trim(),
                              if (existing == null) 'memberId': memberId,
                            },
                            if (existing != null)
                              'expectedVersion': existing['version'],
                          },
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          set(() {
                            saving = false;
                            failure = errorText(
                              e is ApiError
                                  ? e.code
                                  : 'TEMPORARILY_UNAVAILABLE',
                            );
                          });
                        }
                      }
                    },
              child: Text(t(saving ? 'loading' : 'save')),
            ),
          ],
        ),
      ),
    );
    await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
    name.dispose();
    village.dispose();
    code.dispose();
    plan.dispose();
  }

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

  Future<void> registration({
    Json? draft,
    String? replaces,
    Json? memberToEdit,
  }) async {
    if (c.rows('groups').isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t('createGroupFirst'))));
      return;
    }
    final draftKey = 'profile/${memberToEdit?['id'] ?? replaces ?? 'new'}';
    draft ??= c.formDrafts[draftKey] == null
        ? memberToEdit
        : Map<String, dynamic>.from(c.formDrafts[draftKey]);
    String groupId =
        draft?['groupId'] ??
        (managerGroup != 'all' ? managerGroup : c.rows('groups').first['id']);
    final memberId =
        draft?['memberId'] ?? memberToEdit?['id'] ?? const Uuid().v4();
    final intentId = draft?['intentId'] ?? const Uuid().v4();
    bool submitted = false;
    final name = TextEditingController(text: draft?['displayName']),
        contact = TextEditingController(text: draft?['contact']);
    String language = draft?['preferredLanguage'] ?? 'hi',
        livelihood = draft?['livelihoodCategory'] ?? 'tailoring';
    bool saving = false;
    Timer? draftTimer;
    Future<void> retainDraft() => c.saveFormDraft(draftKey, {
      'memberId': memberId,
      'intentId': intentId,
      'groupId': groupId,
      'displayName': name.text,
      'contact': contact.text,
      'preferredLanguage': language,
      'livelihoodCategory': livelihood,
    });
    void changed() {
      draftTimer?.cancel();
      draftTimer = Timer(
        const Duration(milliseconds: 300),
        () => unawaited(act(retainDraft)),
      );
    }

    name.addListener(changed);
    contact.addListener(changed);

    final route = DialogRoute<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(t(memberToEdit == null ? 'addMember' : 'editProfile')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: groupId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: t('group')),
                  items: c
                      .rows('groups')
                      .map(
                        (g) => DropdownMenuItem<String>(
                          value: g['id'],
                          child: Text(g['displayName']),
                        ),
                      )
                      .toList(),
                  onChanged: memberToEdit == null
                      ? (v) {
                          set(() => groupId = v!);
                          changed();
                        }
                      : null,
                ),
                const SizedBox(height: 16),
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
                  items: ['en', 'hi', 'or', 'hoc', 'sat']
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(
                            v == 'en'
                                ? t('english')
                                : v == 'hi'
                                ? t('hindi')
                                : '${{'or': 'Odia', 'hoc': 'Ho', 'sat': 'Santhali'}[v]} · ${t('planned')}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    language = v!;
                    changed();
                  },
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
                  onChanged: (v) {
                    livelihood = v!;
                    changed();
                  },
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
                      if (!await confirm(
                        t('review'),
                        '${t('name')}: ${name.text}\n${t('group')}: ${c.rows('groups').firstWhere((g) => g['id'] == groupId)['displayName']}\n${t('preferredLanguage')}: ${language == 'en'
                            ? t('english')
                            : language == 'hi'
                            ? t('hindi')
                            : '${{'or': 'Odia', 'hoc': 'Ho', 'sat': 'Santhali'}[language]} · ${t('planned')}'}\n${t('livelihood')}: ${t(livelihood)}\n${t('contactOptional')}: ${contact.text}',
                      )) {
                        return;
                      }
                      set(() => saving = true);
                      try {
                        final values = <String, dynamic>{
                          'displayName': name.text.trim(),
                          'preferredLanguage': language,
                          'livelihoodCategory': livelihood,
                          'contact': contact.text.trim(),
                        };
                        await c.enqueue(
                          memberToEdit == null
                              ? 'member.create'
                              : 'member.update',
                          memberToEdit == null
                              ? {
                                  'memberId': memberId,
                                  'groupId': groupId,
                                  ...values,
                                }
                              : {
                                  'memberId': memberId,
                                  'expectedVersion': memberToEdit['version'],
                                  'patch': values,
                                },
                          intentId: intentId,
                          replacesOperationId: replaces,
                        );
                        submitted = true;
                        draftTimer?.cancel();
                        await c.saveFormDraft(draftKey, null);
                      } catch (e) {
                        if (ctx.mounted) set(() => saving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                errorText(
                                  e is ApiError
                                      ? e.code
                                      : 'TEMPORARILY_UNAVAILABLE',
                                ),
                              ),
                            ),
                          );
                        }
                        return;
                      }
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
              child: Text(t('review')),
            ),
          ],
        ),
      ),
    );
    await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
    draftTimer?.cancel();
    if (!submitted && c.valid) {
      await act(
        () => c.saveFormDraft(draftKey, {
          'memberId': memberId,
          'intentId': intentId,
          'groupId': groupId,
          'displayName': name.text,
          'contact': contact.text,
          'preferredLanguage': language,
          'livelihoodCategory': livelihood,
        }),
      );
    }
    name.dispose();
    contact.dispose();
  }

  List<Widget> support({bool includeTitle = true}) {
    final statusField = Semantics(
      container: true,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        itemHeight: null,
        initialValue: supportStatus,
        decoration: InputDecoration(labelText: t('statusFilter')),
        items: ['all', 'active', 'open', 'in_progress', 'resolved']
            .map(
              (v) => DropdownMenuItem(
                value: v,
                child: Text(
                  t(
                    v == 'all'
                        ? 'allStatuses'
                        : v == 'active'
                        ? 'openRequests'
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
    );
    final ownerField = Semantics(
      container: true,
      child: DropdownButtonFormField<String>(
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
    );
    final requests = c
        .rows('supportRequests')
        .where(
          (r) =>
              (supportStatus == 'all' ||
                  (supportStatus == 'active' && r['status'] != 'resolved') ||
                  r['status'] == supportStatus) &&
              (supportOwner == 'all' || r['assignedActorId'] == supportOwner),
        )
        .toList();
    return [
      if (c.actor['role'] != 'participant')
        TextButton.icon(
          onPressed: () => context.go('/monitoring'),
          icon: const Icon(Icons.assignment_outlined),
          label: Text(t('sakhiMonitoring')),
        ),
      if (includeTitle) ...[
        Text(t('support'), style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 24),
      ],
      if (c.actor['role'] == 'sakhi' && c.rows('enterprises').isNotEmpty)
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(t('enterprise')),
            subtitle: Text(c.rows('enterprises').first['name']),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go('/enterprise'),
          ),
        ),
      LayoutBuilder(
        builder: (context, box) {
          if (c.actor['role'] == 'manager' &&
              box.maxWidth >= 650 &&
              MediaQuery.textScalerOf(context).scale(1) < 1.4) {
            return Row(
              children: [
                SizedBox(width: 250, child: statusField),
                const SizedBox(width: 16),
                SizedBox(width: 250, child: ownerField),
              ],
            );
          }
          return Column(
            children: [
              statusField,
              if (c.actor['role'] == 'manager') ...[
                const SizedBox(height: 16),
                ownerField,
              ],
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      if (requests.isEmpty) EmptyState(t('noMatchingRequests')),
      for (final r in requests)
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      r['reference'],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusChip(
                    t(
                      r['status'] == 'open'
                          ? 'openStatus'
                          : r['status'] == 'in_progress'
                          ? 'inProgress'
                          : 'resolved',
                    ),
                    warning: r['status'] != 'resolved',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                r['description'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusChip(
                    t(
                      r['source'] == 'whatsapp_simulation'
                          ? 'simulation'
                          : 'requestHelp',
                    ),
                    icon: Icons.chat_bubble_outline_rounded,
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
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (r['resolutionNote'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(r['resolutionNote']),
                ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: () => supportHistory(r),
                    icon: const Icon(Icons.history_rounded, size: 19),
                    label: Text(t('activity')),
                  ),
                  if (c.actor['role'] == 'manager' && r['status'] != 'resolved')
                    TextButton.icon(
                      onPressed: () => assignSupport(r),
                      icon: const Icon(Icons.person_outline_rounded, size: 19),
                      label: Text(t('reassign')),
                    ),
                  if (c.actor['role'] != 'participant' &&
                      r['status'] != 'resolved')
                    OutlinedButton.icon(
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
                      icon: Icon(
                        r['status'] == 'open'
                            ? Icons.play_arrow_rounded
                            : Icons.check_rounded,
                        size: 19,
                      ),
                      label: Text(
                        t(r['status'] == 'open' ? 'inProgress' : 'resolved'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> reports() => [
    ProgrammeReports(controller: c, t: t, initialGroup: managerGroup),
  ];

  List<Widget> monitoring() {
    if (c.actor['role'] == 'participant') return [Text(t('forbidden'))];
    final visits = c.rows('sakhiVisits');
    return [
      title(t('sakhiMonitoring')),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          chip('${t('recordedVisits')}: ${visits.length}'),
          chip(
            '${t('followUps')}: ${visits.where((v) => v['status'] == 'follow_up').length}',
            warning: true,
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (c.actor['role'] == 'sakhi') button(t('recordVisit'), recordVisit),
      if (visits.isEmpty) empty(),
      for (final v in visits.reversed)
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c
                        .rows('members')
                        .where((m) => m['id'] == v['memberId'])
                        .firstOrNull?['displayName'] ??
                    '',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text('${businessDate(v['businessDate'])} · ${t(v['topic'])}'),
              Text(v['notes']),
              if (v['nextVisitDate'] != null)
                Text('${t('nextVisit')}: ${businessDate(v['nextVisitDate'])}'),
              chip(
                t(
                  v['status'] == 'follow_up'
                      ? 'followUpPending'
                      : v['status'] == 'completed'
                      ? 'completed'
                      : 'recordedVisits',
                ),
                warning: v['status'] == 'follow_up',
              ),
              if (v['outcome'] != null) Text(v['outcome']),
              if (v['status'] == 'follow_up')
                TextButton(
                  onPressed: () => act(() async {
                    final outcome = await input(t('visitOutcome'));
                    if (outcome != null && outcome.trim().isNotEmpty) {
                      await c.onlineMutation('visit.complete', {
                        'visitId': v['id'],
                        'expectedVersion': v['version'],
                        'outcome': outcome.trim(),
                      });
                    }
                  }),
                  child: Text(t('completeFollowUp')),
                ),
            ],
          ),
        ),
    ];
  }

  Future<void> recordVisit() async {
    final member = c.rows('members').firstOrNull;
    if (member == null) return;
    String memberId = member['id'], topic = 'savings';
    DateTime? next;
    final notes = TextEditingController();
    bool saving = false;
    String? failure;
    final intent = const Uuid().v4(), id = const Uuid().v4();
    final route = DialogRoute<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          scrollable: true,
          title: Text(t('recordVisit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                onChanged: (v) => memberId = v!,
              ),
              DropdownButtonFormField<String>(
                initialValue: topic,
                isExpanded: true,
                decoration: InputDecoration(labelText: t('topic')),
                items: ['savings', 'enterprise', 'digital_skills', 'other']
                    .map((v) => DropdownMenuItem(value: v, child: Text(t(v))))
                    .toList(),
                onChanged: (v) => topic = v!,
              ),
              TextField(
                controller: notes,
                maxLength: 2000,
                maxLines: 4,
                decoration: InputDecoration(labelText: t('visitNotes')),
              ),
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) set(() => next = date);
                },
                child: Text(
                  next == null
                      ? t('nextVisit')
                      : businessDate(next!.toIso8601String().substring(0, 10)),
                ),
              ),
              if (failure != null) Text(failure!),
            ],
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
                      if (notes.text.trim().isEmpty) {
                        set(() => failure = t('invalidFields'));
                        return;
                      }
                      set(() => saving = true);
                      try {
                        await c.enqueue('visit.create', {
                          'visitId': id,
                          'memberId': memberId,
                          'businessDate': DateTime.now()
                              .toIso8601String()
                              .substring(0, 10),
                          'topic': topic,
                          'notes': notes.text.trim(),
                          if (next != null)
                            'nextVisitDate': next!.toIso8601String().substring(
                              0,
                              10,
                            ),
                        }, intentId: intent);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          set(() {
                            saving = false;
                            failure = errorText(
                              e is ApiError
                                  ? e.code
                                  : 'TEMPORARILY_UNAVAILABLE',
                            );
                          });
                        }
                      }
                    },
              child: Text(t(saving ? 'loading' : 'save')),
            ),
          ],
        ),
      ),
    );
    await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
    notes.dispose();
  }

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
                    '${actionLabel(event['action'])} · ${displayTime(event['timestamp'])}',
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

  Future<Json> helpPack() async {
    final value =
        c.contentPack ??
        jsonDecode(
          await rootBundle.loadString(
            'packages/pop_ui/assets/content_cards.json',
          ),
        ) as Json;
    if (value['cards'] is! List) {
      throw const FormatException('Invalid help pack');
    }
    for (final card in value['cards']) {
      if (card is! Map ||
          card['id'] is! String ||
          card['keywords'] is! List ||
          !(card['keywords'] as List).every((word) => word is String) ||
          card['locales'] is! Map) {
        throw const FormatException('Invalid help card');
      }
      final locale = card['locales']?[widget.lang];
      if (locale is! Map ||
          locale['title'] is! String ||
          locale['steps'] is! List ||
          !(locale['steps'] as List).every((step) => step is String) ||
          locale['audioScript'] is! String) {
        throw const FormatException('Invalid help locale');
      }
    }
    return value;
  }

  List<Widget> help() => [
    title(t('demoHelp')),
    OutlinedButton.icon(
      onPressed: () => context.go('/assistant'),
      icon: const Icon(Icons.mic_none),
      label: Text(t('assistantTitle')),
    ),
    const SizedBox(height: 16),
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
    FutureBuilder<Json>(
      key: ValueKey(helpRevision),
      future: helpPack(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            children: [
              Text(t('contentLoadFailed')),
              TextButton(
                onPressed: () {
                  rootBundle.evict('packages/pop_ui/assets/content_cards.json');
                  setState(() => helpRevision++);
                },
                child: Text(t('retry')),
              ),
            ],
          );
        }
        if (!snapshot.hasData) return Text(t('loading'));
        final cards = (snapshot.data!['cards'] as List)
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
                    SpeechControl(
                      speech: speech,
                      id: cardData['id'],
                      language: widget.lang,
                      text: cardData['locales'][widget.lang]['audioScript'],
                      t: t,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
    if (currentMember() != null)
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
    final records = c.rows(event['entityType'] as String? ?? '');
    final record = records
        .where((r) => r['id'] == event['entityId'])
        .firstOrNull;
    if (record == null) {
      return event['entityId'] as String? ?? t('programmeRecord');
    }
    return record['displayName'] ??
        record['reference'] ??
        c
            .rows('members')
            .where((m) => m['id'] == record['memberId'])
            .firstOrNull?['displayName'] ??
        event['entityId'];
  }

  Future<void> loadAudit({bool reset = false}) async {
    if (auditLoading) return;
    setState(() {
      auditLoading = true;
      auditError = null;
      if (reset) {
        audit = [];
        auditMore = true;
      }
    });
    try {
      final r = await c.request(
        'GET',
        '/v1/audit-events?offset=${audit.length}&limit=50',
      );
      final page = (r['events'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (mounted) {
        setState(() {
          audit.addAll(page);
          auditLoaded = true;
          auditMore = page.length == 50;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => auditError = errorText(
            e is ApiError ? e.code : 'TEMPORARILY_UNAVAILABLE',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => auditLoading = false);
    }
  }

  List<Widget> activity() {
    if (!auditLoaded && !auditLoading && auditError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(loadAudit());
      });
    }
    return [
      title(t('activity')),
      Wrap(
        children: [
          TextButton(
            onPressed: auditLoading ? null : () => loadAudit(reset: true),
            child: Text(t('refresh')),
          ),
          if (auditMore && audit.isNotEmpty)
            TextButton(
              onPressed: auditLoading ? null : () => loadAudit(),
              child: Text(t('loadMore')),
            ),
        ],
      ),
      if (auditLoading) Text(t('loading')),
      if (auditError != null) Text(auditError!),
      if (audit.isEmpty && !auditLoading && auditError == null) empty(),
      for (final a in audit)
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(actionLabel(a['action'])),
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

  Future<void> editContent() async {
    await c.updateContent();
    if (!mounted || c.contentPack == null) return;
    final pack = jsonDecode(jsonEncode(c.contentPack)) as Json;
    final cards = pack['cards'] as List;
    String selected = cards.first['id'];
    String language = 'en';
    final titleField = TextEditingController();
    final stepsField = TextEditingController();
    final scriptField = TextEditingController();
    bool saving = false;
    String? error;
    void load() {
      final locale = cards.firstWhere(
        (card) => card['id'] == selected,
      )['locales'][language];
      titleField.text = locale['title'];
      stepsField.text = (locale['steps'] as List).join('\n');
      scriptField.text = locale['audioScript'];
    }

    void retain() {
      final locale = cards.firstWhere(
        (card) => card['id'] == selected,
      )['locales'][language];
      locale['title'] = titleField.text.trim();
      locale['steps'] = stepsField.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      locale['audioScript'] = scriptField.text.trim();
    }

    load();
    final operationId = const Uuid().v4();
    Json? publishBody;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(t('manageContent')),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t('draftContent')),
                  DropdownButtonFormField<String>(
                    initialValue: selected,
                    isExpanded: true,
                    items: cards
                        .map(
                          (card) => DropdownMenuItem<String>(
                            value: card['id'],
                            child: Text(card['id']),
                          ),
                        )
                        .toList(),
                    onChanged: saving || publishBody != null
                        ? null
                        : (value) {
                            retain();
                            update(() {
                              selected = value!;
                              load();
                            });
                          },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: language,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                    ],
                    onChanged: saving || publishBody != null
                        ? null
                        : (value) {
                            retain();
                            update(() {
                              language = value!;
                              load();
                            });
                          },
                  ),
                  TextField(
                    controller: titleField,
                    enabled: !saving && publishBody == null,
                    decoration: InputDecoration(labelText: t('contentTitle')),
                  ),
                  TextField(
                    controller: stepsField,
                    enabled: !saving && publishBody == null,
                    maxLines: 6,
                    decoration: InputDecoration(labelText: t('contentSteps')),
                  ),
                  TextField(
                    controller: scriptField,
                    enabled: !saving && publishBody == null,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: t('contentScript')),
                  ),
                  if (error != null)
                    Text(
                      error!,
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
                      retain();
                      update(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        publishBody ??= jsonDecode(
                          jsonEncode({
                            'operationId': operationId,
                            'expectedRevision': pack['revision'] ?? 0,
                            'cards': cards,
                          }),
                        ) as Json;
                        await c.request('POST', '/v1/content', publishBody);
                        await c.updateContent();
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          update(() {
                            saving = false;
                            error = errorText(
                              e is ApiError
                                  ? e.code
                                  : 'TEMPORARILY_UNAVAILABLE',
                            );
                          });
                        }
                      }
                    },
              child: Text(t('publishDraft')),
            ),
          ],
        ),
      ),
    );
    titleField.dispose();
    stepsField.dispose();
    scriptField.dispose();
  }

  List<Widget> capabilities() => [
    title(t('capabilities')),
    TextButton(
      onPressed: () => context.go('/assistant'),
      child: Text(t('assistantTitle')),
    ),
    if (c.actor['role'] == 'manager') ...[
      TextButton(
        onPressed: () => context.go('/administration'),
        child: Text(t('administration')),
      ),
      TextButton(
        onPressed: () => context.go('/reports'),
        child: Text(t('reports')),
      ),
      TextButton(
        onPressed: () => act(editContent),
        child: Text(t('manageContent')),
      ),
    ],
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
          Text('${t('date')}: ${businessDate('2026-11-05')}'),
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
          Text(t('speechDisclosure')),
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
    if (const String.fromEnvironment('AUTH_MODE') == 'cognito') {
      await act(() async {
        final config = await c.request('GET', '/v1/auth/config');
        final token = await organisationSignIn(config);
        if (token != null) await c.login('', '', accessToken: token);
      });
      return;
    }
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
