import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../technicians/screens/technicians_screen.dart';
import '../services/customer_service.dart';
import 'customer_bookings_screen.dart';
import 'customer_profile_screen.dart';
import '../../payments/screens/payments_screen.dart';

class CustomerOverviewScreen extends StatefulWidget {
  const CustomerOverviewScreen({super.key});

  @override
  State<CustomerOverviewScreen> createState() => _CustomerOverviewScreenState();
}

class _CustomerOverviewScreenState extends State<CustomerOverviewScreen> {
  CustomerOverviewData? _data;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadOverviewData();
  }

  // 🌟 ক্যাশ-ফার্স্ট ডেটা লোডিং ও ব্যাকগ্রাউন্ড সিঙ্ক
  Future<void> _loadOverviewData({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await CustomerService.getCustomerOverview(forceRefresh: false);
      if (cached != null && mounted) {
        setState(() {
          _data = cached;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isSyncing = true);
    }

    final fresh = await CustomerService.getCustomerOverview(forceRefresh: true);
    if (mounted) {
      setState(() {
        _data = fresh ?? _data;
        _isLoading = false;
        _isSyncing = false;
      });
    }
  }

  // 🌟 স্ট্যাটাস ব্যাজ কালার ও আইকন হেল্পার
  Color _getStatusBg(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFFFBEB);
      case 'ACCEPTED':
        return const Color(0xFFEFF6FF);
      case 'COMPLETED':
        return const Color(0xFFECFDF5);
      case 'DECLINED':
        return const Color(0xFFFFF1F2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFD97706);
      case 'ACCEPTED':
        return const Color(0xFF2563EB);
      case 'COMPLETED':
        return const Color(0xFF059669);
      case 'DECLINED':
        return const Color(0xFFE11D48);
      default:
        return const Color(0xFF4B5563);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerName = _data?.user?.name ?? AuthService.currentUser?.name ?? 'Valued Customer';

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
              "Customer Dashboard",
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 17,
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
            tooltip: "Refresh Data",
            icon: Icon(
              Icons.refresh_rounded,
              color: _isSyncing ? AppColors.coral : AppColors.ink,
              size: 20,
            ),
            onPressed: () => _loadOverviewData(forceRefresh: true),
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: _isLoading && _data == null
          ? const _CustomerOverviewSkeleton()
          : RefreshIndicator(
              color: AppColors.coral,
              backgroundColor: Colors.white,
              onRefresh: () => _loadOverviewData(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ১. ওয়েলকাম হিরো ব্যানার
                    _buildWelcomeHeroBanner(customerName),

                    const SizedBox(height: 18),

                    // ২. মেট্রিক কার্ডস গ্রিড (৪টি কার্ড)
                    _buildMetricCardsGrid(),

                    const SizedBox(height: 20),

                    // ৩. কুইক অ্যাকশন কার্ডস (৩টি হাইলাইট কার্ড)
                    _buildQuickActionCards(),

                    const SizedBox(height: 22),

                    // ৪. সাম্প্রতিক বুকিং সেকশন
                    _buildRecentBookingsSection(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // 🌟 ১. ওয়েলকাম হিরো ব্যানার
  Widget _buildWelcomeHeroBanner(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppColors.teal, size: 14),
                SizedBox(width: 6),
                Text(
                  "Customer Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
              children: [
                const TextSpan(text: "Welcome back, "),
                TextSpan(
                  text: name,
                  style: const TextStyle(color: AppColors.coral),
                ),
                const TextSpan(text: "!"),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Track service bookings, review technicians, and request expert repair services in one tap.",
            style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB), height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TechniciansScreen()),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                label: const Text(
                  "Book Service",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerBookingsScreen()),
                  );
                },
                icon: const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.white),
                label: const Text(
                  "My Bookings",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🌟 ২. মেট্রিক কার্ডস গ্রিড
  Widget _buildMetricCardsGrid() {
    final total = _data?.totalBookings ?? 0;
    final active = _data?.activeBookingsCount ?? 0;
    final completed = _data?.completedBookingsCount ?? 0;
    final spent = _data?.totalSpent ?? 0.0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _metricTile(
          icon: Icons.calendar_today_rounded,
          iconColor: AppColors.coral,
          bgColor: const Color(0xFFFF5A36).withValues(alpha: 0.1),
          title: "TOTAL BOOKINGS",
          value: "$total",
          subtitle: "All repair history",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerBookingsScreen()),
            );
          },
        ),
        _metricTile(
          icon: Icons.schedule_rounded,
          iconColor: AppColors.teal,
          bgColor: const Color(0xFF0FA894).withValues(alpha: 0.1),
          title: "ACTIVE BOOKINGS",
          value: "$active",
          subtitle: "Pending & Accepted",
          badgeText: "Live",
          badgeColor: const Color(0xFF0FA894),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerBookingsScreen(initialFilter: 'PENDING'),
              ),
            );
          },
        ),
        _metricTile(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF059669),
          bgColor: const Color(0xFF059669).withValues(alpha: 0.1),
          title: "COMPLETED JOBS",
          value: "$completed",
          subtitle: "Finished services",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerBookingsScreen(initialFilter: 'COMPLETED'),
              ),
            );
          },
        ),
        _metricTile(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.ink,
          bgColor: AppColors.ink.withValues(alpha: 0.08),
          title: "TOTAL SPENT",
          value: "৳${spent.toStringAsFixed(0)}",
          subtitle: "Completed invoices",
          badgeText: "View",
          badgeColor: AppColors.coral,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentsScreen(userRole: 'CUSTOMER')),
            );
          },
        ),
      ],
    );
  }

  Widget _metricTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
    required String subtitle,
    String? badgeText,
    Color? badgeColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? iconColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: badgeColor ?? iconColor,
                      ),
                    ),
                  )
                else if (onTap != null)
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 ৩. কুইক অ্যাকশন কার্ডস
  Widget _buildQuickActionCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "QUICK ACTIONS",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _actionTile(
                icon: Icons.handyman_rounded,
                title: "Hire Expert",
                subtitle: "Plumbers & AC techs",
                gradient: const [AppColors.coral, Color(0xFFC23B1F)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TechniciansScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionTile(
                icon: Icons.calendar_month_rounded,
                title: "Bookings",
                subtitle: "Manage repairs",
                gradient: const [AppColors.teal, Color(0xFF0B7A6C)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerBookingsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _actionTile(
                icon: Icons.receipt_long_rounded,
                title: "Payments",
                subtitle: "Invoices & receipts",
                gradient: const [Color(0xFF6366F1), Color(0xFF4338CA)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentsScreen(userRole: 'CUSTOMER')),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionTile(
                icon: Icons.person_rounded,
                title: "Profile",
                subtitle: "Account info",
                gradient: const [AppColors.ink, Color(0xFF2A303C)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 ৪. সাম্প্রতিক বুকিং সেকশন
  Widget _buildRecentBookingsSection() {
    final list = _data?.recentBookings ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recent Bookings",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Your latest service requests",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerBookingsScreen()),
                    );
                  },
                  child: const Row(
                    children: [
                      Text(
                        "View All",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.coral,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.coral),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_today_rounded, size: 30, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "No Bookings Yet",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Hire your first technician to fix home repair issues effortlessly.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TechniciansScreen()),
                        );
                      },
                      icon: const Icon(Icons.search_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        "Explore Technicians",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              itemCount: list.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (ctx, idx) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final item = list[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.coral.withValues(alpha: 0.12),
                    child: Text(
                      item.technicianName.isNotEmpty ? item.technicianName[0].toUpperCase() : "T",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.coral),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.technicianName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.ink),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusBg(item.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _getStatusColor(item.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          item.bookingDate ?? 'Upcoming',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        if (item.slot != null) ...[
                          const SizedBox(width: 8),
                          Text("• ${item.slot}", style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                        const Spacer(),
                        Text(
                          "৳${item.price.toStringAsFixed(0)}",
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerBookingsScreen()),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

// ========================================================
// 🌟 কাস্টমার ওভারভিউ শিমার স্কেলেটন (Pure Flutter)
// ========================================================
class _CustomerOverviewSkeleton extends StatefulWidget {
  const _CustomerOverviewSkeleton();

  @override
  State<_CustomerOverviewSkeleton> createState() => _CustomerOverviewSkeletonState();
}

class _CustomerOverviewSkeletonState extends State<_CustomerOverviewSkeleton>
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ১. হিরো ব্যানার স্কেলেটন
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E4E8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                const SizedBox(height: 18),

                // ২. মেট্রিক গ্রিড স্কেলেটন (৪টি কার্ড)
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(4, (index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E4E8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 80,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E4E8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 50,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E4E8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // ৩. সাম্প্রতিক বুকিংস স্কেলেটন
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
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
