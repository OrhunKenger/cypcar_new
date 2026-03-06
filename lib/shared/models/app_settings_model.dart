class AppSettings {
  final bool isPaidFeaturesEnabled;
  final double listingPostPrice;

  AppSettings({
    required this.isPaidFeaturesEnabled,
    required this.listingPostPrice,
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        isPaidFeaturesEnabled: j['is_paid_features_enabled'] ?? false,
        listingPostPrice: (j['listing_post_price'] as num?)?.toDouble() ?? 0.0,
      );

  factory AppSettings.defaults() =>
      AppSettings(isPaidFeaturesEnabled: false, listingPostPrice: 0);
}
