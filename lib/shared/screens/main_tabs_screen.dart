import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cypcar/features/auth/presentation/providers/auth_provider.dart';
import 'package:cypcar/features/create_listing/presentation/providers/create_listing_provider.dart';
import 'package:cypcar/features/create_listing/presentation/screens/create_listing_screen.dart';
import 'package:cypcar/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:cypcar/features/home/presentation/screens/home_screen.dart';
import 'package:cypcar/shared/models/app_settings_model.dart';
import 'package:cypcar/shared/providers/app_settings_provider.dart';
import 'package:cypcar/shared/widgets/bottom_nav_bar.dart';

class MainTabsScreen extends ConsumerStatefulWidget {
  const MainTabsScreen({super.key});

  @override
  ConsumerState<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends ConsumerState<MainTabsScreen> {
  late final PageController _pageController;
  int _currentIndex = 1; // Ana Sayfa (ortada)

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    // İlan Ver sekmesi için auth kontrolü
    if (index == 2) {
      final isLoggedIn = ref.read(authProvider.notifier).isLoggedIn;
      if (!isLoggedIn) {
        context.push('/login');
        return;
      }
    }
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    // Kullanıcı kaydırarak İlan Ver sekmesine gelirse auth kontrolü
    if (index == 2) {
      final isLoggedIn = ref.read(authProvider.notifier).isLoggedIn;
      if (!isLoggedIn) {
        // Auth yoksa geri Ana Sayfa'ya döndür
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
        context.push('/login');
        return;
      }
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final clState = ref.watch(clProvider);
    final settings =
        ref.watch(appSettingsProvider).valueOrNull ?? AppSettings.defaults();

    final isCreateListingTab = _currentIndex == 2;
    final clOnVehicleStep = clState.step == CLStep.vehicle;

    // Kaydırma kilidi: İlan Ver'de adım 1+'da kaydırma yasak
    final canSwipe = !isCreateListingTab || clOnVehicleStep;

    // Dış BottomNav: İlan Ver adım 1+'da gizle (CreateListing kendi "İleri" butonunu gösterir)
    final showOuterBottomNav = !isCreateListingTab || clOnVehicleStep;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: canSwipe
            ? const PageScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          // Index 0 — Favoriler
          FavoritesScreen(
            showBottomNav: false,
            onBrowseListings: () => _onTabTap(1),
          ),

          // Index 1 — Ana Sayfa
          const HomeScreen(showBottomNav: false),

          // Index 2 — İlan Ver
          CreateListingScreen(
            onCloseInTabs: () => _onTabTap(1),
          ),
        ],
      ),
      bottomNavigationBar: showOuterBottomNav
          ? CypCarBottomNav(
              currentIndex: _currentIndex,
              settings: settings,
              onTabTap: _onTabTap,
            )
          : null,
    );
  }
}
