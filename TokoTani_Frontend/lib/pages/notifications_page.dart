import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/theme_extension.dart';
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
    final theme = AppColors.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryGreen,
        foregroundColor: theme.onPrimary,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Notifikasi',
          style: GoogleFonts.poppins(
            color: theme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ValueListenableBuilder<List<AppNotificationItem>>(
        valueListenable: _notificationsListenable,
        builder: (context, notifications, _) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: theme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak Ada Notifikasi',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada notifikasi terbaru untuk ditampilkan.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotificationCard(notif, theme);
            },
          );
        },
      ),
    );
  }

  static ValueNotifier<List<AppNotificationItem>> get _notificationsListenable {
    return _listenable;
  }

  static final _listenable = ValueNotifier<List<AppNotificationItem>>(
    NotificationService.notifications,
  );

  Widget _buildNotificationCard(AppNotificationItem notif, AppColors theme) {
    final isUnread = !notif.isRead;
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
        boxShadow: theme.softShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isUnread ? theme.primaryGreen.withValues(alpha: 0.15) : theme.lightGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            notif.type == 'order' ? Icons.receipt_rounded : Icons.info_rounded,
            color: isUnread ? theme.primaryGreen : theme.textSecondary,
            size: 24,
          ),
        ),
        title: Text(
          notif.title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              notif.message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: theme.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(notif.time),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: theme.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              )
            : null,
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
      ),
    );
  }
}
