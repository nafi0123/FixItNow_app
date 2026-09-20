import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import '../models/technician_model.dart';

// মাত্র ২ লাইনে ক্যাশিং প্রোভাইডার!
final techniciansProvider = FutureProvider<List<TechnicianModel>>((ref) {
  return ApiService.getTechnicians();
});
