import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/categories_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('plumb')) return Icons.plumbing_rounded;
    if (lower.contains('electr')) return Icons.electric_bolt_rounded;
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit_rounded;
    if (lower.contains('paint')) return Icons.format_paint_rounded;
    if (lower.contains('clean')) return Icons.cleaning_services_rounded;
    if (lower.contains('carpent')) return Icons.carpenter_rounded;
    if (lower.contains('appliance')) return Icons.kitchen_rounded;
    return Icons.build_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Categories',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text('No categories available right now.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final icon = _getCategoryIcon(cat.name);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected ${cat.name}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.coral.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(icon, color: AppColors.coral, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  cat.description ?? 'Verified expert technicians near you.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.coral),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 36, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('Failed to load categories', style: TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: () => ref.refresh(categoriesProvider),
                child: const Text('Retry', style: TextStyle(color: AppColors.coral)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
