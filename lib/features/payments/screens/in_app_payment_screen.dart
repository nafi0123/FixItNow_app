import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/url_helper.dart';
import '../../customer_dashboard/services/customer_service.dart';

class InAppPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String bookingId;
  final double amount;
  final String technicianName;

  const InAppPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.bookingId,
    required this.amount,
    required this.technicianName,
  });

  @override
  State<InAppPaymentScreen> createState() => _InAppPaymentScreenState();
}

class _InAppPaymentScreenState extends State<InAppPaymentScreen>
    with SingleTickerProviderStateMixin {
  // Mobile WebView Controller
  WebViewController? _webViewController;
  int _loadingProgress = 0;
  bool _isLoadingPage = true;

  // Web Hub State
  Timer? _statusPollingTimer;
  bool _isVerifying = false;
  bool _isSuccess = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (!kIsWeb) {
      // 📱 মোবাইল প্ল্যাটফর্ম (Android / iOS): ফুল ইন-অ্যাপ নেটিভ ওয়েবভিউ ইনিশিয়ালাইজেশন
      _initMobileWebView();
    } else {
      // 💻 ওয়েব প্ল্যাটফর্ম (Localhost / Browser Testing): অটো-পোলিং টাইমার
      _statusPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _checkPaymentStatus(silent: true);
      });
    }
  }

  void _initMobileWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoadingPage = true);
            _checkUrlInterception(url);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoadingPage = false);
            _checkUrlInterception(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkUrlInterception(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  // 🌟 URL ইন্টারসেপ্টর: মোবাইল ইন-অ্যাপ গেটওয়ের রিডাইরেক্ট ক্যাচ করা
  bool _checkUrlInterception(String url) {
    if (_isSuccess) return true;
    final lower = url.toLowerCase();

    // পেমেন্ট সাকসেস বা ভ্যালিডেশন পেজে আসলে ইন্টারসেপ্ট করে সাকসেস স্ক্রিনে নিয়ে যাওয়া
    if (lower.contains('/api/payments/confirm') ||
        lower.contains('status=success') ||
        lower.contains('status=valid')) {
      _handlePaymentSuccess();
      return true;
    }

    // পেমেন্ট ফেইল বা ক্যানসেল হলে
    if (lower.contains('status=fail') || lower.contains('status=cancel')) {
      _handlePaymentFailed();
      return true;
    }

    return false;
  }

  void _handlePaymentSuccess() {
    if (_isSuccess) return;
    _isSuccess = true;
    _statusPollingTimer?.cancel();

    if (mounted) {
      _showPaymentSuccessDialog();
    }
  }

  void _handlePaymentFailed() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment was cancelled or failed. You can try again."),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      Navigator.pop(context, false);
    }
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // 🌟 স্ট্যাটাস চেক (ওয়েব এবং ম্যানুয়াল বাটন উভয়ের জন্য)
  Future<void> _checkPaymentStatus({bool silent = false}) async {
    if (_isSuccess) return;
    if (!silent) setState(() => _isVerifying = true);

    try {
      final booking = await CustomerService.getBookingDetails(widget.bookingId);
      if (booking != null && booking.paymentStatus.toUpperCase() == 'PAID') {
        _handlePaymentSuccess();
        return;
      }
    } catch (_) {}

    if (mounted && !silent) {
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment not confirmed yet. Complete it on SSLCommerz, then verify."),
          backgroundColor: Color(0xFFD97706),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF0FA894),
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Payment Successful!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "৳${widget.amount.toStringAsFixed(0)} paid successfully for service with ${widget.technicianName}.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dlgCtx);
                  Navigator.pop(context, true); // Return true to trigger reload
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0FA894),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "View Bookings",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.ink),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text("Exit Payment?", style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text("If you haven't completed payment, you can pay later from My Bookings."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Continue Paying"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context, false);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
                    child: const Text("Exit", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0FA894).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF0FA894)),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SSLCommerz Checkout",
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.ink),
                  ),
                  Text(
                    "100% Encrypted & Secure Payment",
                    style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Check Status",
            icon: _isVerifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.ink),
            onPressed: () => _checkPaymentStatus(silent: false),
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Column(
            children: [
              if (!kIsWeb && _isLoadingPage)
                LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress / 100 : null,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0FA894)),
                  minHeight: 2,
                )
              else
                Container(color: AppColors.border, height: 1),
            ],
          ),
        ),
      ),
      body: kIsWeb ? _buildWebTestingHub() : _buildMobileNativeWebView(),
    );
  }

  // ========================================================
  // 📱 ১. মোবাইল প্ল্যাটফর্ম: ১০০% ইন-অ্যাপ নেটিভ ওয়েবভিউ
  // ========================================================
  Widget _buildMobileNativeWebView() {
    if (_webViewController == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0FA894)));
    }
    return WebViewWidget(controller: _webViewController!);
  }

  // ========================================================
  // 💻 ২. ওয়েব প্ল্যাটফর্ম: লোকালহোস্ট ব্রাউজার টেস্টিং হাব
  // ========================================================
  Widget _buildWebTestingHub() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // অ্যানিমেটেড সিকিউরিটি ব্যাজ
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0FA894).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0FA894).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.payment_rounded,
                        size: 38,
                        color: Color(0xFF0FA894),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              const Text(
                "Payment Session In Progress",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Complete your payment on SSLCommerz using bKash, Nagad, or Card. We'll automatically detect your payment.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
              ),

              const SizedBox(height: 24),

              // সামারি কার্ড
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Payable Amount", style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        Text(
                          "৳${widget.amount.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0FA894),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Technician", style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
                        Text(
                          widget.technicianName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Gateway", style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
                        const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF059669)),
                            SizedBox(width: 4),
                            Text(
                              "SSLCommerz Sandbox",
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // পেমেন্ট পেজ ওপেন করার প্রধান বাটন
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => openUrlUniversal(widget.paymentUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    "Open SSLCommerz Gateway Tab",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0FA894),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ম্যানুয়াল ভেরিফিকেশন বাটন
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isVerifying ? null : () => _checkPaymentStatus(silent: false),
                  icon: _isVerifying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0FA894)),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF0FA894)),
                  label: Text(
                    _isVerifying ? "Verifying..." : "I've Paid — Check Status",
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0FA894),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: Color(0xFF0FA894)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // লাইভ অটো-ডিটেকশন স্ট্যাটাস বার
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Auto-checking every 3s. Status updates automatically.",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
