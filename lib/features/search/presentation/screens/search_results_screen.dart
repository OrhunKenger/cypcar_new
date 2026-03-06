import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cypcar/core/api/api_client.dart';
import 'package:cypcar/core/api/api_endpoints.dart';
import 'package:cypcar/core/providers/currency_provider.dart';
import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/features/listings/domain/models/listing_model.dart';
import 'package:cypcar/features/search/presentation/providers/search_provider.dart';
import 'package:cypcar/features/search/presentation/widgets/filter_bottom_sheet.dart';
import 'package:cypcar/shared/models/app_settings_model.dart';
import 'package:cypcar/shared/models/exchange_rate_model.dart';
import 'package:cypcar/shared/providers/app_settings_provider.dart';
import 'package:cypcar/shared/providers/exchange_rate_provider.dart';
import 'package:cypcar/shared/widgets/listing_card.dart';

// String key kullanıyoruz — Map Dart'ta reference-equality yüzünden her seferinde yeni istek atardı
final _resultsProvider = FutureProvider.family<List<Listing>, String>((ref, queryString) async {
  final client = ref.watch(apiClientProvider);
  final params = Uri.splitQueryString(queryString);
  final response = await client.dio.get(
    ApiEndpoints.listings,
    queryParameters: {...params, 'status': 'ACTIVE', 'size': '50'},
  );
  return PaginatedListings.fromJson(response.data).items;
});

class SearchResultsScreen extends ConsumerWidget {
  final Map<String, String> queryParams;
  const SearchResultsScreen({super.key, required this.queryParams});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);
    final exchangeRate = ref.watch(exchangeRateProvider).valueOrNull ?? ExchangeRate.fallback();
    final settings = ref.watch(appSettingsProvider).valueOrNull ?? AppSettings.defaults();
    final displayCurrency = ref.watch(currencyProvider);

    // String key — rebuild'lerde aynı istek tekrar atılmaz
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final resultsAsync = ref.watch(_resultsProvider(queryString));

    String title() {
      final parts = <String>[];
      if (queryParams['make_id'] != null && state.selectedMake != null) {
        parts.add(state.selectedMake!.name);
      }
      if (queryParams['series_id'] != null && state.selectedSeries != null) {
        parts.add(state.selectedSeries!.name);
      }
      if (queryParams['model_id'] != null && state.selectedModel != null) {
        parts.add(state.selectedModel!.name);
      }
      return parts.isEmpty ? 'Arama Sonuçları' : parts.join(' › ');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                  top: 8,
                  right: 8,
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
        ],
      ),
      body: resultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 64,
                      color: Colors.grey.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text('Sonuç bulunamadı',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Filtrelerinizi değiştirmeyi deneyin',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Sonuç sayısı
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '${listings.length} ilan bulundu',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, i) => ListingCard(
                    listing: listings[i],
                    exchangeRate: exchangeRate,
                    settings: settings,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
