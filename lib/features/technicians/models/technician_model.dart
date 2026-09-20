class TechnicianModel {
  final String id;
  final String name;
  final String email;
  final String? bio;
  final List<String> skills;
  final int experienceYears;
  final double basePrice;
  final String location;
  final double rating;
  final bool isAvailable;

  TechnicianModel({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    required this.skills,
    required this.experienceYears,
    required this.basePrice,
    required this.location,
    required this.rating,
    required this.isAvailable,
  });

  factory TechnicianModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final skillsRaw = json['skills'] as List? ?? [];
    final avail = json['availability'] as Map<String, dynamic>?;

    return TechnicianModel(
      id: json['id'] ?? '',
      name: user?['name'] ?? 'Expert Technician',
      email: user?['email'] ?? '',
      bio: json['bio'],
      skills: skillsRaw.map((e) => e.toString()).toList(),
      experienceYears: (json['experienceYears'] ?? json['experience'] ?? 1) as int,
      basePrice: (json['basePrice'] ?? json['hourlyRate'] ?? 0).toDouble(),
      location: json['location'] ?? 'Dhaka, Bangladesh',
      rating: (json['rating'] ?? 5.0).toDouble(),
      isAvailable: avail?['isAvailable'] ?? true,
    );
  }
}
