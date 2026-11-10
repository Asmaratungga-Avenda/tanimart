import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/utils/order_status.dart';

/// Lencana status berwarna. Warna selalu mengikuti tema aktif.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  factory StatusBadge.order(String status, {Key? key}) => StatusBadge(
    key: key,
    label: OrderStatus.label(status),
    tone: OrderStatus.tone(status),
  );

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = context.palette.tonePair(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
