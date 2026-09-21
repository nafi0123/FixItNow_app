import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../technicians/models/technician_model.dart';
import '../../technicians/screens/technicians_screen.dart';
import '../../technicians/screens/technician_detail_screen.dart';

class TopRatedTechniciansSection extends StatefulWidget {
  const TopRatedTechniciansSection({super.key});

  @override
  State<TopRatedTechniciansSection> createState() => _TopRatedTechniciansSectionState();
}

class _TopRatedTechniciansSectionState extends State<TopRatedTechniciansSection> {
  List<TechnicianModel> technicians = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchTechnicians();
  }

  // API থেকে টেকনিশিয়ান ডাটা নিয়ে আসা
  Future<void> fetchTechnicians() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.technicians));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          final List list = decoded['data'];
          if (mounted) {
            setState(() {
              technicians = list.map((json) => TechnicianModel.fromJson(json)).toList();
              isLoading = false;
            });
          }
          return;
        }
      }
      throw Exception("Failed to load technicians");
    } catch (e) {
      debugPrint("Technicians Fetch Error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Could not load technicians.";
        });
      }
    }
  }

  // নামের আদ্যক্ষর (Initials: যেমন RH, NB) বের করা
  String _getInitials(String name) {
    final parts = name.trim().split(" ");
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase() : "T";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 950;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 16,
        vertical: isDesktop ? 48 : 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // সেকশন হেডার
              _buildHeader(isDesktop),

              const SizedBox(height: 20),

              // X-Axis হরাইজন্টাল স্ক্রোল লিস্ট
              if (isLoading)
                _buildLoadingList()
              else if (errorMessage != null && technicians.isEmpty)
                _buildErrorView()
              else
                _buildHorizontalTechniciansList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ব্যাজ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.verified_user_outlined, size: 13, color: AppColors.coral),
                  SizedBox(width: 5),
                  Text(
                    "VERIFIED EXPERTS",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.coral,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // টাইটেল
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: isDesktop ? 26 : 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
                children: const [
                  TextSpan(text: "Top Rated "),
                  TextSpan(text: "Technicians", style: TextStyle(color: AppColors.coral)),
                ],
              ),
            ),
          ],
        ),

        // ভিউ অল বাটন
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TechniciansScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Row(
            children: const [
              Text(
                "Browse all",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.coral),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.coral),
            ],
          ),
        ),
      ],
    );
  }

  // X-Axis Horizontal List (ডানে-বাঁয়ে স্ক্রোল হবে)
  Widget _buildHorizontalTechniciansList() {
    return SizedBox(
      height: 250, // ফিক্সড কার্ড হাইট
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: technicians.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final tech = technicians[index];
          return _buildTechnicianCard(tech);
        },
      ),
    );
  }

  Widget _buildTechnicianCard(TechnicianModel tech) {
    final initials = _getInitials(tech.name);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TechnicianDetailScreen(
              technicianId: tech.id,
              initialName: tech.name,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 280, // ফিক্সড কার্ড প্রস্থ
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // টপ রো: অ্যাভাটার + নাম + রেটিং
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // প্রোফাইল ইনিশিয়াল ও একটিভ ডট
              Stack(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: tech.isAvailable ? AppColors.teal : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // নাম ও লোকেশন
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tech.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.teal),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.coral),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            tech.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B707E)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // রেটিং ব্যাজ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 2),
                    Text(
                      tech.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // বায়ো / অভিজ্ঞতা
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              tech.bio ?? "Experienced technical repair specialist providing high quality services.",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B707E), height: 1.4),
            ),
          ),

          // স্কিল ও এক্সপেরিয়েন্স ট্যাগ
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE7E2D8)),
                ),
                child: Text(
                  "📅 ${tech.experienceYears}+ Yrs",
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
              ),
              if (tech.skills.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tech.skills.first,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.teal),
                  ),
                ),
            ],
          ),

          const Divider(height: 16, color: Color(0xFFF3EFEA)),

          // ফুটার: রেট এবং ভিউ প্রোফাইল বাটন
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("RATE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey)),
                  Text(
                    "৳${tech.basePrice.toInt()} / hr",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TechnicianDetailScreen(
                        technicianId: tech.id,
                        initialName: tech.name,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text("View Profile", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildLoadingList() {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7E2D8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14))),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 100, height: 14, color: Colors.grey.shade100),
                        const SizedBox(height: 6),
                        Container(width: 60, height: 10, color: Colors.grey.shade50),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(width: double.infinity, height: 10, color: Colors.grey.shade50),
                const Spacer(),
                Container(width: double.infinity, height: 32, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.grey, size: 30),
            const SizedBox(height: 6),
            Text(errorMessage!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            TextButton(
              onPressed: () {
                setState(() => isLoading = true);
                fetchTechnicians();
              },
              child: const Text("Retry", style: TextStyle(color: AppColors.coral, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
