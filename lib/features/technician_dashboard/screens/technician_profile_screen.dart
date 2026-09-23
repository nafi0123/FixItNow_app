import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../services/technician_service.dart';

class TechnicianProfileScreen extends StatefulWidget {
  const TechnicianProfileScreen({super.key});

  @override
  State<TechnicianProfileScreen> createState() => _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen>
    with WidgetsBindingObserver {
  static const String _cacheKey = 'technician_profile_cache';

  UserModel? _user;
  bool _isLoading = true;

  // Active Tab Index: 0 = Profile Details, 1 = Work Schedule & Availability
  int _activeTab = 0;

  // Profile Details Controllers
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _workingHoursController = TextEditingController();

  List<String> _selectedSkills = []; // Stores Category UUIDs
  List<String> _selectedWorkingDays = [];
  bool _isAvailable = true;

  List<CategoryItem> _availableCategories = [];
  bool _isLoadingCategories = false;

  bool _isSavingProfile = false;
  bool _isSavingSchedule = false;

  // Standard Week Days List (Matching Web backend: full names stored, short names displayed)
  final List<Map<String, String>> _weekDays = [
    {'full': 'Monday', 'short': 'Mon'},
    {'full': 'Tuesday', 'short': 'Tue'},
    {'full': 'Wednesday', 'short': 'Wed'},
    {'full': 'Thursday', 'short': 'Thu'},
    {'full': 'Friday', 'short': 'Fri'},
    {'full': 'Saturday', 'short': 'Sat'},
    {'full': 'Sunday', 'short': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bioController.dispose();
    _locationController.dispose();
    _hourlyRateController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadProfileData(isBackground: true);
    }
  }

  // 🌟 Load Categories and Profile Data
  Future<void> _initProfile() async {
    // 1. Try reading from instant cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_cacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final data = jsonDecode(cachedStr) as Map<String, dynamic>;
        if (mounted) {
          _populateFields(data);
          _isLoading = false;
        }
      }
    } catch (e) {
      debugPrint('Profile Cache Read Error: $e');
    }

    // 2. Fetch fresh live data
    await _loadProfileData(isBackground: !_isLoading);
  }

  Future<void> _loadProfileData({bool isBackground = false}) async {
    if (!isBackground) setState(() => _isLoading = true);
    setState(() => _isLoadingCategories = true);

    try {
      final results = await Future.wait([
        TechnicianService.getCategories(),
        AuthService.getUser(forceRefresh: true),
      ]);

      final cats = results[0] as List<CategoryItem>;
      final freshUser = results[1] as UserModel?;

      if (mounted) {
        setState(() {
          _availableCategories = cats;
          _isLoadingCategories = false;
          if (freshUser != null) {
            _user = freshUser;
            if (freshUser.technicianProfile != null) {
              _populateFields(freshUser.technicianProfile!);
            }
          }
          _isLoading = false;
        });

        if (freshUser?.technicianProfile != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, jsonEncode(freshUser!.technicianProfile!));
        }
      }
    } catch (e) {
      debugPrint('Error loading technician profile data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingCategories = false;
        });
      }
    }
  }

  void _populateFields(Map<String, dynamic> prof) {
    _bioController.text = prof['bio']?.toString() ?? '';
    _locationController.text = prof['location']?.toString() ?? '';

    final rate = prof['basePrice'] ?? prof['hourlyRate'] ?? 50;
    _hourlyRateController.text = rate.toString();

    // Skills Category UUIDs
    if (prof['skills'] is List) {
      _selectedSkills = (prof['skills'] as List).map((s) => s.toString()).toList();
    }

    // Availability Object
    final avail = prof['availability'];
    if (avail is Map<String, dynamic>) {
      _isAvailable = avail['isAvailable'] == true;
      _workingHoursController.text = avail['workingHours']?.toString() ?? '09:00 AM - 06:00 PM';
      if (avail['workingDays'] is List) {
        _selectedWorkingDays = (avail['workingDays'] as List).map((d) => d.toString()).toList();
      }
    } else if (prof['isAvailable'] != null) {
      _isAvailable = prof['isAvailable'] == true;
      _workingHoursController.text = prof['workingHours']?.toString() ?? '09:00 AM - 06:00 PM';
      if (prof['workingDays'] is List) {
        _selectedWorkingDays = (prof['workingDays'] as List).map((d) => d.toString()).toList();
      }
    } else {
      if (_workingHoursController.text.isEmpty) {
        _workingHoursController.text = '09:00 AM - 06:00 PM';
      }
      if (_selectedWorkingDays.isEmpty) {
        _selectedWorkingDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
      }
    }
  }

  // 🌟 Toggle Skill Category (Active / Inactive)
  void _toggleSkill(String categoryId) {
    setState(() {
      if (_selectedSkills.contains(categoryId)) {
        _selectedSkills.remove(categoryId);
      } else {
        _selectedSkills.add(categoryId);
      }
    });
  }

  // 🌟 Toggle Working Day (Active / Inactive)
  void _toggleDay(String fullDay, String shortDay) {
    setState(() {
      final hasFull = _selectedWorkingDays.contains(fullDay);
      final hasShort = _selectedWorkingDays.contains(shortDay);

      if (hasFull || hasShort) {
        _selectedWorkingDays.remove(fullDay);
        _selectedWorkingDays.remove(shortDay);
      } else {
        _selectedWorkingDays.add(fullDay);
      }
    });
  }

  // 🌟 Save Profile Details (Bio, Location, Hourly Rate, Category UUID Skills)
  Future<void> _saveProfileDetails() async {
    final messenger = ScaffoldMessenger.of(context);
    final rate = double.tryParse(_hourlyRateController.text.trim()) ?? 50.0;

    setState(() => _isSavingProfile = true);

    final res = await TechnicianService.updateProfile(
      bio: _bioController.text.trim(),
      location: _locationController.text.trim(),
      hourlyRate: rate,
      skills: _selectedSkills,
    );

    if (mounted) {
      setState(() => _isSavingProfile = false);

      if (res.success) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile details updated successfully!'), backgroundColor: Color(0xFF0FA894)),
        );
        _loadProfileData(isBackground: true);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // 🌟 Save Work Schedule & Availability
  Future<void> _saveSchedule() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSavingSchedule = true);

    final res = await TechnicianService.updateAvailability(
      isAvailable: _isAvailable,
      workingDays: _selectedWorkingDays,
      workingHours: _workingHoursController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSavingSchedule = false);

      if (res.success) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Working schedule updated successfully!'), backgroundColor: Color(0xFF0FA894)),
        );
        _loadProfileData(isBackground: true);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // 🌟 Change Password Modal
  Future<void> _openChangePasswordModal() async {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool isSaving = false;
    bool obscureOld = true;
    bool obscureNew = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 16, color: Color(0xFFE7E2D8)),

              const Text('Current Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
              const SizedBox(height: 6),
              TextField(
                controller: oldPasswordCtrl,
                obscureText: obscureOld,
                decoration: InputDecoration(
                  hintText: 'Enter current password',
                  suffixIcon: IconButton(
                    icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, size: 18),
                    onPressed: () => setModalState(() => obscureOld = !obscureOld),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAF8F5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),

              const Text('New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
              const SizedBox(height: 6),
              TextField(
                controller: newPasswordCtrl,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  hintText: 'At least 6 characters',
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                    onPressed: () => setModalState(() => obscureNew = !obscureNew),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAF8F5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),

              const Text('Confirm New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
              const SizedBox(height: 6),
              TextField(
                controller: confirmPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Re-enter new password',
                  filled: true,
                  fillColor: const Color(0xFFFAF8F5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final oldPass = oldPasswordCtrl.text.trim();
                          final newPass = newPasswordCtrl.text.trim();
                          final confirmPass = confirmPasswordCtrl.text.trim();

                          if (oldPass.isEmpty || newPass.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all password fields')));
                            return;
                          }
                          if (newPass != confirmPass) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                            return;
                          }

                          setModalState(() => isSaving = true);
                          final res = await TechnicianService.changePassword(
                            currentPassword: oldPass,
                            newPassword: newPass,
                          );

                          if (!context.mounted) return;
                          Navigator.pop(ctx);

                          if (res.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Color(0xFF0FA894)),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res.message), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 Logout
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text('Are you sure you want to log out of your technician account?', style: TextStyle(fontSize: 13, color: Color(0xFF6B707E))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B707E)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?.name ?? 'Technician';
    final email = _user?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text('Technician Profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF14171C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF14171C)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE7E2D8), height: 1),
        ),
      ),
      body: _isLoading
          ? _buildProfileSkeleton()
          : RefreshIndicator(
              onRefresh: () => _loadProfileData(isBackground: false),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Live Profile Preview Hero Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF14171C), Color(0xFF232832)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: const Color(0xFF0FA894),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'T',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: const TextStyle(color: Color(0xFF9AA0AA), fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0FA894).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF0FA894)),
                                ),
                                child: const Text('TECHNICIAN', style: TextStyle(color: Color(0xFF0FA894), fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Colors.white24),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('Hourly Rate', style: TextStyle(color: Color(0xFF9AA0AA), fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '৳${_hourlyRateController.text.isNotEmpty ? _hourlyRateController.text : "50"}/hr',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 24, color: Colors.white24),
                              Column(
                                children: [
                                  const Text('Status', style: TextStyle(color: Color(0xFF9AA0AA), fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isAvailable ? '🟢 Online' : '🔴 Busy',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 24, color: Colors.white24),
                              Column(
                                children: [
                                  const Text('Location', style: TextStyle(color: Color(0xFF9AA0AA), fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _locationController.text.isNotEmpty ? _locationController.text : 'Dhaka',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Active Tab Bar (Web-like Prominent Navigation)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE7E2D8)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _activeTab = 0),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _activeTab == 0 ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _activeTab == 0
                                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 16,
                                        color: _activeTab == 0 ? Colors.white : const Color(0xFF6B707E),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Profile Details',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: _activeTab == 0 ? Colors.white : const Color(0xFF6B707E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _activeTab = 1),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _activeTab == 1 ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _activeTab == 1
                                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.schedule_outlined,
                                        size: 16,
                                        color: _activeTab == 1 ? Colors.white : const Color(0xFF6B707E),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Work Schedule',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: _activeTab == 1 ? Colors.white : const Color(0xFF6B707E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Tab Content
                    if (_activeTab == 0) _buildProfileDetailsTab() else _buildWorkScheduleTab(),

                    const SizedBox(height: 16),

                    // 4. Card: Security & Password
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE7E2D8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Security & Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
                          const SizedBox(height: 4),
                          const Text('Manage credentials to keep your technician profile secure.', style: TextStyle(fontSize: 11.5, color: Color(0xFF6B707E))),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _openChangePasswordModal,
                            icon: const Icon(Icons.key_outlined, size: 16, color: Color(0xFF1E2026)),
                            label: const Text('Change Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              side: const BorderSide(color: Color(0xFFE7E2D8)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 5. Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, size: 18, color: Color(0xFFE11D48)),
                        label: const Text('Log Out of Technician Account', style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFFECDD3)),
                          backgroundColor: const Color(0xFFFFF1F2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // 🌟 Tab 1: Profile Details & Category Skills
  Widget _buildProfileDetailsTab() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E2D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Technician Details & Skills', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
          const SizedBox(height: 4),
          const Text('Configure your public rates, service areas and repair competencies.', style: TextStyle(fontSize: 11.5, color: Color(0xFF6B707E))),
          const Divider(height: 20, color: Color(0xFFE7E2D8)),

          // Hourly Rate & Location
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hourly Rate (৳) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _hourlyRateController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: '৳ ',
                        filled: true,
                        fillColor: const Color(0xFFFAF8F5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service Location *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Dhanmondi, Dhaka',
                        filled: true,
                        fillColor: const Color(0xFFFAF8F5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bio
          const Text('Professional Bio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
          const SizedBox(height: 6),
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write a short intro about your experience and expertise...',
              filled: true,
              fillColor: const Color(0xFFFAF8F5),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),

          // Skills Category Multi-Select Chips (Loaded dynamically from DB)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Specialized Categories / Skills (${_selectedSkills.length} active) *',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026)),
              ),
              if (_isLoadingCategories)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Select category skills related to your technical service offerings:', style: TextStyle(fontSize: 11, color: Color(0xFF6B707E))),
          const SizedBox(height: 8),

          if (_availableCategories.isEmpty && !_isLoadingCategories)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFFBF3), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE7E2D8))),
              child: const Text('No categories loaded. Please pull down to refresh.', style: TextStyle(fontSize: 12, color: Color(0xFF6B707E))),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableCategories.map((cat) {
                final isChecked = _selectedSkills.contains(cat.id);
                return InkWell(
                  onTap: () => _toggleSkill(cat.id),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isChecked ? AppColors.primary.withValues(alpha: 0.12) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isChecked ? AppColors.primary : const Color(0xFFE7E2D8),
                        width: isChecked ? 1.5 : 1.0,
                      ),
                      boxShadow: isChecked
                          ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isChecked) ...[
                          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                            color: isChecked ? const Color(0xFFC23B1F) : const Color(0xFF4A4E58),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),

          // Save Profile Details Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingProfile ? null : _saveProfileDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSavingProfile
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Profile Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 Tab 2: Work Schedule & Availability
  Widget _buildWorkScheduleTab() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E2D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Work Schedule & Availability', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
          const SizedBox(height: 4),
          const Text('Control when you are ready to receive new client bookings.', style: TextStyle(fontSize: 11.5, color: Color(0xFF6B707E))),
          const Divider(height: 20, color: Color(0xFFE7E2D8)),

          // Live Availability Switch Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _isAvailable ? const Color(0xFF0FA894).withValues(alpha: 0.4) : const Color(0xFFE7E2D8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isAvailable ? Icons.check_circle : Icons.pause_circle_outline,
                            color: _isAvailable ? const Color(0xFF0FA894) : const Color(0xFFEF4444),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isAvailable ? 'Active Booking Status: Online' : 'Active Booking Status: Offline',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2026)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isAvailable
                            ? 'You are currently accepting new customer bookings.'
                            : 'You are offline and not accepting new job requests.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B707E)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isAvailable,
                  onChanged: (val) => setState(() => _isAvailable = val),
                  activeThumbColor: const Color(0xFF0FA894),
                  activeTrackColor: const Color(0xFF0FA894).withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Working Hours
          const Text('Working Hours *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
          const SizedBox(height: 6),
          TextField(
            controller: _workingHoursController,
            decoration: InputDecoration(
              hintText: 'e.g. 09:00 AM - 06:00 PM',
              prefixIcon: const Icon(Icons.schedule, size: 18, color: AppColors.primary),
              filled: true,
              fillColor: const Color(0xFFFAF8F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E2D8))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),

          // Working Days Selector
          Text('Working Days (${_selectedWorkingDays.length} selected) *', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2026))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weekDays.map((dayMap) {
              final full = dayMap['full']!;
              final short = dayMap['short']!;
              final isSelected = _selectedWorkingDays.contains(full) || _selectedWorkingDays.contains(short);

              return InkWell(
                onTap: () => _toggleDay(full, short),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF14171C) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? const Color(0xFF14171C) : const Color(0xFFE7E2D8)),
                    boxShadow: isSelected
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(
                    short,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF4A4E58),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Save Schedule Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingSchedule ? null : _saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0FA894),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSavingSchedule
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Working Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 Shimmer Skeleton
  Widget _buildProfileSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 170,
            decoration: BoxDecoration(color: const Color(0xFFE2E4E8), borderRadius: BorderRadius.circular(24)),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7E2D8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: 150, decoration: BoxDecoration(color: const Color(0xFFE2E4E8), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 16),
                Container(height: 38, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF0F1F3), borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 12),
                Container(height: 38, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF0F1F3), borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
