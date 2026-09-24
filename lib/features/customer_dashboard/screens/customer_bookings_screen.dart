import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../admin/services/admin_service.dart' show PaginationMeta;
import '../../technicians/screens/technicians_screen.dart';
import '../services/customer_service.dart';
import '../../payments/services/payment_service.dart';
import '../../payments/screens/in_app_payment_screen.dart';
import '../../../core/utils/url_helper.dart';

class CustomerBookingsScreen extends StatefulWidget {
  final String? initialFilter;
  const CustomerBookingsScreen({super.key, this.initialFilter});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  List<CustomerBookingItem> _bookings = [];
  PaginationMeta _meta = PaginationMeta(page: 1, limit: 10, total: 0, totalPage: 1);
  bool _isLoading = true;
  bool _isSyncing = false;

  String _statusFilter = "ALL";
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  String? _payingBookingId;

  final List<String> _filterTabs = ["ALL", "PENDING", "ACCEPTED", "COMPLETED", "DECLINED"];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null && _filterTabs.contains(widget.initialFilter)) {
      _statusFilter = widget.initialFilter!;
    }
    _loadBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🌟 ক্যাশ-ফার্স্ট ডেটা লোডিং
  Future<void> _loadBookings({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentPage == 1 && _searchController.text.isEmpty && _statusFilter == 'ALL') {
      final (cachedList, cachedMeta) = await CustomerService.getCustomerBookings(
        page: 1,
        limit: 10,
        forceRefresh: false,
      );
      if (cachedList.isNotEmpty && mounted) {
        setState(() {
          _bookings = cachedList;
          _meta = cachedMeta;
          _isLoading = false;
        });
      }
    } else {
      if (_bookings.isEmpty) {
        setState(() => _isLoading = true);
      } else {
        setState(() => _isSyncing = true);
      }
    }

    final (freshList, freshMeta) = await CustomerService.getCustomerBookings(
      page: _currentPage,
      limit: 10,
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      status: _statusFilter != "ALL" ? _statusFilter : null,
      forceRefresh: true,
    );

    if (mounted) {
      setState(() {
        _bookings = freshList;
        _meta = freshMeta;
        _isLoading = false;
        _isSyncing = false;
      });
    }
  }

  // 🌟 স্ট্যাটাস কালার হেল্পার
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


  // 🌟 পেমেন্ট সম্পন্ন করার লজিক (SSLCommerz সেশন ও ব্রাউজার গেটওয়ে ওপেন)
  Future<void> _handlePayNow(CustomerBookingItem booking) async {
    if (booking.status != 'ACCEPTED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment is only available once technician accepts the request."),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    if (booking.paymentStatus == 'PAID') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This booking is already paid!"),
          backgroundColor: Color(0xFF059669),
        ),
      );
      return;
    }

    setState(() => _payingBookingId = booking.id);

    try {
      final currentOrigin = kIsWeb ? Uri.base.toString() : null;

      final res = await PaymentService.initiatePayment(
        bookingId: booking.id,
        redirectUrl: currentOrigin,
      );

      if (res.success && res.paymentUrl != null) {
        if (!mounted) return;
        setState(() => _payingBookingId = null);

        if (kIsWeb) {
          // 💻 ওয়েবে টেস্টিং: কোনো নতুন ট্যাব খুলবে না! সেম ট্যাবে সরাসরি রিডাইরেক্ট (Next.js-এর মতো)
          openUrlUniversal(res.paymentUrl!, newTab: false);
        } else {
          // 📱 মোবাইলে: ১০০% ইন-অ্যাপ নেটিভ ফুল স্ক্রিন (কোনো ব্রাউজার বা ট্যাব নয়)
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => InAppPaymentScreen(
                paymentUrl: res.paymentUrl!,
                bookingId: booking.id,
                amount: booking.price,
                technicianName: booking.technicianName,
              ),
            ),
          );

          if (mounted) {
            _loadBookings(forceRefresh: true);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message),
              backgroundColor: const Color(0xFFE11D48),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment error: $e"),
            backgroundColor: const Color(0xFFE11D48),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _payingBookingId = null);
      }
    }
  }

  // 🌟 বুকিং ডিটেইলস বটম শিট
  void _showBookingDetailsSheet(CustomerBookingItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Booking Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusBg(item.status),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _getStatusColor(item.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 14),

              // টেকনিশিয়ান তথ্য
              _detailRow(Icons.person_outline_rounded, "Technician", item.technicianName),
              _detailRow(Icons.email_outlined, "Technician Email", item.technicianEmail),
              if (item.technicianLocation != null)
                _detailRow(Icons.location_on_outlined, "Service Location", item.technicianLocation!),
              if (item.technicianPhone != null)
                _detailRow(Icons.phone_outlined, "Phone", item.technicianPhone!),
              _detailRow(Icons.calendar_month_outlined, "Service Date", item.bookingDate ?? "Not Scheduled"),
              if (item.slot != null)
                _detailRow(Icons.access_time_rounded, "Time Slot", item.slot!),
              _detailRow(Icons.receipt_outlined, "Total Price", "৳${item.price.toStringAsFixed(0)}"),
              _detailRow(
                Icons.payment_outlined,
                "Payment Status",
                item.paymentStatus,
                valueColor: item.paymentStatus == "PAID" ? const Color(0xFF059669) : const Color(0xFFD97706),
              ),
              _detailRow(Icons.tag_rounded, "Booking ID", item.id),

              const SizedBox(height: 16),

              // ১. পেমেন্ট অ্যাকশন ও স্ট্যাটাস ইনফো
              if (item.status == 'ACCEPTED' && item.paymentStatus != 'PAID') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _payingBookingId == item.id
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _handlePayNow(item);
                          },
                    icon: _payingBookingId == item.id
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.credit_card_rounded, color: Colors.white, size: 18),
                    label: Text(
                      _payingBookingId == item.id
                          ? "Connecting Gateway..."
                          : "Pay ৳${item.price.toStringAsFixed(0)} Now",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0FA894),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ] else if (item.paymentStatus == 'PAID') ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF059669)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Payment completed successfully via SSLCommerz gateway.",
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF065F46), fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (item.status == 'PENDING') ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Technician must accept your booking request before payment can be made.",
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (item.status == 'DECLINED') ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFE11D48)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "This booking was declined by the technician. Payment is unavailable.",
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF9F1239), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // রিভিউ বাটন যদি সার্ভিস সম্পন্ন হয়ে থাকে
              if (item.status == 'COMPLETED') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showReviewDialog(item);
                    },
                    icon: const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      "Leave a Review",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 রিভিউ জমা দেওয়ার ইন্টারঅ্যাক্টিভ ডায়ালগ
  void _showReviewDialog(CustomerBookingItem booking) {
    int rating = 5;
    final commentCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.star_rounded, color: AppColors.coral, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Rate Technician",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How was your experience with ${booking.technicianName}?",
                      style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                    ),
                    const SizedBox(height: 16),

                    // ৫-স্টার সিলেকশন
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (idx) {
                          final star = idx + 1;
                          return IconButton(
                            iconSize: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            icon: Icon(
                              star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: star <= rating ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                            ),
                            onPressed: () {
                              setDialogState(() => rating = star);
                            },
                          );
                        }),
                      ),
                    ),
                    Center(
                      child: Text(
                        rating == 5
                            ? "Excellent Service!"
                            : rating == 4
                                ? "Very Good!"
                                : rating == 3
                                    ? "Average"
                                    : "Needs Improvement",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text(
                      "Write your review (Optional)",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Share what you liked or any recommendations…",
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.coral),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          final res = await CustomerService.createReview(
                            bookingId: booking.id,
                            technicianProfileId: booking.technicianProfileId,
                            rating: rating,
                            comment: commentCtrl.text.trim(),
                          );

                          if (!dialogCtx.mounted) return;
                          Navigator.pop(dialogCtx);

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: res.success ? const Color(0xFF059669) : const Color(0xFFE11D48),
                              content: Text(res.message),
                            ),
                          );
                          if (res.success) {
                            _loadBookings(forceRefresh: true);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Submit Review", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              "My Bookings (${_meta.total})",
              style: const TextStyle(
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
            tooltip: "Refresh Bookings",
            icon: Icon(Icons.refresh_rounded, color: _isSyncing ? AppColors.coral : AppColors.ink, size: 20),
            onPressed: () => _loadBookings(forceRefresh: true),
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // ১. সার্চ ফিল্ড
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) {
                setState(() => _currentPage = 1);
                _loadBookings(forceRefresh: true);
              },
              decoration: InputDecoration(
                hintText: "Search bookings by technician or id…",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _currentPage = 1);
                          _loadBookings(forceRefresh: true);
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.coral),
                ),
              ),
            ),
          ),

          // ২. ফিল্টার ট্যাব বার (ALL, PENDING, ACCEPTED, COMPLETED, DECLINED)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterTabs.map((tab) {
                  final isSelected = _statusFilter == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        tab == "ALL" ? "All Bookings" : tab,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.ink,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.coral,
                      backgroundColor: const Color(0xFFF3F4F6),
                      side: BorderSide(
                        color: isSelected ? AppColors.coral : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _statusFilter = tab;
                            _currentPage = 1;
                          });
                          _loadBookings(forceRefresh: true);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // ৩. বুকিং লিস্ট
          Expanded(
            child: _isLoading && _bookings.isEmpty
                ? const _CustomerBookingsSkeleton()
                : RefreshIndicator(
                    color: AppColors.coral,
                    onRefresh: () => _loadBookings(forceRefresh: true),
                    child: _bookings.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _bookings.length,
                            separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _bookings[index];
                              return _buildBookingCard(item);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // 🌟 এম্পটি স্টেট
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_rounded, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              _statusFilter == "ALL" ? "No Bookings Found" : "No $_statusFilter Bookings",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            const Text(
              "You don't have any appointments in this category right now.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TechniciansScreen()),
                );
              },
              icon: const Icon(Icons.search_rounded, color: Colors.white, size: 16),
              label: const Text("Hire a Technician", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 সিঙ্গেল বুকিং কার্ড
  Widget _buildBookingCard(CustomerBookingItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // হেডার: টেকনিশিয়ান নাম ও স্ট্যাটাস ব্যাজ
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.coral.withValues(alpha: 0.12),
                child: Text(
                  item.technicianName.isNotEmpty ? item.technicianName[0].toUpperCase() : "T",
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.coral, fontSize: 15),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.technicianName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.technicianLocation ?? "On-demand repair",
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: _getStatusBg(item.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: _getStatusColor(item.status),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.paymentStatus == 'PAID'
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: item.paymentStatus == 'PAID'
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.paymentStatus == 'PAID'
                              ? Icons.check_circle_rounded
                              : Icons.hourglass_top_rounded,
                          size: 10,
                          color: item.paymentStatus == 'PAID'
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          item.paymentStatus == 'PAID' ? 'PAID' : 'UNPAID',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: item.paymentStatus == 'PAID'
                                ? const Color(0xFF059669)
                                : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // ডিটেইলস গ্রিড
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      item.bookingDate ?? "Flexible Date",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              if (item.slot != null)
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      item.slot!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ফুটার: প্রাইস ও বাটনস
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Estimated Cost", style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  Text(
                    "৳${item.price.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink),
                  ),
                ],
              ),
              Row(
                children: [
                  // ১. Pay Now Button (যদি ACCEPTED এবং UNPAID থাকে)
                  if (item.status == 'ACCEPTED' && item.paymentStatus != 'PAID') ...[
                    ElevatedButton.icon(
                      onPressed: _payingBookingId == item.id ? null : () => _handlePayNow(item),
                      icon: _payingBookingId == item.id
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.credit_card_rounded, size: 14, color: Colors.white),
                      label: Text(
                        _payingBookingId == item.id ? "Connecting..." : "Pay ৳${item.price.toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0FA894),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // ২. রিভিউ বাটন বা রিভিউড স্ট্যাটাস (যদি COMPLETED থাকে)
                  if (item.status == 'COMPLETED') ...[
                    if (item.review != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                            const SizedBox(width: 3),
                            Text(
                              "Reviewed (${item.review?['rating'] ?? 5}★)",
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: () => _showReviewDialog(item),
                        icon: const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                        label: const Text(
                          "Review",
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],

                  OutlinedButton.icon(
                    onPressed: () => _showBookingDetailsSheet(item),
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text("Details", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================================================
// 🌟 বুকিং স্ক্রিন শিমার স্কেলেটন (Pure Flutter)
// ========================================================
class _CustomerBookingsSkeleton extends StatefulWidget {
  const _CustomerBookingsSkeleton();

  @override
  State<_CustomerBookingsSkeleton> createState() => _CustomerBookingsSkeletonState();
}

class _CustomerBookingsSkeletonState extends State<_CustomerBookingsSkeleton>
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
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) {
              return Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
