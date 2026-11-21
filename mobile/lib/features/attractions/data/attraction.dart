import 'dart:convert';

import 'admission.dart';

class Attraction {
  final String id;
  final String name;
  final List<String> aliases;
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
  final bool? freeAdmission;
  final String environment;
  final double popularityScore;

  Attraction({
    required this.id,
    required this.name,
    this.aliases = const [],
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
    this.freeAdmission,
    required this.environment,
    required this.popularityScore,
  });

  String get bookmarkKey => id.isEmpty
      ? 'place:${jsonEncode([name, location, district])}'
      : 'attraction:$id';

  String get admissionLabel {
    if (entryFee.isFinite && entryFee > 0) {
      return 'LKR ${entryFee.toStringAsFixed(2)}';
    }
    if (freeAdmission == true) return 'Free';
    if (freeAdmission == false) return admissionNotListed;
    return curatedAdmission([name, ...aliases]) ?? admissionNotListed;
  }

  String get displayLocation => [
    location.trim(),
    district.trim(),
  ].where((part) => part.isNotEmpty).toSet().join(', ');

  String? get visitDuration {
    if (estimatedVisitDuration <= 0) return null;
    final hours = estimatedVisitDuration ~/ 60;
    final minutes = estimatedVisitDuration % 60;
    return [
      if (hours > 0) '$hours ${hours == 1 ? 'hr' : 'hrs'}',
      if (minutes > 0) '$minutes min',
    ].join(' ');
  }

  factory Attraction.fromJson(Map<String, dynamic> json) {
    return Attraction(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      aliases:
          (json['aliases'] as List?)?.whereType<String>().toList() ?? const [],
      location: json['location'] ?? '',
      district: json['district'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      openingTime: json['openingTime'] ?? '',
      closingTime: json['closingTime'] ?? '',
      estimatedVisitDuration:
          (json['estimatedVisitDuration'] as num?)?.round() ?? 0,
      entryFee: (json['entryFee'] as num?)?.toDouble() ?? 0,
      freeAdmission: json['freeAdmission'] as bool?,
      environment: json['environment'] ?? '',
      popularityScore: (json['popularityScore'] ?? 0).toDouble(),
    );
  }
}
