import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cypcar/core/api/api_client.dart';
import 'package:cypcar/core/api/api_endpoints.dart';
import 'package:cypcar/features/listings/domain/models/listing_model.dart';

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepository(ref.watch(apiClientProvider));
});

class ListingsRepository {
  final ApiClient _client;
  ListingsRepository(this._client);

  Future<List<Listing>> fetchRecent({int page = 1, int size = 20}) async {
    final response = await _client.dio.get(
      ApiEndpoints.listings,
      queryParameters: {
        'sort': 'newest',
        'page': page,
        'size': size,
        'status': 'ACTIVE',
      },
    );
    return PaginatedListings.fromJson(response.data).items;
  }

  Future<List<Listing>> fetchFeatured() async {
    final response = await _client.dio.get(ApiEndpoints.featured);
    return (response.data as List).map((e) => Listing.fromJson(e)).toList();
  }

  Future<void> toggleFavorite(String listingId) async {
    await _client.dio.post(ApiEndpoints.toggleFavorite(listingId));
  }

  /// Creates a listing and returns the listing ID.
  Future<Listing> createListing({
    required String category,
    required String makeId,
    required String seriesId,
    String? modelId,
    required String title,
    required String description,
    required double price,
    required int year,
    required int mileage,
    required String color,
    required String condition,
    required String location,
    required String currency,
    String? vehicleType,
    int? engineCc,
    String? driveType,
    String? fuelType,
    String? transmission,
  }) async {
    final response = await _client.dio.post(
      ApiEndpoints.listings,
      data: {
        'category': category,
        'make_id': makeId,
        'series_id': seriesId,
        if (modelId != null) 'model_id': modelId,
        'title': title,
        'description': description,
        'price': price,
        'year': year,
        'mileage': mileage,
        'color': color,
        'condition': condition,
        'location': location,
        'currency': currency,
        if (vehicleType != null) 'vehicle_type': vehicleType,
        if (engineCc != null) 'engine_cc': engineCc,
        if (driveType != null) 'drive_type': driveType,
        if (fuelType != null) 'fuel_type': fuelType,
        if (transmission != null && transmission.isNotEmpty) 'transmission': transmission,
      },
    );
    // Parse id from response (backend returns full ListingResponse)
    final id = response.data['id'] as String;
    // Return minimal Listing with id for image upload
    return _partialListing(id, response.data);
  }

  /// Uploads a single image to an existing listing.
  Future<void> uploadImage(String listingId, XFile image) async {
    final bytes = await image.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: image.name),
    });
    await _client.dio.post(
      ApiEndpoints.listingImages(listingId),
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<void> markSold(String listingId) async {
    await _client.dio.patch(ApiEndpoints.markSold(listingId));
  }

  Future<ListingDetail> fetchListingById(String id) async {
    final response = await _client.dio.get(ApiEndpoints.listingDetail(id));
    return ListingDetail.fromJson(response.data);
  }

  Future<void> reportListing(String listingId, String reason) async {
    await _client.dio.post(
      ApiEndpoints.reportListing(listingId),
      data: {'reason': reason},
    );
  }

  Listing _partialListing(String id, Map<String, dynamic> data) {
    return Listing(
      id: id,
      price: double.parse(data['price'].toString()),
      currency: data['currency'] ?? 'TRY',
      isNegotiable: false,
      status: data['status'] ?? 'PENDING_REVIEW',
      condition: data['condition'] ?? '',
      location: data['location'],
      year: data['year'],
      mileage: data['mileage'],
      transmission: data['transmission'],
      fuelType: data['fuel_type'],
      driveType: data['drive_type'],
      vehicleType: data['vehicle_type'],
      engineCc: data['engine_cc'],
      boostType: data['boost_type'] ?? 'NONE',
      category: data['category'] ?? '',
      make: VehicleMakeInfo(id: data['make_id'] ?? '', name: data['make_name'] ?? ''),
      series: VehicleSeriesInfo(id: data['series_id'] ?? '', name: data['series_name'] ?? ''),
      model: data['model_id'] != null
          ? VehicleModelInfo(id: data['model_id'], name: data['model_name'] ?? '')
          : null,
      images: (data['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isFavorited: false,
      userId: data['user_id'] ?? '',
      viewCount: data['view_count'] ?? 0,
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(data['expires_at'] ?? '') ?? DateTime.now().add(const Duration(days: 30)),
    );
  }
}
