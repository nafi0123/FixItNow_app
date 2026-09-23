import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/customer_service.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isSyncing = false;

  // এডিটিং স্টেট
  bool _isEditingName = false;
  final TextEditingController _nameController = TextEditingController();
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 🌟 ক্যাশ-ফার্স্ট ডেটা লোডিং
  Future<void> _loadProfile({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = AuthService.currentUser;
      if (cached != null && mounted) {
        setState(() {
          _user = cached;
          _nameController.text = cached.name;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isSyncing = true);
    }

    final fresh = await AuthService.getUser(forceRefresh: true);
    if (mounted) {
      setState(() {
        _user = fresh ?? _user;
        if (!_isEditingName && fresh != null) {
          _nameController.text = fresh.name;
        }
        _isLoading = false;
        _isSyncing = false;
      });
    }
  }

  // 🌟 নাম আপডেট হ্যান্ডলার
  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name cannot be empty")),
      );
      return;
    }

    setState(() => _isSavingName = true);
    final res = await CustomerService.updateProfile(name: newName);

    if (mounted) {
      setState(() {
        _isSavingName = false;
        if (res.success) {
          _isEditingName = false;
          _user = AuthService.currentUser;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: res.success ? const Color(0xFF0FA894) : const Color(0xFFC23B1F),
          content: Text(res.message),
        ),
      );
    }
  }

  // 🌟 স্ক্রিনশটের হুবহু চেঞ্জ পাসওয়ার্ড মডাল ডায়ালগ
  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isChanging = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ১. হেডার: "Change Password" ও (X) ক্লোজ বাটন
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Change Password",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF14171C),
                            letterSpacing: -0.3,
                          ),
                        ),
                        InkWell(
                          onTap: isChanging ? null : () => Navigator.pop(dialogCtx),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ২. Current Password ফিল্ড
                    _passwordField(
                      controller: currentPassCtrl,
                      hintText: "Current Password",
                    ),

                    const SizedBox(height: 14),

                    // ৩. New Password ফিল্ড
                    _passwordField(
                      controller: newPassCtrl,
                      hintText: "New Password",
                    ),

                    const SizedBox(height: 14),

                    // ৪. Confirm New Password ফিল্ড
                    _passwordField(
                      controller: confirmPassCtrl,
                      hintText: "Confirm New Password",
                    ),

                    const SizedBox(height: 22),

                    // ৫. ফুল-উইডথ "Update Password" অরেঞ্জ বাটন (স্ক্রিনশটের মতো হুবহু)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isChanging
                            ? null
                            : () async {
                                final current = currentPassCtrl.text.trim();
                                final newP = newPassCtrl.text.trim();
                                final confirm = confirmPassCtrl.text.trim();

                                if (current.isEmpty || newP.isEmpty || confirm.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("All password fields are required")),
                                  );
                                  return;
                                }

                                if (newP != confirm) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("New passwords do not match")),
                                  );
                                  return;
                                }

                                if (newP.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("New password must be at least 6 characters")),
                                  );
                                  return;
                                }

                                setDialogState(() => isChanging = true);
                                final res = await CustomerService.changePassword(
                                  currentPassword: current,
                                  newPassword: newP,
                                );

                                if (!dialogCtx.mounted) return;
                                Navigator.pop(dialogCtx);

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: res.success ? const Color(0xFF0FA894) : const Color(0xFFC23B1F),
                                    content: Text(res.message),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isChanging
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text(
                                "Update Password",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6B7280).withValues(alpha: 0.6), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF14171C),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 15,
            color: Color(0xFF4B5563),
            fontWeight: FontWeight.normal,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "U";
    final parts = name.trim().split(" ");
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(_user?.name ?? "");

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              "My Profile",
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            if (_isSyncing) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh Profile",
            icon: Icon(Icons.refresh_rounded, color: _isSyncing ? AppColors.coral : AppColors.ink, size: 20),
            onPressed: () => _loadProfile(forceRefresh: true),
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: _isLoading && _user == null
          ? const _CustomerProfileSkeleton()
          : RefreshIndicator(
              color: AppColors.coral,
              onRefresh: () => _loadProfile(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ১. পেজ টাইটেল হেডার (ওয়েবের মতো)
                    const Text(
                      "My Profile",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF14171C),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Manage your personal information and account settings.",
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                    ),

                    const SizedBox(height: 16),

                    // ২. অ্যাভাটার + নেম কার্ড (ওয়েবের মতো হুবহু গ্র্যাডিয়েন্ট + ক্যামেরা ব্যাজ)
                    _buildAvatarNameCard(initials),

                    const SizedBox(height: 16),

                    // ৩. ইনফো কার্ডস গ্রিড (৪টি কার্ড: Email, Member Since, Account Type, Status)
                    _buildInfoGrid(),

                    const SizedBox(height: 16),

                    // ৪. সিকিউরিটি সেকশন কার্ড (Password Change)
                    _buildSecuritySection(),

                    const SizedBox(height: 16),

                    // ৫. ডেঞ্জার জোন — সাইন আউট কার্ড
                    _buildSignOutCard(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // 🌟 ২. অ্যাভাটার + নেম কার্ড
  Widget _buildAvatarNameCard(String initials) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E2D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // অ্যাভাটার সাথে ক্যামেরা ব্যাজ
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.coral, Color(0xFFC23B1F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // নাম ও স্ট্যাটাস
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditingName) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          autofocus: true,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.coral),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: _isSavingName ? null : _saveName,
                        icon: _isSavingName
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check_rounded, color: AppColors.teal, size: 22),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _isEditingName = false),
                        icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _user?.name ?? "Customer",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF14171C),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isEditingName = true;
                            _nameController.text = _user?.name ?? "";
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.edit_outlined, size: 15, color: Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 6),

                // কাস্টমার ব্যাজ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 12, color: AppColors.teal),
                      SizedBox(width: 4),
                      Text(
                        "CUSTOMER",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teal,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 ৩. ইনফো কার্ডস গ্রিড (৪টি কার্ড)
  Widget _buildInfoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _infoCard(
                icon: Icons.mail_outline_rounded,
                iconColor: AppColors.coral,
                iconBg: const Color(0xFFFF5A36).withValues(alpha: 0.1),
                title: "EMAIL ADDRESS",
                value: _user?.email ?? "—",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard(
                icon: Icons.calendar_today_rounded,
                iconColor: AppColors.teal,
                iconBg: const Color(0xFF0FA894).withValues(alpha: 0.1),
                title: "MEMBER SINCE",
                value: "Active Member",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _infoCard(
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFF14171C),
                iconBg: const Color(0xFF14171C).withValues(alpha: 0.08),
                title: "ACCOUNT TYPE",
                value: "Customer",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard(
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.teal,
                iconBg: const Color(0xFF0FA894).withValues(alpha: 0.1),
                title: "ACCOUNT STATUS",
                value: "Active & Verified",
                valueColor: AppColors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E2D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? const Color(0xFF14171C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 ৪. সিকিউরিটি সেকশন কার্ড
  Widget _buildSecuritySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E2D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF9CA3AF)),
              SizedBox(width: 6),
              Text(
                "Security",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF14171C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14171C),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Keep your account secure with a strong password.",
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _showChangePasswordDialog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE7E2D8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: const Text(
                  "Change Password",
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14171C),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🌟 ৫. ডেঞ্জার জোন — সাইন আউট কার্ড
  Widget _buildSignOutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E2D8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sign Out",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14171C),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Sign out from this device session.",
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Signed out successfully")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              "Sign Out",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================
// 🌟 প্রোফাইল স্ক্রিন শিমার স্কেলেটন (Pure Flutter)
// ========================================================
class _CustomerProfileSkeleton extends StatefulWidget {
  const _CustomerProfileSkeleton();

  @override
  State<_CustomerProfileSkeleton> createState() => _CustomerProfileSkeletonState();
}

class _CustomerProfileSkeletonState extends State<_CustomerProfileSkeleton>
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE7E2D8)),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE7E2D8)),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE7E2D8)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
