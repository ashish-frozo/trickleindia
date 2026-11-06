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
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final normalText = MediaQuery.textScalerOf(context).scale(1) < 1.4;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const PopWordmark(size: 26),
                    if (wide && normalText) ...[
                      const SizedBox(width: 24),
                      Container(width: 1, height: 28, color: PopColors.border),
                      const SizedBox(width: 24),
                      Text(
                        programmeLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const Spacer(),
                    languageControl,
                    IconButton(
                      tooltip: refreshLabel,
                      onPressed: refreshing ? null : refresh,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    const SizedBox(width: 12),
                    IdentityAvatar(name, size: 36),
                    if (wide && normalText) ...[
                      const SizedBox(width: 10),
                      Text(name, style: Theme.of(context).textTheme.titleSmall),
                    ],
                    IconButton(
                      tooltip: '$name · $signOutLabel',
                      onPressed: signOut,
                      icon: const Icon(Icons.logout_rounded, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            Material(
              color: Colors.white,
              child: VengeanceNavigation(
                labels: destinations,
                icons: icons,
                selected: selected,
                onSelected: onNavigate,
                inline: wide && normalText,
                compact: !wide,
              ),
            ),
            const Divider(),
            DemoBanner(demoLabel),
            Expanded(child: body),
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
              const RecordIllustration(),
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
                          color: const Color(0xff2856bc),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.$1, color: brandAccent, size: 21),
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
