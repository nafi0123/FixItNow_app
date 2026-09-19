import 'package:flutter/material.dart';

class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key});

  // থিম কালার
  static const Color ink = Color(0xFF14171C);
  static const Color coral = Color(0xFFFF5A36);
  static const Color coralDark = Color(0xFFC23B1F);
  static const Color textDark = Color(0xFF1E2026);
  static const Color textMuted = Color(0xFF6B707E);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      // কোনো Row বা ডানে-বামে ভাগ নেই, শুধুমাত্র একটি সিঙ্গেল কলাম
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ১. রেটিং ব্যাজ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: coral.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified_user_outlined, size: 14, color: coral),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Rated 4.9/5 by 10,000+ homeowners in BD",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: coralDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ২. মেইন টাইটেল
              const Text(
                "Something broke?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),

              // গ্রেডিয়েন্ট টাইটেল
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [coral, coralDark],
                ).createShader(bounds),
                child: const Text(
                  "Get it fixed today.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ৩. সাবটাইটেল
              const Text(
                "Tell us what's wrong, pick a time, and a background-checked technician shows up — usually the same day. Upfront pricing, no surprise fees.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: textMuted,
                ),
              ),

              const SizedBox(height: 24),

              // ৪. বাটনসমূহ
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  // Fix something now বাটন
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [coral, coralDark]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: coral.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            "Fix something now",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  ),

                  // Earn as a technician বাটন
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.8),
                      side: BorderSide(color: coral.withOpacity(0.35)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      "Earn as a technician",
                      style: TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ৫. স্ট্যাটস
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: coral.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatItem("500+", "Verified experts"),
                    _buildDivider(),
                    _buildStatItem("10k+", "Jobs done"),
                    _buildDivider(),
                    _buildStatItem("24/7", "Support"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: textDark),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 22,
      width: 1,
      color: coral.withOpacity(0.2),
    );
  }
}
