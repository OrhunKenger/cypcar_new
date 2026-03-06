import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/core/api/api_client.dart';
import 'package:cypcar/core/api/api_endpoints.dart';
import 'package:cypcar/features/listings/domain/models/listing_model.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(apiClientProvider));
});

class FavoritesRepository {
  final ApiClient _client;
  FavoritesRepository(this._client);

  Future<List<Listing>> fetchFavorites() async {
    final response = await _client.dio.get(ApiEndpoints.favorites);
    return (response.data as List).map((e) => Listing.fromJson(e)).toList();
  }

  Future<void> toggleFavorite(String listingId) async {
    await _client.dio.post(ApiEndpoints.toggleFavorite(listingId));
  }
}
