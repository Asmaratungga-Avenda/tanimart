import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../services/notification_service.dart';
import 'order_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const _primaryGreen = AppTheme.primaryGreen;
  static const _lightGreen = AppTheme.lightGreen;
  static const _textPrimary = AppTheme.textPrimary;
  static const _textSecondary = AppTheme.textSecondary;

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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Notifikasi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: NotificationService.unreadCountNotifier,
            builder: (context, unread, _) {
              if (unread == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () {
                  setState(() {
                    NotificationService.markAllAsRead();
                  });
                },
                icon: const Icon(Icons.done_all_rounded,
                    color: Colors.white, size: 18),
                label: Text(
                  'Tandai Dibaca',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) {
              if (val == 'clear') {
                setState(() {
                  NotificationService.clearAll();
                });
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Hapus Semua Notifikasi'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: NotificationService.unreadCountNotifier,
        builder: (context, unreadCount, child) {
          final items = NotificationService.notifications;
          if (items.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final notif = items[i];
              return _buildNotificationCard(notif);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: _primaryGreen,
                size: 56,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Belum Ada Notifikasi',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pemberitahuan status pesanan dan penawaran terbaik akan muncul di sini secara langsung.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: _textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotificationItem notif) {
    return InkWell(
      onTap: () {
        setState(() {
          NotificationService.markAsRead(notif.id);
        });

        if (notif.orderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailPage(orderId: notif.orderId!),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? const Color(0xFFE5E7EB)
                : _primaryGreen.withValues(alpha: 0.35),
            width: notif.isRead ? 0.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notif.isRead
                    ? Colors.grey.shade100
                    : _primaryGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notif.type == 'order'
                    ? Icons.shopping_bag_rounded
                    : Icons.notifications_active_rounded,
                color: notif.isRead ? Colors.grey.shade600 : _primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                      if (!notif.isRead) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(notif.time),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (notif.orderId != null)
                        Row(
                          children: [
                            Text(
                              'Lihat Detail',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _primaryGreen,
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 14, color: _primaryGreen),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

