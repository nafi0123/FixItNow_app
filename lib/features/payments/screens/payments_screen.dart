import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentsScreen extends StatefulWidget {
  final String userRole; // "CUSTOMER", "TECHNICIAN", "ADMIN"

  const PaymentsScreen({
    super.key,
    this.userRole = "CUSTOMER",
  });

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<PaymentItem> _payments = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = "ALL";

  final List<String> _filterTabs = ["ALL", "PAID", "PENDING", "FAILED"];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🌟 ক্যাশ-ফার্স্ট ডেটা লোডিং
  Future<void> _loadPayments({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await PaymentService.getAllPayments(
        userRole: widget.userRole,
        forceRefresh: false,
      );
      if (cached.isNotEmpty && mounted) {
        setState(() {
          _payments = cached;
          _isLoading = false;
        });
      }
    } else {
      if (_payments.isEmpty) {
        setState(() => _isLoading = true);
      } else {
        setState(() => _isSyncing = true);
      }
    }

    final fresh = await PaymentService.getAllPayments(
      userRole: widget.userRole,
      forceRefresh: true,
    );

    if (mounted) {
      setState(() {
        _payments = fresh;
        _isLoading = false;
        _isSyncing = false;
      });
    }
  }

  // 🌟 ফিল্টার ও সার্চ লজিক
  List<PaymentItem> get _filteredPayments {
    return _payments.where((item) {
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          item.transactionId.toLowerCase().contains(query) ||
          item.customerName.toLowerCase().contains(query) ||
          item.technicianName.toLowerCase().contains(query);

      final matchesStatus = _statusFilter == "ALL" || item.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // 🌟 স্ট্যাটাস ব্যাজ কালার হেল্পার
  Color _getStatusBg(String status) {
    switch (status) {
      case 'PAID':
        return const Color(0xFFECFDF5);
      case 'PENDING':
        return const Color(0xFFFFFBEB);
      case 'FAILED':
        return const Color(0xFFFFF1F2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PAID':
        return const Color(0xFF059669);
      case 'PENDING':
        return const Color(0xFFD97706);
      case 'FAILED':
        return const Color(0xFFE11D48);
      default:
        return const Color(0xFF4B5563);
    }
  }

  // 🌟 ইনভয়েস রিসিট বটম শিট (ওয়েবের মতো হুবহু ব্রেকডাউন)
  void _showInvoiceDetailsSheet(PaymentItem item) {
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

              // ইনভয়েস হেডার
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Payment Receipt",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.transactionId,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
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

              // ডিটেইলস রো
              _receiptRow("Customer Name", item.customerName),
              _receiptRow("Customer Email", item.customerEmail),
              _receiptRow("Technician Name", item.technicianName),
              _receiptRow("Technician Email", item.technicianEmail),
              if (item.bookingDate != null)
                _receiptRow("Booking Date", item.bookingDate!),
              if (item.slot != null)
                _receiptRow("Service Slot", item.slot!),
              _receiptRow("Payment Method", "Online Gateway (SSLCommerz)"),
              _receiptRow("Date & Time", item.createdAt.length >= 10 ? item.createdAt.substring(0, 10) : item.createdAt),

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 14),

              // টোটাল অ্যামাউন্ট
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Paid Amount",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                  Text(
                    "৳${item.amount.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.coral,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Close Receipt", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPayments;
    final totalSpent = _payments
        .where((p) => p.status == 'PAID')
        .fold<double>(0.0, (sum, p) => sum + p.amount);

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
              "Payments",
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.userRole,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
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
            tooltip: "Refresh Payments",
            icon: Icon(Icons.refresh_rounded, color: _isSyncing ? AppColors.coral : AppColors.ink, size: 20),
            onPressed: () => _loadPayments(forceRefresh: true),
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
          // ১. সামারি কার্ড
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF3),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7E2D8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TOTAL TRANSACTIONS",
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${_payments.length}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.userRole == "TECHNICIAN" ? "TOTAL EARNED" : "TOTAL AMOUNT PAID",
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "৳${totalSpent.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.coral,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ২. সার্চ ফিল্ড
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search by transaction ID, customer or tech…",
                hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
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

          // ৩. ফিল্টার চিপস
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterTabs.map((tab) {
                  final isSelected = _statusFilter == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        tab == "ALL" ? "All" : tab,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.ink,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.ink,
                      backgroundColor: const Color(0xFFF3F4F6),
                      side: BorderSide(
                        color: isSelected ? AppColors.ink : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _statusFilter = tab);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // ৪. পেমেন্ট লিস্ট
          Expanded(
            child: _isLoading && _payments.isEmpty
                ? const _PaymentsSkeleton()
                : RefreshIndicator(
                    color: AppColors.coral,
                    onRefresh: () => _loadPayments(forceRefresh: true),
                    child: filtered.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _buildPaymentCard(item);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

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
              child: const Icon(Icons.receipt_long_rounded, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              "No Transactions Found",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            const Text(
              "No payment records matching your filter were found.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_rounded, size: 16, color: AppColors.coral),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.transactionId,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: _getStatusBg(item.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _getStatusColor(item.status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userRole == "TECHNICIAN" ? "Customer" : "Technician",
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.userRole == "TECHNICIAN" ? item.customerName : item.technicianName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Amount",
                    style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "৳${item.amount.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.coral,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    item.createdAt.length >= 10 ? item.createdAt.substring(0, 10) : item.createdAt,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showInvoiceDetailsSheet(item),
                child: const Row(
                  children: [
                    Text(
                      "View Receipt",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.ink),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================================================
// 🌟 পেমেন্টস স্ক্রিন শিমার স্কেলেটন (Pure Flutter)
// ========================================================
class _PaymentsSkeleton extends StatefulWidget {
  const _PaymentsSkeleton();

  @override
  State<_PaymentsSkeleton> createState() => _PaymentsSkeletonState();
}

class _PaymentsSkeletonState extends State<_PaymentsSkeleton>
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
                height: 130,
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
