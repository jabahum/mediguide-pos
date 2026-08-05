/// Model representing a medical consultant/doctor available for consultation
class ConsultantModel {
  final String id;
  final String name;
  final String specialty;
  final String imageUrl;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final String hospital;
  final String experience;
  final double consultationFee;
  final List<String> languages;

  const ConsultantModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.imageUrl,
    required this.isAvailable,
    required this.rating,
    required this.reviewCount,
    required this.hospital,
    required this.experience,
    required this.consultationFee,
    required this.languages,
  });

  factory ConsultantModel.fromJson(Map<String, dynamic> json) {
    return ConsultantModel(
      id: json['id'] as String,
      name: json['name'] as String,
      specialty: json['specialty'] as String,
      imageUrl: json['imageUrl'] as String,
      isAvailable: json['isAvailable'] as bool,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      hospital: json['hospital'] as String,
      experience: json['experience'] as String,
      consultationFee: (json['consultationFee'] as num).toDouble(),
      languages: List<String>.from(json['languages'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
      'hospital': hospital,
      'experience': experience,
      'consultationFee': consultationFee,
      'languages': languages,
    };
  }

  /// Status display text based on availability
  String get statusText => isAvailable ? 'Available' : 'Busy';

  /// Formatted consultation fee
  String get formattedFee => '\$${consultationFee.toStringAsFixed(0)}';

  /// Short description combining specialty and hospital
  String get shortDescription => '$specialty at $hospital';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsultantModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ConsultantModel{id: $id, name: $name, specialty: $specialty, isAvailable: $isAvailable}';
  }
}
