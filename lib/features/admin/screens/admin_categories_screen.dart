import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/dashboard_data_table.dart';
import '../services/admin_service.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen>
    with WidgetsBindingObserver {
  static const String _cacheKey = 'admin_categories_cache';

  List<AdminCategoryItem> _categories = [];
  bool _isLoading = true;

  // Pagination & Filtering state
  int _currentPage = 1;
  int _limit = 10;
  int _totalItems = 0;
  int _totalPages = 1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCategoriesWithCache();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchCategories(isBackground: true);
    }
  }

  // 🌟 Instant Cache Loading followed by Background Sync
  Future<void> _initCategoriesWithCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_cacheKey);

      if (cachedStr != null && cachedStr.isNotEmpty) {
        final data = jsonDecode(cachedStr) as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            _totalItems = data['totalItems'] ?? 0;
            _totalPages = data['totalPages'] ?? 1;

            if (data['categories'] is List) {
              _categories = (data['categories'] as List)
                  .map((item) => AdminCategoryItem.fromJson(item))
                  .toList();
            }

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Admin Categories Cache Read Error: $e');
    }

    await _fetchCategories(isBackground: !_isLoading);
  }

  Future<void> _fetchCategories({
    int? page,
    int? limit,
    String? search,
    bool isBackground = false,
  }) async {
    if (!isBackground) {
      if (_categories.isEmpty) {
        setState(() => _isLoading = true);
      }
    }

    if (page != null) _currentPage = page;
    if (limit != null) _limit = limit;
    if (search != null) _searchQuery = search;

    try {
      final res = await AdminService.getAllCategories(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (res.success) {
            _categories = res.categories;
            _totalItems = res.meta.total;
            _totalPages = res.meta.totalPage;
          } else {
            if (!isBackground) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res.message ?? 'Failed to load categories'), backgroundColor: Colors.red),
              );
            }
          }
        });

        // 🌟 Cache default page 1 unscoped query
        if (_currentPage == 1 && _searchQuery.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final cacheData = {
            'totalItems': _totalItems,
            'totalPages': _totalPages,
            'categories': _categories.map((c) => c.toJson()).toList(),
          };
          await prefs.setString(_cacheKey, jsonEncode(cacheData));
        }
      }
    } catch (e) {
      debugPrint('Admin Categories Fetch Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌟 Category Create / Update Modal
  void _openCategoryFormModal([AdminCategoryItem? category]) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Category' : 'Create New Category',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2026),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B707E)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. AC Repair',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe this service category...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a category name')),
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(ctx);

                          final res = isEditing
                              ? await AdminService.updateCategory(
                                  id: category.id,
                                  name: name,
                                  description: descController.text.trim(),
                                )
                              : await AdminService.createCategory(
                                  name: name,
                                  description: descController.text.trim(),
                                );

                          if (!mounted) return;
                          navigator.pop();
                          if (res.success) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(res.message), backgroundColor: Colors.green),
                            );
                            _fetchCategories(page: 1);
                          } else {
                            messenger.showSnackBar(
                              SnackBar(content: Text(res.message), backgroundColor: Colors.red),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEditing ? 'Save Changes' : 'Create Category', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 Confirm Delete Dialog
  Future<void> _confirmDeleteCategory(AdminCategoryItem category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Category?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B707E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B707E))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await AdminService.deleteCategory(category.id);
      if (mounted) {
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message), backgroundColor: Colors.green),
          );
          _fetchCategories(page: 1);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E2026)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Categories',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E2026)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DashboardDataTable<AdminCategoryItem>(
          title: 'Categories',
          subtitle: 'Create, view, update, and manage service categories for technician bookings.',
          icon: Icons.folder_open_outlined,
          headerAction: ElevatedButton.icon(
            onPressed: () => _openCategoryFormModal(),
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
            ),
          ),
          searchHint: 'Search categories...',
          onSearchChanged: (query) => _fetchCategories(search: query, page: 1),
          isLoading: _isLoading,
          items: _categories,
          currentPage: _currentPage,
          totalPages: _totalPages,
          totalItems: _totalItems,
          limit: _limit,
          onPageChanged: (newPage) => _fetchCategories(page: newPage),
          onLimitChanged: (newLimit) => _fetchCategories(limit: newLimit, page: 1),
          emptyTitle: 'No categories found',
          emptySubtitle: 'Create a new category to get started.',
          itemBuilder: (context, category, index) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Tag Icon Box
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.label_outline, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),

                  // 2. Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E2026)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Slug badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBF3),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE7E2D8)),
                              ),
                              child: Text(
                                '/${category.slug}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF6B707E), fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.description?.isNotEmpty == true ? category.description! : 'No description',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: category.description?.isNotEmpty == true ? const Color(0xFF4A4E58) : const Color(0xFF9AA0AA),
                            fontStyle: category.description?.isNotEmpty == true ? FontStyle.normal : FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Edit & Delete Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6B707E)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Edit',
                        onPressed: () => _openCategoryFormModal(category),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE11D48)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDeleteCategory(category),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
