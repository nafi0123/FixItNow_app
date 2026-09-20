import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int? openIndex = 0; // প্রথম প্রশ্নটি ডিফল্ট খোলা থাকবে

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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Help & FAQ",
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ১. হেডার
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.coral.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.coral.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.help_outline_rounded, color: Color(0xFFC23B1F), size: 24),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Questions, answered straight",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "No fine print. Here's exactly how booking a repair on FixItNow works.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B707E)),
                ),

                const SizedBox(height: 28),

                // ২. FAQ অ্যাকর্ডিয়ন লিস্ট
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: faqs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final faq = faqs[index];
                    final isOpen = openIndex == index;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isOpen ? AppColors.coral.withOpacity(0.4) : const Color(0xFFE7E2D8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _toggleFaq(index),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        faq["question"]!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isOpen ? const Color(0xFFC23B1F) : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: isOpen ? 0.5 : 0.0,
                                      duration: const Duration(milliseconds: 200),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.coral,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isOpen) ...[
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, color: Color(0xFFF1EAE0)),
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
                  },
                ),

                const SizedBox(height: 32),

                // ৩. ২৪/৭ সাপোর্ট কার্ড
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF6EA), Color(0xFFFFF0E2)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.coral.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Still stuck on something?",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Our support team answers 24/7 — no bots, no hold music.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B707E)),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Contact support",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
