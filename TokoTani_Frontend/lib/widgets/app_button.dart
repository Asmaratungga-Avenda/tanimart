import 'package:flutter/material.dart';

/// Tombol utama (hijau penuh). Saat [loading] tombol terkunci sehingga tidak
/// bisa ditekan berulang.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.trailing,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  /// Teks di sisi kanan tombol (misalnya total harga).
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: scheme.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: trailing != null ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                Text(trailing!, maxLines: 1),
              ],
            ],
          );

    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        disabledBackgroundColor: loading ? scheme.primary : null,
        disabledForegroundColor: loading ? scheme.onPrimary : null,
      ),
      child: trailing != null && !loading
          ? Row(
              children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Expanded(
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 12),
                Text(trailing!, maxLines: 1),
              ],
            )
          : child,
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Tombol sekunder (garis hijau).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
