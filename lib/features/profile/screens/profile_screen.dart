import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../faq/screens/faq_screen.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../admin/screens/admin_overview_screen.dart';
import '../../admin/screens/admin_users_screen.dart';
import '../../admin/screens/admin_categories_screen.dart';
import '../../admin/screens/admin_profile_screen.dart';
import '../../technician_dashboard/screens/technician_overview_screen.dart';
import '../../technician_dashboard/screens/technician_requests_screen.dart';
import '../../technician_dashboard/screens/technician_services_screen.dart';
import '../../technician_dashboard/screens/technician_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // 🌟 মেমোরি ক্যাশ এবং লোকাল স্টোরেজ থেকে ইনস্ট্যান্ট লোড
  Future<void> _loadUserProfile({bool silent = false}) async {
    final cached = AuthService.currentUser;
    if (cached != null && !silent) {
      setState(() {
        _currentUser = cached;
        _isLoading = false;
      });
    }

    final user = await AuthService.getUser(forceRefresh: true);
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  // 🌟 লগআউট ডায়ালগ
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFE11D48), size: 22),
            SizedBox(width: 8),
            Text(
              "Log Out",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to log out from your account?",
          style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              _loadUserProfile(silent: true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF1E2026),
                    content: Text("Logged out successfully"),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Account',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: _isLoading
          ? const _ProfileScreenSkeleton()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ১. ইউজার লগইন থাকলে প্রোফাইল কার্ড, না থাকলে লগইন প্রম্পট কার্ড
                      _currentUser != null
                          ? _buildLoggedInCard()
                          : _buildLoggedOutCard(),

                      const SizedBox(height: 24),

                      // 🌟 ২. ওয়েবের মতো হুবহু রোল ভিত্তিক ডায়নামিক মেনু
                      if (_currentUser != null) ...[
                        _buildRoleBasedDashboardSection(),
                        const SizedBox(height: 20),
                      ],

                      // ৩. সাপোর্ট ও হেল্প সেকশন
                      const Text(
                        'SUPPORT & HELP',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // FAQ টাইল
                      _optionTile(
                        context,
                        icon: Icons.help_outline_rounded,
                        iconColor: AppColors.coral,
                        title: 'FAQ & Help Center',
                        subtitle: 'Common questions answered clearly',
                        badgeText: 'Important',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FaqScreen(),
                            ),
                          );
                        },
                      ),

                      // কাস্টমার সাপোর্ট টাইল
                      _optionTile(
                        context,
                        icon: Icons.support_agent_rounded,
                        iconColor: AppColors.teal,
                        title: '24/7 Live Support',
                        subtitle: 'Talk directly with support team',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Support Hotline: +880 1700-000000'),
                            ),
                          );
                        },
                      ),

                      // ৪. লগআউট বাটন (ইউজার লগইন থাকলে দেখাবে)
                      if (_currentUser != null) ...[
                        const SizedBox(height: 14),
                        _optionTile(
                          context,
                          icon: Icons.logout_rounded,
                          iconColor: const Color(0xFFE11D48),
                          title: 'Log Out',
                          subtitle: 'Sign out from this device',
                          onTap: _confirmLogout,
                        ),
                      ],

                      const SizedBox(height: 30),

                      // ৫. অ্যাপ ভার্সন ফুটার
                      Center(
                        child: Column(
                          children: const [
                            Text(
                              'FixItNow App v1.0.0',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Fast, Reliable On-Demand Repairs',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // 🌟 ওয়েবসাইটের হুবহু নাম দিয়ে তৈরি রোল ভিত্তিক মেনু সেকশন
  Widget _buildRoleBasedDashboardSection() {
    final role = _currentUser!.role.toUpperCase();

    // 👑 ১. ADMIN রোলের জন্য (ওয়েবের মতো হুবহু)
    if (role == 'ADMIN') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ADMIN DASHBOARD',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          _optionTile(
            context,
            icon: Icons.dashboard_rounded,
            iconColor: AppColors.coral,
            title: "Overview",
            subtitle: "Platform statistics, revenue & insights",
            badgeText: "Admin",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminOverviewScreen()),
              );
            },
          ),
          _optionTile(
            context,
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFF0FA894),
            title: "Manage Users",
            subtitle: "View, manage & ban user accounts",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
              );
            },
          ),
          _optionTile(
            context,
            icon: Icons.category_rounded,
            iconColor: const Color(0xFFD97706),
            title: "Categories",
            subtitle: "Create, edit and organize service categories",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
              );
            },
          ),
          _optionTile(
            context,
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF6366F1),
            title: "Payments",
            subtitle: "Platform-wide transaction history & fees",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Navigating to Payments (/admin-dashboard/payments)")),
              );
            },
          ),
          _optionTile(
            context,
            icon: Icons.person_rounded,
            iconColor: AppColors.ink,
            title: "Profile",
            subtitle: "Admin account credentials & settings",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
              );
            },
          ),
        ],
      );
    }

    // 🔧 ২. TECHNICIAN রোলের জন্য (ওয়েবের মতো হুবহু)
    if (role == 'TECHNICIAN') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TECHNICIAN DASHBOARD',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          _optionTile(
            context,
            icon: Icons.dashboard_rounded,
            iconColor: const Color(0xFF0FA894),
            title: "Overview",
            subtitle: "Daily requests, rating & performance overview",
            badgeText: "Tech",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TechnicianOverviewScreen()),
              );
            },
          ),
          _optionTile(
            context,
            icon: Icons.assignment_rounded,
            iconColor: AppColors.coral,
            title: "Job requests",
            subtitle: "View and accept incoming customer repair requests",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TechnicianRequestsScreen()),
              );
            },
          ),
          _optionTile(
            context,
            icon: Icons.handyman_rounded,
            iconColor: const Color(0xFFD97706),
            title: "My services",
            subtitle: "Manage your services, descriptions and hourly rates",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TechnicianServicesScreen()),
              );
            },
          ),
          _optionTile(
            context,
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF059669),
            title: "Payments",
            subtitle: "Check completed job earnings & withdraw balance",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Navigating to Payments (/technician-dashboard/payments)")),
              );
            },
          ),
          _optionTile(
            context,
            icon: Icons.person_rounded,
            iconColor: AppColors.ink,
            title: "Profile",
            subtitle: "Technician skills, bio and profile settings",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TechnicianProfileScreen()),
              );
            },
          ),
        ],
      );
    }

    // 👤 ৩. CUSTOMER রোলের জন্য (ওয়েবের মতো হুবহু)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CUSTOMER DASHBOARD',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        _optionTile(
          context,
          icon: Icons.dashboard_rounded,
          iconColor: AppColors.coral,
          title: "Overview",
          subtitle: "Summary of ongoing repairs and recommendations",
          badgeText: "Customer",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Navigating to Overview (/dashboard)")),
            );
          },
        ),
        _optionTile(
          context,
          icon: Icons.calendar_month_rounded,
          iconColor: const Color(0xFF0FA894),
          title: "My Bookings",
          subtitle: "Track live status, dates and past technician repairs",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Navigating to My Bookings (/dashboard/bookings)")),
            );
          },
        ),
        _optionTile(
          context,
          icon: Icons.receipt_long_rounded,
          iconColor: const Color(0xFF6366F1),
          title: "Payments",
          subtitle: "Invoices, payment receipts and transaction records",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Navigating to Payments (/dashboard/payments)")),
            );
          },
        ),
        _optionTile(
          context,
          icon: Icons.person_rounded,
          iconColor: AppColors.ink,
          title: "Profile",
          subtitle: "Manage personal account details and address",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Navigating to Profile (/dashboard/profile)")),
            );
          },
        ),
      ],
    );
  }

  // 🌟 লগইন করা ইউজারের প্রোফাইল কার্ড
  Widget _buildLoggedInCard() {
    final initials = _currentUser!.name.isNotEmpty
        ? _currentUser!.name[0].toUpperCase()
        : 'U';

    final isCustomer = _currentUser!.role == 'CUSTOMER';
    final isTech = _currentUser!.role == 'TECHNICIAN';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.ink,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _currentUser!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: isTech
                            ? const Color(0xFFECFDF5)
                            : isCustomer
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isTech
                              ? const Color(0xFFA7F3D0)
                              : isCustomer
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFFFECDD3),
                        ),
                      ),
                      child: Text(
                        _currentUser!.role,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: isTech
                              ? const Color(0xFF059669)
                              : isCustomer
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFFE11D48),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser!.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 লগআউট অবস্থায় প্রম্পট কার্ড
  Widget _buildLoggedOutCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.coral,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Welcome to FixItNow',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sign in to book & track technicians',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final loggedIn = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
              if (loggedIn == true) {
                _loadUserProfile();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Log In',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  color: iconColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================================
// 🌟 প্রোফাইল স্ক্রিন অ্যানিমেটেড শিমার স্কেলেটন (Pure Flutter)
// ========================================================
class _ProfileScreenSkeleton extends StatefulWidget {
  const _ProfileScreenSkeleton();

  @override
  State<_ProfileScreenSkeleton> createState() => _ProfileScreenSkeletonState();
}

class _ProfileScreenSkeletonState extends State<_ProfileScreenSkeleton>
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ১. প্রোফাইল কার্ড স্কেলেটন
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE2E4E8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 140,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E4E8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 180,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F1F3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 60,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E4E8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ২. সেকশন হেডিং স্কেলেটন
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E4E8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ৩. অপশন টাইলস স্কেলেটন
                    ...List.generate(3, (i) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F1F3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 130,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E4E8),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 190,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F1F3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
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
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
