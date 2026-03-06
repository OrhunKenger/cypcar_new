import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/features/auth/presentation/providers/auth_provider.dart';
import 'package:cypcar/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:cypcar/features/listings/domain/models/listing_model.dart';
import 'package:cypcar/shared/models/app_settings_model.dart';
import 'package:cypcar/shared/models/exchange_rate_model.dart';
import 'package:cypcar/shared/providers/app_settings_provider.dart';
import 'package:cypcar/shared/providers/exchange_rate_provider.dart';
import 'package:cypcar/shared/widgets/bottom_nav_bar.dart';
import 'package:cypcar/shared/widgets/listing_card.dart';

class FavoritesScreen extends ConsumerWidget {
  final bool showBottomNav;
  const FavoritesScreen({super.key, this.showBottomNav = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final settings = ref.watch(appSettingsProvider).valueOrNull ?? AppSettings.defaults();
    final exchangeRate = ref.watch(exchangeRateProvider).valueOrNull ?? ExchangeRate.fallback();

    // Giriş yapılmamışsa
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favoriler')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Favorilerini görmek için\ngiriş yapman gerekiyor.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Giriş Yap'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: showBottomNav
            ? CypCarBottomNav(currentIndex: 0, settings: settings)
            : null,
      );
    }

    final favState = ref.watch(favoritesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            title: const Text(
              'Favoriler',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            actions: [
              favState.maybeWhen(
                data: (list) => list.isNotEmpty
                    ? TextButton(
                        onPressed: () => ref.read(favoritesProvider.notifier).fetch(),
                        child: const Text('Yenile', style: TextStyle(color: AppTheme.primary)),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          favState.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Favoriler yüklenemedi'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(favoritesProvider.notifier).fetch(),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            ),
            data: (favorites) => favorites.isEmpty
                ? SliverFillRemaining(child: _EmptyFavorites())
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _FavoriteCard(
                          listing: favorites[index],
                          exchangeRate: exchangeRate,
                          settings: settings,
                        ),
                        childCount: favorites.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.62,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: showBottomNav
          ? CypCarBottomNav(currentIndex: 0, settings: settings)
          : null,
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Henüz favori ilanın yok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlanlara göz at ve beğendiklerini\nfavorilerine ekle.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('İlanlara Göz At'),
          ),
        ],
      ),
    );
  }
}

// ListingCard'ı wrap edip kalp butonunu favoriden çıkarma olarak override eder
class _FavoriteCard extends ConsumerWidget {
  final Listing listing;
  final ExchangeRate exchangeRate;
  final AppSettings settings;

  const _FavoriteCard({
    required this.listing,
    required this.exchangeRate,
    required this.settings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        ListingCard(
          listing: listing.copyWith(isFavorited: true),
          exchangeRate: exchangeRate,
          settings: settings,
        ),
        // Favori butonunu override et — favoriden çıkar
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _confirmRemove(context, ref),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, color: AppTheme.primary, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.cardDark
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.favorite, color: AppTheme.primary, size: 36),
            const SizedBox(height: 12),
            const Text(
              'Favoriden Çıkar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu ilanı favorilerinden çıkarmak istiyor musun?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(favoritesProvider.notifier).remove(listing.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Çıkar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
