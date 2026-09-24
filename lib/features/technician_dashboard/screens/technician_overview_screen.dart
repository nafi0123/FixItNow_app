import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/technician_service.dart';
import 'technician_requests_screen.dart';
import 'technician_services_screen.dart';
import 'technician_profile_screen.dart';
import '../../payments/screens/payments_screen.dart';

class TechnicianOverviewScreen extends StatefulWidget {
  const TechnicianOverviewScreen({super.key});

  @override
  State<TechnicianOverviewScreen> createState() => _TechnicianOverviewScreenState();
}

class _TechnicianOverviewScreenState extends State<TechnicianOverviewScreen>
    with WidgetsBindingObserver {
  static const String _cacheKey = 'technician_overview_cache';

  bool _isLoading = true;
  bool _isSyncing = false;
  UserModel? _techUser;

  int _totalBookings = 0;
  int _pendingRequests = 0;
  int _acceptedBookings = 0;
  int _completedJobs = 0;
  double _totalEarnings = 0.0;
  bool _isAvailable = true;

  List<TechnicianBookingItem> _recentBookings = [];

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
      _loadOverviewData(isBackground: true);
    }
  }

  // 🌟 0ms Instant Cache Loading followed by Silent Network Sync
  Future<void> _initOverviewWithCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_cacheKey);

      if (cachedStr != null && cachedStr.isNotEmpty) {
        final data = jsonDecode(cachedStr) as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            _totalBookings = data['totalBookings'] ?? 0;
            _pendingRequests = data['pendingRequests'] ?? 0;
            _acceptedBookings = data['acceptedBookings'] ?? 0;
            _completedJobs = data['completedJobs'] ?? 0;
            _totalEarnings = (data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
            _isAvailable = data['isAvailable'] ?? true;

            if (data['recentBookings'] is List) {
              _recentBookings = (data['recentBookings'] as List)
                  .map((item) => TechnicianBookingItem.fromJson(item))
                  .toList();
            }

            if (data['techUser'] != null) {
              _techUser = UserModel.fromJson(data['techUser']);
            }

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Technician Overview Cache Read Error: $e');
    }

    await _loadOverviewData(isBackground: !_isLoading);
  }

  Future<void> _loadOverviewData({bool isBackground = false}) async {
    if (!isBackground) {
      if (mounted) setState(() => _isLoading = true);
    } else {
      if (mounted) setState(() => _isSyncing = true);
    }

    try {
      final user = await AuthService.getUser(forceRefresh: true);
      final bookingsRes = await TechnicianService.getTechnicianBookings(page: 1, limit: 10);

      if (bookingsRes.success) {
        final all = bookingsRes.bookings;
        final pending = all.where((b) => b.status.toUpperCase() == 'PENDING').length;
        final accepted = all.where((b) => b.status.toUpperCase() == 'ACCEPTED').length;
        final completed = all.where((b) => b.status.toUpperCase() == 'COMPLETED').length;
        final earnings = all
            .where((b) => b.status.toUpperCase() == 'COMPLETED')
            .fold<double>(0.0, (sum, b) => sum + b.price);

        bool isAvail = true;
        if (user?.technicianProfile != null && user!.technicianProfile!['isAvailable'] != null) {
          isAvail = user.technicianProfile!['isAvailable'] == true;
        }

        if (mounted) {
          setState(() {
            _techUser = user;
            _totalBookings = bookingsRes.meta.total;
            _pendingRequests = pending;
            _acceptedBookings = accepted;
            _completedJobs = completed;
            _totalEarnings = earnings;
            _isAvailable = isAvail;
            _recentBookings = all.take(5).toList();
            _isLoading = false;
            _isSyncing = false;
          });
        }

        // Cache the latest snapshot
        final prefs = await SharedPreferences.getInstance();
        final cacheData = {
          'totalBookings': _totalBookings,
          'pendingRequests': _pendingRequests,
          'acceptedBookings': _acceptedBookings,
          'completedJobs': _completedJobs,
          'totalEarnings': _totalEarnings,
          'isAvailable': _isAvailable,
          'recentBookings': _recentBookings.map((b) => {
            'id': b.id,
            'serviceId': b.serviceId,
            'status': b.status,
            'paymentStatus': b.paymentStatus,
            'bookingDate': b.bookingDate,
            'serviceDate': b.serviceDate,
            'slot': b.slot,
            'price': b.price,
            'customerName': b.customerName,
            'customerEmail': b.customerEmail,
            'createdAt': b.createdAt,
          }).toList(),
          if (_techUser != null) 'techUser': _techUser!.toJson(),
          'cachedAt': DateTime.now().toIso8601String(),
        };
        await prefs.setString(_cacheKey, jsonEncode(cacheData));
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSyncing = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading technician overview: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSyncing = false;
        });
      }
    }
  }

  // 🌟 Live Toggle Availability
  Future<void> _toggleAvailability(bool newValue) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isAvailable = newValue);

    final res = await TechnicianService.updateAvailability(isAvailable: newValue);

    if (!mounted) return;
    if (res.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(newValue ? '🟢 You are now AVAILABLE for jobs' : '🔴 You are now OFFLINE / BUSY'),
          backgroundColor: newValue ? const Color(0xFF0FA894) : const Color(0xFF14171C),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadOverviewData(isBackground: true);
    } else {
      setState(() => _isAvailable = !newValue);
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // 🌟 Quick Accept / Decline
  Future<void> _handleAction(String bookingId, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await TechnicianService.updateBookingStatus(bookingId: bookingId, status: newStatus);

    if (!mounted) return;
    if (res.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Booking marked as $newStatus'),
          backgroundColor: newStatus == 'ACCEPTED' ? const Color(0xFF0FA894) : Colors.redAccent,
        ),
      );
      _loadOverviewData(isBackground: true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text(
          'Technician Dashboard',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF14171C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF14171C)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE7E2D8), height: 1),
        ),
        actions: [
          if (_isSyncing)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadOverviewData(isBackground: false),
            tooltip: 'Refresh Overview',
          ),
        ],
      ),
      body: _isLoading
          ? _buildOverviewSkeleton()
          : RefreshIndicator(
              onRefresh: () => _loadOverviewData(isBackground: false),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroBanner(),
                    const SizedBox(height: 20),

                    // 🌟 Performance KPI Grid
                    const Text(
                      'Performance Metrics',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF14171C)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'New Requests',
                            count: '$_pendingRequests',
                            subtitle: 'Pending confirmation',
                            icon: Icons.notifications_active_outlined,
                            iconColor: const Color(0xFFFF5A36),
                            bgColor: const Color(0xFFFF5A36).withValues(alpha: 0.12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Active Jobs',
                            count: '$_acceptedBookings',
                            subtitle: 'Accepted & in-progress',
                            icon: Icons.engineering_outlined,
                            iconColor: const Color(0xFF0FA894),
                            bgColor: const Color(0xFF0FA894).withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Completed',
                            count: '$_completedJobs',
                            subtitle: 'Successfully finished',
                            icon: Icons.check_circle_outline,
                            iconColor: const Color(0xFF3B82F6),
                            bgColor: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Earnings',
                            count: '৳${_totalEarnings.toStringAsFixed(0)}',
                            subtitle: 'Total completed value',
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: const Color(0xFF10B981),
                            bgColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 🌟 Quick Navigation Actions
                    const Text(
                      'Technician Features',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF14171C)),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickAction(
                      icon: Icons.assignment_outlined,
                      iconColor: const Color(0xFFFF5A36),
                      title: 'Manage Job Requests',
                      subtitle: 'Accept, decline or complete customer job bookings',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TechnicianRequestsScreen()),
                        );
                        _loadOverviewData(isBackground: true);
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildQuickAction(
                      icon: Icons.build_circle_outlined,
                      iconColor: const Color(0xFF0FA894),
                      title: 'My Services & Rates',
                      subtitle: 'Add, update or remove services you offer',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TechnicianServicesScreen()),
                        );
                        _loadOverviewData(isBackground: true);
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildQuickAction(
                      icon: Icons.person_pin_outlined,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Technician Profile & Schedule',
                      subtitle: 'Update hourly rate, working hours and skills',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TechnicianProfileScreen()),
                        );
                        _loadOverviewData(isBackground: true);
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildQuickAction(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: const Color(0xFF10B981),
                      title: 'Payments & Earnings',
                      subtitle: 'Track platform payments, customer invoices and receipts',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PaymentsScreen(userRole: "TECHNICIAN")),
                        );
                        _loadOverviewData(isBackground: true);
                      },
                    ),
                    const SizedBox(height: 24),

                    // 🌟 Recent Booking Requests
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Job Requests',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF14171C)),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TechnicianRequestsScreen()),
                            );
                            _loadOverviewData(isBackground: true);
                          },
                          child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_recentBookings.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE7E2D8)),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.inbox_outlined, size: 40, color: Color(0xFF9AA0AA)),
                            SizedBox(height: 8),
                            Text('No job requests yet', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
                            SizedBox(height: 4),
                            Text('New customer requests will appear here in real-time.', style: TextStyle(fontSize: 12, color: Color(0xFF6B707E))),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentBookings.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final b = _recentBookings[index];
                          final isPending = b.status.toUpperCase() == 'PENDING';
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE7E2D8)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        b.customerName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E2026)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _buildStatusBadge(b.status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF6B707E)),
                                    const SizedBox(width: 4),
                                    Text(
                                      b.serviceDate ?? b.bookingDate ?? 'Upcoming',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B707E)),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '৳${b.price.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0FA894)),
                                    ),
                                  ],
                                ),
                                if (isPending) ...[
                                  const SizedBox(height: 10),
                                  const Divider(height: 1, color: Color(0xFFE7E2D8)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _handleAction(b.id, 'ACCEPTED'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0FA894),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('Accept Job', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _handleAction(b.id, 'DECLINED'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            side: const BorderSide(color: Colors.redAccent),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  // 🌟 Hero Banner with Live Availability Switch
  Widget _buildHeroBanner() {
    final name = _techUser?.name ?? 'Technician';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14171C), Color(0xFF232832)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF0FA894),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'T',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $name 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Manage your jobs and service schedule',
                      style: TextStyle(color: Color(0xFF9AA0AA), fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isAvailable ? const Color(0xFF0FA894) : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isAvailable ? 'Availability: Online & Active' : 'Availability: Offline / Busy',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Switch(
                  value: _isAvailable,
                  onChanged: _toggleAvailability,
                  activeThumbColor: const Color(0xFF0FA894),
                  activeTrackColor: const Color(0xFF0FA894).withValues(alpha: 0.4),
                  inactiveThumbColor: Colors.white70,
                  inactiveTrackColor: Colors.white24,
                ),
              ],
            ),
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
              Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E2026))),
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

  // 🌟 Status Badge
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        bg = const Color(0xFF0FA894).withValues(alpha: 0.12);
        text = const Color(0xFF0FA894);
        break;
      case 'COMPLETED':
        bg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        text = const Color(0xFF3B82F6);
        break;
      case 'DECLINED':
      case 'CANCELLED':
        bg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        text = const Color(0xFFEF4444);
        break;
      case 'PENDING':
      default:
        bg = AppColors.primary.withValues(alpha: 0.12);
        text = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text)),
    );
  }

  // 🌟 Shimmer Skeleton Loader
  Widget _buildOverviewSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E4E8),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 150,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E4E8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
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
          Container(
            width: 130,
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
