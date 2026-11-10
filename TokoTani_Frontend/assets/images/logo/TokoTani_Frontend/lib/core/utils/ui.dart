import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Snackbar seragam. [error] memakai warna galat tema (terbaca di Light & Dark).
void showAppSnack(
  BuildContext context,
  String message, {
  bool error = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final scheme = Theme.of(context).colorScheme;
  final textStyle = Theme.of(context).textTheme.bodyMedium;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: error ? scheme.error : null,
        content: Text(
          message,
          style: error ? textStyle?.copyWith(color: scheme.onError) : null,
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: error ? scheme.onError : null,
                onPressed: onAction,
              )
            : null,
      ),
    );
}

/// Dialog konfirmasi. Mengembalikan true bila pengguna menyetujui.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Batal',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final p = ctx.palette;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              backgroundColor: destructive ? p.danger : null,
              foregroundColor: destructive
                  ? Theme.of(ctx).colorScheme.onError
                  : null,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
