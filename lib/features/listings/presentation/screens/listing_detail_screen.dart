import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cypcar/core/providers/currency_provider.dart';
import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/features/auth/presentation/providers/auth_provider.dart';
import 'package:cypcar/features/listings/data/listings_repository.dart';
import 'package:cypcar/features/listings/domain/models/listing_model.dart';
import 'package:cypcar/features/listings/presentation/providers/listing_detail_provider.dart';
import 'package:cypcar/shared/providers/exchange_rate_provider.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  final PageController _pageCtrl = PageController();
  final GlobalKey _storyCardKey = GlobalKey();
  int _currentPage = 0;
  bool? _isFav;
  bool _favLoading = false;
  bool _altCurrency = false;
  bool _sharingStory = false;
  bool _markingSold = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatPrice(double price, String currency, String displayCurrency) {
    final rate = ref.read(exchangeRateProvider).value;
    double v = price;
    if (currency != displayCurrency && rate != null) {
      if (currency == 'TRY' && displayCurrency == 'GBP') {
        v = price * rate.tryToGbp;
      } else if (currency == 'GBP' && displayCurrency == 'TRY') {
        v = price * rate.gbpToTry;
      }
    }
    if (displayCurrency == 'TRY') {
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)} M ₺';
      return '${NumberFormat('#,###', 'tr_TR').format(v.toInt())} ₺';
    } else {
      return '£${NumberFormat('#,###').format(v.toInt())}';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return DateFormat('d MMM y', 'tr_TR').format(dt);
    if (diff.inDays > 0) return '${diff.inDays} gün önce';
    if (diff.inHours > 0) return '${diff.inHours} saat önce';
    return 'Az önce';
  }

  String _fuelLabel(String? f) {
    const map = {
      'PETROL': 'Benzin',
      'DIESEL': 'Dizel',
      'ELECTRIC': 'Elektrik',
      'HYBRID': 'Hibrit',
      'LPG': 'LPG',
    };
    return map[f] ?? (f ?? '');
  }

  String _transmissionLabel(String? t) =>
      t == 'MANUAL' ? 'Manuel' : t == 'AUTOMATIC' ? 'Otomatik' : (t ?? '');

  String _driveLabel(String? d) {
    const map = {
      'FWD': 'Önden Çekiş',
      'RWD': 'Arkadan İtiş',
      'AWD': 'AWD',
      'FOUR_WD': '4x4',
    };
    return map[d] ?? (d ?? '');
  }

  String _engineLabel(int? cc) {
    if (cc == null) return '';
    return '${(cc / 1000.0).toStringAsFixed(1)}L';
  }

  String _conditionLabel(String? c) =>
      c == 'NEW' ? 'Sıfır' : c == 'USED' ? 'İkinci El' : (c ?? '');

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _toggleFav(ListingDetail listing) async {
    final isLoggedIn = ref.read(authProvider.notifier).isLoggedIn;
    if (!isLoggedIn) {
      context.push('/register');
      return;
    }
    setState(() {
      _isFav = !(_isFav ?? false);
      _favLoading = true;
    });
    try {
      await ref.read(listingsRepositoryProvider).toggleFavorite(listing.id);
    } catch (_) {
      if (mounted) setState(() => _isFav = !(_isFav ?? true));
    } finally {
      if (mounted) setState(() => _favLoading = false);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String number) async {
    final clean = number.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleContact(String? value, String type) {
    final isLoggedIn = ref.read(authProvider.notifier).isLoggedIn;
    if (!isLoggedIn) {
      context.push('/register');
      return;
    }
    if (value == null) return;
    if (type == 'phone') {
      _launchPhone(value);
    } else {
      _launchWhatsApp(value);
    }
  }

  void _showReportSheet(ListingDetail listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportSheet(
        listingId: listing.id,
        repo: ref.read(listingsRepositoryProvider),
      ),
    );
  }

  // ── Share ─────────────────────────────────────────────────────────────────

  void _showShareSheet(ListingDetail listing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(
        onGeneral: () {
          Navigator.pop(context);
          _shareGeneral(listing);
        },
        onStory: () {
          Navigator.pop(context);
          _shareStory(listing);
        },
        sharingStory: _sharingStory,
      ),
    );
  }

  Future<void> _shareGeneral(ListingDetail listing) async {
    if (kIsWeb) {
      _showWebShareSnack();
      return;
    }
    final displayCurrency = ref.read(currencyProvider);
    final price = _formatPrice(listing.price, listing.currency, displayCurrency);
    final year = listing.year != null ? ' ${listing.year}' : '';
    final location = listing.location != null ? '\n📍 ${listing.location}' : '';
    final text =
        '🚗 Satılık:$year ${listing.displayTitle}\n'
        '💰 $price$location\n\n'
        'CypCar uygulamasında görüntüle';
    await Share.share(text, subject: 'CypCar — ${listing.displayTitle}');
  }

  Future<void> _shareStory(ListingDetail listing) async {
    if (kIsWeb) {
      _showWebShareSnack();
      return;
    }
    if (listing.images.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu ilanın fotoğrafı bulunmuyor.')),
        );
      }
      return;
    }

    setState(() => _sharingStory = true);

    try {
      final imageBytes = await _captureStoryCard();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cypcar_story.png');
      await file.writeAsBytes(imageBytes);

      final displayCurrency = ref.read(currencyProvider);
      final price = _formatPrice(listing.price, listing.currency, displayCurrency);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${listing.displayTitle} — $price | CypCar',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paylaşım sırasında bir hata oluştu.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharingStory = false);
    }
  }

  void _showWebShareSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paylaşım özelliği mobil uygulamada kullanılabilir.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<Uint8List> _captureStoryCard() async {
    final boundary = _storyCardKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('Story kartı render edilemedi.');
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ── Mark Sold ─────────────────────────────────────────────────────────────

  Future<void> _markSold(ListingDetail listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Satıldı İşaretle'),
        content: Text(
            '${listing.displayTitle} ilanını satıldı olarak işaretlemek istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, Satıldı'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _markingSold = true);
    try {
      await ref.read(listingsRepositoryProvider).markSold(listing.id);
      ref.invalidate(listingDetailProvider(listing.id));
      if (mounted) _showSoldCelebration(listing);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bir hata oluştu. Tekrar dene.')),
        );
      }
    } finally {
      if (mounted) setState(() => _markingSold = false);
    }
  }

  void _showSoldCelebration(ListingDetail listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _SoldCelebrationSheet(
        listing: listing,
        onShare: () {
          Navigator.pop(context);
          _shareStory(listing);
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final asyncListing = ref.watch(listingDetailProvider(widget.listingId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final textSecondary =
        isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: asyncListing.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(textPrimary, textSecondary),
        data: (listing) {
          _isFav ??= listing.isFavorited;
          return _buildBody(listing, isDark, textPrimary, textSecondary);
        },
      ),
    );
  }

  Widget _buildError(Color textPrimary, Color textSecondary) {
    return Column(
      children: [
        const SafeArea(
          child: SizedBox(
            height: kToolbarHeight,
            child: BackButton(),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: textSecondary),
                const SizedBox(height: 16),
                Text('İlan yüklenemedi',
                    style: TextStyle(color: textPrimary, fontSize: 16)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(listingDetailProvider(widget.listingId)),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ListingDetail listing, bool isDark, Color textPrimary,
      Color textSecondary) {
    final isSold = listing.status == 'SOLD';
    final displayCurrency = ref.watch(currencyProvider);
    final isOwn = ref.watch(authProvider).value?.id == listing.userId;
    final isLoggedIn = ref.read(authProvider.notifier).isLoggedIn;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // ── Şeffaf AppBar ──────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor:
                  isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              actions: [
                // Paylaş
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _showShareSheet(listing),
                ),
                // Favori
                if (_favLoading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(
                      (_isFav ?? false)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: (_isFav ?? false)
                          ? AppTheme.primary
                          : null,
                    ),
                    onPressed: () => _toggleFav(listing),
                  ),
              ],
            ),

            // ── Fotoğraf Galerisi ──────────────────────────────────
            SliverToBoxAdapter(
              child: _ImageCarousel(
                listingId: listing.id,
                images: listing.images,
                isSold: isSold,
                controller: _pageCtrl,
                currentPage: _currentPage,
                onPageChanged: (i) => setState(() => _currentPage = i),
              ),
            ),

            // ── İçerik ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fiyat satırı
                    if (isSold)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'SATILDI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => setState(() => _altCurrency = !_altCurrency),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _formatPrice(
                                    listing.price,
                                    listing.currency,
                                    _altCurrency
                                        ? (displayCurrency == 'GBP' ? 'TRY' : 'GBP')
                                        : displayCurrency,
                                  ),
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: (_altCurrency
                                                ? (displayCurrency == 'GBP' ? 'TRY' : 'GBP')
                                                : displayCurrency) ==
                                            'GBP'
                                        ? const Color(0xFFE8C97A)
                                        : AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.swap_horiz,
                                    size: 16, color: textSecondary),
                              ],
                            ),
                            Text(
                              _altCurrency ? 'Orijinal para birimini gör' : 'Döviz cinsini gör',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Başlık (marka · seri · model)
                    Text(
                      listing.displayTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Konum + Tarih
                    Row(
                      children: [
                        if (listing.location != null) ...[
                          Icon(Icons.location_on_outlined,
                              size: 14, color: textSecondary),
                          const SizedBox(width: 3),
                          Text(listing.location!,
                              style: TextStyle(
                                  fontSize: 13, color: textSecondary)),
                          const SizedBox(width: 14),
                        ],
                        Icon(Icons.access_time,
                            size: 13, color: textSecondary),
                        const SizedBox(width: 3),
                        Text(_timeAgo(listing.createdAt),
                            style: TextStyle(
                                fontSize: 12, color: textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: isDark ? Colors.white12 : Colors.black12),
                    const SizedBox(height: 16),

                    // Teknik Bilgiler başlığı
                    Text(
                      'Teknik Bilgiler',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Özellikler kartı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      child: _SpecsSection(
                        listing: listing,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        fuelLabel: _fuelLabel,
                        transmissionLabel: _transmissionLabel,
                        driveLabel: _driveLabel,
                        engineLabel: _engineLabel,
                        conditionLabel: _conditionLabel,
                      ),
                    ),

                    // Açıklama
                    if (listing.description != null &&
                        listing.description!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Divider(
                          color: isDark ? Colors.white12 : Colors.black12),
                      const SizedBox(height: 16),
                      Text(
                        'Açıklama',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listing.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          height: 1.65,
                        ),
                      ),
                    ],

                    // Satıcı
                    const SizedBox(height: 24),
                    Divider(color: isDark ? Colors.white12 : Colors.black12),
                    const SizedBox(height: 16),
                    Text(
                      'Satıcı',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SellerRow(
                      listing: listing,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    // Şikayet butonu
                    if (!isOwn) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showReportSheet(listing),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flag_outlined,
                                  size: 14, color: textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                'İlanı Şikayet Et',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Gizli Story Kartı (screenshot için) ───────────────────
        Offstage(
          child: RepaintBoundary(
            key: _storyCardKey,
            child: _StoryCard(listing: listing),
          ),
        ),

        // ── Alt İletişim Barı ──────────────────────────────────────
        if (!isOwn)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _ContactBar(
              listing: listing,
              isSold: isSold,
              isLoggedIn: isLoggedIn,
              isDark: isDark,
              onPhone: () => _handleContact(listing.userPhone, 'phone'),
              onWhatsApp: () => _handleContact(listing.userWhatsapp, 'whatsapp'),
            ),
          ),

        // ── Kendi İlanı Alt Barı ───────────────────────────────────
        if (isOwn && !isSold)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _OwnListingBar(
              isDark: isDark,
              loading: _markingSold,
              onMarkSold: () => _markSold(listing),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Image Carousel
// ═══════════════════════════════════════════════════════════════════════════

class _ImageCarousel extends StatelessWidget {
  final String listingId;
  final List<String> images;
  final bool isSold;
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _ImageCarousel({
    required this.listingId,
    required this.images,
    required this.isSold,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          // Fotoğraflar
          images.isEmpty
              ? _placeholder()
              : PageView.builder(
                  controller: controller,
                  itemCount: images.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (_, i) {
                    final img = CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    );
                    final child = GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _FullScreenViewer(
                            images: images,
                            initialIndex: i,
                          ),
                        ),
                      ),
                      child: i == 0
                          ? Hero(tag: 'listing_img_$listingId', child: img)
                          : img,
                    );
                    return child;
                  },
                ),

          // SATILDI overlay
          if (isSold)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'SATILDI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Sayfa noktaları + foto sayısı
          if (images.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == currentPage ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == currentPage
                          ? Colors.white
                          : Colors.white54,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

          // Foto sayısı badge (sağ alt)
          if (images.isNotEmpty)
            Positioned(
              bottom: 10,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${currentPage + 1}/${images.length}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF1A1A1A),
        child: const Center(
          child: Icon(Icons.directions_car,
              size: 60, color: Colors.white12),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// Specs Section
// ═══════════════════════════════════════════════════════════════════════════

class _SpecsSection extends StatelessWidget {
  final ListingDetail listing;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final String Function(String?) fuelLabel;
  final String Function(String?) transmissionLabel;
  final String Function(String?) driveLabel;
  final String Function(int?) engineLabel;
  final String Function(String?) conditionLabel;

  const _SpecsSection({
    required this.listing,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.fuelLabel,
    required this.transmissionLabel,
    required this.driveLabel,
    required this.engineLabel,
    required this.conditionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_SpecRow>[
      if (listing.mileage != null)
        _SpecRow(
          label: 'Kilometre',
          value: '${NumberFormat('#,###', 'tr_TR').format(listing.mileage)} km',
        ),
      if (listing.year != null)
        _SpecRow(label: 'Model Yılı', value: '${listing.year}'),
      if (listing.fuelType != null)
        _SpecRow(label: 'Yakıt', value: fuelLabel(listing.fuelType)),
      if (listing.transmission != null)
        _SpecRow(label: 'Şanzıman', value: transmissionLabel(listing.transmission)),
      if (listing.engineCc != null)
        _SpecRow(label: 'Motor Hacmi', value: engineLabel(listing.engineCc)),
      if (listing.driveType != null)
        _SpecRow(label: 'Çekiş', value: driveLabel(listing.driveType)),
      if (listing.vehicleType != null)
        _SpecRow(label: 'Kasa Tipi', value: _vehicleTypeLabel(listing.vehicleType!)),
      if (listing.condition.isNotEmpty)
        _SpecRow(label: 'Durum', value: conditionLabel(listing.condition)),
      if (listing.color != null)
        _SpecRow(label: 'Renk', value: listing.color!),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      children: List.generate(rows.length, (i) {
        final row = rows[i];
        final isLast = i == rows.length - 1;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    row.label,
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                  Text(
                    row.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              ),
          ],
        );
      }),
    );
  }

  String _vehicleTypeLabel(String t) {
    const map = {
      'SEDAN': 'Sedan',
      'SUV': 'SUV',
      'HATCHBACK': 'Hatchback',
      'COUPE': 'Coupe',
      'CONVERTIBLE': 'Cabrio',
      'WAGON': 'Kombi',
      'PICKUP': 'Pickup',
      'VAN': 'Van',
      'MINIVAN': 'Minivan',
      'SPORT': 'Spor',
      'NAKED': 'Naked',
      'ENDURO': 'Enduro',
      'SCOOTER': 'Scooter',
      'CRUISER': 'Cruiser',
      'ADVENTURE': 'Adventure',
      'ATV': 'ATV',
      'UTV': 'UTV',
      'CLASSIC': 'Klasik',
      'ELECTRIC_BIKE': 'Elektrikli Bisiklet',
      'CARGO_VAN': 'Panelvan',
      'MINIBUS': 'Minibüs',
      'BUS': 'Otobüs',
      'TRUCK': 'Kamyon',
      'OTHER': 'Diğer',
    };
    return map[t] ?? t;
  }
}

class _SpecRow {
  final String label;
  final String value;
  const _SpecRow({required this.label, required this.value});
}

// ═══════════════════════════════════════════════════════════════════════════
// Seller Row
// ═══════════════════════════════════════════════════════════════════════════

class _SellerRow extends StatelessWidget {
  final ListingDetail listing;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const _SellerRow({
    required this.listing,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/profile/${listing.userId}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
              backgroundImage: listing.userPhoto != null
                  ? CachedNetworkImageProvider(listing.userPhoto!)
                  : null,
              child: listing.userPhoto == null
                  ? Text(
                      _initials(listing.userName),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // İsim
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.userName,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Satıcı profilini gör',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textSecondary),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Contact Bar
// ═══════════════════════════════════════════════════════════════════════════

class _ContactBar extends StatelessWidget {
  final ListingDetail listing;
  final bool isSold;
  final bool isLoggedIn;
  final bool isDark;
  final VoidCallback onPhone;
  final VoidCallback onWhatsApp;

  const _ContactBar({
    required this.listing,
    required this.isSold,
    required this.isLoggedIn,
    required this.isDark,
    required this.onPhone,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppTheme.cardDark : Colors.white;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isSold
          ? _soldMessage()
          : isLoggedIn
              ? _buttons(context)
              : _loginPrompt(context),
    );
  }

  Widget _soldMessage() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'Bu araç satılmıştır',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      );

  Widget _loginPrompt(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => context.push('/register'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Satıcıyla İletişime Geç',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      );

  Widget _buttons(BuildContext context) {
    final hasPhone = listing.userPhone != null;
    final hasWhatsApp = listing.userWhatsapp != null;

    if (!hasPhone && !hasWhatsApp) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'İletişim bilgisi yok',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return Row(
      children: [
        if (hasPhone)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPhone,
              icon: const Icon(Icons.phone_outlined, size: 18),
              label: const Text('Telefon'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (hasPhone && hasWhatsApp) const SizedBox(width: 10),
        if (hasWhatsApp)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onWhatsApp,
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Report Sheet
// ═══════════════════════════════════════════════════════════════════════════

class _ReportSheet extends StatefulWidget {
  final String listingId;
  final ListingsRepository repo;

  const _ReportSheet({required this.listingId, required this.repo});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _selected;
  bool _loading = false;

  static const _reasons = [
    'Yanıltıcı veya yanlış bilgi',
    'Araç zaten satılmış',
    'Dolandırıcılık şüphesi',
    'Uygunsuz içerik',
    'Diğer',
  ];

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      await widget.repo.reportListing(widget.listingId, _selected!);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şikayetiniz iletildi. Teşekkürler.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bir hata oluştu. Tekrar deneyin.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.surfaceDark : Colors.white;
    final textPrimary =
        isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'İlanı Şikayet Et',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Şikayet nedeninizi seçin',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ..._reasons.map((r) => RadioListTile<String>(
                value: r,
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v),
                title: Text(r, style: TextStyle(fontSize: 14, color: textPrimary)),
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selected == null || _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Şikayet Gönder',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Own Listing Bar
// ═══════════════════════════════════════════════════════════════════════════

class _OwnListingBar extends StatelessWidget {
  final bool isDark;
  final bool loading;
  final VoidCallback onMarkSold;

  const _OwnListingBar({
    required this.isDark,
    required this.loading,
    required this.onMarkSold,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppTheme.cardDark : Colors.white;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: loading ? null : onMarkSold,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle_outline, size: 20),
          label: Text(
            loading ? 'İşleniyor...' : 'Satıldı Olarak İşaretle',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sold Celebration Sheet
// ═══════════════════════════════════════════════════════════════════════════

class _SoldCelebrationSheet extends StatelessWidget {
  final ListingDetail listing;
  final VoidCallback onShare;
  final VoidCallback onClose;

  const _SoldCelebrationSheet({
    required this.listing,
    required this.onShare,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.surfaceDark : Colors.white;
    final textPrimary =
        isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final textSecondary =
        isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Konfeti ikonu
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🎉', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Tebrikler!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${listing.displayTitle} ilanın\nCypCar\'da satıldı.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bunu çevrenle paylaş!',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // Story paylaş
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.camera_alt_outlined, size: 20),
              label: const Text(
                "Story'de Paylaş",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE1306C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Kapat
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: onClose,
              child: Text(
                'Şimdi Değil',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Share Sheet
// ═══════════════════════════════════════════════════════════════════════════

class _ShareSheet extends StatelessWidget {
  final VoidCallback onGeneral;
  final VoidCallback onStory;
  final bool sharingStory;

  const _ShareSheet({
    required this.onGeneral,
    required this.onStory,
    required this.sharingStory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.surfaceDark : Colors.white;
    final textPrimary =
        isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final textSecondary =
        isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Paylaş',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Genel Paylaş
          _ShareOption(
            icon: Icons.share_outlined,
            iconColor: const Color(0xFF0088CC),
            title: 'Genel Paylaş',
            subtitle: 'WhatsApp, Telegram, mesaj ve daha fazlası',
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: onGeneral,
          ),
          const SizedBox(height: 10),

          // Story Paylaş
          _ShareOption(
            icon: Icons.camera_alt_outlined,
            iconColor: const Color(0xFFE1306C),
            title: "Story'de Paylaş",
            subtitle: 'Instagram, Snapchat ve diğer story platformları',
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: sharingStory ? null : onStory,
            trailing: sharingStory
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ShareOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Story Card  (9:16 — Offstage render için)
// ═══════════════════════════════════════════════════════════════════════════

class _StoryCard extends StatelessWidget {
  final ListingDetail listing;
  const _StoryCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final price = _buildPrice();

    return SizedBox(
      width: 360,
      height: 640,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Arkaplan görsel
          listing.images.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: listing.images.first,
                  fit: BoxFit.cover,
                )
              : Container(color: Colors.black),

          // Alt koyu gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Üst: CypCar logosu
          Positioned(
            top: 32,
            left: 24,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'CypCar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          // Sağ üst: cypcar.app watermark
          Positioned(
            top: 36,
            right: 24,
            child: Text(
              'cypcar.app',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Alt: İlan bilgileri
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Durum badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    listing.year != null
                        ? '${listing.year} • Satılık'
                        : 'Satılık',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                // Araç adı
                Text(
                  listing.displayTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                // Fiyat
                Text(
                  price,
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (listing.location != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white60, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        listing.location!,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildPrice() {
    final v = listing.price;
    if (listing.currency == 'GBP') {
      return '£${NumberFormat('#,###').format(v.toInt())}';
    }
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} M ₺';
    return '${NumberFormat('#,###', 'tr_TR').format(v.toInt())} ₺';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Full Screen Image Viewer
// ═══════════════════════════════════════════════════════════════════════════

class _FullScreenViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_current + 1} / ${widget.images.length}',
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 0.8,
          maxScale: 5.0,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.images[i],
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white30),
              ),
              errorWidget: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white30,
                size: 60,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
