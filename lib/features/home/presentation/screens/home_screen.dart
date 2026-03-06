import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cypcar/core/providers/currency_provider.dart';
import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/core/theme/theme_provider.dart';
import 'package:cypcar/features/auth/domain/models/user_model.dart';
import 'package:cypcar/features/auth/presentation/providers/auth_provider.dart';
import 'package:cypcar/features/listings/presentation/providers/listings_provider.dart';
import 'package:cypcar/shared/models/app_settings_model.dart';
import 'package:cypcar/shared/models/exchange_rate_model.dart';
import 'package:cypcar/shared/providers/app_settings_provider.dart';
import 'package:cypcar/shared/providers/catalog_provider.dart';
import 'package:cypcar/shared/providers/exchange_rate_provider.dart';
import 'package:cypcar/shared/widgets/bottom_nav_bar.dart';
import 'package:cypcar/shared/widgets/listing_card.dart';

// Kategori görsel bilgileri
const _categoryMeta = {
  'OTOMOBIL': (label: 'Otomobil', icon: Icons.directions_car_rounded),
  'ARAZI_SUV_PICKUP': (label: 'Arazi & SUV', icon: Icons.terrain_rounded),
  'MOTORSIKLET': (label: 'Motorsiklet', icon: Icons.two_wheeler_rounded),
  'TICARI': (label: 'Ticari', icon: Icons.local_shipping_rounded),
};

class HomeScreen extends ConsumerWidget {
  final bool showBottomNav;
  const HomeScreen({super.key, this.showBottomNav = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final listingsState = ref.watch(recentListingsProvider);
    final featuredState = ref.watch(featuredListingsProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final exchangeAsync = ref.watch(exchangeRateProvider);
    final displayCurrency = ref.watch(currencyProvider);

    final settings = settingsAsync.valueOrNull ?? AppSettings.defaults();
    final exchangeRate = exchangeAsync.valueOrNull ?? ExchangeRate.fallback();
    final isPaid = settings.isPaidFeaturesEnabled;
    final user = authState.valueOrNull;

    final displayListings = isPaid
        ? featuredState.valueOrNull ?? []
        : listingsState.valueOrNull ?? [];
    final isLoading = isPaid ? featuredState.isLoading : listingsState.isLoading;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            toolbarHeight: 56,
            titleSpacing: 16,
            title: const _CypCarLogo(),
            actions: [
              _CurrencyToggle(displayCurrency: displayCurrency, rate: exchangeRate),
              const SizedBox(width: 4),
              const _ThemeToggle(),
              _NotificationButton(onTap: () {
                if (user == null) { context.push('/login'); return; }
                context.push('/notifications');
              }),
              const SizedBox(width: 8),
            ],
          ),

          // ── Profil ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _ProfileSection(user: user),
            ),
          ),

          // ── Araç Tipi Kartları ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Arama',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _VehicleTypeCards(),
                ],
              ),
            ),
          ),

          // ── Bölüm Başlığı ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
              child: Row(
                children: [
                  if (isPaid)
                    const Icon(Icons.bolt, color: AppTheme.primary, size: 18),
                  Text(
                    isPaid ? ' Öne Çıkan İlanlar' : 'Son Eklenen İlanlar',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),

          // ── İlan Grid ─────────────────────────────────────────────
          if (isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              ),
            )
          else if (displayListings.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: Text('Henüz ilan yok')),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ListingCard(
                    listing: displayListings[index],
                    exchangeRate: exchangeRate,
                    settings: settings,
                  ),
                  childCount: displayListings.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: showBottomNav
          ? CypCarBottomNav(currentIndex: 1, settings: settings)
          : null,
    );
  }
}

// ── Logo ──────────────────────────────────────────────────────────────────────

class _CypCarLogo extends StatelessWidget {
  const _CypCarLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/app_logo.png',
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'CypCar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

// ── Döviz Butonu ──────────────────────────────────────────────────────────────

class _CurrencyToggle extends ConsumerWidget {
  final String displayCurrency;
  final ExchangeRate rate;
  const _CurrencyToggle({required this.displayCurrency, required this.rate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => ref.read(currencyProvider.notifier).state =
          displayCurrency == 'TRY' ? 'GBP' : 'TRY',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
            width: 0.5,
          ),
        ),
        child: Text(
          displayCurrency == 'TRY' ? '£  TL' : 'TL  £',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

// ── Tema Butonu ───────────────────────────────────────────────────────────────

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 22,
      ),
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}

// ── Bildirimler ───────────────────────────────────────────────────────────────

class _NotificationButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NotificationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_outlined, size: 24),
      onPressed: onTap,
    );
  }
}

// ── Profil Bölümü ─────────────────────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  final UserModel? user;
  const _ProfileSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardDark : AppTheme.cardLight;

    if (user != null) {
      return GestureDetector(
        onTap: () => context.push('/profile/${user!.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                backgroundImage: user!.profilePhotoUrl != null
                    ? NetworkImage(user!.profilePhotoUrl!)
                    : null,
                child: user!.profilePhotoUrl == null
                    ? Text(
                        user!.fullName.isNotEmpty
                            ? user!.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoş geldin,',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                    Text(
                      user!.fullName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ],
          ),
        ),
      );
    }

    // ── Giriş yapılmamış ──────────────────────────────────────────
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                child: Icon(
                  Icons.person_outline,
                  color: isDark ? Colors.white38 : Colors.black26,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Kıbrıs\'ın araç platformuna\nhoş geldin!',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.4),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Giriş Yap',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => context.push('/register'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Kayıt Ol',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Araç Tipi Kartları ────────────────────────────────────────────────────────

class _VehicleTypeCards extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return categoriesAsync.when(
      loading: () => _buildGrid(context, isDark, _categoryMeta.keys.toList()),
      error: (_, __) => _buildGrid(context, isDark, _categoryMeta.keys.toList()),
      data: (cats) => _buildGrid(context, isDark, cats),
    );
  }

  Widget _buildGrid(BuildContext context, bool isDark, List<String> categories) {
    final cardColor = isDark ? AppTheme.cardDark : AppTheme.cardLight;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: categories.map((cat) {
        final meta = _categoryMeta[cat];
        final label = meta?.label ?? cat;
        final icon = meta?.icon ?? Icons.directions_car;

        return GestureDetector(
          onTap: () => context.push('/search?category=$cat'),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
