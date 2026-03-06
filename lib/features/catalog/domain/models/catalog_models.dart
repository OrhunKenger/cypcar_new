class MakeModel {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final bool isActive;

  MakeModel({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    required this.isActive,
  });

  factory MakeModel.fromJson(Map<String, dynamic> j) => MakeModel(
        id: j['id'],
        name: j['name'],
        slug: j['slug'] ?? '',
        logoUrl: j['logo_url'],
        isActive: j['is_active'] ?? true,
      );
}

class SeriesModel {
  final String id;
  final String name;
  final String slug;
  final String category;
  final bool isActive;

  SeriesModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.category,
    required this.isActive,
  });

  factory SeriesModel.fromJson(Map<String, dynamic> j) => SeriesModel(
        id: j['id'],
        name: j['name'],
        slug: j['slug'] ?? '',
        category: j['category'] ?? '',
        isActive: j['is_active'] ?? true,
      );
}

class VehicleModelModel {
  final String id;
  final String name;
  final String slug;
  final bool isActive;

  VehicleModelModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
  });

  factory VehicleModelModel.fromJson(Map<String, dynamic> j) => VehicleModelModel(
        id: j['id'],
        name: j['name'],
        slug: j['slug'] ?? '',
        isActive: j['is_active'] ?? true,
      );
}
