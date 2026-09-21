import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../categories/models/category_model.dart';
import '../../technicians/screens/technician_detail_screen.dart';
import '../models/service_model.dart';

class ServicesScreen extends StatefulWidget {
  final String? initialCategoryId;
  final String? initialCategoryName;

  const ServicesScreen({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<ServiceModel> _services = [];
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;

  int _currentPage = 1;
  final int _limit = 8; // গ্রিডের জন্য ৮টি করে ডেটা লোড হবে
  int _totalServices = 0;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _fetchCategories();
    _fetchServices(page: 1);

    // Infinite scroll listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && !_isLoadingMore && _hasMore) {
          _fetchServices(page: _currentPage + 1);
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

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.categories));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          final List list = decoded['data'];
          if (mounted) {
            setState(() {
              _categories = list.map((e) => CategoryModel.fromJson(e)).toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Filter categories load error: $e");
    }
  }

  Future<void> _fetchServices({
    required int page,
    bool isRefresh = false,
  }) async {
    if (page == 1) {
      if (!isRefresh) {
        setState(() {
          _isLoading = true;
          _services.clear();
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
        if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty)
          'categoryId': _selectedCategoryId!,
      };

      final uri = Uri.parse(ApiEndpoints.services)
          .replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          final List list = decoded['data'];
          final newServices =
              list.map((json) => ServiceModel.fromJson(json)).toList();
          final meta = decoded['meta'] as Map<String, dynamic>?;
          final totalPage = meta?['totalPage'] ?? 1;
          final total = meta?['total'] ?? newServices.length;

          if (mounted) {
            setState(() {
              if (page == 1) {
                _services = newServices;
              } else {
                _services.addAll(newServices);
              }
              _currentPage = page;
              _totalServices = total;
              _hasMore = page < totalPage;
              _isLoading = false;
              _isLoadingMore = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Services Fetch Error: $e");
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
      _fetchServices(page: 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 Category Screen এর মতো রেস্পন্সিভ গ্রিড কলাম সংখ্যা (মোবাইলে ২ টা)
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2; // মোবাইলে সর্বনিম্ন ২ টি
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
              title: Text(
                widget.initialCategoryName != null
                    ? "${widget.initialCategoryName} Services"
                    : "Services Directory",
                style: const TextStyle(
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
        onRefresh: () => _fetchServices(page: 1, isRefresh: true),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ১. ডার্ক হিরো হেডার ও সার্চবার
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
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
                            "VERIFIED HOME SERVICES",
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
                            text: "Find & Book ",
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: "Services",
                            style: TextStyle(color: AppColors.coral),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Professional plumbing, electrical, cleaning, and repair solutions backed by certified technicians.",
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
                          hintText: "Search services by name or description...",
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

              // ২. হরাইজন্টাল (X-Axis) ক্যাটাগরি ফিল্টার চিপস
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCategoryFilterChip(
                        label: "All Services",
                        isSelected: _selectedCategoryId == null,
                        onTap: () {
                          if (_selectedCategoryId != null) {
                            setState(() => _selectedCategoryId = null);
                            _fetchServices(page: 1);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ..._categories.map((cat) {
                        final isSelected = _selectedCategoryId == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryFilterChip(
                            label: cat.name,
                            isSelected: isSelected,
                            onTap: () {
                              if (_selectedCategoryId != cat.id) {
                                setState(() => _selectedCategoryId = cat.id);
                                _fetchServices(page: 1);
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ৩. রেজাল্ট হেডার
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Showing ${_services.length} of $_totalServices available services",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_selectedCategoryId != null || _searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = null;
                            _searchQuery = '';
                            _searchController.clear();
                          });
                          _fetchServices(page: 1);
                        },
                        child: const Text(
                          "Reset filters",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.coral,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ৪. সার্ভিসেস ২-কলাম গ্রিড (Category Screen এর মতো)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    if (_isLoading)
                      _ServicesSkeletonGrid(
                        crossAxisCount: crossAxisCount,
                        cardCount: 6,
                      )
                    else if (_services.isEmpty)
                      _buildEmptyState()
                    else ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _services.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount, // মোবাইলে ২ টি কার্ড
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 215,
                        ),
                        itemBuilder: (context, index) {
                          return _buildServiceCard(_services[index]);
                        },
                      ),

                      // নিচে স্ক্রোল করার পর ২টা স্কেলেটন কার্ড
                      if (_isLoadingMore) ...[
                        const SizedBox(height: 12),
                        _ServicesSkeletonGrid(
                          crossAxisCount: crossAxisCount,
                          cardCount: 2,
                        ),
                      ],
                    ],

                    if (!_hasMore && _services.isNotEmpty && !_isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            "You have reached the end of all services",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (label == "All Services" ? AppColors.ink : AppColors.coral)
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (label == "All Services"
                            ? AppColors.ink
                            : AppColors.coral)
                        .withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
            ),
          ),
        ),
      ),
    );
  }

  // 🌟 ২-কলামের কার্ড যা কোনোভাবেই ওভারফ্লো করবে না এবং দেখতে প্রিমিয়াম
  Widget _buildServiceCard(ServiceModel service) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E2D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // টপ রো: ক্যাটাগরি ও ডিউরেশন ব্যাজ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.handyman_rounded,
                        size: 11,
                        color: AppColors.coral,
                      ),
                      const SizedBox(width: 3.5),
                      Flexible(
                        child: Text(
                          service.categoryName ?? "Service",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.coral,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_filled_rounded,
                      size: 10,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      service.duration,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // সার্ভিস টাইটেল
          Text(
            service.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 4),

          // সার্ভিস বিবরণী
          Text(
            service.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B707E),
              height: 1.35,
            ),
          ),

          const SizedBox(height: 8),

          // টেকনিশিয়ান ব্যাজ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFDE68A).withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 12,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    service.technicianName ?? "Certified Expert",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF3EFEA)),
          const SizedBox(height: 8),

          // ফুটার: প্রাইস এবং বুক বাটন
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "PRICE",
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "৳${service.price.toInt()}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  if (service.technicianId != null &&
                      service.technicianId!.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TechnicianDetailScreen(
                          technicianId: service.technicianId!,
                          initialName: service.technicianName,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Technician details not available"),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14171C),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "View Technician",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 11,
                        color: AppColors.coral,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
              Icons.handyman_outlined,
              color: Colors.grey,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "No services found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Try adjusting your search query or selecting a different category.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF6B707E)),
          ),
        ],
      ),
    );
  }
}

// ========================================================
// 🌟 অ্যানিমেটেড পালসিং স্কেলেটন গ্রিড (Pure Flutter Shimmer)
// ========================================================
class _ServicesSkeletonGrid extends StatefulWidget {
  final int crossAxisCount;
  final int cardCount;

  const _ServicesSkeletonGrid({
    required this.crossAxisCount,
    this.cardCount = 6,
  });

  @override
  State<_ServicesSkeletonGrid> createState() => _ServicesSkeletonGridState();
}

class _ServicesSkeletonGridState extends State<_ServicesSkeletonGrid>
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
              mainAxisExtent: 215,
            ),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE7E2D8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 65,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E4E8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Container(
                          width: 45,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E4E8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E4E8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F1F3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 70,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F1F3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F1F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF3EFEA)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E4E8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E4E8),
                            borderRadius: BorderRadius.circular(8),
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
