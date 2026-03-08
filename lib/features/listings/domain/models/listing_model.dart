class VehicleMakeInfo {
  final String id;
  final String name;
  final String? logoUrl;
  VehicleMakeInfo({required this.id, required this.name, this.logoUrl});
  factory VehicleMakeInfo.fromJson(Map<String, dynamic> j) =>
      VehicleMakeInfo(id: j['id'], name: j['name'], logoUrl: j['make_logo_url']);
}

class VehicleSeriesInfo {
  final String id;
  final String name;
  VehicleSeriesInfo({required this.id, required this.name});
  factory VehicleSeriesInfo.fromJson(Map<String, dynamic> j) =>
      VehicleSeriesInfo(id: j['id'], name: j['name']);
}

class VehicleModelInfo {
  final String id;
  final String name;
  VehicleModelInfo({required this.id, required this.name});
  factory VehicleModelInfo.fromJson(Map<String, dynamic> j) =>
      VehicleModelInfo(id: j['id'], name: j['name']);
}

class Listing {
  final String id;
  final double price;
  final String currency; // TRY | GBP
  final bool isNegotiable;
  final String status;
  final String condition;
  final String? location;
  final int? year;
  final int? mileage;
  final String? transmission;
  final String? fuelType;
  final String? driveType;
  final String? vehicleType;
  final int? engineCc;
  final String boostType; // NONE | HOMEPAGE | URGENT
  final String category;
  final VehicleMakeInfo make;
  final VehicleSeriesInfo series;
  final VehicleModelInfo? model;
  final List<String> images;
  final bool isFavorited;
  final String userId;
  final int viewCount;
  final DateTime createdAt;
  final DateTime expiresAt;

  Listing({
    required this.id,
    required this.price,
    required this.currency,
    required this.isNegotiable,
    required this.status,
    required this.condition,
    this.location,
    this.year,
    this.mileage,
    this.transmission,
    this.fuelType,
    this.driveType,
    this.vehicleType,
    this.engineCc,
    required this.boostType,
    required this.category,
    required this.make,
    required this.series,
    this.model,
    required this.images,
    required this.isFavorited,
    required this.userId,
    required this.viewCount,
    required this.createdAt,
    required this.expiresAt,
  });

  factory Listing.fromJson(Map<String, dynamic> j) => Listing(
        id: j['id'],
        price: double.parse(j['price'].toString()),
        currency: j['currency'] ?? 'TRY',
        isNegotiable: j['is_negotiable'] ?? false,
        status: j['status'] ?? '',
        condition: j['condition'] ?? '',
        location: j['location'],
        year: j['year'],
        mileage: j['mileage'],
        transmission: j['transmission'],
        fuelType: j['fuel_type'],
        driveType: j['drive_type'],
        vehicleType: j['vehicle_type'],
        engineCc: j['engine_cc'],
        boostType: j['boost_type'] ?? 'NONE',
        category: j['category'] ?? '',
        make: VehicleMakeInfo(
          id: j['make_id'] ?? '',
          name: j['make_name'] ?? '',
          logoUrl: j['make_logo_url'],
        ),
        series: VehicleSeriesInfo(id: j['series_id'] ?? '', name: j['series_name'] ?? ''),
        model: j['model_id'] != null ? VehicleModelInfo(id: j['model_id'], name: j['model_name'] ?? '') : null,
        images: (j['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
        isFavorited: j['is_favorited'] ?? false,
        userId: j['user_id'] ?? '',
        viewCount: j['view_count'] ?? 0,
        createdAt: DateTime.parse(j['created_at']),
        expiresAt: DateTime.parse(j['expires_at']),
      );

  String get displayTitle {
    final parts = [make.name, series.name, if (model != null) model!.name];
    return parts.join(' ');
  }

  Listing copyWith({bool? isFavorited, int? viewCount}) => Listing(
        id: id,
        price: price,
        currency: currency,
        isNegotiable: isNegotiable,
        status: status,
        condition: condition,
        location: location,
        year: year,
        mileage: mileage,
        transmission: transmission,
        fuelType: fuelType,
        driveType: driveType,
        vehicleType: vehicleType,
        engineCc: engineCc,
        boostType: boostType,
        category: category,
        make: make,
        series: series,
        model: model,
        images: images,
        isFavorited: isFavorited ?? this.isFavorited,
        userId: userId,
        viewCount: viewCount ?? this.viewCount,
        createdAt: createdAt,
        expiresAt: expiresAt,
      );
}

class ListingDetail {
  final String id;
  final String? title;
  final String? description;
  final double price;
  final String currency;
  final bool isNegotiable;
  final String status;
  final String condition;
  final String? location;
  final int? year;
  final int? mileage;
  final String? color;
  final String? transmission;
  final String? fuelType;
  final String? driveType;
  final String? vehicleType;
  final int? engineCc;
  final String boostType;
  final String category;
  final VehicleMakeInfo make;
  final VehicleSeriesInfo series;
  final VehicleModelInfo? model;
  final List<String> images;
  bool isFavorited;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String? userPhone;
  final String? userWhatsapp;
  final int viewCount;
  final DateTime createdAt;
  final DateTime expiresAt;

  ListingDetail({
    required this.id,
    this.title,
    this.description,
    required this.price,
    required this.currency,
    required this.isNegotiable,
    required this.status,
    required this.condition,
    this.location,
    this.year,
    this.mileage,
    this.color,
    this.transmission,
    this.fuelType,
    this.driveType,
    this.vehicleType,
    this.engineCc,
    required this.boostType,
    required this.category,
    required this.make,
    required this.series,
    this.model,
    required this.images,
    required this.isFavorited,
    required this.userId,
    required this.userName,
    this.userPhoto,
    this.userPhone,
    this.userWhatsapp,
    required this.viewCount,
    required this.createdAt,
    required this.expiresAt,
  });

  String get displayTitle {
    final parts = <String>[make.name, series.name];
    if (model != null) parts.add(model!.name);
    return parts.join(' ');
  }

  factory ListingDetail.fromJson(Map<String, dynamic> j) => ListingDetail(
        id: j['id'],
        title: j['title'],
        description: j['description'],
        price: double.parse(j['price'].toString()),
        currency: j['currency'] ?? 'TRY',
        isNegotiable: j['is_negotiable'] ?? false,
        status: j['status'] ?? '',
        condition: j['condition'] ?? '',
        location: j['location'],
        year: j['year'],
        mileage: j['mileage'],
        color: j['color'],
        transmission: j['transmission'],
        fuelType: j['fuel_type'],
        driveType: j['drive_type'],
        vehicleType: j['vehicle_type'],
        engineCc: j['engine_cc'],
        boostType: j['boost_type'] ?? 'NONE',
        category: j['category'] ?? '',
        make: VehicleMakeInfo(
          id: j['make_id'] ?? '',
          name: j['make_name'] ?? '',
          logoUrl: j['make_logo_url'],
        ),
        series: VehicleSeriesInfo(id: j['series_id'] ?? '', name: j['series_name'] ?? ''),
        model: j['model_id'] != null ? VehicleModelInfo(id: j['model_id'], name: j['model_name'] ?? '') : null,
        images: (j['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
        isFavorited: j['is_favorited'] ?? false,
        userId: j['user_id'] ?? '',
        userName: j['owner_name'] ?? 'Satıcı',
        userPhoto: j['owner_photo_url'],
        userPhone: j['owner_phone'],
        userWhatsapp: j['owner_whatsapp'],
        viewCount: j['view_count'] ?? 0,
        createdAt: DateTime.parse(j['created_at']),
        expiresAt: DateTime.parse(j['expires_at']),
      );

  ListingDetail copyWith({bool? isFavorited}) => ListingDetail(
        id: id,
        title: title,
        description: description,
        price: price,
        currency: currency,
        isNegotiable: isNegotiable,
        status: status,
        condition: condition,
        location: location,
        year: year,
        mileage: mileage,
        color: color,
        transmission: transmission,
        fuelType: fuelType,
        driveType: driveType,
        vehicleType: vehicleType,
        engineCc: engineCc,
        boostType: boostType,
        category: category,
        make: make,
        series: series,
        model: model,
        images: images,
        isFavorited: isFavorited ?? this.isFavorited,
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        userPhone: userPhone,
        userWhatsapp: userWhatsapp,
        viewCount: viewCount,
        createdAt: createdAt,
        expiresAt: expiresAt,
      );
}

class PaginatedListings {
  final List<Listing> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  PaginatedListings({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  factory PaginatedListings.fromJson(Map<String, dynamic> j) => PaginatedListings(
        items: (j['items'] as List).map((e) => Listing.fromJson(e)).toList(),
        total: j['total'] ?? 0,
        page: j['page'] ?? 1,
        size: j['size'] ?? 20,
        pages: j['pages'] ?? 1,
      );
}
