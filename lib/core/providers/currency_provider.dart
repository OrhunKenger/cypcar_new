import 'package:flutter_riverpod/flutter_riverpod.dart';

// 'TRY' veya 'GBP'
final currencyProvider = StateProvider<String>((ref) => 'TRY');
