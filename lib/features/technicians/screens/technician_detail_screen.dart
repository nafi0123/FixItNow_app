import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../customer_dashboard/services/customer_service.dart';
import '../../customer_dashboard/screens/customer_bookings_screen.dart';

// ==========================================
// 🌟 টেকনিশিয়ান ডিটেইল মডেল
// ==========================================
class TechnicianDetailModel {
  final String id;
  final String name;
  final String email;
  final String bio;
  final List<String> skills;
  final int experienceYears;
  final double basePrice;
  final String location;
  final double rating;
  final bool isAvailable;
  final String? workingHours;
  final List<String> workingDays;
  final List<TechServiceItem> services;
  final List<TechReviewItem> reviews;

  TechnicianDetailModel({
    required this.id,
    required this.name,
    required this.email,
    required this.bio,
    required this.skills,
    required this.experienceYears,
    required this.basePrice,
    required this.location,
    required this.rating,
    required this.isAvailable,
    this.workingHours,
    required this.workingDays,
    required this.services,
    required this.reviews,
  });

  factory TechnicianDetailModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final avail = json['availability'] as Map<String, dynamic>?;
    final skillsRaw = json['skills'] as List? ?? [];
    final servicesRaw = json['services'] as List? ?? [];
    final reviewsRaw = json['reviews'] as List? ?? [];
    final daysRaw = avail?['workingDays'] as List? ?? [];

    return TechnicianDetailModel(
      id: json['id'] ?? '',
      name: user?['name'] ?? 'Expert Technician',
      email: user?['email'] ?? '',
      bio: json['bio'] ??
          'Certified home repair & installation specialist dedicated to high-quality work.',
      skills: skillsRaw.map((e) => e.toString()).toList(),
      experienceYears:
          (json['experienceYears'] ?? json['experience'] ?? 1) as int,
      basePrice: (json['basePrice'] ?? json['hourlyRate'] ?? 0).toDouble(),
      location: json['location'] ?? 'Dhaka, Bangladesh',
      rating: (json['rating'] ?? 5.0).toDouble(),
      isAvailable: (avail?['isAvailable'] as bool?) ??
          (json['isAvailable'] as bool?) ??
          true,
      workingHours: avail?['workingHours'] as String?,
      workingDays: daysRaw.map((e) => e.toString()).toList(),
      services: servicesRaw.map((e) => TechServiceItem.fromJson(e)).toList(),
      reviews: reviewsRaw.map((e) => TechReviewItem.fromJson(e)).toList(),
    );
  }
}

class TechServiceItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String duration;
  final String? categoryName;

  TechServiceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    this.categoryName,
  });

  factory TechServiceItem.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;
    return TechServiceItem(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Service',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      duration: json['duration'] ?? '1-2 Hours',
      categoryName: cat?['name'],
    );
  }
}

class TechReviewItem {
  final String id;
  final double rating;
  final String comment;
  final String createdAt;
  final String customerName;

  TechReviewItem({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.customerName,
  });

  factory TechReviewItem.fromJson(Map<String, dynamic> json) {
    final cust = json['customer'] as Map<String, dynamic>?;
    return TechReviewItem(
      id: json['id'] ?? '',
      rating: (json['rating'] ?? 5.0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] ?? '',
      customerName: cust?['name'] ?? 'Verified Customer',
    );
  }
}

// ==========================================
// 🌟 টেকনিশিয়ান ডিটেইল স্ক্রিন (UI)
// ==========================================
class TechnicianDetailScreen extends StatefulWidget {
  final String technicianId;
  final String? initialName;

  const TechnicianDetailScreen({
    super.key,
    required this.technicianId,
    this.initialName,
  });

  @override
  State<TechnicianDetailScreen> createState() => _TechnicianDetailScreenState();
}

class _TechnicianDetailScreenState extends State<TechnicianDetailScreen> {
  // 🌟 ইন-মেমোরি ক্যাশিং: আগে ভিজিট করা টেকনিশিয়ান প্রোফাইল সাথে সাথে রেন্ডার হবে
  static final Map<String, TechnicianDetailModel> _techCache = {};

  TechnicianDetailModel? _tech;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (_techCache.containsKey(widget.technicianId)) {
      _tech = _techCache[widget.technicianId];
      _isLoading = false;
      // ব্যাকগ্রাউন্ডে সাইলেন্ট আপডেট
      _fetchTechnicianDetail(silent: true);
    } else {
      _fetchTechnicianDetail();
    }
  }

  Future<void> _fetchTechnicianDetail({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final uri = Uri.parse('${ApiEndpoints.technicians}/${widget.technicianId}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final loadedTech = TechnicianDetailModel.fromJson(decoded['data']);
          _techCache[widget.technicianId] = loadedTech; // 👈 ক্যাশে সেভ
          if (mounted) {
            setState(() {
              _tech = loadedTech;
              _isLoading = false;
            });
          }
          return;
        }
      }
      if (!silent && mounted) {
        setState(() {
          _errorMessage = "Could not load technician details.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          _errorMessage = "Network error: $e";
          _isLoading = false;
        });
      }
    }
  }

  // 🌟 বুকিং বটম শীট ডায়ালগ
  Future<void> _openBookingSheet() async {
    if (_tech == null) return;

    final user = await AuthService.getUser();
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please log in as a Customer to book this technician."),
          backgroundColor: AppColors.coral,
          action: SnackBarAction(
            label: "Login",
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    if (user.role.toUpperCase() != 'CUSTOMER') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Only Customer accounts can book technicians. You are logged in as a ${user.role}."),
          backgroundColor: const Color(0xFFD97706),
        ),
      );
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookingBottomSheet(technician: _tech!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.initialName ?? "Technician Profile",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: _tech != null ? _buildStickyBottomBar() : null,
      body: _isLoading
          ? const _TechnicianDetailSkeleton()
          : _errorMessage != null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ১. প্রোফাইল ইনফো হেডার কার্ড
                      _buildProfileHeaderCard(),
                      const SizedBox(height: 16),

                      // ২. বায়ো / অ্যাবাউট সেকশন
                      _buildAboutSection(),
                      const SizedBox(height: 16),

                      // ৩. কাজের সময় ও দিন (Working Schedule)
                      if (_tech!.workingHours != null ||
                          _tech!.workingDays.isNotEmpty) ...[
                        _buildScheduleSection(),
                        const SizedBox(height: 16),
                      ],

                      // ৪. স্কিলস ও এক্সপার্টাইজ
                      if (_tech!.skills.isNotEmpty) ...[
                        _buildSkillsSection(),
                        const SizedBox(height: 16),
                      ],

                      // ৫. অফার করা সার্ভিসেস ও প্রাইসিং
                      if (_tech!.services.isNotEmpty) ...[
                        _buildOfferedServicesSection(),
                        const SizedBox(height: 16),
                      ],

                      // ৬. কাস্টমার রিভিউস
                      _buildCustomerReviewsSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  // ১. প্রোফাইল হেডার কার্ড
  Widget _buildProfileHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E2D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // বড় অ্যাভাটার
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.ink,
                    child: Text(
                      _tech!.name.isNotEmpty ? _tech!.name[0].toUpperCase() : 'T',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _tech!.isAvailable
                            ? const Color(0xFF10B981)
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // নাম ও লোকেশন
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _tech!.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: AppColors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: AppColors.coral,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _tech!.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B707E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF3EFEA)),
          const SizedBox(height: 12),

          // রেটিং ও স্ট্যাটাস ব্যাজ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _tech!.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _tech!.isAvailable
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _tech!.isAvailable
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFFECDD3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _tech!.isAvailable
                          ? Icons.check_circle_rounded
                          : Icons.access_time_filled_rounded,
                      size: 14,
                      color: _tech!.isAvailable
                          ? const Color(0xFF059669)
                          : const Color(0xFFE11D48),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _tech!.isAvailable
                          ? "Available Now"
                          : "Currently Offline",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _tech!.isAvailable
                            ? const Color(0xFF059669)
                            : const Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ২. বায়ো / অ্যাবাউট সেকশন
  Widget _buildAboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E2D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "About Technician",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tech!.bio,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ৩. শিডিউল সেকশন
  Widget _buildScheduleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E2D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.schedule_rounded, size: 16, color: AppColors.coral),
              SizedBox(width: 6),
              Text(
                "Working Schedule & Hours",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_tech!.workingHours != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3EFEA)),
              ),
              child: Row(
                children: [
                  const Text(
                    "Active Hours: ",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _tech!.workingHours!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_tech!.workingDays.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3EFEA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Working Days: ",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      _tech!.workingDays.join(", "),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ৪. স্কিলস সেকশন
  Widget _buildSkillsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E2D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Skills & Expertise",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tech!.skills.map((skill) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3EFEA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.handyman_rounded,
                      size: 12,
                      color: AppColors.coral,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ৫. অফার করা সার্ভিসেস ও প্রাইসিং
  Widget _buildOfferedServicesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E2D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.sell_rounded, size: 15, color: AppColors.coral),
              SizedBox(width: 6),
              Text(
                "Offered Services & Pricing",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: _tech!.services.map((srv) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF3EFEA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            srv.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Text(
                          "৳${srv.price.toInt()}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.coral,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      srv.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B707E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Est. Duration: ${srv.duration}",
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ৬. কাস্টমার রিভিউস সেকশন
  Widget _buildCustomerReviewsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E2D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Customer Reviews (${_tech!.reviews.length})",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              if (_tech!.reviews.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "${_tech!.rating.toStringAsFixed(1)} / 5.0",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_tech!.reviews.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3EFEA)),
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 28,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 6),
                  Text(
                    "No customer reviews yet",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Be the first customer to book and share your feedback!",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _tech!.reviews.map((rev) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF3EFEA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rev.customerName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (starIdx) {
                              return Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: starIdx < rev.rating.round()
                                    ? const Color(0xFFD97706)
                                    : Colors.grey.shade300,
                              );
                            }),
                          ),
                        ],
                      ),
                      if (rev.comment.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          "\"${rev.comment}\"",
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // নিচে ফিক্সড স্টিকি বুকিং বার (Sticky Bottom Bar)
  Widget _buildStickyBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "STANDARD RATE",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "৳${_tech!.basePrice.toInt()}/hr",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _tech!.isAvailable ? _openBookingSheet : null,
            icon: const Icon(Icons.calendar_month_rounded, size: 15, color: Colors.white),
            label: Text(
              _tech!.isAvailable ? "Book This Technician" : "Currently Offline",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _tech!.isAvailable ? AppColors.coral : Colors.grey,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? "Error loading profile",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _fetchTechnicianDetail,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
              child: const Text("Retry", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🌟 অ্যানিমেটেড পালসিং স্কেলেটন লোডার (Pure Flutter Shimmer)
// ==========================================
class _TechnicianDetailSkeleton extends StatefulWidget {
  const _TechnicianDetailSkeleton();

  @override
  State<_TechnicianDetailSkeleton> createState() =>
      _TechnicianDetailSkeletonState();
}

class _TechnicianDetailSkeletonState extends State<_TechnicianDetailSkeleton>
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ১. প্রোফাইল কার্ড স্কেলেটন
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE7E2D8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
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
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E4E8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 100,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F1F3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFF3EFEA)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 65,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E4E8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Container(
                            width: 100,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E4E8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ২. অ্যাবাউট সেকশন স্কেলেটন
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE7E2D8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E4E8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F1F3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F1F3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 180,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F1F3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ৩. শিডিউল সেকশন স্কেলেটন
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE7E2D8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E4E8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F1F3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F1F3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ৪. স্কিলস সেকশন স্কেলেটন
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE7E2D8)),
                  ),
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
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(4, (i) {
                          return Container(
                            width: 80.0 + (i * 20),
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F1F3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ৫. অফার করা সার্ভিসেস স্কেলেটন
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE7E2D8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 160,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E4E8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(2, (i) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F1F3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E4E8),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  Container(
                                    width: 50,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E4E8),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E4E8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 90,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E4E8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ৬. কাস্টমার রিভিউস স্কেলেটন
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE7E2D8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 140,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E4E8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            width: 60,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E4E8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(2, (i) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBF3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF3EFEA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 90,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E4E8),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(5, (_) {
                                      return Container(
                                        width: 12,
                                        height: 12,
                                        margin: const EdgeInsets.only(left: 2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE2E4E8),
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E4E8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
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

// ==========================================
// 🌟 বুকিং অ্যাপয়েন্টমেন্ট মডাল (Web-Fidelity Booking Modal)
// ==========================================
class _BookingBottomSheet extends StatefulWidget {
  final TechnicianDetailModel technician;

  const _BookingBottomSheet({required this.technician});

  @override
  State<_BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<_BookingBottomSheet> {
  late DateTime _selectedDate;
  String _selectedSlot = '';
  final TextEditingController _customSlotController = TextEditingController();
  TechServiceItem? _selectedService;
  late double _currentPrice;
  bool _isSubmitting = false;

  late List<String> _slots;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _currentPrice = widget.technician.basePrice;
    _slots = _generateSlots(widget.technician.workingHours);
    if (_slots.isNotEmpty) {
      _selectedSlot = _slots[0];
    } else {
      _selectedSlot = '10:00 AM - 12:00 PM';
    }
  }

  @override
  void dispose() {
    _customSlotController.dispose();
    super.dispose();
  }

  // 🌟 কাজের সময় থেকে স্লট জেনারেশন (Web matching)
  List<String> _generateSlots(String? workingHours) {
    const defaultSlots = [
      '09:00 AM - 11:00 AM',
      '11:00 AM - 01:00 PM',
      '02:00 PM - 04:00 PM',
      '04:00 PM - 06:00 PM',
    ];

    if (workingHours == null || !workingHours.contains('-')) {
      return defaultSlots;
    }

    try {
      final parts = workingHours.split('-');
      int? parseMinutes(String timeStr) {
        final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false)
            .firstMatch(timeStr.trim());
        if (match == null) return null;
        int hours = int.parse(match.group(1)!);
        int mins = int.parse(match.group(2)!);
        String period = match.group(3)!.toUpperCase();
        if (period == 'PM' && hours < 12) hours += 12;
        if (period == 'AM' && hours == 12) hours = 0;
        return hours * 60 + mins;
      }

      int startMins = parseMinutes(parts[0]) ?? 540; // 09:00 AM
      int endMins = parseMinutes(parts[1]) ?? 1080;  // 06:00 PM

      if (endMins <= startMins) {
        return defaultSlots;
      }

      String formatMins(int total) {
        int h = (total ~/ 60) % 24;
        int m = total % 60;
        String period = h >= 12 ? 'PM' : 'AM';
        h = h % 12;
        if (h == 0) h = 12;
        return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period";
      }

      final generated = <String>[];
      int current = startMins;
      const duration = 120; // 2 hours

      while (current < endMins) {
        int next = current + duration;
        if (next > endMins) next = endMins;
        if (next - current >= 30) {
          generated.add("${formatMins(current)} - ${formatMins(next)}");
        }
        current = next;
      }

      return generated.isNotEmpty ? generated : defaultSlots;
    } catch (_) {
      return defaultSlots;
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  // 🌟 বুকিং জমা দেওয়ার লজিক (POST /api/bookings)
  Future<void> _submitBooking() async {
    final effectiveSlot = _customSlotController.text.trim().isNotEmpty
        ? _customSlotController.text.trim()
        : _selectedSlot;

    if (effectiveSlot.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or specify a time slot.'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final res = await CustomerService.createBooking(
      technicianProfileId: widget.technician.id,
      bookingDate: _formatDate(_selectedDate),
      slot: effectiveSlot,
      serviceId: _selectedService?.id,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.success) {
      Navigator.pop(context); // Close sheet
      _showBookingSuccessDialog(effectiveSlot);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: const Color(0xFFE11D48),
        ),
      );
    }
  }

  void _showBookingSuccessDialog(String slot) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Booking Requested!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your appointment with ${widget.technician.name} on ${_formatDate(_selectedDate)} at $slot has been submitted.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      "Status: PENDING. Technician will accept or decline soon. You can pay once accepted!",
                      style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dlgCtx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dlgCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerBookingsScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "My Bookings",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // হ্যান্ডেল বার
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // হেডার
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.coral,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Book Appointment",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            "With ${widget.technician.name}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 16),

              // ১. অফার করা সার্ভিস নির্বাচন (ঐচ্ছিক)
              if (widget.technician.services.isNotEmpty) ...[
                const Text(
                  "Select Offered Service",
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedService?.id ?? '',
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.ink),
                      items: [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text(
                            "Standard Hourly Rate (৳${widget.technician.basePrice.toInt()}/hr)",
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                          ),
                        ),
                        ...widget.technician.services.map((srv) {
                          return DropdownMenuItem<String>(
                            value: srv.id,
                            child: Text(
                              "${srv.name} — ৳${srv.price.toInt()} (${srv.duration})",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          if (val == null || val.isEmpty) {
                            _selectedService = null;
                            _currentPrice = widget.technician.basePrice;
                          } else {
                            final match = widget.technician.services.firstWhere((s) => s.id == val);
                            _selectedService = match;
                            _currentPrice = match.price;
                            if (match.duration.isNotEmpty) {
                              _selectedSlot = match.duration;
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ২. টেকনিশিয়ানের কাজের সময় ব্যাজ
              if (widget.technician.workingHours != null && widget.technician.workingHours!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Active Hours: ${widget.technician.workingHours!}${widget.technician.workingDays.isNotEmpty ? ' (${widget.technician.workingDays.join(", ")})' : ''}",
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ৩. তারিখ নির্বাচন
              const Text(
                "Select Appointment Date",
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 45)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.coral),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ৪. টাইম স্লট নির্বাচন
              const Text(
                "Select Preferred Time Slot",
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _slots.map((slot) {
                  final isSel = _customSlotController.text.isEmpty && _selectedSlot == slot;
                  return InkWell(
                    onTap: () {
                      _customSlotController.clear();
                      setState(() => _selectedSlot = slot);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.coral : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? AppColors.coral : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            slot,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSel ? Colors.white : const Color(0xFF374151),
                            ),
                          ),
                          if (isSel) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 10),
              TextField(
                controller: _customSlotController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: "Or enter custom time (e.g. 05:30 PM)",
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.coral),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ৫. প্রাইস ও সামারি কার্ড
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7E2D8)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedService != null ? "Service Price" : "Standard Rate",
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                        Text(
                          "৳${_currentPrice.toInt()}",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Booking Date", style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Time Slot", style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                        Text(
                          _customSlotController.text.trim().isNotEmpty
                              ? _customSlotController.text.trim()
                              : _selectedSlot,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Color(0xFFE7E2D8)),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Initial Status", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.ink)),
                        Text(
                          "PENDING APPROVAL",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ৬. সাবমিট বাটন
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          "Confirm Booking",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
