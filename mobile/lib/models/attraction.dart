class Attraction {
  final String id;
  final String name;
  final String location;
  final String district;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final String openingTime;
  final String closingTime;
  final int estimatedVisitDuration;
  final double entryFee;
  final String environment;
  final double popularityScore;

  Attraction({
    required this.id,
    required this.name,
    required this.location,
    required this.district,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.openingTime,
    required this.closingTime,
    required this.estimatedVisitDuration,
    required this.entryFee,
    required this.environment,
    required this.popularityScore,
  });

  factory Attraction.fromJson(Map<String, dynamic> json) {
    return Attraction(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      district: json['district'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      openingTime: json['openingTime'] ?? '',
      closingTime: json['closingTime'] ?? '',
      estimatedVisitDuration: json['estimatedVisitDuration'] ?? 0,
      entryFee: (json['entryFee'] ?? 0).toDouble(),
      environment: json['environment'] ?? '',
      popularityScore: (json['popularityScore'] ?? 0).toDouble(),
    );
  }
}