class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String duration;
  final String categoryId;
  final String? categoryName;
  final String? technicianId;
  final String? technicianName;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.categoryId,
    this.categoryName,
    this.technicianId,
    this.technicianName,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;
    final techProfile = json['technicianProfile'] as Map<String, dynamic>?;
    final user = techProfile?['user'] as Map<String, dynamic>?;

    return ServiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Service',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      duration: json['duration'] ?? '1-2 Hours',
      categoryId: json['categoryId'] ?? '',
      categoryName: cat?['name'] ?? 'General Service',
      technicianId: json['technicianProfileId'],
      technicianName: user?['name'],
    );
  }
}
