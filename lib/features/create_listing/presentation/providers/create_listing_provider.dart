import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cypcar/features/catalog/domain/models/catalog_models.dart';

enum CLStep { vehicle, technical, info, location, photos, boost }

enum VehicleSubStep { category, make, series, model }

// ─────────────────────────────────────────────────────────────────────────────

class CLState {
  final CLStep step;
  final VehicleSubStep vehicleSubStep;
  final bool isSubmitting;
  final String? submitError;

  // Step 0 — Vehicle
  final String? category;
  final MakeModel? make;
  final SeriesModel? series;
  final VehicleModelModel? model;

  // Step 1 — Technical
  final int? year;
  final String? condition;    // NEW / USED
  final String? vehicleType;
  final String? fuelType;
  final String? transmission;
  final String? driveType;
  final int? engineCc;

  // Step 2 — Info
  final String price;
  final String currency;      // GBP / TRY
  final String mileage;
  final String? color;
  final String title;
  final String description;

  // Step 3 — Location
  final String? city;

  // Step 4 — Photos
  final List<XFile> images;

  // Step 5 — Boost
  final String boostType;     // NONE / HOMEPAGE / URGENT

  const CLState({
    this.step = CLStep.vehicle,
    this.vehicleSubStep = VehicleSubStep.category,
    this.isSubmitting = false,
    this.submitError,
    this.category,
    this.make,
    this.series,
    this.model,
    this.year,
    this.condition,
    this.vehicleType,
    this.fuelType,
    this.transmission,
    this.driveType,
    this.engineCc,
    this.price = '',
    this.currency = 'GBP',
    this.mileage = '',
    this.color,
    this.title = '',
    this.description = '',
    this.city,
    this.images = const [],
    this.boostType = 'NONE',
  });

  String get autoTitle {
    return [
      if (year != null) year.toString(),
      if (make != null) make!.name,
      if (series != null) series!.name,
      if (model != null) model!.name,
    ].join(' ');
  }

  bool get canProceedStep0 => category != null && make != null && series != null;

  bool get canProceedStep1 {
    if (year == null || condition == null) return false;
    if (fuelType == null || engineCc == null) return false;
    if (vehicleType == null) return false;
    final isMoto = category == 'MOTORSIKLET';
    if (!isMoto) {
      if (transmission == null || transmission!.isEmpty) return false;
      if (driveType == null) return false;
    }
    return true;
  }

  bool get canProceedStep2 {
    final p = double.tryParse(price.replaceAll(',', '.'));
    final m = int.tryParse(mileage);
    return p != null &&
        p > 0 &&
        m != null &&
        m >= 0 &&
        color != null &&
        description.trim().length >= 10 &&
        title.trim().length >= 5;
  }

  bool get canProceedStep3 => city != null;
  bool get canProceedStep4 => images.isNotEmpty;

  CLState copyWith({
    CLStep? step,
    VehicleSubStep? vehicleSubStep,
    bool? isSubmitting,
    Object? submitError = _keep,
    Object? category = _keep,
    Object? make = _keep,
    Object? series = _keep,
    Object? model = _keep,
    Object? year = _keep,
    Object? condition = _keep,
    Object? vehicleType = _keep,
    Object? fuelType = _keep,
    Object? transmission = _keep,
    Object? driveType = _keep,
    Object? engineCc = _keep,
    String? price,
    String? currency,
    String? mileage,
    Object? color = _keep,
    String? title,
    String? description,
    Object? city = _keep,
    List<XFile>? images,
    String? boostType,
  }) {
    return CLState(
      step: step ?? this.step,
      vehicleSubStep: vehicleSubStep ?? this.vehicleSubStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError == _keep ? this.submitError : submitError as String?,
      category: category == _keep ? this.category : category as String?,
      make: make == _keep ? this.make : make as MakeModel?,
      series: series == _keep ? this.series : series as SeriesModel?,
      model: model == _keep ? this.model : model as VehicleModelModel?,
      year: year == _keep ? this.year : year as int?,
      condition: condition == _keep ? this.condition : condition as String?,
      vehicleType: vehicleType == _keep ? this.vehicleType : vehicleType as String?,
      fuelType: fuelType == _keep ? this.fuelType : fuelType as String?,
      transmission: transmission == _keep ? this.transmission : transmission as String?,
      driveType: driveType == _keep ? this.driveType : driveType as String?,
      engineCc: engineCc == _keep ? this.engineCc : engineCc as int?,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      mileage: mileage ?? this.mileage,
      color: color == _keep ? this.color : color as String?,
      title: title ?? this.title,
      description: description ?? this.description,
      city: city == _keep ? this.city : city as String?,
      images: images ?? this.images,
      boostType: boostType ?? this.boostType,
    );
  }
}

const _keep = Object();

// ─────────────────────────────────────────────────────────────────────────────

class CLNotifier extends StateNotifier<CLState> {
  CLNotifier() : super(const CLState());

  // ── Vehicle ───────────────────────────────────────────────────────────

  void selectCategory(String cat) => state = state.copyWith(
        category: cat,
        vehicleSubStep: VehicleSubStep.make,
        make: null,
        series: null,
        model: null,
      );

  void selectMake(MakeModel m) => state = state.copyWith(
        make: m,
        vehicleSubStep: VehicleSubStep.series,
        series: null,
        model: null,
      );

  void selectSeries(SeriesModel s, {bool hasModels = true}) {
    state = state.copyWith(
      series: s,
      vehicleSubStep: hasModels ? VehicleSubStep.model : VehicleSubStep.model,
      model: null,
    );
    if (!hasModels) {
      nextStep();
    }
  }

  void selectModel(VehicleModelModel? m) {
    state = state.copyWith(model: m);
    nextStep();
  }

  void vehicleGoBack() {
    switch (state.vehicleSubStep) {
      case VehicleSubStep.make:
        state = state.copyWith(
            vehicleSubStep: VehicleSubStep.category, make: null, series: null, model: null);
      case VehicleSubStep.series:
        state = state.copyWith(vehicleSubStep: VehicleSubStep.make, series: null, model: null);
      case VehicleSubStep.model:
        state = state.copyWith(vehicleSubStep: VehicleSubStep.series, model: null);
      case VehicleSubStep.category:
        break;
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────

  void goToStep(int i) {
    if (i < 0 || i >= CLStep.values.length) return;
    if (i > state.step.index) return;
    state = state.copyWith(
      step: CLStep.values[i],
      vehicleSubStep: CLStep.values[i] == CLStep.vehicle ? VehicleSubStep.category : null,
    );
  }

  void nextStep({bool isPaidEnabled = false}) {
    final next = state.step.index + 1;
    // Skip boost step if paid features disabled
    final maxStep = isPaidEnabled ? CLStep.values.length - 1 : CLStep.photos.index;
    if (next > maxStep) return;

    final nextStepVal = CLStep.values[next];
    // Auto-fill title when entering info step
    if (nextStepVal == CLStep.info && state.title.isEmpty) {
      state = state.copyWith(step: nextStepVal, title: state.autoTitle);
    } else {
      state = state.copyWith(step: nextStepVal);
    }
  }

  // ── Technical ─────────────────────────────────────────────────────────

  void setYear(int y) => state = state.copyWith(year: y);
  void setCondition(String c) => state = state.copyWith(condition: c);
  void setVehicleType(String? vt) => state = state.copyWith(vehicleType: vt);
  void setFuelType(String? ft) => state = state.copyWith(fuelType: ft);
  void setTransmission(String? t) => state = state.copyWith(transmission: t);
  void setDriveType(String? dt) => state = state.copyWith(driveType: dt);
  void setEngineCc(int? cc) => state = state.copyWith(engineCc: cc);

  // ── Info ──────────────────────────────────────────────────────────────

  void setPrice(String p) => state = state.copyWith(price: p);
  void setCurrency(String c) => state = state.copyWith(currency: c);
  void setMileage(String m) => state = state.copyWith(mileage: m);
  void setColor(String? c) => state = state.copyWith(color: c);
  void setTitle(String t) => state = state.copyWith(title: t);
  void setDescription(String d) => state = state.copyWith(description: d);

  // ── Location ──────────────────────────────────────────────────────────

  void setCity(String c) => state = state.copyWith(city: c);

  // ── Photos ────────────────────────────────────────────────────────────

  void addImages(List<XFile> newImages) {
    final all = [...state.images, ...newImages];
    state = state.copyWith(images: all.length > 10 ? all.take(10).toList() : all);
  }

  void removeImage(int index) {
    final list = [...state.images]..removeAt(index);
    state = state.copyWith(images: list);
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = [...state.images];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(images: list);
  }

  // ── Boost ─────────────────────────────────────────────────────────────

  void setBoostType(String bt) => state = state.copyWith(boostType: bt);

  // ── Submit ────────────────────────────────────────────────────────────

  void setSubmitting(bool v) => state = state.copyWith(isSubmitting: v);
  void setError(String? e) => state = state.copyWith(submitError: e);
  void reset() => state = const CLState();
}

final clProvider = StateNotifierProvider<CLNotifier, CLState>((ref) => CLNotifier());
