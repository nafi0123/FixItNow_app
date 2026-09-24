import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FaqSection extends StatefulWidget {
  const FaqSection({super.key});

  @override
  State<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<FaqSection> {
  // প্রথম প্রশ্নটি ডিফল্টভাবে ওপেন থাকবে (ওয়েবসাইটের মতো)
  int? openIndex = 0;

  // ওয়েবসাইটের আসল FAQ ডাটা
  final List<Map<String, String>> faqs = [
    {
      "question": "How do I book a technician?",
      "answer":
          "Search for the service you need, compare verified technicians by rating and price, pick a time slot, and confirm. Most bookings get a technician assigned within minutes."
    },
    {
      "question": "Are technicians actually background-checked?",
      "answer":
          "Every technician passes an NID verification, a skills assessment, and a background check before they're allowed to take a single job on FixItNow."
    },
    {
      "question": "What happens if the repair isn't done right?",
      "answer":
          "You're covered by our Service Guarantee. Flag it within 7 days and we'll send someone back to fix it properly — no extra charge."
    },
    {
      "question": "How do I pay?",
      "answer":
          "Pay online with mobile banking or a card when you book, or choose Cash on Service and pay the technician once the job's done."
    },
    {
      "question": "Can I cancel or reschedule?",
      "answer":
          "Yes — free of charge, any time up to 2 hours before the scheduled slot. Just manage it from your dashboard."
    },
  ];

  void _toggleFaq(int index) {
    setState(() {
      openIndex = (openIndex == index) ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 950;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        // ওয়েবের মতো উষ্ণ ক্রিম গ্রেডিয়েন্ট
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFBF3),
            Color(0xFFFFF6EA),
            Color(0xFFFFF0E2),
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 16,
        vertical: isDesktop ? 64 : 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ১. হেডার
              _buildHeader(isDesktop),

              const SizedBox(height: 32),

              // ২. FAQ অ্যাকর্ডিয়ন লিস্ট
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: faqs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final faq = faqs[index];
                  final isOpen = openIndex == index;

                  return _buildFaqItem(faq, index, isOpen);
                },
              ),

              const SizedBox(height: 36),

              // ৩. বটম সাপোর্ট কলআউট কার্ড
              _buildSupportCallout(isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Column(
      children: [
        // আইকন ব্যাজ
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.coral.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.help_outline_rounded, color: Color(0xFFC23B1F), size: 22),
        ),

        const SizedBox(height: 14),

        // টাইটেল
        Text(
          "Questions, answered straight",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop ? 34 : 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        // সাবটাইটেল
        const Text(
          "No fine print. Here's exactly how booking a repair on FixItNow works.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B707E),
          ),
        ),
      ],
    );
  }

  // সিঙ্গেল FAQ কার্ড (টগলযোগ্য)
  Widget _buildFaqItem(Map<String, String> faq, int index, bool isOpen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOpen ? AppColors.coral.withValues(alpha: 0.35) : AppColors.coral.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleFaq(index),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // প্রশ্ন ও অ্যারো আইকন
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        faq["question"]!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isOpen ? const Color(0xFFC23B1F) : AppColors.textDark,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isOpen ? 0.5 : 0.0, // ১৮০ ডিগ্রি রোটেশন
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.coral,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                // উত্তর (স্মুথ এক্সপ্যান্ড)
                if (isOpen) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF3ECE1)),
                  const SizedBox(height: 10),
                  Text(
                    faq["answer"]!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: Color(0xFF6B707E),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // বটম সাপোর্ট বক্স
  Widget _buildSupportCallout(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF6EA), Color(0xFFFFF0E2)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Text(
            "Still stuck on something?",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            "Our support team answers 24/7 — no bots, no hold music.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF6B707E)),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to Contact Support
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              "Contact support",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
