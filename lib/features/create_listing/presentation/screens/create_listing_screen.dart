import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/features/catalog/data/catalog_repository.dart';
import 'package:cypcar/features/catalog/domain/models/catalog_models.dart';
import 'package:cypcar/features/create_listing/presentation/providers/create_listing_provider.dart';
import 'package:cypcar/features/listings/data/listings_repository.dart';
import 'package:cypcar/shared/models/app_settings_model.dart';
import 'package:cypcar/shared/providers/app_settings_provider.dart';

// ── Catalog providers (same pattern as search screen) ────────────────────────

final _clMakesProvider = FutureProvider.family<List<MakeModel>, String>((ref, cat) {
  return ref.watch(catalogRepositoryProvider).fetchMakes(cat);
});

final _clSeriesProvider = FutureProvider.family<List<SeriesModel>, String>((ref, key) {
  final parts = key.split('|');
  return ref.watch(catalogRepositoryProvider).fetchSeries(parts[0], category: parts[1]);
});

final _clModelsProvider =
    FutureProvider.family<List<VehicleModelModel>, String>((ref, seriesId) {
  return ref.watch(catalogRepositoryProvider).fetchModels(seriesId);
});

// ── Constants ─────────────────────────────────────────────────────────────────

const _categoryMeta = {
  'OTOMOBIL': (label: 'Otomobil', icon: Icons.directions_car_rounded),
  'ARAZI_SUV_PICKUP': (label: 'Arazi & SUV', icon: Icons.terrain_rounded),
  'MOTORSIKLET': (label: 'Motorsiklet', icon: Icons.two_wheeler_rounded),
  'TICARI': (label: 'Ticari', icon: Icons.local_shipping_rounded),
};

const _vehicleTypesByCategory = {
  'OTOMOBIL': [
    ('SEDAN', 'Sedan'),
    ('HATCHBACK', 'Hatchback'),
    ('SUV', 'SUV'),
    ('COUPE', 'Coupe'),
    ('CONVERTIBLE', 'Cabrio'),
    ('WAGON', 'Station Wagon'),
  ],
  'ARAZI_SUV_PICKUP': [
    ('SUV', 'SUV'),
    ('PICKUP', 'Pickup'),
    ('VAN', 'Van'),
    ('MINIVAN', 'Minivan'),
  ],
  'MOTORSIKLET': [
    ('SPORT', 'Sport'),
    ('NAKED', 'Naked'),
    ('SCOOTER', 'Scooter'),
    ('ENDURO', 'Enduro'),
    ('CRUISER', 'Cruiser'),
    ('ADVENTURE', 'Adventure'),
    ('ATV', 'ATV'),
    ('UTV', 'UTV'),
    ('CLASSIC', 'Klasik'),
    ('ELECTRIC_BIKE', 'Elektrikli'),
  ],
  'TICARI': [
    ('CARGO_VAN', 'Kargo / Panelvan'),
    ('MINIBUS', 'Minibüs'),
    ('BUS', 'Otobüs'),
    ('TRUCK', 'Kamyon'),
    ('PICKUP', 'Pickup'),
    ('VAN', 'Van'),
    ('OTHER', 'Diğer'),
  ],
};

const _fuelTypes = [
  ('PETROL', 'Benzin'),
  ('DIESEL', 'Dizel'),
  ('ELECTRIC', 'Elektrik'),
  ('HYBRID', 'Hibrit'),
  ('LPG', 'LPG'),
];

const _driveTypes = [
  ('FWD', 'Önden Çekiş (FWD)'),
  ('RWD', 'Arkadan İtiş (RWD)'),
  ('AWD', 'Dört Çeker (AWD)'),
  ('FOUR_WD', '4x4 (4WD)'),
];

List<(int, String)> _getEngineCcOptions(String? category) {
  if (category == 'MOTORSIKLET') {
    return [
      (50, '50cc'), (125, '125cc'), (250, '250cc'), (300, '300cc'),
      (400, '400cc'), (450, '450cc'), (500, '500cc'), (600, '600cc'),
      (650, '650cc'), (750, '750cc'), (800, '800cc'), (900, '900cc'),
      (1000, '1000cc'), (1100, '1100cc'), (1200, '1200cc'),
      (1300, '1300cc'), (1400, '1400cc'), (1800, '1800cc'),
    ];
  } else if (category == 'TICARI') {
    return [
      (1500, '1.5L'), (1900, '1.9L'), (2000, '2.0L'), (2200, '2.2L'),
      (2500, '2.5L'), (2800, '2.8L'), (3000, '3.0L'), (3500, '3.5L'),
      (4000, '4.0L'), (5000, '5.0L'), (6000, '6.0L'), (7000, '7.0L'),
      (8000, '8.0L+'),
    ];
  } else {
    return [
      (600, '0.6L'), (800, '0.8L'), (1000, '1.0L'), (1100, '1.1L'),
      (1200, '1.2L'), (1400, '1.4L'), (1500, '1.5L'), (1600, '1.6L'),
      (1800, '1.8L'), (2000, '2.0L'), (2200, '2.2L'), (2400, '2.4L'),
      (2500, '2.5L'), (2700, '2.7L'), (3000, '3.0L'), (3500, '3.5L'),
      (4000, '4.0L'), (4500, '4.5L'), (5000, '5.0L'), (6000, '6.0L+'),
    ];
  }
}

const _colors = [
  ('Beyaz', Color(0xFFFFFFFF)),
  ('Siyah', Color(0xFF1A1A1A)),
  ('Gümüş', Color(0xFFC0C0C0)),
  ('Gri', Color(0xFF808080)),
  ('Kırmızı', Color(0xFFCC0000)),
  ('Bordo', Color(0xFF800020)),
  ('Mavi', Color(0xFF1565C0)),
  ('Lacivert', Color(0xFF1A237E)),
  ('Yeşil', Color(0xFF2E7D32)),
  ('Sarı', Color(0xFFFFC107)),
  ('Turuncu', Color(0xFFE65100)),
  ('Kahverengi', Color(0xFF5D4037)),
  ('Bej', Color(0xFFD7CCC8)),
  ('Altın', Color(0xFFFFD700)),
  ('Mor', Color(0xFF6A1B9A)),
];

const _cyprusCities = [
  (name: 'Lefkoşa', icon: Icons.location_city_rounded, desc: 'Başkent'),
  (name: 'Girne', icon: Icons.anchor_rounded, desc: 'Kuzey Kıbrıs'),
  (name: 'Gazimağusa', icon: Icons.castle_rounded, desc: 'Tarihi Şehir'),
  (name: 'Güzelyurt', icon: Icons.park_rounded, desc: 'Batı Kıbrıs'),
  (name: 'İskele', icon: Icons.beach_access_rounded, desc: 'Doğu Kıbrıs'),
  (name: 'Lefke', icon: Icons.grass_rounded, desc: 'Batı Kıbrıs'),
];

const _stepLabels = ['Araç', 'Teknik', 'İlan', 'Konum', 'Fotoğraf', 'Boost'];

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class CreateListingScreen extends ConsumerStatefulWidget {
  /// Tab modunda back butonu çıkmak yerine Ana Sayfa'ya döner
  final VoidCallback? onCloseInTabs;

  const CreateListingScreen({
    super.key,
    this.onCloseInTabs,
  });

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  @override
  void initState() {
    super.initState();
    // Reset state when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clProvider.notifier).reset();
    });
  }

  Future<bool> _onWillPop(CLState state) async {
    if (state.step == CLStep.vehicle &&
        state.vehicleSubStep == VehicleSubStep.category) {
      return true;
    }
    if (state.step == CLStep.vehicle) {
      ref.read(clProvider.notifier).vehicleGoBack();
      return false;
    }
    ref.read(clProvider.notifier).goToStep(state.step.index - 1);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(appSettingsProvider).valueOrNull ?? AppSettings.defaults();
    final isPaid = settings.isPaidFeaturesEnabled;
    final totalSteps = isPaid ? 6 : 5;
    final labels = isPaid ? _stepLabels : _stepLabels.take(5).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canPop = await _onWillPop(state);
        if (canPop && context.mounted) {
          if (widget.onCloseInTabs != null) {
            widget.onCloseInTabs!();
          } else {
            context.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
        appBar: _buildAppBar(state, isDark),
        body: Column(
          children: [
            _ProgressBar(
              currentStep: state.step.index,
              totalSteps: totalSteps,
              labels: labels,
              onStepTap: (i) {
                if (i < state.step.index) {
                  ref.read(clProvider.notifier).goToStep(i);
                }
              },
            ),
            Expanded(child: _buildBody(state, isDark, isPaid)),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(state, isDark, isPaid),
      ),
    );
  }

  AppBar _buildAppBar(CLState state, bool isDark) {
    final String subtitle;
    if (state.step == CLStep.vehicle) {
      subtitle = switch (state.vehicleSubStep) {
        VehicleSubStep.category => 'Araç kategorisi seçin',
        VehicleSubStep.make => 'Marka seçin',
        VehicleSubStep.series => '${state.make?.name ?? ''} · Seri seçin',
        VehicleSubStep.model => '${state.series?.name ?? ''} · Model seçin',
      };
    } else {
      subtitle = switch (state.step) {
        CLStep.technical => 'Teknik özellikler',
        CLStep.info => 'İlan bilgileri',
        CLStep.location => 'Konum seçin',
        CLStep.photos => 'Fotoğraf ekleyin',
        CLStep.boost => 'İlanı öne çıkarın',
        _ => '',
      };
    }

    return AppBar(
      backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () async {
          final canPop = await _onWillPop(ref.read(clProvider));
          if (canPop && mounted) {
            if (widget.onCloseInTabs != null) {
              widget.onCloseInTabs!();
            } else {
              context.pop();
            }
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('İlan Ver',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CLState state, bool isDark, bool isPaid) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
      child: KeyedSubtree(
        key: ValueKey('${state.step}_${state.vehicleSubStep}'),
        child: switch (state.step) {
          CLStep.vehicle => _VehicleStep(state: state, isDark: isDark),
          CLStep.technical => _TechnicalStep(state: state, isDark: isDark),
          CLStep.info => _InfoStep(state: state, isDark: isDark),
          CLStep.location => _LocationStep(state: state, isDark: isDark),
          CLStep.photos => _PhotosStep(state: state, isDark: isDark),
          CLStep.boost => _BoostStep(isDark: isDark),
        },
      ),
    );
  }

  Widget? _buildBottomBar(CLState state, bool isDark, bool isPaid) {
    if (state.step == CLStep.vehicle) {
      return null;
    }

    final bool isLastStep =
        state.step == (isPaid ? CLStep.boost : CLStep.photos);
    final bool canProceed = switch (state.step) {
      CLStep.vehicle => state.canProceedStep0,
      CLStep.technical => state.canProceedStep1,
      CLStep.info => state.canProceedStep2,
      CLStep.location => state.canProceedStep3,
      CLStep.photos => state.canProceedStep4,
      CLStep.boost => true,
    };

    return Container(
      color: isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: canProceed && !state.isSubmitting
                  ? () => _handleNext(state, isPaid)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed ? AppTheme.primary : Colors.grey[700],
                foregroundColor: Colors.white,
                elevation: canProceed ? 0 : 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastStep ? 'İlanı Yayınla' : 'İleri',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        if (!isLastStep) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNext(CLState state, bool isPaid) {
    if (state.step == (isPaid ? CLStep.boost : CLStep.photos)) {
      _submit();
    } else {
      ref.read(clProvider.notifier).nextStep(isPaidEnabled: isPaid);
    }
  }

  Future<void> _submit() async {
    final state = ref.read(clProvider);
    final notifier = ref.read(clProvider.notifier);
    notifier.setSubmitting(true);
    notifier.setError(null);

    try {
      final repo = ref.read(listingsRepositoryProvider);
      final listing = await repo.createListing(
        category: state.category!,
        makeId: state.make!.id,
        seriesId: state.series!.id,
        modelId: state.model?.id,
        title: state.title,
        description: state.description,
        price: double.parse(state.price.replaceAll(',', '.')),
        year: state.year!,
        mileage: int.parse(state.mileage),
        color: state.color!,
        condition: state.condition!,
        location: state.city!,
        currency: state.currency,
        vehicleType: state.vehicleType,
        engineCc: state.engineCc,
        driveType: state.driveType,
        fuelType: state.fuelType,
        transmission: state.transmission,
      );

      // Upload images sequentially
      for (final image in state.images) {
        await repo.uploadImage(listing.id.toString(), image);
      }

      notifier.reset();
      if (mounted) {
        context.go('/listing/${listing.id}');
      }
    } catch (e) {
      notifier.setError(e.toString());
      notifier.setSubmitting(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress Bar
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;
  final void Function(int) onStepTap;

  const _ProgressBar({
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final isCompleted = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.primary
                      : (isDark ? Colors.white12 : Colors.black12),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          } else {
            // Step circle
            final stepIndex = i ~/ 2;
            final isCompleted = stepIndex < currentStep;
            final isCurrent = stepIndex == currentStep;
            final label = stepIndex < labels.length ? labels[stepIndex] : '';

            return GestureDetector(
              onTap: isCompleted ? () => onStepTap(stepIndex) : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.primary
                          : isCurrent
                              ? Colors.transparent
                              : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: AppTheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check_rounded,
                              size: 15, color: Colors.white)
                          : Text(
                              '${stepIndex + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isCurrent
                                    ? AppTheme.primary
                                    : (isDark ? Colors.white38 : Colors.black38),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent || isCompleted
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isCurrent
                          ? AppTheme.primary
                          : isCompleted
                              ? AppTheme.primary.withValues(alpha: 0.7)
                              : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                ],
              ),
            );
          }
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 0 — Vehicle Selection
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleStep extends ConsumerStatefulWidget {
  final CLState state;
  final bool isDark;
  const _VehicleStep({required this.state, required this.isDark});

  @override
  ConsumerState<_VehicleStep> createState() => _VehicleStepState();
}

class _VehicleStepState extends ConsumerState<_VehicleStep> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
        () => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subStep = widget.state.vehicleSubStep;
    final showSearch = subStep == VehicleSubStep.make || subStep == VehicleSubStep.series;

    // Clear search when sub-step changes
    ref.listen(
      clProvider.select((s) => s.vehicleSubStep),
      (_, __) {
        _searchCtrl.clear();
        setState(() => _query = '');
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.state.make != null)
          _VehicleBreadcrumb(state: widget.state, isDark: widget.isDark),
        if (showSearch)
          _VehicleSearchBar(
            controller: _searchCtrl,
            query: _query,
            hint: subStep == VehicleSubStep.make ? 'Marka ara...' : 'Seri ara...',
            isDark: widget.isDark,
          ),
        Expanded(child: _buildContent(subStep)),
      ],
    );
  }

  Widget _buildContent(VehicleSubStep subStep) {
    switch (subStep) {
      case VehicleSubStep.category:
        return _CategoryGrid(isDark: widget.isDark);
      case VehicleSubStep.make:
        return _MakeGrid(
          category: widget.state.category!,
          query: _query,
          isDark: widget.isDark,
        );
      case VehicleSubStep.series:
        return _SeriesGrid(
          makeId: widget.state.make!.id,
          category: widget.state.category!,
          query: _query,
          isDark: widget.isDark,
        );
      case VehicleSubStep.model:
        return _ModelGrid(
          seriesId: widget.state.series!.id,
          seriesName: widget.state.series!.name,
          isDark: widget.isDark,
        );
    }
  }
}

class _VehicleSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final String hint;
  final bool isDark;
  const _VehicleSearchBar(
      {required this.controller,
      required this.query,
      required this.hint,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black26,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20, color: isDark ? Colors.white38 : Colors.black38),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: isDark ? Colors.white54 : Colors.black45,
                    onPressed: controller.clear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

class _VehicleBreadcrumb extends ConsumerWidget {
  final CLState state;
  final bool isDark;
  const _VehicleBreadcrumb({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = _categoryMeta[state.category];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _BCChip(
            label: meta?.label ?? state.category ?? '',
            isActive: state.vehicleSubStep == VehicleSubStep.make,
            isDark: isDark,
            onTap: () => ref
                .read(clProvider.notifier)
                .selectCategory(state.category!),
          ),
          if (state.make != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.chevron_right_rounded,
                  size: 16, color: isDark ? Colors.white30 : Colors.black26),
            ),
            _BCChip(
              label: state.make!.name,
              isActive: state.vehicleSubStep == VehicleSubStep.series,
              isDark: isDark,
              onTap: () =>
                  ref.read(clProvider.notifier).selectMake(state.make!),
            ),
          ],
          if (state.series != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.chevron_right_rounded,
                  size: 16, color: isDark ? Colors.white30 : Colors.black26),
            ),
            _BCChip(
              label: state.series!.name,
              isActive: state.vehicleSubStep == VehicleSubStep.model,
              isDark: isDark,
              onTap: () =>
                  ref.read(clProvider.notifier).selectSeries(state.series!),
            ),
          ],
        ],
      ),
    );
  }
}

class _BCChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;
  const _BCChip(
      {required this.label,
      required this.isActive,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive
                ? AppTheme.primary
                : (isDark ? Colors.white54 : Colors.black45),
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  final bool isDark;
  const _CategoryGrid({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(clProvider).category;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Araç tipi seçin',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: _categoryMeta.entries.map((e) {
              final isSelected = e.key == selected;
              return GestureDetector(
                onTap: () => ref.read(clProvider.notifier).selectCategory(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : (isDark ? AppTheme.cardDark : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        e.value.icon,
                        size: 22,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        e.value.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MakeGrid extends ConsumerWidget {
  final String category;
  final String query;
  final bool isDark;
  const _MakeGrid(
      {required this.category, required this.query, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_clMakesProvider(category));

    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(
          child: Text('Yüklenemedi',
              style: TextStyle(color: Colors.grey[500], fontSize: 14))),
      data: (makes) {
        final filtered = query.isEmpty
            ? makes
            : makes
                .where((m) => m.name.toLowerCase().contains(query))
                .toList();
        if (filtered.isEmpty) {
          return Center(
              child: Text('Sonuç yok',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14)));
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final make = filtered[i];
            return GestureDetector(
              onTap: () => ref.read(clProvider.notifier).selectMake(make),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 2))
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.grey.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: make.logoUrl != null
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: CachedNetworkImage(
                                imageUrl: make.logoUrl!,
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) => _LetterAvatar(make.name),
                              ),
                            )
                          : _LetterAvatar(make.name),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        make.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SeriesGrid extends ConsumerWidget {
  final String makeId;
  final String category;
  final String query;
  final bool isDark;
  const _SeriesGrid(
      {required this.makeId,
      required this.category,
      required this.query,
      required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_clSeriesProvider('$makeId|$category'));

    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(
          child: Text('Yüklenemedi',
              style: TextStyle(color: Colors.grey[500], fontSize: 14))),
      data: (series) {
        final filtered = query.isEmpty
            ? series
            : series
                .where((s) => s.name.toLowerCase().contains(query))
                .toList();
        if (filtered.isEmpty) {
          return Center(
              child: Text('Sonuç yok',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14)));
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _TextCard(
            label: filtered[i].name,
            isDark: isDark,
            onTap: () async {
              final models = await ref.read(catalogRepositoryProvider).fetchModels(filtered[i].id);
              ref.read(clProvider.notifier).selectSeries(filtered[i], hasModels: models.isNotEmpty);
            },
          ),
        );
      },
    );
  }
}

class _ModelGrid extends ConsumerStatefulWidget {
  final String seriesId;
  final String seriesName;
  final bool isDark;
  const _ModelGrid(
      {required this.seriesId,
      required this.seriesName,
      required this.isDark});

  @override
  ConsumerState<_ModelGrid> createState() => _ModelGridState();
}

class _ModelGridState extends ConsumerState<_ModelGrid> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_clModelsProvider(widget.seriesId));

    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(
          child: Text('Yüklenemedi',
              style: TextStyle(color: Colors.grey[500], fontSize: 14))),
      data: (models) {
        // Model yoksa info göster, İleri butonu zaten aktif olacak
        if (models.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 48, color: Colors.grey[500]),
                  const SizedBox(height: 16),
                  Text(
                    'Bu seri için alt model bulunmuyor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aşağıdaki İleri butonuna basarak devam edebilirsiniz',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final selectedModel = ref.watch(clProvider).model;

        return Column(
          children: [
            // Model opsiyonel bilgisi
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.blue.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16,
                        color: widget.isDark ? Colors.white38 : Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Model seçimi opsiyoneldir. Seçmeden de devam edebilirsiniz.',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark ? Colors.white54 : Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                itemCount: models.length,
                itemBuilder: (_, i) {
                  final isSelected = selectedModel?.id == models[i].id;
                  return _TextCard(
                    label: models[i].name,
                    isDark: widget.isDark,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(clProvider.notifier).selectModel(models[i]);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Technical Details
// ─────────────────────────────────────────────────────────────────────────────

class _TechnicalStep extends ConsumerWidget {
  final CLState state;
  final bool isDark;
  const _TechnicalStep({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(clProvider.notifier);
    final isMoto = state.category == 'MOTORSIKLET';
    final vtOptions =
        _vehicleTypesByCategory[state.category] ?? const <(String, String)>[];
    final ccOptions = _getEngineCcOptions(state.category);

    String? formatEngineCc(int? cc) {
      if (cc == null) return null;
      final match = ccOptions.where((o) => o.$1 == cc).firstOrNull;
      return match?.$2;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year — required
          _FieldTile(
            label: 'Model Yılı',
            isRequired: true,
            value: state.year?.toString(),
            placeholder: 'Seçin',
            icon: Icons.calendar_today_rounded,
            isDark: isDark,
            onTap: () async {
              final y = await showYearPicker(context, selected: state.year);
              if (y != null) notifier.setYear(y);
            },
          ),
          const SizedBox(height: 12),

          // Condition — required
          _SectionLabel(label: 'Araç Durumu *', isDark: isDark),
          const SizedBox(height: 8),
          _TwoOptionCards(
            optionA: ('NEW', 'Sıfır', Icons.fiber_new_rounded),
            optionB: ('USED', 'İkinci El', Icons.history_rounded),
            selected: state.condition,
            isDark: isDark,
            onSelect: notifier.setCondition,
          ),
          const SizedBox(height: 16),

          // Transmission — zorunlu (motorsiklet hariç)
          if (!isMoto) ...[
            _SectionLabel(label: 'Şanzıman *', isDark: isDark),
            const SizedBox(height: 8),
            _TwoOptionCards(
              optionA: ('MANUAL', 'Manuel', Icons.settings_rounded),
              optionB: ('AUTOMATIC', 'Otomatik', Icons.auto_mode_rounded),
              selected: state.transmission,
              isDark: isDark,
              onSelect: notifier.setTransmission,
              allowDeselect: false,
            ),
            const SizedBox(height: 16),
          ],

          // Vehicle Type — zorunlu
          if (vtOptions.isNotEmpty) ...[
            _FieldTile(
              label: 'Kasa Tipi',
              isRequired: true,
              value: vtOptions
                  .where((o) => o.$1 == state.vehicleType)
                  .firstOrNull
                  ?.$2,
              placeholder: 'Kasa tipini seçin',
              icon: Icons.directions_car_outlined,
              isDark: isDark,
              onTap: () async {
                final picked = await showPickerSheet(
                  context,
                  title: 'Kasa Tipi',
                  options: vtOptions
                      .map((o) => (value: o.$1, label: o.$2))
                      .toList(),
                  selected: state.vehicleType,
                  isDark: isDark,
                );
                if (picked != null) notifier.setVehicleType(picked);
              },
            ),
            const SizedBox(height: 12),
          ],

          // Fuel Type — zorunlu
          _FieldTile(
            label: 'Yakıt Tipi',
            isRequired: true,
            value: _fuelTypes
                .where((o) => o.$1 == state.fuelType)
                .firstOrNull
                ?.$2,
            placeholder: 'Yakıt tipini seçin',
            icon: Icons.local_gas_station_rounded,
            isDark: isDark,
            onTap: () async {
              final picked = await showPickerSheet(
                context,
                title: 'Yakıt Tipi',
                options: _fuelTypes
                    .map((o) => (value: o.$1, label: o.$2))
                    .toList(),
                selected: state.fuelType,
                isDark: isDark,
              );
              if (picked != null) notifier.setFuelType(picked);
            },
          ),
          const SizedBox(height: 12),

          // Drive Type — zorunlu (motorsiklet hariç)
          if (!isMoto) ...[
            _FieldTile(
              label: 'Çekiş',
              isRequired: true,
              value: _driveTypes
                  .where((o) => o.$1 == state.driveType)
                  .firstOrNull
                  ?.$2,
              placeholder: 'Çekiş tipini seçin',
              icon: Icons.settings_input_component_rounded,
              isDark: isDark,
              onTap: () async {
                final picked = await showPickerSheet(
                  context,
                  title: 'Çekiş Tipi',
                  options: _driveTypes
                      .map((o) => (value: o.$1, label: o.$2))
                      .toList(),
                  selected: state.driveType,
                  isDark: isDark,
                );
                if (picked != null) notifier.setDriveType(picked);
              },
            ),
            const SizedBox(height: 12),
          ],

          // Engine CC — zorunlu
          _FieldTile(
            label: 'Motor Hacmi',
            isRequired: true,
            value: formatEngineCc(state.engineCc),
            placeholder: 'Motor hacmini seçin',
            icon: Icons.engineering_rounded,
            isDark: isDark,
            onTap: () async {
              final picked = await showPickerSheet(
                context,
                title: 'Motor Hacmi',
                options: ccOptions
                    .map((o) => (value: o.$1.toString(), label: o.$2))
                    .toList(),
                selected: state.engineCc?.toString(),
                isDark: isDark,
              );
              if (picked != null) notifier.setEngineCc(int.tryParse(picked));
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Listing Info
// ─────────────────────────────────────────────────────────────────────────────

class _InfoStep extends ConsumerStatefulWidget {
  final CLState state;
  final bool isDark;
  const _InfoStep({required this.state, required this.isDark});

  @override
  ConsumerState<_InfoStep> createState() => _InfoStepState();
}

class _InfoStepState extends ConsumerState<_InfoStep> {
  late final TextEditingController _priceCtrl;
  late final TextEditingController _mileageCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(clProvider);
    _priceCtrl = TextEditingController(text: s.price);
    _mileageCtrl = TextEditingController(text: s.mileage);
    _titleCtrl = TextEditingController(text: s.title);
    _descCtrl = TextEditingController(text: s.description);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _mileageCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(clProvider.notifier);
    final s = ref.watch(clProvider);
    final isDark = widget.isDark;

    final inputStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : Colors.black87,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Currency toggle
          Row(
            children: [
              _SectionLabel(label: 'Fiyat *', isDark: isDark),
              const Spacer(),
              Container(
                height: 34,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['GBP', 'TRY'].map((c) {
                    final isSelected = s.currency == c;
                    return GestureDetector(
                      onTap: () => notifier.setCurrency(c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          c,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white54 : Colors.black45),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Price field
          _InputField(
            controller: _priceCtrl,
            placeholder: '0',
            prefix: s.currency == 'GBP' ? '£' : '₺',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            isDark: isDark,
            onChanged: notifier.setPrice,
          ),
          const SizedBox(height: 16),

          // Mileage
          _SectionLabel(label: 'Kilometre *', isDark: isDark),
          const SizedBox(height: 8),
          _InputField(
            controller: _mileageCtrl,
            placeholder: '0',
            suffix: 'km',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            isDark: isDark,
            onChanged: notifier.setMileage,
          ),
          const SizedBox(height: 16),

          // Color
          _SectionLabel(label: 'Renk *', isDark: isDark),
          const SizedBox(height: 12),
          _ColorGrid(selectedColor: s.color, isDark: isDark),
          const SizedBox(height: 16),

          // Title
          _SectionLabel(label: 'İlan Başlığı *', isDark: isDark),
          const SizedBox(height: 4),
          Text(
            'Otomatik oluşturuldu, düzenleyebilirsiniz',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
            ),
            child: TextField(
              controller: _titleCtrl,
              style: inputStyle,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Örn: 2020 BMW 3 Serisi 320i',
                hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black26,
                    fontSize: 14,
                    fontWeight: FontWeight.w400),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                counterStyle: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white30 : Colors.black.withValues(alpha: 0.30)),
              ),
              onChanged: notifier.setTitle,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          _SectionLabel(label: 'Açıklama *', isDark: isDark),
          const SizedBox(height: 4),
          Text(
            'En az 10 karakter',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
            ),
            child: TextField(
              controller: _descCtrl,
              style: inputStyle,
              maxLines: 6,
              maxLength: 5000,
              decoration: InputDecoration(
                hintText:
                    'Araç hakkında detaylı bilgi verin...\n(Ekstra özellikler, bakım geçmişi, hasar durumu vs.)',
                hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black26,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                counterStyle: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white30 : Colors.black.withValues(alpha: 0.30)),
              ),
              onChanged: notifier.setDescription,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorGrid extends ConsumerWidget {
  final String? selectedColor;
  final bool isDark;
  const _ColorGrid({required this.selectedColor, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _colors.map((c) {
        final isSelected = c.$1 == selectedColor;
        final isLight = c.$2 == const Color(0xFFFFFFFF) ||
            c.$2 == const Color(0xFFD7CCC8) ||
            c.$2 == const Color(0xFFFFD700) ||
            c.$2 == const Color(0xFFFFC107) ||
            c.$2 == const Color(0xFFC0C0C0);

        return GestureDetector(
          onTap: () => ref.read(clProvider.notifier).setColor(c.$1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.$2,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: AppTheme.primary, width: 3)
                      : Border.all(
                          color: isLight
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.transparent,
                          width: 1),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1)
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(Icons.check_rounded,
                        size: 20,
                        color: isLight ? Colors.black87 : Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 44,
                child: Text(
                  c.$1,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primary
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Location
// ─────────────────────────────────────────────────────────────────────────────

class _LocationStep extends ConsumerWidget {
  final CLState state;
  final bool isDark;
  const _LocationStep({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İlanın yayınlanacağı şehri seçin',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: _cyprusCities.map((city) {
              final isSelected = city.name == state.city;
              return GestureDetector(
                onTap: () =>
                    ref.read(clProvider.notifier).setCity(city.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : (isDark ? AppTheme.cardDark : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.black.withValues(alpha: 0.08)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        city.icon,
                        size: 28,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white60 : AppTheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        city.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        city.desc,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white70
                              : (isDark ? Colors.white38 : Colors.black38),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Photos
// ─────────────────────────────────────────────────────────────────────────────

class _PhotosStep extends ConsumerStatefulWidget {
  final CLState state;
  final bool isDark;
  const _PhotosStep({required this.state, required this.isDark});

  @override
  ConsumerState<_PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends ConsumerState<_PhotosStep> {
  final _picker = ImagePicker();

  Future<void> _pickImages() async {
    final remaining = 10 - ref.read(clProvider).images.length;
    if (remaining <= 0) return;

    final picked = await _picker.pickMultiImage(limit: remaining);
    if (picked.isNotEmpty) {
      ref.read(clProvider.notifier).addImages(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(clProvider).images;
    final isDark = widget.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Text(
                'Fotoğraflar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: images.isEmpty
                      ? Colors.orange.withValues(alpha: 0.15)
                      : AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${images.length}/10',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: images.isEmpty ? Colors.orange : AppTheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (images.length < 10)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add_photo_alternate_rounded,
                            size: 16, color: AppTheme.primary),
                        SizedBox(width: 6),
                        Text('Ekle',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'İlk fotoğraf kapak resmi olarak kullanılır. Sürükleyerek sıralayabilirsiniz.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (images.isEmpty)
          Expanded(
            child: GestureDetector(
              onTap: _pickImages,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_photo_alternate_rounded,
                          size: 34, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Fotoğraf Ekle',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'En az 1, en fazla 10 fotoğraf',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              onReorder: ref.read(clProvider.notifier).reorderImages,
              proxyDecorator: (child, index, animation) => child,
              itemCount: images.length + (images.length < 10 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == images.length) {
                  return _AddPhotoTile(
                      key: const ValueKey('add'), isDark: isDark, onTap: _pickImages);
                }
                final image = images[index];
                return _PhotoTile(
                  key: ValueKey(image.path),
                  image: image,
                  index: index,
                  isDark: isDark,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PhotoTile extends ConsumerWidget {
  final XFile image;
  final int index;
  final bool isDark;
  const _PhotoTile(
      {required this.image,
      required this.index,
      required this.isDark,
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: index == 0
            ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(13),
              bottomLeft: Radius.circular(13),
            ),
            child: SizedBox(
              width: 90,
              height: 90,
              child: _XFileImage(xfile: image),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (index == 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Kapak Fotoğrafı',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary)),
                  ),
                if (index > 0)
                  Text(
                    'Fotoğraf ${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: Colors.red[400], size: 22),
            onPressed: () =>
                ref.read(clProvider.notifier).removeImage(index),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.drag_handle_rounded,
                color: Colors.grey, size: 20),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _AddPhotoTile(
      {required this.isDark, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                color: AppTheme.primary.withValues(alpha: 0.7), size: 24),
            const SizedBox(width: 10),
            Text('Fotoğraf Ekle',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

class _XFileImage extends StatefulWidget {
  final XFile xfile;
  const _XFileImage({required this.xfile});

  @override
  State<_XFileImage> createState() => _XFileImageState();
}

class _XFileImageState extends State<_XFileImage> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.xfile.readAsBytes();
    if (mounted) setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) {
      return Container(
        color: AppTheme.cardDark,
        child: const Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.primary)),
      );
    }
    return Image.memory(_bytes!, fit: BoxFit.cover);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5 — Boost
// ─────────────────────────────────────────────────────────────────────────────

class _BoostStep extends ConsumerWidget {
  final bool isDark;
  const _BoostStep({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(clProvider).boostType;
    final notifier = ref.read(clProvider.notifier);

    const options = [
      (
        value: 'NONE',
        title: 'Normal İlan',
        subtitle: 'İlanınız standart listede görünür',
        icon: Icons.list_alt_rounded,
        badge: 'Ücretsiz',
        isFree: true,
      ),
      (
        value: 'HOMEPAGE',
        title: 'Anasayfa İlanı',
        subtitle: 'İlanınız anasayfada öne çıkar',
        icon: Icons.star_rounded,
        badge: 'Yakında',
        isFree: false,
      ),
      (
        value: 'URGENT',
        title: 'Acil İlan',
        subtitle: 'İlanınız "Acil" etiketi ile görünür',
        icon: Icons.bolt_rounded,
        badge: 'Yakında',
        isFree: false,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İlanınızı öne çıkarmak ister misiniz?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((opt) {
            final isSelected = selected == opt.value;
            final isDisabled = !opt.isFree;

            return GestureDetector(
              onTap: isDisabled ? null : () => notifier.setBoostType(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : (isDark ? AppTheme.cardDark : Colors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : isDisabled
                            ? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05))
                            : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        opt.icon,
                        size: 24,
                        color: isSelected
                            ? AppTheme.primary
                            : (isDisabled
                                ? (isDark ? Colors.white30 : Colors.black26)
                                : (isDark ? Colors.white60 : Colors.black54)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDisabled
                                  ? (isDark ? Colors.white38 : Colors.black38)
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opt.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: opt.isFree
                                ? Colors.green.withValues(alpha: 0.12)
                                : Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            opt.badge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: opt.isFree ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 6),
                          const Icon(Icons.check_circle_rounded,
                              color: AppTheme.primary, size: 20),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LetterAvatar extends StatelessWidget {
  final String name;
  const _LetterAvatar(this.name);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;
  const _TextCard(
      {required this.label,
      required this.isDark,
      required this.onTap,
      this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : (isDark ? AppTheme.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05)),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String? value;
  final String placeholder;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _FieldTile({
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.value,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: hasValue
                    ? AppTheme.primary
                    : (isDark ? Colors.white38 : Colors.black38)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isRequired ? '$label *' : label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? value! : placeholder,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.white30 : Colors.black.withValues(alpha: 0.30)),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.white38 : Colors.black38, size: 22),
          ],
        ),
      ),
    );
  }
}

class _TwoOptionCards extends StatelessWidget {
  final (String, String, IconData) optionA;
  final (String, String, IconData) optionB;
  final String? selected;
  final bool isDark;
  final void Function(String) onSelect;
  final bool allowDeselect;

  const _TwoOptionCards({
    required this.optionA,
    required this.optionB,
    required this.selected,
    required this.isDark,
    required this.onSelect,
    this.allowDeselect = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [optionA, optionB].map((opt) {
        final isSelected = selected == opt.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (allowDeselect && isSelected) {
                onSelect('');
              } else {
                onSelect(opt.$1);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                  right: opt == optionA ? 6 : 0,
                  left: opt == optionB ? 6 : 0),
              height: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : (isDark ? AppTheme.cardDark : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDark
                            ? Colors.white12
                            : Colors.black.withValues(alpha: 0.08)),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3))
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    opt.$3,
                    size: 20,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    opt.$2,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final String? prefix;
  final String? suffix;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final bool isDark;
  final void Function(String) onChanged;

  const _InputField({
    required this.controller,
    required this.placeholder,
    required this.keyboardType,
    required this.inputFormatters,
    required this.isDark,
    required this.onChanged,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          if (prefix != null)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                prefix!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black26,
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              onChanged: onChanged,
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                suffix!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Picker Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

Future<String?> showPickerSheet(
  BuildContext context, {
  required String title,
  required List<({String value, String label})> options,
  String? selected,
  bool isDark = true,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _PickerSheet(
      title: title,
      options: options,
      selected: selected,
    ),
  );
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<({String value, String label})> options;
  final String? selected;
  const _PickerSheet(
      {required this.title, required this.options, this.selected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxH = MediaQuery.of(context).size.height * 0.7;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Options
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: options.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 20,
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
              ),
              itemBuilder: (_, i) {
                final opt = options[i];
                final isSelected = opt.value == selected;
                return InkWell(
                  onTap: () => Navigator.pop(context, opt.value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primary
                                  : (isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_rounded,
                              color: AppTheme.primary, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Year Picker
// ─────────────────────────────────────────────────────────────────────────────

Future<int?> showYearPicker(BuildContext context, {int? selected}) {
  final currentYear = DateTime.now().year;
  final years = List.generate(currentYear - 1979, (i) => currentYear - i);
  final initialIndex =
      selected != null ? years.indexOf(selected).clamp(0, years.length - 1) : 0;

  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      int pickedYear = selected ?? currentYear;
      final controller =
          FixedExtentScrollController(initialItem: initialIndex);

      return Container(
        height: 380,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Text(
                    'Model Yılı',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Selection highlight
                  Container(
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    controller: controller,
                    itemExtent: 52,
                    perspective: 0.004,
                    diameterRatio: 2.5,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => pickedYear = years[i],
                    childDelegate: ListWheelChildListDelegate(
                      children: years.map((y) {
                        return Center(
                          child: Text(
                            y.toString(),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, pickedYear),
                  child: const Text('Seç',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
