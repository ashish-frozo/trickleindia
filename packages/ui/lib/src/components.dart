import 'package:flutter/material.dart';

import 'tokens.dart';
import 'vengeance.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar,
    body: SafeArea(
      top: false,
      bottom: bottomNavigationBar == null,
      child: body,
    ),
    bottomNavigationBar: bottomNavigationBar,
  );
}

class PopWordmark extends StatelessWidget {
  final bool inverse;
  final double size;
  const PopWordmark({super.key, this.inverse = false, this.size = 22});
  @override
  Widget build(BuildContext context) => Text(
    'PoP 2.0',
    style: TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w600,
      letterSpacing: -.7,
      color: inverse ? Colors.white : PopColors.forest,
    ),
  );
}

class DemoBanner extends StatelessWidget {
  final String text;
  const DemoBanner(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: PopColors.primaryTint,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: teal),
    ),
  );
}

class LanguageSwitcher extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const LanguageSwitcher({
    super.key,
    required this.label,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.translate_rounded, size: 19),
      label: Text(
        label,
        style: label == 'हिन्दी'
            ? const TextStyle(fontFamily: 'packages/pop_ui/NotoSansDevanagari')
            : null,
      ),
      style: TextButton.styleFrom(
        backgroundColor: PopColors.surfaceSoft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    ),
  );
}

class IdentityAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool inverse;
  const IdentityAvatar(
    this.name, {
    super.key,
    this.size = 44,
    this.inverse = false,
  });
  @override
  Widget build(BuildContext context) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((s) => s.characters.first).join();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: inverse ? const Color(0xffdceade) : PopColors.primaryTint,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          style: TextStyle(
            color: teal,
            fontSize: size * .34,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final bool warning;
  final IconData? icon;
  const StatusChip(this.label, {super.key, this.warning = false, this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: warning ? PopColors.warningTint : PopColors.primaryTint,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon ??
              (warning
                  ? Icons.schedule_rounded
                  : Icons.check_circle_outline_rounded),
          size: 17,
          color: warning ? PopColors.warning : teal,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: warning ? PopColors.warning : teal,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    ),
  );
}

class MoneyAmount extends StatelessWidget {
  final String value;
  final double size;
  final Color? color;
  final TextAlign align;
  const MoneyAmount(
    this.value, {
    super.key,
    this.size = 32,
    this.color,
    this.align = TextAlign.left,
  });
  @override
  Widget build(BuildContext context) {
    final text = Text(
      value,
      maxLines: 1,
      softWrap: false,
      textAlign: align,
      style: TextStyle(
        fontSize: size,
        height: 1.2,
        letterSpacing: -.6,
        fontWeight: FontWeight.w600,
        color: color ?? ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return Semantics(
      excludeSemantics: true,
      label: value,
      child: LayoutBuilder(
        builder: (context, box) => box.hasBoundedWidth
            ? Align(
                alignment: align == TextAlign.right
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: FittedBox(fit: BoxFit.scaleDown, child: text),
              )
            : text,
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String label, value;
  final IconData? icon;
  final String? caption;
  final bool enclosed;
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.caption,
    this.enclosed = true,
  });
  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PopColors.primaryTint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 21, color: teal),
            ),
            const SizedBox(width: 13),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: muted),
                ),
                const SizedBox(height: 8),
                MoneyAmount(value, size: 29),
                if (caption != null) ...[
                  const SizedBox(height: 6),
                  Text(caption!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return enclosed
        ? SurfaceCard(padding: EdgeInsets.zero, child: content)
        : content;
  }
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  const SurfaceCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(PopSpacing.card),
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: VengeanceSurface(
      dark: color == PopColors.forest,
      padding: padding,
      child: child,
    ),
  );
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionHeading(this.title, {super.key, this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String message;
  const EmptyState(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Row(
      children: [
        const Icon(Icons.inbox_outlined, size: 28, color: muted),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: muted),
          ),
        ),
      ],
    ),
  );
}

class ErrorState extends StatelessWidget {
  final String message, retryLabel;
  final VoidCallback onRetry;
  const ErrorState({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
    decoration: BoxDecoration(
      color: PopColors.errorTint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Icon(Icons.info_outline, color: PopColors.error, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(message),
          ),
        ),
        TextButton(onPressed: onRetry, child: Text(retryLabel)),
      ],
    ),
  );
}

class CapabilityBadge extends StatelessWidget {
  final String label;
  final bool planned;
  const CapabilityBadge(this.label, {super.key, this.planned = false});
  @override
  Widget build(BuildContext context) => StatusChip(label, warning: planned);
}

class MemberRow extends StatelessWidget {
  final String name, summary;
  final VoidCallback onTap;
  const MemberRow({
    super.key,
    required this.name,
    required this.summary,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      minVerticalPadding: 10,
      leading: IdentityAvatar(name),
      title: Text(name, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(summary),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 23),
      onTap: onTap,
    ),
  );
}

class TransactionRow extends StatelessWidget {
  final String title, amount, date, status;
  final String? subject;
  final Widget? correction;
  final IconData icon;
  const TransactionRow({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    this.subject,
    this.correction,
    this.icon = Icons.south_west_rounded,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: PopColors.border)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PopColors.primaryTint,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 20, color: teal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                [?subject, date].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(
                status,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: teal),
              ),
              ?correction,
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(child: MoneyAmount(amount, size: 21, align: TextAlign.right)),
      ],
    ),
  );
}

class SyncStatusBar extends StatelessWidget {
  final String label, actionLabel;
  final IconData icon;
  final VoidCallback onPressed;
  const SyncStatusBar({
    super.key,
    required this.label,
    required this.actionLabel,
    required this.icon,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Material(
      color: PopColors.surfaceSoft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 3, 10, 3),
        child: Row(
          children: [
            Icon(icon, color: teal, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: teal),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: actionLabel,
              onPressed: onPressed,
              icon: const Icon(Icons.sync_rounded, size: 22),
            ),
          ],
        ),
      ),
    ),
  );
}

class ReviewSheet extends StatefulWidget {
  final String title, summary, confirmLabel, cancelLabel;
  final VoidCallback onConfirm, onCancel;
  const ReviewSheet({
    super.key,
    required this.title,
    required this.summary,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
  });
  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  bool committed = false;
  void commit() {
    if (committed) return;
    setState(() => committed = true);
    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: PopColors.primaryTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.fact_check_outlined, color: teal, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(widget.title)),
      ],
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in widget.summary.split('\n'))
            if (line.trim().isEmpty)
              const SizedBox(height: 10)
            else if (line.contains(':'))
              _ReviewLine(line)
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(line),
              ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: committed ? null : widget.onCancel,
        child: Text(widget.cancelLabel),
      ),
      FilledButton(
        onPressed: committed ? null : commit,
        child: Text(widget.confirmLabel),
      ),
    ],
  );
}

class _ReviewLine extends StatelessWidget {
  final String line;
  const _ReviewLine(this.line);
  @override
  Widget build(BuildContext context) {
    final split = line.indexOf(':');
    final label = line.substring(0, split);
    final value = line.substring(split + 1).trim();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PopColors.border)),
      ),
      child: MediaQuery.textScalerOf(context).scale(1) > 1.35
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 5),
                Text(value, style: Theme.of(context).textTheme.titleSmall),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
    );
  }
}

class HelpAudioButton extends StatelessWidget {
  final bool reviewedAssetAvailable;
  final String label;
  final VoidCallback? play;
  const HelpAudioButton({
    super.key,
    required this.reviewedAssetAvailable,
    required this.label,
    this.play,
  });
  @override
  Widget build(BuildContext context) => reviewedAssetAvailable && play != null
      ? IconButton(
          tooltip: label,
          onPressed: play,
          icon: const Icon(Icons.volume_up_outlined),
        )
      : const SizedBox.shrink();
}
