import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/dashboard_data_table.dart';
import '../services/technician_service.dart';

class TechnicianServicesScreen extends StatefulWidget {
  const TechnicianServicesScreen({super.key});

  @override
  State<TechnicianServicesScreen> createState() => _TechnicianServicesScreenState();
}

class _TechnicianServicesScreenState extends State<TechnicianServicesScreen>
    with WidgetsBindingObserver {
  static const String _cacheKey = 'technician_services_cache';

  List<TechnicianServiceItem> _services = [];
  List<CategoryItem> _categories = [];
  bool _isLoading = true;

  // Pagination & Search
  int _currentPage = 1;
  int _limit = 10;
  int _totalItems = 0;
  int _totalPages = 1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initServicesWithCache();
    _loadCategories();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchServices(isBackground: true);
      _loadCategories();
    }
  }

    Future<void> _loadCategories() async {
    try {
      final cats = await TechnicianService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories for service dropdown: ');
    }
  }

  // 🌟 0ms Instant Cache Loading followed by Background Sync
  Future<void> _initServicesWithCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_cacheKey);

      if (cachedStr != null && cachedStr.isNotEmpty) {
        final data = jsonDecode(cachedStr) as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            _totalItems = data['totalItems'] ?? 0;
            _totalPages = data['totalPages'] ?? 1;

            if (data['services'] is List) {
              _services = (data['services'] as List)
                  .map((item) => TechnicianServiceItem.fromJson(item))
                  .toList();
            }

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Technician Services Cache Read Error: $e');
    }

    await _fetchServices(isBackground: !_isLoading);
  }

  Future<void> _fetchServices({
    int? page,
    int? limit,
    String? search,
    bool isBackground = false,
  }) async {
    if (!isBackground) {
      if (_services.isEmpty) {
        setState(() => _isLoading = true);
      }
    }

    if (page != null) _currentPage = page;
    if (limit != null) _limit = limit;
    if (search != null) _searchQuery = search;

    try {
      final res = await TechnicianService.getAllServices(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (res.success) {
            _services = res.services;
            _totalItems = res.meta.total;
            _totalPages = res.meta.totalPage;
          } else {
            if (!isBackground) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res.message), backgroundColor: Colors.red),
              );
            }
          }
        });

        // Cache default page 1 snapshot
        if (_currentPage == 1 && _searchQuery.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final cacheData = {
            'totalItems': _totalItems,
            'totalPages': _totalPages,
            'services': _services.map((s) => s.toJson()).toList(),
          };
          await prefs.setString(_cacheKey, jsonEncode(cacheData));
        }
      }
    } catch (e) {
      debugPrint('Technician Services Fetch Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌟 Create / Edit Service Modal
  Future<void> _openServiceFormModal([TechnicianServiceItem? serviceToEdit]) async {
    // If categories are empty, fetch now
    if (_categories.isEmpty) {
      await _loadCategories();
    }

    final isEditing = serviceToEdit != null;
    final nameCtrl = TextEditingController(text: serviceToEdit?.name ?? '');
    final descCtrl = TextEditingController(text: serviceToEdit?.description ?? '');
    final priceCtrl = TextEditingController(text: serviceToEdit != null ? serviceToEdit.price.toStringAsFixed(0) : '');
    final durationCtrl = TextEditingController(text: serviceToEdit?.duration ?? '1-2 Hours');
    String? selectedCategoryId = serviceToEdit?.categoryId;

    if (selectedCategoryId == null || selectedCategoryId.isEmpty || !_categories.any((c) => c.id == selectedCategoryId)) {
      if (_categories.isNotEmpty) {
        selectedCategoryId = _categories.first.id;
      }
    }

    bool isSubmitting = false;

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Service' : 'Add New Service',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2026)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B707E)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 16, color: Color(0xFFE7E2D8)),

              // Service Name
              const Text('Service Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Master AC Deep Cleaning',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9AA0AA)),
                  filled: true,
                  fillColor: const Color(0xFFFAF8F5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),

              // Category Dropdown
              const Text('Category *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE7E2D8)),
                ),
                child: _categories.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.0),
                        child: Text('Loading categories...', style: TextStyle(fontSize: 13, color: Color(0xFF9AA0AA))),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedCategoryId != null && _categories.any((c) => c.id == selectedCategoryId) ? selectedCategoryId : _categories.first.id,
                          hint: const Text('Select a category', style: TextStyle(fontSize: 13, color: Color(0xFF9AA0AA))),
                          items: _categories.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(
                                c.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E2026)),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedCategoryId = val);
                            }
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // Price & Duration
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Price (৳) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'e.g. 500',
                            prefixText: '৳ ',
                            filled: true,
                            fillColor: const Color(0xFFFAF8F5),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimated Duration *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: durationCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. 1-2 Hours',
                            filled: true,
                            fillColor: const Color(0xFFFAF8F5),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              const Text('Description (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Explain what is included in this repair / service...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9AA0AA)),
                  filled: true,
                  fillColor: const Color(0xFFFAF8F5),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          final price = double.tryParse(priceCtrl.text.trim());
                          final duration = durationCtrl.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter service name')));
                            return;
                          }
                          if (price == null || price <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid price')));
                            return;
                          }
                          if (selectedCategoryId == null || selectedCategoryId!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
                            return;
                          }

                          setModalState(() => isSubmitting = true);

                          TechnicianActionResponse res;
                          if (isEditing) {
                            res = await TechnicianService.updateService(
                              id: serviceToEdit.id,
                              name: name,
                              description: descCtrl.text.trim(),
                              price: price,
                              duration: duration.isEmpty ? '1-2 Hours' : duration,
                              categoryId: selectedCategoryId!,
                            );
                          } else {
                            res = await TechnicianService.createService(
                              name: name,
                              description: descCtrl.text.trim(),
                              price: price,
                              duration: duration.isEmpty ? '1-2 Hours' : duration,
                              categoryId: selectedCategoryId!,
                            );
                          }

                          if (!context.mounted) return;
                          Navigator.pop(ctx);

                          if (res.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res.message), backgroundColor: const Color(0xFF0FA894)),
                            );
                            _fetchServices(page: 1);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res.message), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          isEditing ? 'Save Changes' : 'Create Service',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 Delete Service Confirmation
  Future<void> _confirmDeleteService(TechnicianServiceItem service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Service?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(
          'Are you sure you want to delete "${service.name}"? This action cannot be undone.',
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
      final res = await TechnicianService.deleteService(service.id);
      if (mounted) {
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message), backgroundColor: const Color(0xFF0FA894)),
          );
          _fetchServices(page: 1);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message), backgroundColor: Colors.redAccent),
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
          'My Services',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E2026)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE7E2D8), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DashboardDataTable<TechnicianServiceItem>(
          title: 'My Services',
          subtitle: 'Create and customize services you provide to customers.',
          icon: Icons.build_circle_outlined,
          headerAction: ElevatedButton.icon(
            onPressed: () => _openServiceFormModal(),
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('Add Service', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
            ),
          ),
          searchHint: 'Search services...',
          onSearchChanged: (query) => _fetchServices(search: query, page: 1),
          isLoading: _isLoading,
          items: _services,
          currentPage: _currentPage,
          totalPages: _totalPages,
          totalItems: _totalItems,
          limit: _limit,
          onPageChanged: (newPage) => _fetchServices(page: newPage),
          onLimitChanged: (newLimit) => _fetchServices(limit: newLimit, page: 1),
          emptyTitle: 'No services offered yet',
          emptySubtitle: 'Click "+ Add Service" to publish your first service offering.',
          itemBuilder: (context, service, index) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0FA894).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.handyman_outlined, size: 20, color: Color(0xFF0FA894)),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                service.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E2026)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBF3),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE7E2D8)),
                              ),
                              child: Text(
                                service.categoryName,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        if (service.description != null && service.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            service.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B707E)),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '৳${service.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0FA894)),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time, size: 13, color: Color(0xFF9AA0AA)),
                            const SizedBox(width: 4),
                            Text(
                              service.duration,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B707E)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6B707E)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Edit',
                        onPressed: () => _openServiceFormModal(service),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE11D48)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDeleteService(service),
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
