import 'package:flutter/material.dart';

import 'components.dart';
import 'tokens.dart';
import 'vengeance.dart';

class ProgrammeWorkspace extends StatelessWidget {
  final Widget body;
  final String pageTitle,
      programmeLabel,
      demoLabel,
      name,
      role,
      refreshLabel,
      signOutLabel;
  final List<String> destinations;
  final List<IconData> icons;
  final int selected;
  final ValueChanged<int> onNavigate;
  final VoidCallback refresh, signOut;
  final Widget languageControl;
  final bool refreshing;
  const ProgrammeWorkspace({
    super.key,
    required this.body,
    required this.pageTitle,
    required this.programmeLabel,
    required this.demoLabel,
    required this.name,
    required this.role,
    required this.refreshLabel,
    required this.signOutLabel,
    required this.destinations,
    required this.icons,
    required this.selected,
    required this.onNavigate,
    required this.refresh,
    required this.signOut,
    required this.languageControl,
    this.refreshing = false,
  });
  @override
  Widget build(BuildContext context) {
    final expanded = MediaQuery.sizeOf(context).width >= 1100;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: expanded ? 244 : 100,
              margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: PopColors.border),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: expanded ? 24 : 8,
                      vertical: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (expanded)
                          const PopWordmark(size: 28)
                        else
                          const Text(
                            'PoP',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (expanded) ...[
                          const SizedBox(height: 8),
                          Text(
                            programmeLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(indent: 20, endIndent: 20),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: VengeanceNavigation(
                        labels: destinations,
                        icons: icons,
                        selected: selected,
                        onSelected: onNavigate,
                        vertical: true,
                        compact: !expanded,
                      ),
                    ),
                  ),
                  const Divider(indent: 20, endIndent: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 18,
                    ),
                    child: expanded
                        ? Row(
                            children: [
                              IdentityAvatar(name, size: 34),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    Text(
                                      role,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: signOutLabel,
                                onPressed: signOut,
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  size: 18,
                                ),
                              ),
                            ],
                          )
                        : IconButton(
                            tooltip: '$name · $signOutLabel',
                            onPressed: signOut,
                            icon: const Icon(Icons.logout_rounded),
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 18, 24, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                programmeLabel,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pageTitle,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        languageControl,
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: refreshLabel,
                          onPressed: refreshing ? null : refresh,
                          icon: refreshing
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: DemoBanner(demoLabel),
                    ),
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomePanel extends StatelessWidget {
  final String title, description, offline, sync, review;
  const WelcomePanel({
    super.key,
    required this.title,
    required this.description,
    required this.offline,
    required this.sync,
    required this.review,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(20),
    child: VengeanceSurface(
      dark: true,
      radius: 32,
      padding: EdgeInsets.zero,
      child: SizedBox.expand(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PopWordmark(inverse: true, size: 28),
              const SizedBox(height: 36),
              const CommunityOrbit(),
              const SizedBox(height: 28),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 42,
                  height: 1.15,
                  letterSpacing: -1.6,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: PopColors.forestMuted),
              ),
              const SizedBox(height: 32),
              for (final item in [
                (Icons.cloud_done_outlined, offline),
                (Icons.sync_rounded, sync),
                (Icons.verified_outlined, review),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xff36412a),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.$1, color: vengeanceLime, size: 21),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),
              Text(
                'Trickle Up India Foundation',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: PopColors.forestMuted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
