import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/core/theme/app_theme.dart';
import 'package:cypcar/features/search/presentation/providers/search_provider.dart';

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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle & Header (Fixed)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
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
              ],
            ),
          ),

          // Scrollable Options
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 16),

                  // Renk Seçimi
                  _sectionLabel('Renk'),
                  _ColorGrid(
                    selectedColor: _filters.color,
                    onSelect: (c) => setState(() => _filters = c == _filters.color
                        ? _filters.copyWith(clearColor: true)
                        : _filters.copyWith(color: c)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Action (Sticky)
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: bg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _apply,
                child: const Text('Filtreleri Uygula',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
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

class _ColorGrid extends StatelessWidget {
  final String? selectedColor;
  final Function(String) onSelect;

  const _ColorGrid({required this.selectedColor, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 12,
      runSpacing: 16,
      children: _colors.map((c) {
        final isSelected = selectedColor == c.$1;
        return GestureDetector(
          onTap: () => onSelect(c.$1),
          child: SizedBox(
            width: 50,
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.$2,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1)),
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 20,
                          color: c.$1 == 'Beyaz' || c.$1 == 'Bej' || c.$1 == 'Sarı' || c.$1 == 'Altın'
                              ? Colors.black87
                              : Colors.white,
                        )
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  c.$1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.primary
                        : (isDark ? Colors.white54 : Colors.black54),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
