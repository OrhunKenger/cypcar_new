import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/features/auth/presentation/providers/auth_provider.dart';
import 'package:cypcar/features/notifications/domain/models/notification_model.dart';
import 'package:cypcar/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:cypcar/shared/models/app_settings_model.dart';
import 'package:cypcar/shared/providers/app_settings_provider.dart';
import 'package:cypcar/shared/widgets/bottom_nav_bar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final settings = ref.watch(appSettingsProvider).valueOrNull ?? AppSettings.defaults();

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bildirimler')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Bildirimleri görmek için\ngiriş yapman gerekiyor.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Giriş Yap'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CypCarBottomNav(currentIndex: -1, settings: settings),
      );
    }

    final state = ref.watch(notificationsProvider);
    final hasUnread = state.items.any((n) => !n.isRead);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            title: const Text(
              'Bildirimler',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            actions: [
              if (hasUnread)
                TextButton(
                  onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
                  child: const Text(
                    'Tümünü Oku',
                    style: TextStyle(color: AppTheme.primary, fontSize: 13),
                  ),
                ),
            ],
          ),
          if (state.isLoading && state.items.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else if (state.error != null && state.items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Bildirimler yüklenemedi'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(notificationsProvider.notifier).fetch(),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            )
          else if (state.items.isEmpty)
            const SliverFillRemaining(child: _EmptyNotifications())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == state.items.length) {
                    return state.hasMore
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: TextButton(
                                onPressed: () =>
                                    ref.read(notificationsProvider.notifier).loadMore(),
                                child: state.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primary,
                                        ),
                                      )
                                    : const Text('Daha Fazla Yükle'),
                              ),
                            ),
                          )
                        : const SizedBox(height: 100);
                  }
                  return _NotificationTile(notification: state.items[index]);
                },
                childCount: state.items.length + 1,
              ),
            ),
        ],
      ),
      bottomNavigationBar: CypCarBottomNav(currentIndex: -1, settings: settings),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFF5F5);
    final readBg = isDark ? AppTheme.backgroundDark : Colors.white;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade700,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => ref.read(notificationsProvider.notifier).delete(notification.id),
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            ref.read(notificationsProvider.notifier).markRead(notification.id);
          }
          _handleTap(context, notification);
        },
        child: Container(
          color: notification.isRead ? readBg : unreadBg,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NotificationIcon(type: notification.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (!notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            notification.body,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatTime(notification.createdAt),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, AppNotification n) {
    final data = n.data;
    if (data == null) return;

    switch (n.type) {
      case 'LISTING_FAVORITED':
      case 'LISTING_APPROVED':
      case 'LISTING_REJECTED':
      case 'LISTING_EXPIRING_SOON':
      case 'LISTING_EXPIRED':
      case 'FAVORITE_PRICE_DECREASED':
      case 'FAVORITE_PRICE_INCREASED':
        final listingId = data['listing_id'] as String?;
        if (listingId != null) context.push('/listing/$listingId');
      case 'PROFILE_VIEWED':
        final userId = data['viewer_id'] as String?;
        if (userId != null) context.push('/profile/$userId');
      default:
        break;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return DateFormat('d MMM').format(dt);
  }
}

class _NotificationIcon extends StatelessWidget {
  final String type;

  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconData(type);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  (IconData, Color) _iconData(String type) {
    switch (type) {
      case 'LISTING_FAVORITED':
        return (Icons.favorite, AppTheme.primary);
      case 'PROFILE_VIEWED':
        return (Icons.visibility, Colors.blue);
      case 'FAVORITE_PRICE_DECREASED':
        return (Icons.trending_down, Colors.green);
      case 'FAVORITE_PRICE_INCREASED':
        return (Icons.trending_up, Colors.orange);
      case 'LISTING_APPROVED':
        return (Icons.check_circle, Colors.green);
      case 'LISTING_REJECTED':
        return (Icons.cancel, AppTheme.primary);
      case 'LISTING_EXPIRING_SOON':
        return (Icons.timer, Colors.orange);
      case 'LISTING_EXPIRED':
        return (Icons.timer_off, Colors.grey);
      default:
        return (Icons.notifications, Colors.grey);
    }
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Henüz bildirim yok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlan favorilendi, fiyat değişimi gibi\ngelişmeleri buradan takip edebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
