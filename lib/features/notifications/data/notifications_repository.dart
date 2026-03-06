import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/core/api/api_client.dart';
import 'package:cypcar/core/api/api_endpoints.dart';
import 'package:cypcar/features/notifications/domain/models/notification_model.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

class NotificationsRepository {
  final ApiClient _client;
  NotificationsRepository(this._client);

  Future<NotificationListResponse> fetchNotifications({int page = 1, int size = 20}) async {
    final response = await _client.dio.get(
      ApiEndpoints.notifications,
      queryParameters: {'page': page, 'size': size},
    );
    return NotificationListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> fetchUnreadCount() async {
    final response = await _client.dio.get(ApiEndpoints.notificationsUnreadCount);
    return (response.data as Map<String, dynamic>)['count'] as int;
  }

  Future<void> markRead(String id) async {
    await _client.dio.patch(ApiEndpoints.notificationMarkRead(id));
  }

  Future<void> markAllRead() async {
    await _client.dio.patch(ApiEndpoints.notificationsReadAll);
  }

  Future<void> deleteNotification(String id) async {
    await _client.dio.delete(ApiEndpoints.notificationDelete(id));
  }
}
