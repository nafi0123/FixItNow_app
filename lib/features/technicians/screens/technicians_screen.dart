import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../categories/models/category_model.dart';
import 'technician_detail_screen.dart';
import '../models/technician_model.dart';

class TechniciansScreen extends StatefulWidget {
  const TechniciansScreen({super.key});

  @override
  State<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends State<TechniciansScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<TechnicianModel> _technicians = [];
  List<CategoryModel> _categories = [];

  // Filter States
  String _searchQuery = '';
  String _selectedCategory = '';
  String _minRating = '';
  String _selectedLocation = '';
  bool _availableOnly = false;
  double _maxPrice = 2000.0;
  String _sortBy = 'recommended'; // 'recommended', 'rating-desc', 'price-asc', 'price-desc'

  int _currentPage = 1;
  final int _limit = 8; // গ্রিডের সুবিধার জন্য ৮টি করে পেজিনেশন
  int _totalTechnicians = 0;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchTechnicians(page: 1);

    // Infinite scroll listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && !_isLoadingMore && _hasMore) {
          _fetchTechnicians(page: _currentPage + 1);
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

  // অ্যাক্টিভ ফিল্টার সংখ্যা
  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategory.isNotEmpty) count++;
    if (_minRating.isNotEmpty) count++;
    if (_selectedLocation.isNotEmpty) count++;
    if (_availableOnly) count++;
    if (_maxPrice < 2000.0) count++;
    if (_sortBy != 'recommended') count++;
    return count;
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
      debugPrint("Categories load error: $e");
    }
  }

  Future<void> _fetchTechnicians({
    required int page,
    bool isRefresh = false,
  }) async {
    if (page == 1) {
      if (!isRefresh) {
        setState(() {
          _isLoading = true;
          _technicians.clear();
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
        if (_selectedLocation.isNotEmpty) 'location': _selectedLocation,
        if (_minRating.isNotEmpty) 'rating': _minRating,
        if (_selectedCategory.isNotEmpty) 'skills': _selectedCategory,
      };

      final uri = Uri.parse(ApiEndpoints.technicians)
          .replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          final List list = decoded['data'];
          var newTechs =
              list.map((json) => TechnicianModel.fromJson(json)).toList();

          // ক্লায়েন্ট-সাইড ফিল্টারিং (Availability & Max Price)
          if (_availableOnly) {
            newTechs = newTechs.where((t) => t.isAvailable).toList();
          }
          if (_maxPrice < 2000.0) {
            newTechs = newTechs.where((t) => t.basePrice <= _maxPrice).toList();
          }

          // ক্লায়েন্ট-সাইড সর্টিং
          if (_sortBy == 'rating-desc') {
            newTechs.sort((a, b) => b.rating.compareTo(a.rating));
          } else if (_sortBy == 'price-asc') {
            newTechs.sort((a, b) => a.basePrice.compareTo(b.basePrice));
          } else if (_sortBy == 'price-desc') {
            newTechs.sort((a, b) => b.basePrice.compareTo(a.basePrice));
          }

          final meta = decoded['meta'] as Map<String, dynamic>?;
          final totalPage = meta?['totalPage'] ?? 1;
          final total = meta?['total'] ?? newTechs.length;

          if (mounted) {
            setState(() {
              if (page == 1) {
                _technicians = newTechs;
              } else {
                _technicians.addAll(newTechs);
              }
              _currentPage = page;
              _totalTechnicians = total;
              _hasMore = page < totalPage;
              _isLoading = false;
              _isLoadingMore = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Technicians Fetch Error: $e");
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
      _fetchTechnicians(page: 1);
    });
  }

  void _resetAllFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCategory = '';
      _minRating = '';
      _selectedLocation = '';
      _availableOnly = false;
      _maxPrice = 2000.0;
      _sortBy = 'recommended';
    });
    _fetchTechnicians(page: 1);
  }

  // 🌟 ফিল্টার বটম শীট ওপেন
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _TechnicianFilterBottomSheet(
          categories: _categories,
          currentCategory: _selectedCategory,
          currentRating: _minRating,
          currentLocation: _selectedLocation,
          currentAvailableOnly: _availableOnly,
          currentMaxPrice: _maxPrice,
          onApply: (cat, rating, loc, avail, maxP) {
            setState(() {
              _selectedCategory = cat;
              _minRating = rating;
              _selectedLocation = loc;
              _availableOnly = avail;
              _maxPrice = maxP;
            });
            _fetchTechnicians(page: 1);
          },
          onReset: () {
            _resetAllFilters();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // রেস্পন্সিভ গ্রিড: মোবাইলে ২টা, ট্যাবলেটে ৩টা, ডেস্কটপে ৪টা
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
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
                "Technicians Directory",
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
        onRefresh: () => _fetchTechnicians(page: 1, isRefresh: true),
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
                        color: AppColors.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.verified_rounded,
                            color: AppColors.teal,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "VERIFIED EXPERT NETWORK",
                            style: TextStyle(
                              color: AppColors.teal,
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
                            text: "Find Local ",
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: "Technicians",
                            style: TextStyle(color: AppColors.coral),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Certified background-checked professionals ready to fix your home issues instantly.",
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
                          hintText: "Search technician by name, skill...",
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

              // ২. 🌟 হরাইজন্টাল (X-Axis) কুইক ফিল্টার বার
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: [
                      // [⚙️ Filters Modal Button]
                      InkWell(
                        onTap: _showFilterModal,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _activeFilterCount > 0
                                ? AppColors.coral
                                : const Color(0xFF14171C),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (_activeFilterCount > 0
                                        ? AppColors.coral
                                        : AppColors.ink)
                                    .withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _activeFilterCount > 0
                                    ? "Filters ($_activeFilterCount)"
                                    : "Filters",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // [🟢 Available Now Toggle Chip]
                      _buildFilterChip(
                        label: "Available Now",
                        icon: Icons.circle,
                        iconColor: const Color(0xFF10B981),
                        isSelected: _availableOnly,
                        onTap: () {
                          setState(() => _availableOnly = !_availableOnly);
                          _fetchTechnicians(page: 1);
                        },
                      ),

                      const SizedBox(width: 8),

                      // [⭐ 4.5+ Rating Chip]
                      _buildFilterChip(
                        label: "⭐ 4.5+",
                        isSelected: _minRating == "4.5",
                        onTap: () {
                          setState(() {
                            _minRating = (_minRating == "4.5") ? "" : "4.5";
                          });
                          _fetchTechnicians(page: 1);
                        },
                      ),

                      const SizedBox(width: 8),

                      // [📍 Dhaka Chip]
                      _buildFilterChip(
                        label: "Dhaka",
                        icon: Icons.location_on_outlined,
                        isSelected: _selectedLocation == "Dhaka",
                        onTap: () {
                          setState(() {
                            _selectedLocation =
                                (_selectedLocation == "Dhaka") ? "" : "Dhaka";
                          });
                          _fetchTechnicians(page: 1);
                        },
                      ),

                      const SizedBox(width: 8),

                      // [⇅ Sort Menu]
                      PopupMenuButton<String>(
                        initialValue: _sortBy,
                        onSelected: (val) {
                          setState(() => _sortBy = val);
                          _fetchTechnicians(page: 1);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'recommended',
                            child: Text("Recommended"),
                          ),
                          const PopupMenuItem(
                            value: 'rating-desc',
                            child: Text("Highest Rated ⭐"),
                          ),
                          const PopupMenuItem(
                            value: 'price-asc',
                            child: Text("Price: Low to High"),
                          ),
                          const PopupMenuItem(
                            value: 'price-desc',
                            child: Text("Price: High to Low"),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.swap_vert_rounded,
                                size: 14,
                                color: Color(0xFF4B5563),
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Sort",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ৩. রেজাল্ট হেডার ও রিসেট অপশন
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Showing ${_technicians.length} of $_totalTechnicians technicians",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_activeFilterCount > 0 || _searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: _resetAllFilters,
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

              // ৪. 🌟 টেকনিশিয়ান ২-কলাম গ্রিড (Category & Service Screen এর মতো)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    if (_isLoading)
                      _TechniciansSkeletonGrid(
                        crossAxisCount: crossAxisCount,
                        cardCount: 6,
                      )
                    else if (_technicians.isEmpty)
                      _buildEmptyState()
                    else ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _technicians.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount, // মোবাইলে ২ টি কার্ড
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 225, // কার্ড সমান ও সুবিন্যস্ত
                        ),
                        itemBuilder: (context, index) {
                          return _buildTechnicianCard(_technicians[index]);
                        },
                      ),

                      // স্ক্রোল লোডিংয়ের সময় নিচে ২টা স্কেলেটন কার্ড
                      if (_isLoadingMore) ...[
                        const SizedBox(height: 12),
                        _TechniciansSkeletonGrid(
                          crossAxisCount: crossAxisCount,
                          cardCount: 2,
                        ),
                      ],
                    ],

                    if (!_hasMore &&
                        _technicians.isNotEmpty &&
                        !_isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            "You have reached the end of all technicians",
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.coral.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.coral : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 9, color: iconColor ?? AppColors.coral),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.coral : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 ২-কলামের কম্প্যাক্ট প্রিমিয়াম টেকনিশিয়ান কার্ড
  Widget _buildTechnicianCard(TechnicianModel tech) {
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
          // টপ রো: অ্যাভাটার (উইথ অনলাইন ডট) এবং রেটিং
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: const Color(0xFF14171C),
                    child: Text(
                      tech.name.isNotEmpty ? tech.name[0].toUpperCase() : 'T',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: tech.isAvailable
                            ? const Color(0xFF10B981)
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFDE68A).withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 2.5),
                    Text(
                      tech.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // টেকনিশিয়ান নাম ও ভেরিফায়েড ব্যাজ
          Row(
            children: [
              Expanded(
                child: Text(
                  tech.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.check_circle_rounded,
                size: 13,
                color: AppColors.teal,
              ),
            ],
          ),

          const SizedBox(height: 3),

          // এক্সপেরিয়েন্স ও লোকেশন
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 11,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  "${tech.experienceYears}y exp • ${tech.location}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF6B707E),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // প্রাইমারি স্কিল ট্যাগ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF3EFEA)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.handyman_rounded,
                  size: 11,
                  color: AppColors.coral,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    tech.skills.isNotEmpty
                        ? tech.skills.first
                        : "General Repair",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF3EFEA)),
          const SizedBox(height: 6),

          // ফুটার: ঘণ্টা প্রতি রেট ও বুক বাটন
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "RATE",
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "৳${tech.basePrice.toInt()}/hr",
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TechnicianDetailScreen(
                        technicianId: tech.id,
                        initialName: tech.name,
                      ),
                    ),
                  );
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
                      Icon(
                        Icons.person_rounded,
                        size: 11,
                        color: AppColors.coral,
                      ),
                      SizedBox(width: 3),
                      Text(
                        "View Profile",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 10,
                        color: Colors.white70,
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
              Icons.person_search_rounded,
              color: Colors.grey,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "No technicians found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Try adjusting your active filters or clear them to view all.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF6B707E)),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _resetAllFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Reset All Filters",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================
// 🌟 মডার্ন ফিল্টার বটম শীট (Bottom Sheet Filter Modal)
// ========================================================
class _TechnicianFilterBottomSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final String currentCategory;
  final String currentRating;
  final String currentLocation;
  final bool currentAvailableOnly;
  final double currentMaxPrice;
  final Function(String cat, String rating, String loc, bool avail, double maxP)
      onApply;
  final VoidCallback onReset;

  const _TechnicianFilterBottomSheet({
    required this.categories,
    required this.currentCategory,
    required this.currentRating,
    required this.currentLocation,
    required this.currentAvailableOnly,
    required this.currentMaxPrice,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_TechnicianFilterBottomSheet> createState() =>
      _TechnicianFilterBottomSheetState();
}

class _TechnicianFilterBottomSheetState
    extends State<_TechnicianFilterBottomSheet> {
  late String _tempCategory;
  late String _tempRating;
  late String _tempLocation;
  late bool _tempAvailableOnly;
  late double _tempMaxPrice;

  @override
  void initState() {
    super.initState();
    _tempCategory = widget.currentCategory;
    _tempRating = widget.currentRating;
    _tempLocation = widget.currentLocation;
    _tempAvailableOnly = widget.currentAvailableOnly;
    _tempMaxPrice = widget.currentMaxPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // হ্যান্ডেল বার
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // হেডার
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Filter Technicians",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onReset();
                    },
                    child: const Text(
                      "Reset All",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.coral,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1, color: Color(0xFFF3EFEA)),
              const SizedBox(height: 16),

              // ১. ক্যাটাগরি ফিল্টার
              const Text(
                "Service Category",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildOptionPill(
                    label: "All Categories",
                    isSelected: _tempCategory.isEmpty,
                    onTap: () => setState(() => _tempCategory = ""),
                  ),
                  ...widget.categories.map((cat) {
                    final isSel = _tempCategory.toLowerCase() ==
                            cat.name.toLowerCase() ||
                        _tempCategory == cat.id;
                    return _buildOptionPill(
                      label: cat.name,
                      isSelected: isSel,
                      onTap: () => setState(() => _tempCategory = cat.name),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 18),

              // ২. মিনিমাম রেটিং
              const Text(
                "Minimum Rating",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildRatingBox("Any", ""),
                  const SizedBox(width: 8),
                  _buildRatingBox("⭐ 4.5+", "4.5"),
                  const SizedBox(width: 8),
                  _buildRatingBox("⭐ 4.0+", "4.0"),
                  const SizedBox(width: 8),
                  _buildRatingBox("⭐ 3.5+", "3.5"),
                ],
              ),
              const SizedBox(height: 18),

              // ৩. শহর / লোকেশন
              const Text(
                "Popular Cities",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ["Dhaka", "Chittagong", "Sylhet"].map((city) {
                  final isSel = _tempLocation == city;
                  return _buildOptionPill(
                    label: city,
                    isSelected: isSel,
                    onTap: () {
                      setState(() {
                        _tempLocation = isSel ? "" : city;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // ৪. বাজেট / ঘণ্টা প্রতি রেট স্লাইডার
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Max Hourly Rate",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    "৳${_tempMaxPrice.toInt()}/hr",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _tempMaxPrice,
                min: 200,
                max: 2000,
                divisions: 18,
                activeColor: AppColors.teal,
                onChanged: (val) => setState(() => _tempMaxPrice = val),
              ),
              const SizedBox(height: 10),

              // ৫. অ্যাভেইলেবিলিটি সুইচ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Available Now Only",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  Switch.adaptive(
                    value: _tempAvailableOnly,
                    activeTrackColor: AppColors.teal,
                    onChanged: (val) =>
                        setState(() => _tempAvailableOnly = val),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // অ্যাপ্লাই বাটন
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onApply(
                      _tempCategory,
                      _tempRating,
                      _tempLocation,
                      _tempAvailableOnly,
                      _tempMaxPrice,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Apply Filters",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.coral : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBox(String label, String value) {
    final isSel = _tempRating == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tempRating = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel
                ? AppColors.coral.withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? AppColors.coral : const Color(0xFFE5E7EB),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel ? AppColors.coral : const Color(0xFF4B5563),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================================
// 🌟 পালসিং শিমার স্কেলেটন গ্রিড (Pure Flutter Shimmer)
// ========================================================
class _TechniciansSkeletonGrid extends StatefulWidget {
  final int crossAxisCount;
  final int cardCount;

  const _TechniciansSkeletonGrid({
    required this.crossAxisCount,
    this.cardCount = 6,
  });

  @override
  State<_TechniciansSkeletonGrid> createState() =>
      _TechniciansSkeletonGridState();
}

class _TechniciansSkeletonGridState extends State<_TechniciansSkeletonGrid>
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
              mainAxisExtent: 225,
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
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE2E4E8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 42,
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
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
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
                          width: 48,
                          height: 22,
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
