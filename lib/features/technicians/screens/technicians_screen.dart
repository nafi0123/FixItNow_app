import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/technicians_provider.dart';

class TechniciansScreen extends ConsumerWidget {
  const TechniciansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techAsync = ref.watch(techniciansProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Find Technicians',
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
      body: techAsync.when(
        data: (techs) {
          if (techs.isEmpty) {
            return const Center(child: Text('No technicians found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: techs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final tech = techs[index];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.coral.withValues(alpha: 0.12),
                          child: Text(
                            tech.name.isNotEmpty ? tech.name[0] : 'T',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.coral,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      tech.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 14),
                                        const SizedBox(width: 3),
                                        Text(
                                          tech.rating.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${tech.experienceYears}+ years exp • ${tech.location}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (tech.skills.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tech.skills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF374151), fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF3EFEA)),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Starting from', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text(
                              '৳${tech.basePrice.toInt()}/hr',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Booking request for ${tech.name}')),
                            );
                          },
                          icon: const Icon(Icons.calendar_month_rounded, size: 14, color: Colors.white),
                          label: const Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.coral,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.coral)),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 36, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('Failed to load technicians', style: TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: () => ref.refresh(techniciansProvider),
                child: const Text('Retry', style: TextStyle(color: AppColors.coral)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
