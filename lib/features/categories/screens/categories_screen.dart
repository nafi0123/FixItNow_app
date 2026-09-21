import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../models/category_model.dart';
import '../../services/screens/services_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<CategoryModel> _categories = [];
  int _currentPage = 1;
  final int _limit = 8;
  int _totalCategories = 0;

  bool _isLoading = true; // প্রথম পেজের লোডিং (স্কেলেটন দেখাবে)
  bool _isLoadingMore = false; // স্ক্রোল করার পর নিচের লোডিং (স্কেলেটন দেখাবে)
  bool _hasMore = true;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchCategories(page: 1);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && !_isLoadingMore && _hasMore) {
          _fetchCategories(page: _currentPage + 1);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchCategories({
    required int page,
    bool isRefresh = false,
  }) async {
    if (page == 1) {
      if (!isRefresh) {
        setState(() {
          _isLoading = true;
          _categories.clear();
        });
      }
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final queryParams = {
        'page': page.toString(),
        'limit': _limit.toString(),
        if (_searchQuery.isNotEmpty) 'searchTerm': _searchQuery,
      };

      final uri = Uri.parse(ApiEndpoints.categories)
          .replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          final List list = decoded['data'];
          final newCategories = list
              .map((json) => CategoryModel.fromJson(json))
              .toList();
          final meta = decoded['meta'] as Map<String, dynamic>?;
          final totalPage = meta?['totalPage'] ?? 1;
          final total = meta?['total'] ?? newCategories.length;

          if (mounted) {
            setState(() {
              if (page == 1) {
                _categories = newCategories;
              } else {
                _categories.addAll(newCategories);
              }
              _currentPage = page;
              _totalCategories = total;
              _hasMore = page < totalPage;
              _isLoading = false;
              _isLoadingMore = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Categories Fetch Error: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _searchQuery = val.trim();
      });
      _fetchCategories(page: 1);
    });
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('plumb')) return Icons.plumbing_rounded;
    if (lower.contains('electr')) return Icons.electric_bolt_rounded;
    if (lower.contains('ac') || lower.contains('air')) {
      return Icons.ac_unit_rounded;
    }
    if (lower.contains('paint')) return Icons.format_paint_rounded;
    if (lower.contains('clean')) return Icons.cleaning_services_rounded;
    if (lower.contains('carpent')) return Icons.carpenter_rounded;
    if (lower.contains('appliance')) return Icons.kitchen_rounded;
    return Icons.build_rounded;
  }

  String _getSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll('&', '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  @override
  Widget build(BuildContext context) {
    // রেস্পন্সিভ কলাম সংখ্যা
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2; // মোবাইলে সর্বনিম্ন ২টি
    if (screenWidth >= 1200) {
      crossAxisCount = 4;
    } else if (screenWidth >= 750) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: Navigator.canPop(context)
          ? AppBar(
              backgroundColor: AppColors.ink,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                "Service Categories",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.coral,
        onRefresh: () => _fetchCategories(page: 1, isRefresh: true),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ১. হিরো হেডার ও সার্চবার
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF14171C), Color(0xFF1B1E26)],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.coral.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.coral.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.coral,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "SERVICE DIRECTORY",
                            style: TextStyle(
                              color: AppColors.coral,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: "Explore All ",
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: "Categories",
                            style: TextStyle(color: AppColors.coral),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Find verified expert technicians across all categories with instant booking.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 20),

                    // সার্চবার
                    Container(
                      constraints: const BoxConstraints(maxWidth: 550),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F242D),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        cursorColor: AppColors.coral,
                        decoration: InputDecoration(
                          hintText: "Search categories e.g. Plumbing, AC...",
                          hintStyle: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white54,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white54,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ২. ক্যাটাগরি গ্রিড সেকশন
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "All Available Categories",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        if (!_isLoading)
                          Text(
                            "Showing ${_categories.length} of $_totalCategories",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 🌟 ১. প্রথম পেজের লোডিং স্কেলেটন (Shimmer Grid)
                    if (_isLoading)
                      SkeletonLoadingGrid(
                        crossAxisCount: crossAxisCount,
                        cardCount: 6,
                      )
                    // ২. এম্পটি স্টেট
                    else if (_categories.isEmpty)
                      _buildEmptyState()
                    // ৩. রিয়েল ক্যাটাগরি গ্রিড ভিউ
                    else ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _categories.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 210,
                        ),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final icon = _getCategoryIcon(cat.name);
                          final slug = _getSlug(cat.name);

                          return _buildCategoryCard(context, cat, icon, slug);
                        },
                      ),

                      // 🌟 ৪. নিচে স্ক্রোল করার পর লোডিং স্কেলেটন
                      if (_isLoadingMore) ...[
                        const SizedBox(height: 12),
                        SkeletonLoadingGrid(
                          crossAxisCount: crossAxisCount,
                          cardCount: 2, // স্ক্রোলে ২টা স্কেলেটন কার্ড দেখাবে
                        ),
                      ],

                      // ৫. সব ডেটা শেষ হয়ে গেলে নোটিশ
                      if (!_hasMore &&
                          _categories.isNotEmpty &&
                          !_isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              "You have reached the end of the directory",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    dynamic cat,
    IconData icon,
    String slug,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E2D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServicesScreen(
                  initialCategoryId: cat.id,
                  initialCategoryName: cat.name,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.coral.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppColors.coral, size: 20),
                    ),
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBF3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          "/$slug",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: "monospace",
                            color: Color(0xFF6B707E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  cat.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    cat.description ??
                        "Top-rated repair & installation services.",
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Browse ${cat.name} Services",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.coral,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.coral,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E2D8)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: Colors.grey,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "No categories found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty
                ? "No categories match \"$_searchQuery\""
                : "No service categories available right now.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B707E)),
          ),
        ],
      ),
    );
  }
}

// ========================================================
// 🌟 অ্যানিমেটেড পালসিং লোডিং স্কেলেটন উইজেট (Pure Flutter)
// ========================================================
class SkeletonLoadingGrid extends StatefulWidget {
  final int crossAxisCount;
  final int cardCount;

  const SkeletonLoadingGrid({
    super.key,
    required this.crossAxisCount,
    this.cardCount = 6,
  });

  @override
  State<SkeletonLoadingGrid> createState() => _SkeletonLoadingGridState();
}

class _SkeletonLoadingGridState extends State<SkeletonLoadingGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _opacityAnim = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.cardCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 210,
            ),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7E2D8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // আইকন ও স্ল্যাগ স্কেলেটন
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E4E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F1F3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // টাইটেল স্কেলেটন
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E4E8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ডেসক্রিপশন স্কেলেটন
                    Container(
                      width: double.infinity,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F1F3),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 75,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F1F3),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),

                    const Spacer(),
                    const Divider(height: 1, color: Color(0xFFF3EFEA)),
                    const SizedBox(height: 8),

                    // বাটন স্কেলেটন
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 45,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E4E8),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE2E4E8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
