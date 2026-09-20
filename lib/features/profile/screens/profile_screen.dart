import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../faq/screens/faq_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Account',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ১. ইউজার প্রোফাইল কার্ড / লগইন প্রম্পট
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.coral,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Welcome to FixItNow',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Sign in to book & track technicians',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Login / Auth flow coming next!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ২. হেল্প ও সাপোর্ট সেকশন (FAQ সেকশন এখানে প্রধান প্রাধান্য পাবে)
                const Text(
                  'SUPPORT & HELP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),

                // 🎯 FAQ & Help Center টাইল
                _optionTile(
                  context,
                  icon: Icons.help_outline_rounded,
                  iconColor: AppColors.coral,
                  title: 'FAQ & Help Center',
                  subtitle: 'Common questions answered clearly',
                  badgeText: 'Important',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FaqScreen(),
                      ),
                    );
                  },
                ),

                // ২৪/৭ কাস্টমার সাপোর্ট টাইল
                _optionTile(
                  context,
                  icon: Icons.support_agent_rounded,
                  iconColor: AppColors.teal,
                  title: '24/7 Live Support',
                  subtitle: 'Talk directly with support team',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Support Hotline: +880 1700-000000'),
                      ),
                    );
                  },
                ),

                // শর্তাবলী ও প্রাইভেসি
                _optionTile(
                  context,
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Terms & Privacy Policy',
                  subtitle: 'Safety, rights and platform rules',
                  onTap: () {},
                ),

                const SizedBox(height: 24),

                // ৩. জেনারেল সেটিংস
                const Text(
                  'PREFERENCES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),

                _optionTile(
                  context,
                  icon: Icons.language_rounded,
                  iconColor: Colors.orange,
                  title: 'Language / ভাষা',
                  subtitle: 'English / বাংলা',
                  onTap: () {},
                ),

                _optionTile(
                  context,
                  icon: Icons.notifications_none_rounded,
                  iconColor: Colors.purple,
                  title: 'Notifications',
                  subtitle: 'Booking alerts and updates',
                  onTap: () {},
                ),

                const SizedBox(height: 30),

                // অ্যাপ ভার্সন ফুটার
                Center(
                  child: Column(
                    children: const [
                      Text(
                        'FixItNow App v1.0.0',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Fast, Reliable On-Demand Repairs',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.coral.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  color: AppColors.coral,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
