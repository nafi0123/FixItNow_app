class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "CUSTOMER", "TECHNICIAN", "ADMIN"
  final bool isBanned;
  final String? createdAt;
  final Map<String, dynamic>? technicianProfile;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isBanned = false,
    this.createdAt,
    this.technicianProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: (json['role'] ?? 'CUSTOMER').toString().toUpperCase(),
      isBanned: json['isBanned'] as bool? ?? false,
      createdAt: json['createdAt']?.toString(),
      technicianProfile: json['technicianProfile'] is Map<String, dynamic> ? json['technicianProfile'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'isBanned': isBanned,
      if (createdAt != null) 'createdAt': createdAt,
      if (technicianProfile != null) 'technicianProfile': technicianProfile,
    };
  }
}
