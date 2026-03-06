import 'package:cypcar/features/listings/domain/models/listing_model.dart';

class PublicProfile {
  final String id;
  final String fullName;
  final String? profilePhotoUrl;
  final DateTime memberSince;
  final int totalListings;
  final int totalViews;
  final List<Listing> listings;

  const PublicProfile({
    required this.id,
    required this.fullName,
    this.profilePhotoUrl,
    required this.memberSince,
    required this.totalListings,
    required this.totalViews,
    required this.listings,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> j) => PublicProfile(
        id: j['id'],
        fullName: j['full_name'],
        profilePhotoUrl: j['profile_photo_url'],
        memberSince: DateTime.parse(j['member_since']),
        totalListings: j['total_listings'] ?? 0,
        totalViews: j['total_views'] ?? 0,
        listings: (j['listings'] as List?)
                ?.map((e) => Listing.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
