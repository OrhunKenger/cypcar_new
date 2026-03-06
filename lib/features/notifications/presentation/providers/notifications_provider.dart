import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/features/notifications/domain/models/notification_model.dart';
import 'package:cypcar/features/notifications/data/notifications_repository.dart';

// Unread count — lightweight, used in app bar badge
final notificationUnreadCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.fetchUnreadCount();
});

// Full list state
class NotificationsState {
  final List<AppNotification> items;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const NotificationsState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  NotificationsState copyWith({
    List<AppNotification>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repo;
  final Ref _ref;

  NotificationsNotifier(this._repo, this._ref) : super(const NotificationsState());

  Future<void> fetch() async {
    state = const NotificationsState(isLoading: true);
    try {
      final result = await _repo.fetchNotifications(page: 1);
      state = NotificationsState(
        items: result.items,
        isLoading: false,
        hasMore: result.page < result.pages,
        currentPage: 1,
      );
    } catch (e) {
      state = NotificationsState(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repo.fetchNotifications(page: nextPage);
      state = state.copyWith(
        items: [...state.items, ...result.items],
        isLoading: false,
        hasMore: nextPage < result.pages,
        currentPage: nextPage,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markRead(String id) async {
    // Optimistic update
    state = state.copyWith(
      items: state.items.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
    );
    try {
      await _repo.markRead(id);
      _ref.invalidate(notificationUnreadCountProvider);
    } catch (_) {
      // rollback
      state = state.copyWith(
        items: state.items.map((n) => n.id == id ? n.copyWith(isRead: false) : n).toList(),
      );
    }
  }

  Future<void> markAllRead() async {
    final prev = state.items;
    state = state.copyWith(
      items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
    );
    try {
      await _repo.markAllRead();
      _ref.invalidate(notificationUnreadCountProvider);
    } catch (_) {
      state = state.copyWith(items: prev);
    }
  }

  Future<void> delete(String id) async {
    final prev = state.items;
    state = state.copyWith(items: state.items.where((n) => n.id != id).toList());
    try {
      await _repo.deleteNotification(id);
      _ref.invalidate(notificationUnreadCountProvider);
    } catch (_) {
      state = state.copyWith(items: prev);
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  final notifier = NotificationsNotifier(repo, ref);
  notifier.fetch();
  return notifier;
});
