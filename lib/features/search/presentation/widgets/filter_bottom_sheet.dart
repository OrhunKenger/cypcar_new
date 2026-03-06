import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/features/search/presentation/providers/search_provider.dart';

void showFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late SearchFilters _filters;

  final _yearMinCtrl = TextEditingController();
  final _yearMaxCtrl = TextEditingController();
  final _priceMinCtrl = TextEditingController();
  final _priceMaxCtrl = TextEditingController();
  final _mileageMaxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = ref.read(searchProvider).filters;
    if (_filters.yearMin != null) _yearMinCtrl.text = '${_filters.yearMin}';
    if (_filters.yearMax != null) _yearMaxCtrl.text = '${_filters.yearMax}';
    if (_filters.priceMin != null) _priceMinCtrl.text = '${_filters.priceMin!.toInt()}';
    if (_filters.priceMax != null) _priceMaxCtrl.text = '${_filters.priceMax!.toInt()}';
    if (_filters.mileageMax != null) _mileageMaxCtrl.text = '${_filters.mileageMax}';
  }

  @override
  void dispose() {
    _yearMinCtrl.dispose();
    _yearMaxCtrl.dispose();
    _priceMinCtrl.dispose();
    _priceMaxCtrl.dispose();
    _mileageMaxCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final updated = _filters.copyWith(
      yearMin: int.tryParse(_yearMinCtrl.text),
      yearMax: int.tryParse(_yearMaxCtrl.text),
      priceMin: double.tryParse(_priceMinCtrl.text),
      priceMax: double.tryParse(_priceMaxCtrl.text),
      mileageMax: int.tryParse(_mileageMaxCtrl.text),
    );
    ref.read(searchProvider.notifier).updateFilters(updated);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() => _filters = const SearchFilters());
    _yearMinCtrl.clear();
    _yearMaxCtrl.clear();
    _priceMinCtrl.clear();
    _priceMaxCtrl.clear();
    _mileageMaxCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.surfaceDark : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Detaylı Filtrele',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Temizle',
                      style: TextStyle(color: AppTheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sıralama
            _sectionLabel('Sıralama'),
            _ChipGroup(
              options: const {
                'newest': 'En Yeni',
                'price_asc': 'Fiyat ↑',
                'price_desc': 'Fiyat ↓',
              },
              selected: _filters.sort,
              onSelect: (v) => setState(() => _filters = _filters.copyWith(sort: v)),
            ),
            const SizedBox(height: 16),

            // Durum
            _sectionLabel('Durum'),
            _ChipGroup(
              options: const {'NEW': 'Sıfır', 'USED': 'İkinci El'},
              selected: _filters.condition,
              onSelect: (v) => setState(() => _filters = v == _filters.condition
                  ? _filters.copyWith(clearCondition: true)
                  : _filters.copyWith(condition: v)),
            ),
            const SizedBox(height: 16),

            // Yakıt
            _sectionLabel('Yakıt Tipi'),
            _ChipGroup(
              options: const {
                'PETROL': 'Benzin',
                'DIESEL': 'Dizel',
                'ELECTRIC': 'Elektrik',
                'HYBRID': 'Hibrit',
                'LPG': 'LPG',
              },
              selected: _filters.fuelType,
              onSelect: (v) => setState(() => _filters = v == _filters.fuelType
                  ? _filters.copyWith(clearFuelType: true)
                  : _filters.copyWith(fuelType: v)),
            ),
            const SizedBox(height: 16),

            // Vites
            _sectionLabel('Vites'),
            _ChipGroup(
              options: const {'MANUAL': 'Manuel', 'AUTOMATIC': 'Otomatik'},
              selected: _filters.transmission,
              onSelect: (v) => setState(() => _filters = v == _filters.transmission
                  ? _filters.copyWith(clearTransmission: true)
                  : _filters.copyWith(transmission: v)),
            ),
            const SizedBox(height: 16),

            // Çekiş
            _sectionLabel('Çekiş'),
            _ChipGroup(
              options: const {'FWD': 'Önden', 'RWD': 'Arkadan', 'AWD': 'AWD', 'FOUR_WD': '4x4'},
              selected: _filters.driveType,
              onSelect: (v) => setState(() => _filters = v == _filters.driveType
                  ? _filters.copyWith(clearDriveType: true)
                  : _filters.copyWith(driveType: v)),
            ),
            const SizedBox(height: 16),

            // Yıl aralığı
            _sectionLabel('Yıl Aralığı'),
            Row(
              children: [
                Expanded(child: _numField(_yearMinCtrl, 'Min', 2000)),
                const SizedBox(width: 10),
                Expanded(child: _numField(_yearMaxCtrl, 'Max', 2025)),
              ],
            ),
            const SizedBox(height: 16),

            // Fiyat aralığı
            _sectionLabel('Fiyat Aralığı (₺)'),
            Row(
              children: [
                Expanded(child: _numField(_priceMinCtrl, 'Min', 0)),
                const SizedBox(width: 10),
                Expanded(child: _numField(_priceMaxCtrl, 'Max', 10000000)),
              ],
            ),
            const SizedBox(height: 16),

            // Kilometre max
            _sectionLabel('Kilometre (max)'),
            _numField(_mileageMaxCtrl, 'Max km', 500000),
            const SizedBox(height: 24),

            // Uygula
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _apply,
                child: const Text('Filtreleri Uygula',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Widget _numField(TextEditingController ctrl, String hint, int example) =>
      TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}

class _ChipGroup extends StatelessWidget {
  final Map<String, String> options;
  final String? selected;
  final void Function(String) onSelect;

  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final isSelected = selected == e.key;
        return GestureDetector(
          onTap: () => onSelect(e.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppTheme.primary : Colors.grey.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                fontSize: 12.5,
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
