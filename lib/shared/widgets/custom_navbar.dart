import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../features/categories/models/category_model.dart';
import '../../features/faq/screens/faq_screen.dart';
import '../../features/services/screens/services_screen.dart';

class CustomNavbar extends StatefulWidget implements PreferredSizeWidget {
  final Function(int)? onTabSelected;

  const CustomNavbar({super.key, this.onTabSelected});

  @override
  State<CustomNavbar> createState() => _CustomNavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(92);
}

class _CustomNavbarState extends State<CustomNavbar> {
  List<CategoryModel> categories = [];
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.categories));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          final List list = decoded['data'];
          if (mounted) {
            setState(() {
              categories = list
                  .map((json) => CategoryModel.fromJson(json))
                  .toList();
              isLoadingCategories = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("API Fetch Error: $e");
    }

    if (mounted) {
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      color: AppColors.ink,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
        // ১. টপ গ্রেডিয়েন্ট লাইন (Coral -> Teal)
        Container(
          height: 3,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.coral, AppColors.teal]),
          ),
        ),

        // ২. টপ ইউটিলিটি স্ট্রিপ
        Container(
          color: AppColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "142 technicians online now",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              if (!isMobile)
                const Text(
                  "Book before 6pm for same-day service",
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
            ],
          ),
        ),

        // ৩. মেইন নেভবার (Cream Background)
        Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // লোগো (ট্যাপ করলে Home ট্যাবে যাবে)
              InkWell(
                onTap: () => widget.onTabSelected?.call(0),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.build_rounded,
                        color: AppColors.coral,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: "FixIt",
                            style: TextStyle(color: AppColors.ink),
                          ),
                          TextSpan(
                            text: "Now",
                            style: TextStyle(color: AppColors.coral),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // মাঝের লিংকসমূহ (ডেস্কটপে)
              if (!isMobile)
                Row(
                  children: [
                    // ক্যাটাগরি ড্রপডাউন (ট্যাব ১)
                    PopupMenuButton<CategoryModel>(
                      offset: const Offset(0, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              "Categories",
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            isLoadingCategories
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                          ],
                        ),
                      ),
                      itemBuilder: (context) {
                        if (categories.isEmpty) {
                          return [
                            const PopupMenuItem(
                              enabled: false,
                              child: Text(
                                "No categories found",
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ];
                        }
                        return categories.map((cat) {
                          return PopupMenuItem<CategoryModel>(
                            value: cat,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: AppColors.coral,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  cat.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      onSelected: (cat) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServicesScreen(
                              initialCategoryId: cat.id,
                              initialCategoryName: cat.name,
                            ),
                          ),
                        );
                      },
                    ),

                    _navButton("Services", () => widget.onTabSelected?.call(2)), // 2. Service
                    _navButton("Technicians", () => widget.onTabSelected?.call(3)), // 3. Technician

                    // FAQ লিংক ডেস্কটপে
                    _navButton("FAQ", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FaqScreen()),
                      );
                    }),
                  ],
                ),

              // ডানের বাটনসমূহ
              Row(
                children: [
                  // 🎯 FAQ কুইক হেল্প আইকন (সবার জন্য সহজেই অ্যাক্সেসযোগ্য)
                  IconButton(
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.ink,
                      size: 22,
                    ),
                    tooltip: "FAQ & Help",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FaqScreen()),
                      );
                    },
                  ),

                  // ডেস্কটপে লগইন ও গেট স্টার্টেড বাটন
                  if (!isMobile) ...[
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () => widget.onTabSelected?.call(4), // 4. Account
                      child: const Text(
                        "Log in",
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => widget.onTabSelected?.call(4), // 4. Account
                      icon: const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Get started",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
  }

  Widget _navButton(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}