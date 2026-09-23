import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/dashboard_data_table.dart';
import '../services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with WidgetsBindingObserver {
  static const String _cacheKey = 'admin_users_cache';

  List<AdminUserItem> _users = [];
  bool _isLoading = true;
  String? _updatingUserId;

  // Pagination & Filtering state
  int _currentPage = 1;
  int _limit = 10;
  int _totalItems = 0;
  int _totalPages = 1;
  String _searchQuery = '';
  String _selectedRole = 'ALL';

  final List<String> _roleFilters = ['ALL', 'CUSTOMER', 'TECHNICIAN', 'ADMIN'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initUsersWithCache();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchUsers(isBackground: true);
    }
  }

  // 🌟 Instant Cache Loading followed by Background Sync
  Future<void> _initUsersWithCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_cacheKey);

      if (cachedStr != null && cachedStr.isNotEmpty) {
        final data = jsonDecode(cachedStr) as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            _totalItems = data['totalItems'] ?? 0;
            _totalPages = data['totalPages'] ?? 1;

            if (data['users'] is List) {
              _users = (data['users'] as List)
                  .map((item) => AdminUserItem.fromJson(item))
                  .toList();
            }

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Admin Users Cache Read Error: $e');
    }

    await _fetchUsers(isBackground: !_isLoading);
  }

  Future<void> _fetchUsers({
    int? page,
    int? limit,
    String? search,
    String? role,
    bool isBackground = false,
  }) async {
    if (!isBackground) {
      if (_users.isEmpty) {
        setState(() => _isLoading = true);
      }
    }

    if (page != null) _currentPage = page;
    if (limit != null) _limit = limit;
    if (search != null) _searchQuery = search;
    if (role != null) _selectedRole = role;

    try {
      final res = await AdminService.getAllUsers(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery,
        role: _selectedRole,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (res.success) {
            _users = res.users;
            _totalItems = res.meta.total;
            _totalPages = res.meta.totalPage;
          } else {
            if (!isBackground) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res.message ?? 'Failed to load users'), backgroundColor: Colors.red),
              );
            }
          }
        });

        // 🌟 Cache default page 1 unscoped query
        if (_currentPage == 1 && _searchQuery.isEmpty && _selectedRole == 'ALL') {
          final prefs = await SharedPreferences.getInstance();
          final cacheData = {
            'totalItems': _totalItems,
            'totalPages': _totalPages,
            'users': _users.map((u) => u.toJson()).toList(),
          };
          await prefs.setString(_cacheKey, jsonEncode(cacheData));
        }
      }
    } catch (e) {
      debugPrint('Admin Users Fetch Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌟 Ban / Unban User Handler with Instant Cache Update
  Future<void> _confirmToggleBan(AdminUserItem user) async {
    final nextBannedState = !user.isBanned;
    final actionText = nextBannedState ? 'Ban' : 'Unban';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$actionText User?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(
          'Are you sure you want to $actionText "${user.name}" (${user.email})? ${nextBannedState ? "They will lose access to FixItNow." : "Their account will be restored."}',
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
              backgroundColor: nextBannedState ? const Color(0xFFE11D48) : const Color(0xFF0FA894),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(actionText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _updatingUserId = user.id);

      final res = await AdminService.updateUserStatus(
        userId: user.id,
        isBanned: nextBannedState,
      );

      if (mounted) {
        setState(() => _updatingUserId = null);

        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message), backgroundColor: Colors.green),
          );

          // Update local state and cache immediately
          final updated = _users.map((u) => u.id == user.id ? u.copyWith(isBanned: nextBannedState) : u).toList();
          setState(() {
            _users = updated;
          });

          final prefs = await SharedPreferences.getInstance();
          final cacheData = {
            'totalItems': _totalItems,
            'totalPages': _totalPages,
            'users': updated.map((u) => u.toJson()).toList(),
          };
          await prefs.setString(_cacheKey, jsonEncode(cacheData));
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
          'Manage Users',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E2026)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DashboardDataTable<AdminUserItem>(
          title: 'Users Management',
          subtitle: 'Audit all registered customers, technicians, and system administrators.',
          icon: Icons.manage_accounts_outlined,
          searchHint: 'Search by name or email...',
          onSearchChanged: (query) => _fetchUsers(search: query, page: 1),
          filterWidget: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _roleFilters.map((role) {
                final isSelected = _selectedRole == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      role,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF6B707E),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFFFAF8F5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (selected) {
                      if (selected) {
                        _fetchUsers(role: role, page: 1);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          isLoading: _isLoading,
          items: _users,
          currentPage: _currentPage,
          totalPages: _totalPages,
          totalItems: _totalItems,
          limit: _limit,
          onPageChanged: (newPage) => _fetchUsers(page: newPage),
          onLimitChanged: (newLimit) => _fetchUsers(limit: newLimit, page: 1),
          emptyTitle: 'No users found',
          emptySubtitle: 'Try adjusting your search or role filters.',
          itemBuilder: (context, user, index) {
            final isUpdating = _updatingUserId == user.id;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Initial Avatar (Dark ink box)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14171C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 2. Info (Name, Email, Role)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E2026),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildRoleBadge(user.role),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B707E)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Status Pill & Ban/Unban Action
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Status Badge
                      DashboardStatusBadge(status: user.isBanned ? 'BLOCKED' : 'ACTIVE'),
                      const SizedBox(height: 6),

                      // Ban / Unban Button
                      if (user.role != 'ADMIN')
                        InkWell(
                          onTap: isUpdating ? null : () => _confirmToggleBan(user),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isBanned
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: user.isBanned
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFFECDD3),
                              ),
                            ),
                            child: isUpdating
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 1.5),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        user.isBanned ? Icons.check_circle_outline : Icons.block,
                                        size: 12,
                                        color: user.isBanned
                                            ? const Color(0xFF059669)
                                            : const Color(0xFFE11D48),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.isBanned ? 'Unban' : 'Ban',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: user.isBanned
                                              ? const Color(0xFF059669)
                                              : const Color(0xFFE11D48),
                                        ),
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
          },
        ),
      ),
    );
  }

  // 🌟 Web Style Role Badge
  Widget _buildRoleBadge(String role) {
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
