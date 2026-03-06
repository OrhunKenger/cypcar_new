import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/features/auth/presentation/providers/auth_provider.dart';
import 'package:cypcar/shared/models/app_settings_model.dart';

class CypCarBottomNav extends ConsumerWidget {
  final int currentIndex;
  final AppSettings? settings;
  /// Sağlanırsa context.go() yerine bu callback kullanılır (MainTabsScreen için)
  final void Function(int)? onTabTap;

  const CypCarBottomNav({
    super.key,
    required this.currentIndex,
    this.settings,
    this.onTabTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaid = settings?.isPaidFeaturesEnabled ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final iconColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            width: 0.5,
          ),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Favoriler
              _NavItem(
                icon: Icons.favorite_border,
                activeIcon: Icons.favorite,
                label: 'Favoriler',
                isActive: currentIndex == 0,
                iconColor: iconColor,
                onTap: () => onTabTap != null ? onTabTap!(0) : context.go('/favorites'),
              ),

              // Ana Sayfa (ortada, yüksek)
              const SizedBox(width: 64),

              // Ücretli açıksa Acil (Ana Sayfa'nın sağında, biraz yüksek)
              if (isPaid)
                _UrgentButton(
                  onTap: () {
                    final isLoggedIn = ref.read(authProvider.notifier).isLoggedIn;
                    if (!isLoggedIn) {
                      context.push('/login');
                      return;
                    }
                    // TODO: Acil ilanlar sayfası
                  },
                )
              else
                // İlan Ver
                _NavItem(
                  icon: Icons.add_box_outlined,
                  activeIcon: Icons.add_box,
                  label: 'İlan Ver',
                  isActive: currentIndex == 2,
                  iconColor: iconColor,
                  onTap: () {
                    if (onTabTap != null) {
                      onTabTap!(2);
                      return;
                    }
                    final isLoggedIn = ref.read(authProvider.notifier).isLoggedIn;
                    if (!isLoggedIn) {
                      context.push('/login');
                      return;
                    }
                    context.push('/create-listing');
                  },
                ),

              // Ücretli açıksa İlan Ver sağa eklenir
              if (isPaid)
                _NavItem(
                  icon: Icons.add_box_outlined,
                  activeIcon: Icons.add_box,
                  label: 'İlan Ver',
                  isActive: currentIndex == 3,
                  iconColor: iconColor,
                  onTap: () {
                    if (onTabTap != null) {
                      onTabTap!(2);
                      return;
                    }
                    final isLoggedIn = ref.read(authProvider.notifier).isLoggedIn;
                    if (!isLoggedIn) {
                      context.push('/login');
                      return;
                    }
                    context.push('/create-listing');
                  },
                ),
            ],
          ),

          // Ana Sayfa butonu — ortada, yükseltilmiş
          Positioned(
            top: -20,
            child: _HomeButton(
              isActive: currentIndex == 1,
              onTap: () => onTabTap != null ? onTabTap!(1) : context.go('/'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final Color iconColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primary : iconColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppTheme.primary : iconColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _HomeButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.home_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            'Ana Sayfa',
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppTheme.primary : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentButton extends StatelessWidget {
  final VoidCallback onTap;
  const _UrgentButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 3),
          const Text(
            'Acil',
            style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
