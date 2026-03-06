import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/features/listings/data/listings_repository.dart';
import 'package:cypcar/features/listings/domain/models/listing_model.dart';

final listingDetailProvider =
    FutureProvider.family<ListingDetail, String>((ref, id) {
  return ref.watch(listingsRepositoryProvider).fetchListingById(id);
});
