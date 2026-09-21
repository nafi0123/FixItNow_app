import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../categories/models/category_model.dart';

class PopularServicesSection extends StatefulWidget {
  const PopularServicesSection({super.key});

  @override
  State<PopularServicesSection> createState() => _PopularServicesSectionState();
}

class _PopularServicesSectionState extends State<PopularServicesSection> {
  List<CategoryModel> categories = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      // 👈 ?limit=8 সহ রিকোয়েস্ট পাঠাবে
      final response = await http.get(
        Uri.parse("${ApiEndpoints.categories}?limit=8"),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          final List list = decoded['data'];
          if (mounted) {
            setState(() {
              // 👈 সর্বোচ্চ সাম্প্রতিক ৮টি ক্যাটাগরি রাখা হলো
              categories = list
                  .map((json) => CategoryModel.fromJson(json))
                  .take(8)
                  .toList();
              isLoading = false;
            });
          }
          return;
        }
      }
      throw Exception("Failed to load categories");
    } catch (e) {
      debugPrint("Categories Fetch Error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Could not load services.";
        });
      }
    }
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ac') ||
        lower.contains('cooling') ||
        lower.contains('heat')) {
      return Icons.ac_unit_rounded;
    } else if (lower.contains('electric')) {
      return Icons.bolt_rounded;
    } else if (lower.contains('plumb') ||
        lower.contains('pipe') ||
        lower.contains('leak')) {
      return Icons.water_drop_outlined;
    } else if (lower.contains('clean') || lower.contains('paint')) {
      return Icons.cleaning_services_rounded;
    } else if (lower.contains('appliance')) {
      return Icons.kitchen_rounded;
    }
    return Icons.build_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 950;

    return Container(
      width: double.infinity,
      color: const Color(0xFFFAF8F5),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 16,
        vertical: isDesktop ? 48 : 28, // উচ্চতা একদম পারফেক্ট ও কমপ্যাক্ট
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // হেডার
              _buildSectionHeader(isDesktop),

              const SizedBox(height: 20),

              // X-Axis হরাইজন্টাল স্ক্রোল সেকশন
              if (isLoading)
                _buildLoadingHorizontalList()
              else if (errorMessage != null && categories.isEmpty)
                _buildErrorView()
              else
                _buildHorizontalCategoriesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ব্যাজ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.folder_outlined, size: 13, color: AppColors.teal),
                  SizedBox(width: 5),
                  Text(
                    "CATEGORIES",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.teal,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // টাইটেল
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: isDesktop ? 26 : 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
                children: const [
                  TextSpan(text: "Popular "),
                  TextSpan(
                    text: "Services",
                    style: TextStyle(color: AppColors.coral),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ডানের ভিউ অল বাটন
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Row(
            children: const [
              Text(
                "See all",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.coral,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.coral,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔥 X-Axis Horizontal Scroll List (ডানে-বাঁয়ে স্ক্রোল হবে)
  Widget _buildHorizontalCategoriesList() {
    return SizedBox(
      height: 195, // ফিক্সড ছোট উচ্চতা, Y-axis আর লম্বা হবে না
      child: ListView.separated(
        scrollDirection: Axis.horizontal, // 👈 X-axis scroll
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final icon = _getCategoryIcon(cat.name);

          return _buildCategoryCard(cat, icon);
        },
      ),
    );
  }

  // ফিক্সড সাইজের কম্প্যাক্ট কার্ড (হরাইজন্টাল স্ক্রোলের জন্য)
  Widget _buildCategoryCard(CategoryModel cat, IconData icon) {
    return InkWell(
      onTap: () {
        debugPrint("Selected Service: ${cat.name}");
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 230, // 👈 ফিক্সড কার্ড প্রস্থ
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7E2D8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // আইকন এবং রাইট অ্যারো
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.coral, size: 22),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9F8F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ক্যাটাগরির নাম
            Text(
              cat.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),

            const SizedBox(height: 4),

            // বিবরণ
            Expanded(
              child: Text(
                cat.description ?? "Verified expert technicians near you.",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B707E),
                  height: 1.35,
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF3EFEA)),
            const SizedBox(height: 8),

            // ফাইন্ড টেকনিশিয়ান লিংক
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Book service",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: AppColors.coral,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // লোডিং শিমার (হরাইজন্টাল)
  Widget _buildLoadingHorizontalList() {
    return SizedBox(
      height: 195,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return Container(
            width: 230,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7E2D8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(height: 12),
                Container(width: 120, height: 14, color: Colors.grey.shade100),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 10,
                  color: Colors.grey.shade50,
                ),
                const Spacer(),
                Container(width: 80, height: 10, color: Colors.grey.shade100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.grey, size: 30),
            const SizedBox(height: 6),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            TextButton(
              onPressed: () {
                setState(() => isLoading = true);
                fetchCategories();
              },
              child: const Text(
                "Retry",
                style: TextStyle(color: AppColors.coral, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
