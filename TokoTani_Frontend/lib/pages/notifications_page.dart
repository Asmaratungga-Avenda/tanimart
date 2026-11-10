import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import 'order_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit yang lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
    return DateFormat('d MMM yyyy, HH:mm', 'id').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ValueListenableBuilder<List<AppNotificationItem>>(
        valueListenable: _listenable,
        builder: (context, notifications, _) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 80, color: colors.outlineVariant),
                  const SizedBox(height: 16),
                  const Text(
                    'Tidak Ada Notifikasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada notifikasi untuk Anda saat ini.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotificationCard(notif, colors, theme);
            },
          );
        },
      ),
    );
  }

  static final _listenable = ValueNotifier<List<AppNotificationItem>>(
    NotificationService.notifications,
  );

  Widget _buildNotificationCard(AppNotificationItem notif, ColorScheme colors, ThemeData theme) {
    final isUnread = !notif.isRead;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUnread ? colors.primary : colors.outlineVariant, width: isUnread ? 1.5 : 1),
      ),
      child: ListTile(
        onTap: () {
          if (notif.orderId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailPage(orderId: notif.orderId!),
              ),
            );
          }
          NotificationService.markAsRead(notif.id);
        },
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isUnread ? colors.primary.withValues(alpha: 0.1) : colors.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            notif.type == 'order' ? Icons.receipt_long_rounded : Icons.info_outline_rounded,
            color: isUnread ? colors.primary : colors.onSurfaceVariant,
            size: 24,
          ),
        ),
        title: Text(
          notif.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notif.message,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(notif.time),
              style: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
              )
            : null,
      ),
    );
  }
}
