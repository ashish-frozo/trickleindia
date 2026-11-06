// Flutter adaptations of VengeanceUI SpotlightNavbar, GlowBorderCard and
// ResearchBentoGrid.Panel. Copyright (c) 2025-2026 Ashutoshx7, MIT.
// Provenance: docs/design/VENGEANCE_UI.md; licence bundled in assets/licenses.

import 'package:flutter/material.dart';

import 'tokens.dart';

const brandAccent = Color(0xffffd5c8);
Duration _duration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 220);

/// Shared surface derived from GlowBorderCard / Panel, simplified after feedback.
/// Only interaction-driven animation: no battery-consuming perpetual effects.
class VengeanceSurface extends StatefulWidget {
  const VengeanceSurface({
    super.key,
    required this.child,
    this.dark = false,
    this.padding = const EdgeInsets.all(20),
    this.radius = 16,
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
        color: widget.dark ? PopColors.forest : Colors.white,
        border: Border.all(
          color: hovered ? PopColors.outline : PopColors.border,
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
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff2e63e7), Color(0xff163ea6)],
        ).createShader(rect),
    );
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
    this.inline = false,
  });
  final List<String> labels;
  final List<IconData> icons;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool vertical, compact, inline;
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
      final color = active ? teal : muted;
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
        color: active ? teal : muted,
      );
      return Padding(
        padding: EdgeInsets.all(widget.vertical ? 3 : 2),
        child: AnimatedContainer(
          duration: _duration(context),
          decoration: BoxDecoration(
            color: active
                ? PopColors.primaryTint
                : lit
                ? PopColors.surfaceSoft
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: active ? const Color(0xffc7d7ff) : Colors.transparent,
            ),
          ),
          child: TextButton(
            onHover: (value) => setState(() => hovered = value ? i : null),
            onFocusChange: (value) =>
                setState(() => hovered = value ? i : null),
            onPressed: () => widget.onSelected(i),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: widget.vertical && !widget.compact ? 16 : 4,
                vertical: widget.vertical ? 13 : 9,
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
              child: (widget.vertical && !widget.compact) || widget.inline
                  ? Row(
                      children: [
                        icon,
                        const SizedBox(width: 12),
                        Expanded(child: label),
                        if (active)
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: teal,
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
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
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

/// Decorative record sheets, with no implied financial data.
class RecordIllustration extends StatelessWidget {
  const RecordIllustration({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 180,
      width: double.infinity,
      child: CustomPaint(painter: _RecordPainter()),
    ),
  );
}

class _RecordPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * .64;
    for (var i = 0; i < 3; i++) {
      final rect = Rect.fromLTWH(
        (size.width - w) / 2 + (i - 1) * 18,
        18 + i * 26,
        w,
        100,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        Paint()
          ..color = [
            const Color(0xff87aaf5),
            const Color(0xffc5d7ff),
            Colors.white,
          ][i],
      );
      if (i == 2) {
        canvas.drawCircle(
          Offset(rect.left + 27, rect.top + 29),
          12,
          Paint()..color = const Color(0xffe7efff),
        );
        for (var row = 0; row < 3; row++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                rect.left + 50,
                rect.top + 20 + row * 22,
                w - 78 - row * 16,
                6,
              ),
              const Radius.circular(3),
            ),
            Paint()..color = const Color(0xffd5e2fc),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RecordPainter old) => false;
}
