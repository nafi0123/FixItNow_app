import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/admin_service.dart';
import 'admin_users_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_profile_screen.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen>
    with WidgetsBindingObserver {
  static const String _cacheKey = 'admin_overview_cache';

  bool _isLoading = true;
  bool _isSyncing = false;
  UserModel? _adminUser;

  int _totalUsers = 0;
  int _totalCustomers = 0;
  int _totalTechnicians = 0;
  int _totalCategories = 0;

  List<AdminUserItem> _recentUsers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initOverviewWithCache();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 🌟 Re-sync when app resumes from background or another app
      _loadOverviewData(isBackground: true);
    }
  }

  // 🌟 0ms Instant Cache Loading followed by Background Sync
  Future<void> _initOverviewWithCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_cacheKey);

      if (cachedStr != null && cachedStr.isNotEmpty) {
        final data = jsonDecode(cachedStr) as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            _totalUsers = data['totalUsers'] ?? 0;
            _totalCustomers = data['totalCustomers'] ?? 0;
            _totalTechnicians = data['totalTechnicians'] ?? 0;
            _totalCategories = data['totalCategories'] ?? 0;

            if (data['recentUsers'] is List) {
              _recentUsers = (data['recentUsers'] as List)
                  .map((item) => AdminUserItem.fromJson(item))
                  .toList();
            }

            if (data['adminUser'] != null) {
              _adminUser = UserModel.fromJson(data['adminUser']);
            }

            // Cached data rendered immediately in 0ms!
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Admin Overview Cache Read Error: $e');
    }

    // Always fetch fresh data silently
    await _loadOverviewData(isBackground: !_isLoading);
  }

  Future<void> _loadOverviewData({bool isBackground = false}) async {
    if (!isBackground) {
      if (mounted) setState(() => _isLoading = true);
    } else {
      if (mounted) setState(() => _isSyncing = true);
    }

    try {
      final user = await AuthService.getUser();
      final usersRes = await AdminService.getAllUsers(limit: 100);
      final catRes = await AdminService.getAllCategories(limit: 100);

      if (mounted) {
        int nextTotalUsers = _totalUsers;
        int nextTotalCustomers = _totalCustomers;
        int nextTotalTechnicians = _totalTechnicians;
        int nextTotalCategories = _totalCategories;
        List<AdminUserItem> nextRecentUsers = _recentUsers;

        if (usersRes.success) {
          final all = usersRes.users;
          nextTotalUsers = usersRes.meta.total;
          nextTotalCustomers = all.where((u) => u.role == 'CUSTOMER').length;
          nextTotalTechnicians = all.where((u) => u.role == 'TECHNICIAN').length;
          nextRecentUsers = all.take(5).toList();
        }

        if (catRes.success) {
          nextTotalCategories = catRes.meta.total;
        }

        setState(() {
          _adminUser = user;
          _totalUsers = nextTotalUsers;
          _totalCustomers = nextTotalCustomers;
          _totalTechnicians = nextTotalTechnicians;
          _totalCategories = nextTotalCategories;
          _recentUsers = nextRecentUsers;
          _isLoading = false;
          _isSyncing = false;
        });

        // 🌟 Save to SharedPreferences Cache
        final prefs = await SharedPreferences.getInstance();
        final cacheData = {
          'totalUsers': nextTotalUsers,
          'totalCustomers': nextTotalCustomers,
          'totalTechnicians': nextTotalTechnicians,
          'totalCategories': nextTotalCategories,
          'recentUsers': nextRecentUsers.map((u) => u.toJson()).toList(),
          if (user != null) 'adminUser': user.toJson(),
        };
        await prefs.setString(_cacheKey, jsonEncode(cacheData));
      }
    } catch (e) {
      debugPrint('Admin Overview Fetch Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSyncing = false;
        });
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
          'Admin Overview',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E2026)),
        ),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF1E2026)),
            onPressed: () => _loadOverviewData(isBackground: false),
          ),
        ],
      ),
      body: _isLoading
          ? _buildOverviewSkeleton()
          : RefreshIndicator(
              onRefresh: () => _loadOverviewData(isBackground: true),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Welcome Dark Hero Banner (Web style)
                    _buildWelcomeBanner(),
                    const SizedBox(height: 20),

                    // 2. Metrics Title
                    const Text(
                      'Platform Insights',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2026),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Grid of Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Total Users',
                            count: '$_totalUsers',
                            subtitle: 'All platform users',
                            icon: Icons.people_alt_outlined,
                            iconColor: AppColors.primary,
                            bgColor: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Categories',
                            count: '$_totalCategories',
                            subtitle: 'Service categories',
                            icon: Icons.folder_open_outlined,
                            iconColor: const Color(0xFFD97706),
                            bgColor: const Color(0xFFD97706).withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Customers',
                            count: '$_totalCustomers',
                            subtitle: 'Service clients',
                            icon: Icons.person_outline,
                            iconColor: const Color(0xFF0FA894),
                            bgColor: const Color(0xFF0FA894).withValues(alpha: 0.1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Technicians',
                            count: '$_totalTechnicians',
                            subtitle: 'Verified pros',
                            icon: Icons.build_outlined,
                            iconColor: const Color(0xFF8B5CF6),
                            bgColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 4. Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2026),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildQuickAction(
                      icon: Icons.manage_accounts_outlined,
                      iconColor: AppColors.primary,
                      title: 'Manage Users',
                      subtitle: 'Audit accounts, filter roles, ban or unban users',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                        );
                        _loadOverviewData(isBackground: true);
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildQuickAction(
                      icon: Icons.category_outlined,
                      iconColor: const Color(0xFFD97706),
                      title: 'Manage Categories',
                      subtitle: 'Add, update or remove repair service categories',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
                        );
                        _loadOverviewData(isBackground: true);
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildQuickAction(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: const Color(0xFF0FA894),
                      title: 'Admin Profile Settings',
                      subtitle: 'Update your account name and security password',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
                        );
                        _loadOverviewData(isBackground: true);
                      },
                    ),
                    const SizedBox(height: 24),

                    // 5. Recent Users Preview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Registered Users',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2026),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                            );
                            _loadOverviewData(isBackground: true);
                          },
                          child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE7E2D8)),
                      ),
                      child: _recentUsers.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text('No users registered yet', style: TextStyle(fontSize: 12, color: Color(0xFF6B707E))),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentUsers.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE7E2D8)),
                              itemBuilder: (context, index) {
                                final user = _recentUsers[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF14171C),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2026))),
                                            Text(user.email, style: const TextStyle(fontSize: 11, color: Color(0xFF6B707E))),
                                          ],
                                        ),
                                      ),
                                      _buildSmallRoleBadge(user.role),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // 🌟 Welcome Hero Banner
  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14171C), Color(0xFF1E252F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text('ADMIN CONTROL PANEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome back, ${_adminUser?.name ?? "Admin"} 👋',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Here is a quick summary of what is happening across FixItNow platform today.',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  // 🌟 Stat Card
  Widget _buildStatCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E2026))),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B707E))),
        ],
      ),
    );
  }

  // 🌟 Quick Action Tile
  Widget _buildQuickAction({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7E2D8)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E2026))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B707E))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9AA0AA)),
          ],
        ),
      ),
    );
  }

  // 🌟 Small Role Badge
  Widget _buildSmallRoleBadge(String role) {
    Color bg;
    Color text;
    switch (role) {
      case 'ADMIN':
        bg = const Color(0xFF14171C);
        text = Colors.white;
        break;
      case 'TECHNICIAN':
        bg = const Color(0xFF0FA894).withValues(alpha: 0.12);
        text = const Color(0xFF0FA894);
        break;
      case 'CUSTOMER':
      default:
        bg = AppColors.primary.withValues(alpha: 0.12);
        text = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(role, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: text)),
    );
  }

  // 🌟 Full Screen Shimmer Skeleton for Admin Overview
  Widget _buildOverviewSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner skeleton
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E4E8),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 20),

          // Title skeleton
          Container(
            width: 140,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E4E8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),

          // Stat cards skeleton
          Row(
            children: [
              Expanded(child: _buildSkeletonCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildSkeletonCard()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSkeletonCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildSkeletonCard()),
            ],
          ),
          const SizedBox(height: 24),

          // Quick actions title skeleton
          Container(
            width: 120,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E4E8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          _buildSkeletonQuickAction(),
          const SizedBox(height: 10),
          _buildSkeletonQuickAction(),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFF0F1F3), borderRadius: BorderRadius.circular(10))),
              Container(width: 36, height: 22, decoration: BoxDecoration(color: const Color(0xFFE2E4E8), borderRadius: BorderRadius.circular(4))),
            ],
          ),
          const SizedBox(height: 12),
          Container(width: 70, height: 12, decoration: BoxDecoration(color: const Color(0xFFE2E4E8), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          Container(width: 90, height: 9, decoration: BoxDecoration(color: const Color(0xFFF0F1F3), borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }

  Widget _buildSkeletonQuickAction() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E2D8)),
      ),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF0F1F3), borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 110, height: 13, decoration: BoxDecoration(color: const Color(0xFFE2E4E8), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(width: 180, height: 10, decoration: BoxDecoration(color: const Color(0xFFF0F1F3), borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
