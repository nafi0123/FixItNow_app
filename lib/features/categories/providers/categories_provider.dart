import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import '../models/category_model.dart';

// মাত্র ২ লাইনে ক্যাশিং প্রোভাইডার!
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ApiService.getCategories();
});
