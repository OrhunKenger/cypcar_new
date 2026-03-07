import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/listings/presentation/providers/listings_provider.dart';
import '../../../../shared/providers/app_settings_provider.dart';
import '../../../../shared/providers/catalog_provider.dart';
import '../../../../shared/providers/exchange_rate_provider.dart';

const _bgDark = Color(0xFF0D0000);
const _bgCenter = Color(0xFF3A0A06);
const _lineColor = Color(0xFF8B1A1A);
const _subtitleColor = Color(0xFF888888);
const _textNormal = Color(0xFF000000);
const _textShimmer = Color(0xFFFFFFFF);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Tüm elemanlar aynı anda belirir
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  // CC + CYPCAR aynı anda parlar
  late AnimationController _shimmerCtrl;
  late Animation<Color?> _shimmerColor;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic),
    );

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _shimmerColor = ColorTween(begin: _textNormal, end: _textShimmer).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeOut),
    );

    _warmupBackend();
    _runSequence();
  }

  /// Animasyon oynarken backend'i arka planda ısındır
  void _warmupBackend() {
    ref.read(appSettingsProvider);
    ref.read(exchangeRateProvider);
    ref.read(categoriesProvider);
    ref.read(recentListingsProvider);
    ref.read(authProvider);
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _fadeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _shimmerCtrl.forward();
    if (mounted) _navigate();
  }

  Future<void> _navigate() async {
    await ref.read(secureStorageProvider).hasTokens();
    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Widget _shimmerText(String text, double fontSize, FontWeight weight, double letterSpacing) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) {
        final color = _shimmerColor.value ?? _textNormal;
        return Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            letterSpacing: letterSpacing,
            height: 1,
            shadows: _shimmerCtrl.value > 0.2
                ? [
                    Shadow(
                      color: _textShimmer.withValues(alpha: _shimmerCtrl.value * 0.8),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.15),
            radius: 0.7,
            colors: [_bgCenter, _bgDark],
            stops: [0.0, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo ────────────────────────────────────────
                AnimatedBuilder(
                  animation: _shimmerCtrl,
                  builder: (_, __) {
                    return Image.asset(
                      'assets/images/app_logo.png',
                      width: 340,
                      height: 340,
                      fit: BoxFit.contain,
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ── Yatay çizgi ─────────────────────────────────
                Container(width: 180, height: 1, color: _lineColor),

                const SizedBox(height: 32),

                // ── CYPCAR ──────────────────────────────────────
                _shimmerText('CYPCAR', 34, FontWeight.w700, 8),

                const SizedBox(height: 20),

                // ── Alt yazı ────────────────────────────────────
                const Text(
                  "K I B R I S ' A   Ö Z E L   A R A Ç   A L I M - S A T I M   P L A T F O R M U",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _subtitleColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
