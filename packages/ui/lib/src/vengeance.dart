// Flutter adaptations of VengeanceUI SpotlightNavbar, GlowBorderCard and
// ResearchBentoGrid.Panel. Copyright (c) 2025-2026 Ashutoshx7, MIT.
// Provenance: docs/design/VENGEANCE_UI.md; licence bundled in assets/licenses.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

const vengeanceLime = Color(0xffd7f56b);
Duration _duration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 220);

/// Conic edge and radial illumination translated from GlowBorderCard / Panel.
/// Only interaction-driven animation: no battery-consuming perpetual effects.
class VengeanceSurface extends StatefulWidget {
  const VengeanceSurface({
    super.key,
    required this.child,
    this.dark = false,
    this.padding = const EdgeInsets.all(20),
    this.radius = 22,
  });
  final Widget child;
  final bool dark;
  final EdgeInsetsGeometry padding;
  final double radius;
  @override
  State<VengeanceSurface> createState() => _VengeanceSurfaceState();
}

class _VengeanceSurfaceState extends State<VengeanceSurface> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: AnimatedContainer(
      duration: _duration(context),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: hovered ? .08 : .035),
            blurRadius: hovered ? 28 : 16,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: SweepGradient(
          colors: widget.dark
              ? [
                  const Color(0xff555b48),
                  vengeanceLime.withValues(alpha: hovered ? .8 : .35),
                  const Color(0xff30352c),
                  const Color(0xff555b48),
                ]
              : [
                  PopColors.border,
                  hovered ? const Color(0xff9aab75) : Colors.white,
                  PopColors.border,
                  PopColors.border,
                ],
        ),
      ),
      padding: const EdgeInsets.all(1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius - 1),
        child: Material(
          color: widget.dark ? PopColors.forest : Colors.white,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: CustomPaint(painter: _PanelLight(widget.dark)),
                  ),
                ),
              ),
              Padding(padding: widget.padding, child: widget.child),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PanelLight extends CustomPainter {
  _PanelLight(this.dark);
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    if (!dark) return;
    final center = Offset(size.width * .95, 0);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.topRight,
          radius: 1.3,
          colors: [vengeanceLime.withValues(alpha: .13), Colors.transparent],
        ).createShader(rect),
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .055);
    for (var radius = 70.0; radius < size.longestSide * 1.5; radius += 46) {
      canvas.drawCircle(center, radius, p);
    }
  }

  @override
  bool shouldRepaint(_PanelLight old) => dark != old.dark;
}

/// Cursor spotlight, active ambience and rounded navigation from SpotlightNavbar.
/// Native Material buttons retain keyboard activation and focus indicators.
class VengeanceNavigation extends StatefulWidget {
  const VengeanceNavigation({
    super.key,
    required this.labels,
    required this.icons,
    required this.selected,
    required this.onSelected,
    this.vertical = false,
    this.compact = false,
  });
  final List<String> labels;
  final List<IconData> icons;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool vertical, compact;
  @override
  State<VengeanceNavigation> createState() => _VengeanceNavigationState();
}

class _VengeanceNavigationState extends State<VengeanceNavigation> {
  int? hovered;
  @override
  Widget build(BuildContext context) {
    final items = List.generate(widget.labels.length, (i) {
      final active = widget.selected == i;
      final lit = hovered == i || active;
      final color = active ? Colors.white : ink;
      final label = Text(
        widget.labels[i],
        textAlign: widget.vertical && !widget.compact
            ? TextAlign.left
            : TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, fontSize: widget.compact ? 11 : null),
      );
      final icon = Icon(
        widget.icons[i],
        size: 22,
        color: active ? vengeanceLime : muted,
      );
      return Padding(
        padding: EdgeInsets.all(widget.vertical ? 3 : 2),
        child: AnimatedContainer(
          duration: _duration(context),
          decoration: BoxDecoration(
            color: active
                ? PopColors.forest
                : lit
                ? PopColors.surfaceSoft
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: lit ? PopColors.outline : Colors.transparent,
            ),
            gradient: lit
                ? RadialGradient(
                    center: const Alignment(0, 1.4),
                    radius: 1.6,
                    colors: active
                        ? [const Color(0xff3c4724), PopColors.forest]
                        : [const Color(0xffe8eddc), Colors.white],
                  )
                : null,
          ),
          child: TextButton(
            onHover: (value) => setState(() => hovered = value ? i : null),
            onFocusChange: (value) =>
                setState(() => hovered = value ? i : null),
            onPressed: () => widget.onSelected(i),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: widget.vertical && !widget.compact ? 16 : 4,
                vertical: 13,
              ),
              minimumSize: const Size(48, 52),
              foregroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Semantics(
              selected: active,
              excludeSemantics: true,
              label:
                  '${widget.labels[i]} Tab ${i + 1} of ${widget.labels.length}',
              child: widget.vertical && !widget.compact
                  ? Row(
                      children: [
                        icon,
                        const SizedBox(width: 12),
                        Expanded(child: label),
                        if (active)
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: vengeanceLime,
                          ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [icon, const SizedBox(height: 6), label],
                    ),
            ),
          ),
        ),
      );
    });
    return widget.vertical
        ? Column(children: items)
        : Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: PopColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .04),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((e) => Expanded(child: e)).toList(),
            ),
          );
  }
}

/// Decorative linked rings: a community motif, not a data chart.
class CommunityOrbit extends StatelessWidget {
  const CommunityOrbit({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 180,
      width: double.infinity,
      child: CustomPaint(painter: _OrbitPainter()),
    ),
  );
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final middle = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 3, 66.0);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < 3; i++) {
      final center = middle + Offset((i - 1) * radius * .78, i == 1 ? -12 : 12);
      p.color = i == 1 ? vengeanceLime : Colors.white.withValues(alpha: .26);
      canvas.drawCircle(center, radius, p);
      canvas.drawCircle(
        center + Offset(0, -radius),
        5,
        Paint()..color = i == 1 ? vengeanceLime : Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => false;
}
