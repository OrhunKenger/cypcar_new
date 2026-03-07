import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/features/catalog/domain/models/catalog_models.dart';

enum SearchStep { make, series, model }

class SearchFilters {
  final int? yearMin;
  final int? yearMax;
  final double? priceMin;
  final double? priceMax;
  final int? mileageMax;
  final String? fuelType;
  final String? transmission;
  final String? driveType;
  final String? condition;
  final String? color;
  final String sort;

  const SearchFilters({
    this.yearMin,
    this.yearMax,
    this.priceMin,
    this.priceMax,
    this.mileageMax,
    this.fuelType,
    this.transmission,
    this.driveType,
    this.condition,
    this.color,
    this.sort = 'newest',
  });

  SearchFilters copyWith({
    int? yearMin,
    int? yearMax,
    double? priceMin,
    double? priceMax,
    int? mileageMax,
    String? fuelType,
    String? transmission,
    String? driveType,
    String? condition,
    String? color,
    String? sort,
    bool clearFuelType = false,
    bool clearTransmission = false,
    bool clearDriveType = false,
    bool clearCondition = false,
    bool clearColor = false,
  }) =>
      SearchFilters(
        yearMin: yearMin ?? this.yearMin,
        yearMax: yearMax ?? this.yearMax,
        priceMin: priceMin ?? this.priceMin,
        priceMax: priceMax ?? this.priceMax,
        mileageMax: mileageMax ?? this.mileageMax,
        fuelType: clearFuelType ? null : (fuelType ?? this.fuelType),
        transmission: clearTransmission ? null : (transmission ?? this.transmission),
        driveType: clearDriveType ? null : (driveType ?? this.driveType),
        condition: clearCondition ? null : (condition ?? this.condition),
        color: clearColor ? null : (color ?? this.color),
        sort: sort ?? this.sort,
      );

  Map<String, dynamic> toQueryParams() {
    return {
      if (yearMin != null) 'year_min': yearMin,
      if (yearMax != null) 'year_max': yearMax,
      if (priceMin != null) 'price_min': priceMin,
      if (priceMax != null) 'price_max': priceMax,
      if (mileageMax != null) 'mileage_max': mileageMax,
      if (fuelType != null) 'fuel_type': fuelType,
      if (transmission != null) 'transmission': transmission,
      if (driveType != null) 'drive_type': driveType,
      if (condition != null) 'condition': condition,
      if (color != null) 'color': color,
      'sort': sort,
    };
  }

  bool get hasActiveFilters =>
      yearMin != null ||
      yearMax != null ||
      priceMin != null ||
      priceMax != null ||
      mileageMax != null ||
      fuelType != null ||
      transmission != null ||
      driveType != null ||
      condition != null ||
      color != null;
}

class SearchState {
  final String selectedCategory;
  final MakeModel? selectedMake;
  final SeriesModel? selectedSeries;
  final VehicleModelModel? selectedModel;
  final SearchFilters filters;
  final SearchStep step;

  const SearchState({
    required this.selectedCategory,
    this.selectedMake,
    this.selectedSeries,
    this.selectedModel,
    this.filters = const SearchFilters(),
    this.step = SearchStep.make,
  });

  SearchState copyWith({
    String? selectedCategory,
    MakeModel? selectedMake,
    SeriesModel? selectedSeries,
    VehicleModelModel? selectedModel,
    SearchFilters? filters,
    SearchStep? step,
    bool clearMake = false,
    bool clearSeries = false,
    bool clearModel = false,
  }) =>
      SearchState(
        selectedCategory: selectedCategory ?? this.selectedCategory,
        selectedMake: clearMake ? null : (selectedMake ?? this.selectedMake),
        selectedSeries: clearSeries ? null : (selectedSeries ?? this.selectedSeries),
        selectedModel: clearModel ? null : (selectedModel ?? this.selectedModel),
        filters: filters ?? this.filters,
        step: step ?? this.step,
      );

  Map<String, dynamic> toQueryParams() => {
        'category': selectedCategory,
        if (selectedMake != null) 'make_id': selectedMake!.id,
        if (selectedSeries != null) 'series_id': selectedSeries!.id,
        if (selectedModel != null) 'model_id': selectedModel!.id,
        'status': 'ACTIVE',
        ...filters.toQueryParams(),
      };
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier()
      : super(const SearchState(selectedCategory: 'OTOMOBIL'));

  void selectCategory(String category) {
    state = SearchState(
      selectedCategory: category,
      step: SearchStep.make,
    );
  }

  void selectMake(MakeModel make) {
    state = state.copyWith(
      selectedMake: make,
      clearSeries: true,
      clearModel: true,
      step: SearchStep.series,
    );
  }

  void selectSeries(SeriesModel series) {
    state = state.copyWith(
      selectedSeries: series,
      clearModel: true,
      step: SearchStep.model,
    );
  }

  void selectModel(VehicleModelModel model) {
    state = state.copyWith(selectedModel: model);
  }

  void updateFilters(SearchFilters filters) {
    state = state.copyWith(filters: filters);
  }

  void goBack() {
    switch (state.step) {
      case SearchStep.series:
        state = state.copyWith(
          clearMake: true,
          clearSeries: true,
          clearModel: true,
          step: SearchStep.make,
        );
      case SearchStep.model:
        state = state.copyWith(
          clearSeries: true,
          clearModel: true,
          step: SearchStep.series,
        );
      case SearchStep.make:
        break;
    }
  }

  void reset() {
    state = SearchState(selectedCategory: state.selectedCategory);
  }
}
