import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cypcar/core/providers/currency_provider.dart';
import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/features/auth/presentation/providers/auth_provider.dart';
import 'package:cypcar/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:cypcar/features/listings/data/listings_repository.dart';
import 'package:cypcar/features/listings/domain/models/listing_model.dart';
import 'package:cypcar/features/listings/presentation/providers/listings_provider.dart';
import 'package:cypcar/shared/models/exchange_rate_model.dart';
import 'package:cypcar/shared/models/app_settings_model.dart';

class ListingCard extends ConsumerWidget {
  final Listing listing;
  final ExchangeRate? exchangeRate;
  final AppSettings? settings;

  const ListingCard({
    super.key,
    required this.listing,
    this.exchangeRate,
    this.settings,
  });

  String _formatPrice(BuildContext context, String displayCurrency) {
    double displayPrice = listing.price;

    if (listing.currency != displayCurrency && exchangeRate != null) {
      if (listing.currency == 'TRY' && displayCurrency == 'GBP') {
        displayPrice = listing.price * exchangeRate!.tryToGbp;
      } else if (listing.currency == 'GBP' && displayCurrency == 'TRY') {
        displayPrice = listing.price * exchangeRate!.gbpToTry;
      }
    }

    if (displayCurrency == 'TRY') {
      if (displayPrice >= 1000000) {
        return '${(displayPrice / 1000000).toStringAsFixed(2)} M ₺';
      } else if (displayPrice >= 1000) {
        return '${NumberFormat('#,###', 'tr_TR').format(displayPrice.toInt())} ₺';
      }
      return '${displayPrice.toStringAsFixed(0)} ₺';
    } else {
      return '£${NumberFormat('#,###').format(displayPrice.toInt())}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayCurrency = ref.watch(currencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final textPrimary = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final textSecondary = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final isPaidEnabled = settings?.isPaidFeaturesEnabled ?? false;
    final hasBoost = isPaidEnabled && listing.boostType != 'NONE';

    return GestureDetector(
      onTap: () => context.push('/listing/${listing.id}', extra: listing),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Görsel ────────────────────────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Arkaplan
                  Hero(
                    tag: 'listing_img_${listing.id}',
                    child: listing.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: listing.images.first,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _imagePlaceholder(isDark),
                            errorWidget: (_, __, ___) => _imagePlaceholder(isDark),
                          )
                        : _imagePlaceholder(isDark),
                  ),

                  // BOOST badge
                  if (hasBoost)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: Colors.white, size: 11),
                            const SizedBox(width: 2),
                            Text(
                              'BOOST',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Favori butonu
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _FavoriteButton(listing: listing),
                  ),

                  // İstatistikler (İzlenme & Fotoğraf)
                  Positioned(
                    bottom: 6,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // İzlenme sayısı
                          const Icon(Icons.visibility, color: Colors.white, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            '${listing.viewCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                          const SizedBox(width: 6),
                          const Text('|', style: TextStyle(color: Colors.white38, fontSize: 10)),
                          const SizedBox(width: 6),
                          // Fotoğraf sayısı
                          const Icon(Icons.camera_alt, color: Colors.white, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            '${listing.images.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bilgiler ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Text(
                    listing.displayTitle,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5),

                  // Yıl | km | vites
                  Row(
                    children: [
                      if (listing.year != null) ...[
                        Icon(Icons.calendar_today_outlined, size: 12.5, color: textSecondary),
                        const SizedBox(width: 3),
                        Text('${listing.year}', style: TextStyle(fontSize: 12, color: textSecondary)),
                        const SizedBox(width: 8),
                      ],
                      if (listing.mileage != null) ...[
                        Icon(Icons.speed_outlined, size: 12.5, color: textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '${NumberFormat('#,###', 'tr_TR').format(listing.mileage)} km',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Fiyat
                  Text(
                    _formatPrice(context, displayCurrency),
                    style: TextStyle(
                      color: displayCurrency == 'GBP'
                          ? const Color(0xFFB8960A)
                          : AppTheme.primary,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Konum
                  if (listing.location != null)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12.5, color: textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            listing.location!,
                            style: TextStyle(fontSize: 12, color: textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(bool isDark) => Container(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
        child: Center(
          child: Icon(
            Icons.directions_car,
            size: 40,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      );
}

class _FavoriteButton extends ConsumerStatefulWidget {
  final Listing listing;
  const _FavoriteButton({required this.listing});

  @override
  ConsumerState<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<_FavoriteButton> {
  late bool _isFav;

  @override
  void initState() {
    super.initState();
    _isFav = widget.listing.isFavorited;
  }

  Future<void> _toggle() async {
    final isLoggedIn = ref.read(authProvider.notifier).isLoggedIn;
    if (!isLoggedIn) {
      context.push('/login');
      return;
    }
    setState(() => _isFav = !_isFav);
    try {
      await ref.read(listingsRepositoryProvider).toggleFavorite(widget.listing.id);
      ref.read(recentListingsProvider.notifier).updateFavorite(widget.listing.id, _isFav);
      // Refresh favorites list if it exists
      ref.invalidate(favoritesProvider);
    } catch (_) {
      setState(() => _isFav = !_isFav);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isFav ? Icons.favorite : Icons.favorite_border,
          color: _isFav ? AppTheme.primary : Colors.white,
          size: 16,
        ),
      ),
    );
  }
}
