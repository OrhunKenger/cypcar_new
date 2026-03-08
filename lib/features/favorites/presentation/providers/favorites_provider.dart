import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/features/favorites/data/favorites_repository.dart';
import 'package:cypcar/features/listings/domain/models/listing_model.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<Listing>>>((ref) {
  return FavoritesNotifier(ref.watch(favoritesRepositoryProvider));
});

class FavoritesNotifier extends StateNotifier<AsyncValue<List<Listing>>> {
  final FavoritesRepository _repo;

  FavoritesNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    try {
      state = const AsyncValue.loading();
      final items = await _repo.fetchFavorites();
      if (mounted) state = AsyncValue.data(items);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void updateViewCount(String listingId, int viewCount) {
    state.whenData((listings) {
      state = AsyncValue.data(
        listings.map<Listing>((l) => l.id == listingId ? l.copyWith(viewCount: viewCount) : l).toList(),
      );
    });
  }

  Future<void> remove(String listingId) async {
    // Optimistic remove
    state.whenData((list) {
      state = AsyncValue.data(list.where((l) => l.id != listingId).toList());
    });
    try {
      await _repo.toggleFavorite(listingId);
    } catch (_) {
      // Geri al
      fetch();
    }
  }
}
