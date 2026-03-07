import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/features/catalog/data/catalog_repository.dart';
import 'package:cypcar/features/catalog/domain/models/catalog_models.dart';
import 'package:cypcar/features/search/presentation/providers/search_provider.dart';
import 'package:cypcar/features/search/presentation/widgets/filter_bottom_sheet.dart';
import 'package:cypcar/shared/providers/catalog_provider.dart';

const _categoryMeta = {
  'OTOMOBIL':       (label: 'Otomobil',   icon: Icons.directions_car_rounded),
  'ARAZI_SUV_PICKUP': (label: 'Arazi & SUV', icon: Icons.terrain_rounded),
  'MOTORSIKLET':    (label: 'Motorsiklet', icon: Icons.two_wheeler_rounded),
  'TICARI':         (label: 'Ticari',      icon: Icons.local_shipping_rounded),
};

final _makesProvider = FutureProvider.family<List<MakeModel>, String>((ref, cat) {
  return ref.watch(catalogRepositoryProvider).fetchMakes(cat);
});

final _seriesProvider = FutureProvider.family<List<SeriesModel>, String>((ref, key) {
  final parts = key.split('|');
  return ref.watch(catalogRepositoryProvider).fetchSeries(parts[0], category: parts[1]);
});

final _modelsProvider = FutureProvider.family<List<VehicleModelModel>, String>((ref, seriesId) {
  return ref.watch(catalogRepositoryProvider).fetchModels(seriesId);
});

// ─────────────────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const SearchScreen({super.key, this.initialCategory});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchProvider.notifier).selectCategory(widget.initialCategory!);
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Step değişince arama temizle
    ref.listen(searchProvider.select((s) => s.step), (_, __) => _clearSearch());

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
      appBar: _buildAppBar(state, isDark),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryChips(),
          if (state.selectedMake != null) _Breadcrumb(state: state),
          // Arama barı (make ve series adımında)
          if (state.step != SearchStep.model)
            _SearchBar(controller: _searchCtrl, query: _query, step: state.step),
          Expanded(child: _buildContent(state, isDark)),
        ],
      ),
      bottomNavigationBar: state.step != SearchStep.model
          ? _BottomSearchBar(state: state)
          : null,
    );
  }

  AppBar _buildAppBar(SearchState state, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () {
          if (state.step == SearchStep.make) {
            context.pop();
          } else {
            _clearSearch();
            ref.read(searchProvider.notifier).goBack();
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Araç Bul',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          Text(
            _stepLabel(state),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => showFilterSheet(context),
            ),
            if (state.filters.hasActiveFilters)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  String _stepLabel(SearchState state) {
    switch (state.step) {
      case SearchStep.make:   return 'Marka seçin';
      case SearchStep.series: return '${state.selectedMake?.name ?? ''} · Seri seçin';
      case SearchStep.model:  return '${state.selectedSeries?.name ?? ''} · Model seçin';
    }
  }

  Widget _buildContent(SearchState state, bool isDark) {
    switch (state.step) {
      case SearchStep.make:
        return _MakeGrid(
          category: state.selectedCategory,
          query: _query,
          key: ValueKey('make_${state.selectedCategory}'),
        );
      case SearchStep.series:
        return _SeriesList(
          makeId: state.selectedMake!.id,
          category: state.selectedCategory,
          query: _query,
          key: ValueKey('series_${state.selectedMake!.id}_${state.selectedCategory}'),
        );
      case SearchStep.model:
        return _ModelList(
          seriesId: state.selectedSeries!.id,
          seriesName: state.selectedSeries!.name,
          key: ValueKey('model_${state.selectedSeries!.id}'),
        );
    }
  }
}

// ── Arama Barı ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final SearchStep step;
  const _SearchBar({required this.controller, required this.query, required this.step});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hint = step == SearchStep.make ? 'Marka ara...' : 'Seri ara...';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
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

// ── Kategori Chips ────────────────────────────────────────────────────────────

class _CategoryChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? _categoryMeta.keys.toList();
    final selected = ref.watch(searchProvider).selectedCategory;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = cats[i];
          final meta = _categoryMeta[cat];
          final isSelected = cat == selected;

          return GestureDetector(
            onTap: () => ref.read(searchProvider.notifier).selectCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : (isDark ? AppTheme.cardDark : Colors.white),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  else if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    meta?.icon ?? Icons.directions_car,
                    size: 15,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white54 : Colors.grey[600]),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    meta?.label ?? cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Breadcrumb ────────────────────────────────────────────────────────────────

class _Breadcrumb extends ConsumerWidget {
  final SearchState state;
  const _Breadcrumb({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref.read(searchProvider.notifier).selectCategory(state.selectedCategory),
            child: _BreadcrumbChip(
              label: state.selectedMake!.name,
              isActive: state.step == SearchStep.series,
              isDark: isDark,
            ),
          ),
          if (state.selectedSeries != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.chevron_right_rounded, size: 16,
                  color: isDark ? Colors.white30 : Colors.black26),
            ),
            GestureDetector(
              onTap: state.step == SearchStep.model
                  ? () => ref.read(searchProvider.notifier).selectMake(state.selectedMake!)
                  : null,
              child: _BreadcrumbChip(
                label: state.selectedSeries!.name,
                isActive: state.step == SearchStep.model,
                isDark: isDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  const _BreadcrumbChip({required this.label, required this.isActive, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primary.withValues(alpha: 0.12)
            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
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
    );
  }
}

// ── Marka Grid ────────────────────────────────────────────────────────────────

class _MakeGrid extends ConsumerWidget {
  final String category;
  final String query;
  const _MakeGrid({required this.category, required this.query, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_makesProvider(category));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => _ErrorState(),
      data: (makes) {
        final filtered = query.isEmpty
            ? makes
            : makes.where((m) => m.name.toLowerCase().contains(query)).toList();

        if (filtered.isEmpty) {
          return _EmptyState(message: query.isEmpty ? 'Bu kategoride marka yok' : '"$query" bulunamadı');
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _MakeCard(make: filtered[i], isDark: isDark),
        );
      },
    );
  }
}

class _MakeCard extends ConsumerWidget {
  final MakeModel make;
  final bool isDark;
  const _MakeCard({required this.make, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(searchProvider.notifier).selectMake(make),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
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
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: make.logoUrl != null
                  ? Padding(
                      padding: const EdgeInsets.all(6), // Padding düşürüldü (10 -> 6)
                      child: CachedNetworkImage(
                        imageUrl: make.logoUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _LetterAvatar(name: make.name),
                      ),
                    )
                  : _LetterAvatar(name: make.name),
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
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  final String name;
  const _LetterAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Ortak metin kartı (seri & model) ─────────────────────────────────────────

class _TextCard extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _TextCard({required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
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
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Seri Listesi ──────────────────────────────────────────────────────────────

class _SeriesList extends ConsumerWidget {
  final String makeId;
  final String category;
  final String query;
  const _SeriesList({required this.makeId, required this.category, required this.query, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_seriesProvider('$makeId|$category'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => _ErrorState(),
      data: (series) {
        final filtered = query.isEmpty
            ? series
            : series.where((s) => s.name.toLowerCase().contains(query)).toList();

        if (filtered.isEmpty) {
          return _EmptyState(message: query.isEmpty ? 'Seri bulunamadı' : '"$query" bulunamadı');
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
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
            onTap: () => ref.read(searchProvider.notifier).selectSeries(filtered[i]),
          ),
        );
      },
    );
  }
}

// ── Model Listesi ─────────────────────────────────────────────────────────────

class _ModelList extends ConsumerStatefulWidget {
  final String seriesId;
  final String seriesName;
  const _ModelList({required this.seriesId, required this.seriesName, super.key});

  @override
  ConsumerState<_ModelList> createState() => _ModelListState();
}

class _ModelListState extends ConsumerState<_ModelList> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_modelsProvider(widget.seriesId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.read(searchProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => _ErrorState(),
      data: (models) {
        if (models.isEmpty && !_navigated) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _goToResults(context, state);
          });
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

        return Column(
          children: [
            // "Tüm seri ilanlarını gör" butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: GestureDetector(
                onTap: () => _goToResults(context, state),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.15),
                        AppTheme.primary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_rounded, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Tüm ${widget.seriesName} ilanlarını gör',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                itemCount: models.length,
                itemBuilder: (_, i) => _TextCard(
                  label: models[i].name,
                  isDark: isDark,
                  onTap: () {
                    ref.read(searchProvider.notifier).selectModel(models[i]);
                    _goToResults(context, ref.read(searchProvider));
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


// ── Alt Arama Butonu ──────────────────────────────────────────────────────────

class _BottomSearchBar extends ConsumerWidget {
  final SearchState state;
  const _BottomSearchBar({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = state.selectedMake == null
        ? 'Tüm İlanları Gör'
        : state.selectedSeries != null
            ? '${state.selectedSeries!.name} İlanlarını Gör'
            : '${state.selectedMake!.name} İlanlarını Gör';

    return Container(
      color: isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => _goToResults(context, state),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Yardımcı widget'lar ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.withValues(alpha: 0.35)),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Yüklenemedi',
          style: TextStyle(color: Colors.grey[500], fontSize: 14)),
    );
  }
}

// ── Sonuçlara git ─────────────────────────────────────────────────────────────

void _goToResults(BuildContext context, SearchState state) {
  final params = state.toQueryParams();
  final queryString = params.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
      .join('&');
  context.push('/search/results?$queryString');
}
