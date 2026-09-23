import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/dashboard_data_table.dart';
import '../services/technician_service.dart';

class TechnicianRequestsScreen extends StatefulWidget {
  const TechnicianRequestsScreen({super.key});

  @override
  State<TechnicianRequestsScreen> createState() => _TechnicianRequestsScreenState();
}

class _TechnicianRequestsScreenState extends State<TechnicianRequestsScreen>
    with WidgetsBindingObserver {
  static const String _cacheKey = 'technician_requests_cache';

  List<TechnicianBookingItem> _bookings = [];
  bool _isLoading = true;
  String? _updatingBookingId;

  // Filtering & Pagination State
  int _currentPage = 1;
  int _limit = 10;
  int _totalItems = 0;
  int _totalPages = 1;
  String _searchQuery = '';
  String _selectedStatus = 'ALL';

  final List<String> _statusFilters = ['ALL', 'PENDING', 'ACCEPTED', 'COMPLETED', 'DECLINED', 'CANCELLED'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initRequestsWithCache();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchBookings(isBackground: true);
    }
  }

  // 🌟 Instant Cache Loading (0ms) followed by silent Network Sync
  Future<void> _initRequestsWithCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_cacheKey);

      if (cachedStr != null && cachedStr.isNotEmpty) {
        final data = jsonDecode(cachedStr) as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            _totalItems = data['totalItems'] ?? 0;
            _totalPages = data['totalPages'] ?? 1;

            if (data['bookings'] is List) {
              _bookings = (data['bookings'] as List)
                  .map((item) => TechnicianBookingItem.fromJson(item))
                  .toList();
            }

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Technician Requests Cache Read Error: $e');
    }

    await _fetchBookings(isBackground: !_isLoading);
  }

  Future<void> _fetchBookings({
    int? page,
    int? limit,
    String? search,
    String? status,
    bool isBackground = false,
  }) async {
    if (!isBackground) {
      if (_bookings.isEmpty) {
        setState(() => _isLoading = true);
      }
    }

    if (page != null) _currentPage = page;
    if (limit != null) _limit = limit;
    if (search != null) _searchQuery = search;
    if (status != null) _selectedStatus = status;

    try {
      final res = await TechnicianService.getTechnicianBookings(
        page: _currentPage,
        limit: _limit,
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        search: _searchQuery,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (res.success) {
            _bookings = res.bookings;
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

        // Cache default page 1 unscoped query
        if (_currentPage == 1 && _searchQuery.isEmpty && _selectedStatus == 'ALL') {
          final prefs = await SharedPreferences.getInstance();
          final cacheData = {
            'totalItems': _totalItems,
            'totalPages': _totalPages,
            'bookings': _bookings.map((b) => {
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
          };
          await prefs.setString(_cacheKey, jsonEncode(cacheData));
        }
      }
    } catch (e) {
      debugPrint('Technician Requests Fetch Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌟 Action Handler (Accept, Decline, Complete)
  Future<void> _handleStatusChange(TechnicianBookingItem booking, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _updatingBookingId = booking.id);

    final res = await TechnicianService.updateBookingStatus(
      bookingId: booking.id,
      status: newStatus,
    );

    if (mounted) {
      setState(() => _updatingBookingId = null);

      if (res.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Job status updated to $newStatus'),
            backgroundColor: newStatus == 'ACCEPTED'
                ? const Color(0xFF0FA894)
                : newStatus == 'COMPLETED'
                    ? const Color(0xFF3B82F6)
                    : Colors.redAccent,
          ),
        );

        // Optimistic local update
        final updatedList = _bookings.map((b) {
          if (b.id == booking.id) {
            return b.copyWith(status: newStatus);
          }
          return b;
        }).toList();

        setState(() {
          _bookings = updatedList;
        });

        // Update cache
        final prefs = await SharedPreferences.getInstance();
        final cacheData = {
          'totalItems': _totalItems,
          'totalPages': _totalPages,
          'bookings': updatedList.map((b) => {
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
        };
        await prefs.setString(_cacheKey, jsonEncode(cacheData));

        _fetchBookings(isBackground: true);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: Colors.redAccent),
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
          'Job Requests',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E2026)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE7E2D8), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DashboardDataTable<TechnicianBookingItem>(
          title: 'Job Requests',
          subtitle: 'Manage all customer repair and service bookings in real-time.',
          icon: Icons.assignment_outlined,
          searchHint: 'Search by customer or booking ID...',
          onSearchChanged: (query) => _fetchBookings(search: query, page: 1),
          isLoading: _isLoading,
          items: _bookings,
          currentPage: _currentPage,
          totalPages: _totalPages,
          totalItems: _totalItems,
          limit: _limit,
          onPageChanged: (newPage) => _fetchBookings(page: newPage),
          onLimitChanged: (newLimit) => _fetchBookings(limit: newLimit, page: 1),
          emptyTitle: 'No job requests found',
          emptySubtitle: _selectedStatus == 'ALL'
              ? 'Incoming customer bookings will show up here.'
              : 'No bookings matching the "$_selectedStatus" filter.',
          filterWidget: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((st) {
                final isSelected = _selectedStatus == st;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(st),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _fetchBookings(status: st, page: 1);
                      }
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : const Color(0xFFE7E2D8),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF4A4E58),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }).toList(),
            ),
          ),
          itemBuilder: (context, booking, index) {
            final isUpdating = _updatingBookingId == booking.id;
            final isPending = booking.status.toUpperCase() == 'PENDING';
            final isAccepted = booking.status.toUpperCase() == 'ACCEPTED';
            final isCompleted = booking.status.toUpperCase() == 'COMPLETED';

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar Icon
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0FA894).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_outline, size: 22, color: Color(0xFF0FA894)),
                      ),
                      const SizedBox(width: 12),

                      // Customer details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E2026)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.customerEmail,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B707E)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Status Badge
                      _buildStatusPill(booking.status),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Booking Details Grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE7E2D8)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF6B707E)),
                            const SizedBox(width: 6),
                            Text(
                              'Date: ${booking.serviceDate ?? booking.bookingDate ?? 'N/A'}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E2026)),
                            ),
                            if (booking.slot != null && booking.slot!.isNotEmpty) ...[
                              const Spacer(),
                              const Icon(Icons.access_time, size: 14, color: Color(0xFF6B707E)),
                              const SizedBox(width: 4),
                              Text(booking.slot!, style: const TextStyle(fontSize: 11.5, color: Color(0xFF4A4E58))),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fee: ৳${booking.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0FA894)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: booking.paymentStatus?.toUpperCase() == 'PAID'
                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                booking.paymentStatus?.toUpperCase() == 'PAID' ? 'PAID' : 'UNPAID',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: booking.paymentStatus?.toUpperCase() == 'PAID' ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions Section
                  if (isPending || isAccepted || isCompleted) ...[
                    const SizedBox(height: 12),
                    if (isUpdating)
                      const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    else if (isPending)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleStatusChange(booking, 'ACCEPTED'),
                              icon: const Icon(Icons.check, size: 16, color: Colors.white),
                              label: const Text('Accept Job', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0FA894),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _handleStatusChange(booking, 'DECLINED'),
                              icon: const Icon(Icons.close, size: 16, color: Color(0xFFE11D48)),
                              label: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFECDD3)),
                                backgroundColor: const Color(0xFFFFF1F2),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (isAccepted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleStatusChange(booking, 'COMPLETED'),
                          icon: const Icon(Icons.done_all, size: 16, color: Colors.white),
                          label: const Text('Mark Job as Completed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      )
                    else if (isCompleted)
                      Row(
                        children: const [
                          Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                          SizedBox(width: 6),
                          Text('Completed & Delivered', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                        ],
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }
}
