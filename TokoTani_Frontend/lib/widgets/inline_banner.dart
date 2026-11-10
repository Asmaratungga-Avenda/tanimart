import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/utils/order_status.dart';

/// Pesan inline (galat / info) dengan aksi opsional.
class InlineBanner extends StatelessWidget {
  const InlineBanner({
    super.key,
    required this.message,
    this.title,
    this.tone = StatusTone.danger,
    this.icon = Icons.error_outline_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? title;
  final StatusTone tone;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = context.palette.tonePair(tone);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: text.titleSmall?.copyWith(color: foreground),
                  ),
                Text(
                  message,
                  style: text.bodySmall?.copyWith(color: p.textPrimary),
                ),
                if (actionLabel != null && onAction != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: InkWell(
                      onTap: onAction,
                      child: Text(
                        actionLabel!,
                        style: text.labelMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
