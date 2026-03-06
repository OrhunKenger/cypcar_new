import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/core/api/api_client.dart';
import 'package:cypcar/core/api/api_endpoints.dart';
import 'package:cypcar/features/catalog/domain/models/catalog_models.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(apiClientProvider));
});

class CatalogRepository {
  final ApiClient _client;
  CatalogRepository(this._client);

  Future<List<String>> fetchCategories() async {
    final response = await _client.dio.get(ApiEndpoints.categories);
    return (response.data as List).map((e) {
      // Backend {value: "OTOMOBIL", label: "Otomobil"} objesi dönüyor
      if (e is Map) return e['value'].toString();
      return e.toString();
    }).toList();
  }

  Future<List<MakeModel>> fetchMakes(String category) async {
    final response = await _client.dio.get(ApiEndpoints.makesByCategory(category));
    return (response.data as List).map((e) => MakeModel.fromJson(e)).toList();
  }

  Future<List<SeriesModel>> fetchSeries(String makeId, {required String category}) async {
    final response = await _client.dio.get(
      ApiEndpoints.seriesByMake(makeId),
      queryParameters: {'category': category},
    );
    return (response.data as List).map((e) => SeriesModel.fromJson(e)).toList();
  }

  Future<List<VehicleModelModel>> fetchModels(String seriesId) async {
    final response = await _client.dio.get(ApiEndpoints.modelsBySeries(seriesId));
    return (response.data as List).map((e) => VehicleModelModel.fromJson(e)).toList();
  }
}
