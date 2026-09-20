import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../features/categories/models/category_model.dart';
import '../../features/faq/screens/faq_screen.dart'; // 👈 FAQ স্ক্রিন ইমপোর্ট

class CustomNavbar extends StatefulWidget implements PreferredSizeWidget {
  const CustomNavbar({super.key});

  @override
  State<CustomNavbar> createState() => _CustomNavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(100);
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

    return Column(
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // লোগো
              Row(
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

              // মাঝের লিংকসমূহ (ডেস্কটপে)
              if (!isMobile)
                Row(
                  children: [
                    _navButton("Services"),
                    _navButton("Technicians"),

                    // ক্যাটাগরি ড্রপডাউন
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
                        debugPrint("Selected Category: ${cat.name}");
                      },
                    ),
                  ],
                ),

              // ডানের বাটনসমূহ
              Row(
                children: [
                  if (!isMobile) ...[
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Log in",
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  ElevatedButton.icon(
                    onPressed: () {},
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
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  // মোবাইল মেনু আইকন
                  if (isMobile) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: AppColors.ink,
                        size: 26,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navButton(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextButton(
        onPressed: () {},
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

// ----------------------------------------------------
// মোবাইল ড্রয়ার (ক্লিন ও আলাদা FAQ পেজ নেভিগেশনসহ)
// ----------------------------------------------------
class MobileAppDrawer extends StatefulWidget {
  const MobileAppDrawer({super.key});

  @override
  State<MobileAppDrawer> createState() => _MobileAppDrawerState();
}

class _MobileAppDrawerState extends State<MobileAppDrawer> {
  List<CategoryModel> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
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
              isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Drawer Categories Error: $e");
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ১. হেডার
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.build_rounded,
                          color: AppColors.coral,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // ২. ড্রয়ার লিংকসমূহ
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                children: [
                  _drawerTile(Icons.handyman_outlined, "Services", () {}),
                  _drawerTile(Icons.people_alt_outlined, "Technicians", () {}),

                  // ক্যাটাগরি মেনু
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: const PageStorageKey('drawer_categories'),
                      leading: const Icon(
                        Icons.category_outlined,
                        color: AppColors.coral,
                        size: 20,
                      ),
                      title: const Text(
                        "Categories",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      children: isLoading
                          ? [
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          : categories.map((cat) {
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.only(
                                  left: 48,
                                  right: 16,
                                ),
                                leading: const Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: AppColors.teal,
                                ),
                                title: Text(
                                  cat.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              );
                            }).toList(),
                    ),
                  ),

                  // 🎯 নতুন আলাদা FAQ পেজের বাটন (ক্লিক করলেই আলাদা পেজ খুলবে)
                  _drawerTile(Icons.help_outline_rounded, "FAQ & Help", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FaqScreen(),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ৩. নিচের বাটনসমূহ
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Column(
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 42),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Log in",
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Get started",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.teal, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: Colors.grey,
      ),
      onTap: () {
        Navigator.pop(context); // ড্রয়ার বন্ধ হবে
        onTap(); // নতুন পেজ খুলবে
      },
    );
  }
}
