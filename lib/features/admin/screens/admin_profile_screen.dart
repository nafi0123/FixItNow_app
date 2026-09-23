import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../services/admin_service.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen>
    with WidgetsBindingObserver {
  static const String _cacheKey = 'admin_profile_cache';

  UserModel? _user;
  bool _isLoading = true;

  // Edit Name State
  bool _isEditingName = false;
  final TextEditingController _nameController = TextEditingController();
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initProfileWithCache();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadProfile(isBackground: true);
    }
  }

  // 🌟 Instant Cache Loading followed by Background Sync
  Future<void> _initProfileWithCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_cacheKey);

      if (cachedStr != null && cachedStr.isNotEmpty) {
        final data = jsonDecode(cachedStr) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _user = UserModel.fromJson(data);
            _nameController.text = _user?.name ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Admin Profile Cache Read Error: $e');
    }

    await _loadProfile(isBackground: !_isLoading);
  }

  Future<void> _loadProfile({bool isBackground = false}) async {
    if (!isBackground && _user == null) {
      setState(() => _isLoading = true);
    }

    try {
      final user = await AuthService.getUser(forceRefresh: true);
      if (mounted) {
        setState(() {
          _user = user;
          _nameController.text = user?.name ?? '';
          _isLoading = false;
        });

        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, jsonEncode(user.toJson()));
        }
      }
    } catch (e) {
      debugPrint('Admin Profile Fetch Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌟 Save Name
  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _isSavingName = true);

    final res = await AdminService.updateAdminProfile(name: newName);

    if (mounted) {
      setState(() => _isSavingName = false);

      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: Colors.green),
        );
        setState(() {
          _isEditingName = false;
        });
        _loadProfile(isBackground: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 🌟 Change Password Modal
  void _openChangePasswordModal() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
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
                  const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2026)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B707E)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: currentPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: newPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: confirmPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
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
                          final currentP = currentPassController.text;
                          final newP = newPassController.text;
                          final confirmP = confirmPassController.text;

                          if (currentP.isEmpty || newP.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all password fields')),
                            );
                            return;
                          }

                          if (newP != confirmP) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('New passwords do not match!')),
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(ctx);

                          final res = await AdminService.changePassword(
                            currentPassword: currentP,
                            newPassword: newP,
                          );

                          if (!mounted) return;
                          navigator.pop();
                          if (res.success) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(res.message), backgroundColor: Colors.green),
                            );
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
                      : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 Logout
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text(
          'Are you sure you want to log out of the admin panel?',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B707E)),
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
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove('admin_overview_cache');
      await prefs.remove('admin_users_cache');
      await prefs.remove('admin_categories_cache');

      await AuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
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
          'Admin Profile',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E2026)),
        ),
      ),
      body: _isLoading
          ? _buildProfileSkeleton()
          : RefreshIndicator(
              onRefresh: () => _loadProfile(isBackground: true),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 1. Dark Hero Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
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
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                _user?.name.isNotEmpty == true ? _user!.name[0].toUpperCase() : 'A',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _user?.name ?? 'Admin User',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _user?.email ?? '',
                            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user_outlined, size: 12, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'PLATFORM ADMINISTRATOR',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Personal Information Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE7E2D8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Account Information',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E2026)),
                              ),
                              if (!_isEditingName)
                                InkWell(
                                  onTap: () => setState(() => _isEditingName = true),
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                                        SizedBox(width: 4),
                                        Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_isEditingName) ...[
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _nameController.text = _user?.name ?? '';
                                      _isEditingName = false;
                                    });
                                  },
                                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B707E), fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _isSavingName ? null : _saveName,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  child: _isSavingName
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ] else ...[
                            _infoTile('Full Name', _user?.name ?? 'N/A', Icons.person_outline),
                          ],
                          const Divider(height: 24, color: Color(0xFFE7E2D8)),

                          _infoTile('Email Address', _user?.email ?? 'N/A', Icons.email_outlined),
                          const Divider(height: 24, color: Color(0xFFE7E2D8)),

                          _infoTile('Role', _user?.role ?? 'ADMIN', Icons.shield_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Security Settings (Change Password)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE7E2D8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Security & Password',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E2026)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage credentials to secure your admin account access.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B707E)),
                          ),
                          const SizedBox(height: 14),

                          OutlinedButton.icon(
                            onPressed: _openChangePasswordModal,
                            icon: const Icon(Icons.key_outlined, size: 16, color: Color(0xFF1E2026)),
                            label: const Text('Change Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              side: const BorderSide(color: Color(0xFFE7E2D8)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, size: 18, color: Color(0xFFE11D48)),
                        label: const Text('Log Out of Admin Account', style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFFECDD3)),
                          backgroundColor: const Color(0xFFFFF1F2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE7E2D8)),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF6B707E)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B707E))),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
          ],
        ),
      ],
    );
  }

  // 🌟 Shimmer Profile Skeleton Loader
  Widget _buildProfileSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Banner Skeleton
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E4E8),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 20),
          // Info Card Skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7E2D8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: 140, decoration: BoxDecoration(color: const Color(0xFFE2E4E8), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 16),
                Container(height: 38, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF0F1F3), borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 12),
                Container(height: 38, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF0F1F3), borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
