import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/features/catalog/data/catalog_repository.dart';

final categoriesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(catalogRepositoryProvider).fetchCategories();
});
