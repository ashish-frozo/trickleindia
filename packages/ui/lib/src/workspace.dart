import 'package:flutter/material.dart';

import 'components.dart';
import 'tokens.dart';

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
    final sidebar = expanded ? 232.0 : 88.0;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: sidebar,
              child: Material(
                color: PopColors.forest,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        expanded ? 24 : 8,
                        28,
                        expanded ? 24 : 8,
                        24,
                      ),
                      child: expanded
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const PopWordmark(inverse: true, size: 26),
                                const SizedBox(height: 6),
                                Text(
                                  programmeLabel,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: PopColors.forestMuted),
                                ),
                              ],
                            )
                          : const Text(
                              'PoP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const Divider(
                      color: Color(0xff386459),
                      indent: 18,
                      endIndent: 18,
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          for (var i = 0; i < destinations.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: TextButton(
                                onPressed: () => onNavigate(i),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: selected == i
                                      ? PopColors.primaryTint
                                      : Colors.transparent,
                                  foregroundColor: selected == i
                                      ? teal
                                      : Colors.white,
                                  overlayColor: selected == i
                                      ? teal
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Semantics(
                                  selected: selected == i,
                                  label:
                                      '${destinations[i]} Tab ${i + 1} of ${destinations.length}',
                                  excludeSemantics: true,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: expanded ? 16 : 3,
                                      vertical: expanded ? 15 : 12,
                                    ),
                                    child: expanded
                                        ? Row(
                                            children: [
                                              Icon(
                                                icons[i],
                                                size: 21,
                                                color: selected == i
                                                    ? teal
                                                    : PopColors.forestMuted,
                                              ),
                                              const SizedBox(width: 13),
                                              Expanded(
                                                child: Text(
                                                  destinations[i],
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: selected == i
                                                            ? ink
                                                            : Colors.white,
                                                        fontWeight:
                                                            selected == i
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            children: [
                                              Icon(
                                                icons[i],
                                                size: 23,
                                                color: selected == i
                                                    ? teal
                                                    : PopColors.forestMuted,
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                destinations[i],
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: selected == i
                                                          ? ink
                                                          : Colors.white,
                                                      fontSize: 11,
                                                    ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(
                      color: Color(0xff386459),
                      indent: 18,
                      endIndent: 18,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: expanded
                          ? Row(
                              children: [
                                IdentityAvatar(name, size: 36, inverse: true),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(color: Colors.white),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        role,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: PopColors.forestMuted,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: signOutLabel,
                                  onPressed: signOut,
                                  style: IconButton.styleFrom(
                                    foregroundColor: PopColors.forestMuted,
                                    minimumSize: const Size(32, 48),
                                    padding: EdgeInsets.zero,
                                  ),
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
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: PopColors.forestMuted,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Material(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 20, 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.space_dashboard_outlined,
                            size: 18,
                            color: muted,
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 17,
                            color: muted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pageTitle,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          languageControl,
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: refreshLabel,
                            onPressed: refreshing ? null : refresh,
                            icon: refreshing
                                ? const SizedBox.square(
                                    dimension: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DemoBanner(demoLabel),
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
    color: PopColors.forest,
    padding: const EdgeInsets.all(48),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PopWordmark(inverse: true, size: 28),
        const Spacer(),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(color: Colors.white, fontSize: 40, height: 1.2),
        ),
        const SizedBox(height: 24),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: PopColors.forestMuted),
        ),
        const SizedBox(height: 40),
        for (final item in [
          (Icons.phone_android_outlined, offline),
          (Icons.sync_rounded, sync),
          (Icons.groups_outlined, review),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xff2d5b4f),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.$1,
                    color: const Color(0xffd5e6da),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.$2,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        Text(
          'Trickle Up India Foundation',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: PopColors.forestMuted),
        ),
      ],
    ),
  );
}
