import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';

/// Pemilih jumlah [-] n [+]. Tombol dikunci di batas [min]/[max] atau saat [busy].
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max,
    this.busy = false,
    this.compact = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;
  final bool busy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = compact ? 30.0 : 38.0;
    final canDecrease = !busy && value > min;
    final canIncrease = !busy && (max == null || value < max!);

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: 'Kurangi jumlah',
            size: size,
            onTap: canDecrease ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: compact ? 30 : 38,
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: p.brandText,
                      ),
                    )
                  : Text(
                      '$value',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: 'Tambah jumlah',
            size: size,
            onTap: canIncrease ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? p.brandText : p.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
