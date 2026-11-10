import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import 'app_button.dart';

/// Membungkus isi agar tetap bisa ditarik (pull-to-refresh) saat konten pendek.
class _CenteredScroll extends StatelessWidget {
  const _CenteredScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Keadaan galat: pesan asli dari server + tombol coba lagi.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Terjadi kendala',
    this.scrollable = true,
  });

  final String message;
  final VoidCallback? onRetry;
  final String title;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: p.dangerSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_off_rounded, size: 34, color: p.danger),
          ),
          const SizedBox(height: 16),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            message,
            style: text.bodyMedium?.copyWith(color: p.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Coba Lagi',
              icon: Icons.refresh_rounded,
              expanded: false,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
    return scrollable ? _CenteredScroll(child: body) : body;
  }
}

/// Keadaan kosong yang mengajak pengguna bertindak.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.scrollable = true,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: p.brandSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: p.brandText),
          ),
          const SizedBox(height: 18),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              style: text.bodyMedium?.copyWith(color: p.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            PrimaryButton(
              label: actionLabel!,
              expanded: false,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
    return scrollable ? _CenteredScroll(child: body) : body;
  }
}
