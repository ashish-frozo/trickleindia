import 'package:flutter/material.dart';

import 'tokens.dart';

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

class DemoBanner extends StatelessWidget {
  final String text;
  const DemoBanner(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: const Color(0xffe8f3ef),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    child: Text(text, style: const TextStyle(fontSize: 14, color: teal)),
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
  Widget build(BuildContext context) =>
      TextButton(onPressed: onPressed, child: Text(label));
}

class StatusChip extends StatelessWidget {
  final String label;
  final bool warning;
  const StatusChip(this.label, {super.key, this.warning = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: warning ? const Color(0xfffff4de) : const Color(0xffe8f3ef),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          warning ? Icons.schedule : Icons.check_circle_outline,
          size: 20,
          color: warning ? const Color(0xff83510a) : teal,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: warning ? const Color(0xff83510a) : teal,
              fontSize: 14,
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
  const MoneyAmount(this.value, {super.key, this.size = 32});
  @override
  Widget build(BuildContext context) => Semantics(
    excludeSemantics: true,
    label: value,
    child: Text(
      value,
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: ink),
    ),
  );
}

class MetricCard extends StatelessWidget {
  final String label, value;
  const MetricCard({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 14)),
        const SizedBox(height: 8),
        MoneyAmount(value),
      ],
    ),
  );
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
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: color ?? Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xffd9e3dd)),
    ),
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(padding: padding, child: child),
  );
}

class EmptyState extends StatelessWidget {
  final String message;
  const EmptyState(this.message, {super.key});
  @override
  Widget build(BuildContext context) => SurfaceCard(child: Text(message));
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
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
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
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minVerticalPadding: 12,
    leading: CircleAvatar(
      backgroundColor: const Color(0xffe8f3ef),
      child: Text(name.substring(0, 1)),
    ),
    title: Text(name),
    subtitle: Text(summary),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class TransactionRow extends StatelessWidget {
  final String title, amount, date, status;
  final Widget? correction;
  const TransactionRow({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    this.correction,
  });
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        MoneyAmount(amount, size: 24),
        Text(date),
        StatusChip(status),
        ?correction,
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
      color: const Color(0xfff1f3ed),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: teal),
        title: Text(label),
        trailing: IconButton(
          tooltip: actionLabel,
          onPressed: onPressed,
          icon: const Icon(Icons.sync),
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
    title: Text(widget.title),
    content: SingleChildScrollView(child: Text(widget.summary)),
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
