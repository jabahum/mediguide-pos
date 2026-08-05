/// Model representing a health facility (hospital, clinic, pharmacy)
class FacilityModel {
  final String id;
  final String name;
  final String type;
  final String address;
  final double latitude;
  final double longitude;
  final double distance; // in kilometers
  final double rating;
  final int reviewCount;
  final String phoneNumber;
  final List<String> services;
  final bool is24Hours;
  final bool hasEmergency;
  final String imageUrl;

  const FacilityModel({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.phoneNumber,
    required this.services,
    required this.is24Hours,
    required this.hasEmergency,
    required this.imageUrl,
  });

  factory FacilityModel.fromJson(Map<String, dynamic> json) {
    return FacilityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      phoneNumber: json['phoneNumber'] as String,
      services: List<String>.from(json['services'] as List),
      is24Hours: json['is24Hours'] as bool,
      hasEmergency: json['hasEmergency'] as bool,
      imageUrl: json['imageUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'rating': rating,
      'reviewCount': reviewCount,
      'phoneNumber': phoneNumber,
      'services': services,
      'is24Hours': is24Hours,
      'hasEmergency': hasEmergency,
      'imageUrl': imageUrl,
    };
  }

  /// Formatted distance string
  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).round()}m away';
    }
    return '${distance.toStringAsFixed(1)}km away';
  }

  /// Operating hours display text
  String get operatingHours => is24Hours ? '24/7' : '8:00 AM - 8:00 PM';

  /// Facility type display icon
  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'hospital':
        return '🏥';
      case 'clinic':
        return '🏥';
      case 'pharmacy':
        return '💊';
      case 'laboratory':
        return '🧪';
      default:
        return '🏥';
    }
  }

  /// Primary service offered (first in services list)
  String get primaryService => services.isNotEmpty ? services.first : 'General';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacilityModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FacilityModel{id: $id, name: $name, type: $type, distance: $formattedDistance}';
  }
}
