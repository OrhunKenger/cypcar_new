import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/features/listings/data/listings_repository.dart';
import 'package:cypcar/features/listings/domain/models/listing_model.dart';

final recentListingsProvider = StateNotifierProvider<ListingsNotifier, AsyncValue<List<Listing>>>((ref) {
  return ListingsNotifier(ref.watch(listingsRepositoryProvider));
});

final featuredListingsProvider = FutureProvider<List<Listing>>((ref) {
  return ref.watch(listingsRepositoryProvider).fetchFeatured();
});

class ListingsNotifier extends StateNotifier<AsyncValue<List<Listing>>> {
  final ListingsRepository _repo;
  ListingsNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    try {
      state = const AsyncValue.loading();
      final items = await _repo.fetchRecent();
      if (mounted) state = AsyncValue.data(items);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void updateFavorite(String listingId, bool isFavorited) {
    state.whenData((listings) {
      state = AsyncValue.data(
        listings.map((l) => l.id == listingId ? l.copyWith(isFavorited: isFavorited) : l).toList(),
      );
    });
  }

  void updateViewCount(String listingId, int viewCount) {
    state.whenData((listings) {
      state = AsyncValue.data(
        listings.map<Listing>((l) => l.id == listingId ? l.copyWith(viewCount: viewCount) : l).toList(),
      );
    });
  }
}
